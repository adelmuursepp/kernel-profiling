import torch
import cutlass
import cutlass.cute as cute
from cutlass import Float32, BFloat16, Int64
from cutlass.cute.runtime import from_dlpack
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait


# ── Activation ───────────────────────────────────────────────────────────────

def silu_f32(x: Float32) -> Float32:
    """SiLU(x) = x / (1 + exp(-x)), using fast 2^x hardware instruction."""
    LOG2_E = Float32(1.4426950408889634)
    exp_neg_x = cute.math.exp2(x * Float32(-1.0) * LOG2_E, fastmath=True)
    return x / (Float32(1.0) + exp_neg_x)


# ── Kernel class ─────────────────────────────────────────────────────────────

class SwiGLUHopperTMA:
    """
    SwiGLU kernel using TMA for gmem->smem copy and WGMMA for matrix multiply.

    One warpgroup (128 threads) per block.
    Warp 0 issues TMA loads for X, W1, W2; all 4 warps perform WGMMA.
    PipelineTmaAsync mbarrier synchronizes producer (TMA) and consumers (WGMMA).

    Tile sizes:
      tile_m = 64   -- fixed by WGMMA atom (one warpgroup = 64 output rows)
      tile_k = 64   -- 4 WGMMA K-steps of 16 each
      tile_n = 128  -- tunable
    """

    def __init__(self, tile_m: int = 64, tile_n: int = 128, tile_k: int = 64):
        self.tile_m = tile_m
        self.tile_n = tile_n
        self.tile_k = tile_k
        self.num_stages = 1
        self.shared_storage = None

    def _make_tma_atom(self, tensor, smem_layout_staged, tile_mn):
        """Create TMA copy atom + TMA global tensor for a single tile."""
        op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
        smem_layout_single = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
            op, tensor, smem_layout_single, tile_mn
        )
        return tma_atom, tma_tensor

    def _tma_partition(self, tma_atom, s_staged, g_tiled):
        """
        Partition staged smem tensor and k-tiled gmem tensor for TMA access.

        Groups (row, col) modes into a single TMA mode so tma_partition sees
        ((rows, cols), rest) on both sides.
        Returns (tAsX, tAgX) where:
          tAsX shape: (TMA, stages)   -- smem: select stage with state.index
          tAgX shape: (TMA, k_tiles)  -- gmem: select k-tile with state.count
        """
        s_tma = cute.group_modes(s_staged, 0, 2)  # ((M,K), stages)
        g_tma = cute.group_modes(g_tiled,  0, 2)  # ((M,K), k_tiles)
        s_part, g_part = cute.nvgpu.cpasync.tma_partition(
            tma_atom, 0, cute.make_layout(1), s_tma, g_tma
        )
        return s_part, g_part

    @cute.jit
    def __call__(self, mX, mW1, mW2, mOut):
        a_layout = utils.LayoutEnum.from_tensor(mX)
        b_layout = utils.LayoutEnum.from_tensor(mW1)

        tile_shape_mnk = (self.tile_m, self.tile_n, self.tile_k)

        tiled_mma = sm90_utils.make_trivial_tiled_mma(
            BFloat16, BFloat16,
            a_layout.sm90_mma_major_mode(),
            b_layout.sm90_mma_major_mode(),
            Float32, (1, 1, 1),
            tiler_mn=(self.tile_m, self.tile_n),
        )

        smem_layout_a = sm90_utils.make_smem_layout_a(a_layout, tile_shape_mnk, BFloat16, self.num_stages)
        smem_layout_b = sm90_utils.make_smem_layout_b(b_layout, tile_shape_mnk, BFloat16, self.num_stages)

        # Build TMA descriptors for X, W1, W2
        tma_atom_x,  tma_tensor_x  = self._make_tma_atom(mX,  smem_layout_a, (self.tile_m, self.tile_k))
        tma_atom_w1, tma_tensor_w1 = self._make_tma_atom(mW1, smem_layout_b, (self.tile_n, self.tile_k))
        tma_atom_w2, tma_tensor_w2 = self._make_tma_atom(mW2, smem_layout_b, (self.tile_n, self.tile_k))

        @cute.struct
        class SharedStorage:
            # mbarrier storage: num_stages * 2 Int64 words (phase + count per stage)
            mainloop_pipeline_array_ptr: cute.struct.MemRange[Int64, self.num_stages * 2]
            sX:  cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_a)], 1024]
            sW1: cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_b)], 1024]
            sW2: cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_b)], 1024]

        self.shared_storage = SharedStorage

        grid  = (self._grid_m, self._grid_n, 1)
        block = (128, 1, 1)

        # Pass TMA atoms, tensors, tiled_mma, and smem layouts as explicit kernel
        # arguments to cross the @cute.jit -> @cute.kernel MLIR region boundary.
        self.kernel(
            tma_atom_x,  tma_tensor_x,
            tma_atom_w1, tma_tensor_w1,
            tma_atom_w2, tma_tensor_w2,
            mOut, tiled_mma, smem_layout_a, smem_layout_b,
        ).launch(grid=grid, block=block)

    @cute.kernel
    def kernel(self,
               tma_atom_x:  cute.CopyAtom, mX_tma:  cute.Tensor,
               tma_atom_w1: cute.CopyAtom, mW1_tma: cute.Tensor,
               tma_atom_w2: cute.CopyAtom, mW2_tma: cute.Tensor,
               mOut: cute.Tensor,
               tiled_mma: cute.TiledMma,
               smem_layout_a: cute.ComposedLayout,
               smem_layout_b: cute.ComposedLayout):

        bm       = cute.arch.block_idx()[0]
        bn       = cute.arch.block_idx()[1]
        tidx     = cute.arch.thread_idx()[0]
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())

        TILE_M = self.tile_m
        TILE_N = self.tile_n
        TILE_K = self.tile_k

        # Prefetch TMA descriptors from gmem to L2 (latency optimization)
        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_x)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_w1)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_w2)

        # ── Allocate shared memory ────────────────────────────────────────────
        smem    = cutlass.utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)
        mbar_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()

        # Staged smem tensors: shape (M,K,stages) or (N,K,stages)
        sX  = storage.sX.get_tensor(smem_layout_a.outer, swizzle=smem_layout_a.inner)
        sW1 = storage.sW1.get_tensor(smem_layout_b.outer, swizzle=smem_layout_b.inner)
        sW2 = storage.sW2.get_tensor(smem_layout_b.outer, swizzle=smem_layout_b.inner)

        # ── Pipeline setup ────────────────────────────────────────────────────
        # tx_count = bytes TMA will write per stage across all 3 tiles.
        # The mbarrier uses this to know when TMA has finished.
        a_smem_single = cute.slice_(smem_layout_a, (None, None, 0))
        b_smem_single = cute.slice_(smem_layout_b, (None, None, 0))
        tma_copy_bytes = (cute.size_in_bytes(BFloat16, a_smem_single)
                        + cute.size_in_bytes(BFloat16, b_smem_single) * 2)

        # Producer: warp 0 (1 thread issues the mbarrier arrive after TMA).
        # Consumer: all 4 warps (128 threads / 32 = 4 warps arrive at release).
        producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 1)
        consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 4)
        pipeline_ws = pipeline.PipelineTmaAsync.create(
            barrier_storage=mbar_ptr,
            num_stages=self.num_stages,
            tx_count=tma_copy_bytes,
            producer_group=producer_group,
            consumer_group=consumer_group,
        )
        pipeline_init_arrive()
        pipeline_init_wait()

        # ── Gmem tiles ────────────────────────────────────────────────────────
        # local_tile with None keeps K as an iteration axis -> shape (M,K,k_tiles)
        gX_tiled  = cute.local_tile(mX_tma,  (TILE_M, TILE_K), (bm, None))
        gW1_tiled = cute.local_tile(mW1_tma, (TILE_N, TILE_K), (bn, None))
        gW2_tiled = cute.local_tile(mW2_tma, (TILE_N, TILE_K), (bn, None))
        gOut      = cute.local_tile(mOut,    (TILE_M, TILE_N), (bm, bn))

        k_tile_count = cute.size(gX_tiled, mode=[2])

        # ── TMA partition ─────────────────────────────────────────────────────
        # Result shapes:
        #   tAsX: (TMA, stages)  tAgX: (TMA, k_tiles)
        tAsX,  tAgX  = self._tma_partition(tma_atom_x,  sX,  gX_tiled)
        tAsW1, tAgW1 = self._tma_partition(tma_atom_w1, sW1, gW1_tiled)
        tAsW2, tAgW2 = self._tma_partition(tma_atom_w2, sW2, gW2_tiled)

        # ── MMA setup ─────────────────────────────────────────────────────────
        thr_mma  = tiled_mma.get_slice(tidx)
        tCgOut   = thr_mma.partition_C(gOut)
        gate_acc = cute.make_rmem_tensor(tCgOut.shape, Float32)
        up_acc   = cute.make_rmem_tensor(tCgOut.shape, Float32)

        # Partition staged smem for MMA fragments.
        # Using staged tensors (not sliced) gives fragments shape (..., k_blocks, stages)
        # so we can index by (None, None, k_block_idx, consumer_state.index).
        tCsX  = thr_mma.partition_A(sX)
        tCsW1 = thr_mma.partition_B(sW1)
        tCsW2 = thr_mma.partition_B(sW2)
        tCrX  = tiled_mma.make_fragment_A(tCsX)
        tCrW1 = tiled_mma.make_fragment_B(tCsW1)
        tCrW2 = tiled_mma.make_fragment_B(tCsW2)

        # Compute k_blocks statically: WGMMA K atom is always 16.
        # cute.size(tCrX, mode=[2]) returns stages=1, not k_blocks, for
        # atom_layout_mnk=(1,1,1). Using the Python-level constant avoids
        # accidentally getting the wrong dimension.
        MMA_K = 16
        num_k_blocks = TILE_K // MMA_K  # e.g. 64 // 16 = 4

        producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, self.num_stages
        )
        consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self.num_stages
        )

        # Explicitly zero accumulator registers, then keep ACCUMULATE=True for every
        # gemm call. tiled_mma.set() is compile-time: inside cutlass.range(unroll=1)
        # the loop body is traced once, so set(True) after a gemm never changes the
        # already-emitted instruction — every gemm would silently use ACCUMULATE=False,
        # overwriting the accumulator each k-block instead of summing. Zeroing here
        # and using scale-d=1 throughout gives D=0+A*B on the first call and
        # D=D+A*B on all subsequent calls, accumulating correctly across all tiles.
        for i in range(cute.size(gate_acc)):
            gate_acc[i] = Float32(0.0)
            up_acc[i]   = Float32(0.0)

        tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

        # ── Main K-loop ───────────────────────────────────────────────────────
        for _ in cutlass.range(k_tile_count, unroll=1):
            # Warp 0 issues TMA loads for X, W1, W2 for this k-tile.
            if warp_idx == 0:
                pipeline_ws.producer_acquire(producer_state)
                tma_mbar_ptr = pipeline_ws.producer_get_barrier(producer_state)

                tAgX_k  = tAgX[ (None, producer_state.count)]
                tAsX_p  = tAsX[ (None, producer_state.index)]
                tAgW1_k = tAgW1[(None, producer_state.count)]
                tAsW1_p = tAsW1[(None, producer_state.index)]
                tAgW2_k = tAgW2[(None, producer_state.count)]
                tAsW2_p = tAsW2[(None, producer_state.index)]

                cute.copy(tma_atom_x,  tAgX_k,  tAsX_p,  tma_bar_ptr=tma_mbar_ptr)
                cute.copy(tma_atom_w1, tAgW1_k, tAsW1_p, tma_bar_ptr=tma_mbar_ptr)
                cute.copy(tma_atom_w2, tAgW2_k, tAsW2_p, tma_bar_ptr=tma_mbar_ptr)

                pipeline_ws.producer_commit(producer_state)

            # All 128 threads wait for TMA to complete, then run WGMMA.
            pipeline_ws.consumer_wait(consumer_state)
            cute.nvgpu.warpgroup.fence()

            for k_block_idx in cutlass.range(num_k_blocks, unroll_full=True):
                k_block_coord = (None, None, k_block_idx, consumer_state.index)
                cute.gemm(tiled_mma, gate_acc, tCrX[k_block_coord], tCrW1[k_block_coord], gate_acc)
                cute.gemm(tiled_mma, up_acc,   tCrX[k_block_coord], tCrW2[k_block_coord], up_acc)

            cute.nvgpu.warpgroup.commit_group()
            cute.nvgpu.warpgroup.wait_group(0)
            pipeline_ws.consumer_release(consumer_state)
            producer_state.advance()
            consumer_state.advance()

        # ── Epilogue: SiLU(gate) * up -> BF16 -> gmem ────────────────────────
        for i in range(cute.size(gate_acc)):
            tCgOut[i] = BFloat16(silu_f32(gate_acc[i]) * up_acc[i])


# ── Python wrapper ────────────────────────────────────────────────────────────

_kernel_cache = {}

def swiglu_cutedsl(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    tokens, d_model = x.shape
    hidden_dim = w1.shape[0]
    out = torch.empty(tokens, hidden_dim, dtype=x.dtype, device=x.device)

    # mark_compact_shape_dynamic(mode=0): marks the row dimension (tokens / hidden_dim)
    # as dynamic so the kernel handles any size without recompilation.
    # stride_order=(0,1): compact row-major strides (outer, inner), required by TMA
    # to build a valid descriptor (TMA needs statically-known strides).
    def _wrap(t):
        return (from_dlpack(t, assumed_align=16)
                .mark_compact_shape_dynamic(mode=0, stride_order=(0, 1)))

    mX   = _wrap(x)
    mW1  = _wrap(w1)
    mW2  = _wrap(w2)
    mOut = _wrap(out)

    key = (tokens, d_model, hidden_dim, x.dtype)
    if key not in _kernel_cache:
        op = SwiGLUHopperTMA()
        op._grid_m = (tokens     + op.tile_m - 1) // op.tile_m
        op._grid_n = (hidden_dim + op.tile_n - 1) // op.tile_n
        _kernel_cache[key] = cute.compile(op, mX, mW1, mW2, mOut)

    _kernel_cache[key](mX, mW1, mW2, mOut)
    return out
