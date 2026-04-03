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

class SwiGLUHopperTMAPipelined:
    """
    SwiGLU with multi-stage TMA pipelining.

    vs swiglu_cutedsl.py (num_stages=1):
      num_stages=1: serial  LOAD k → COMPUTE k → LOAD k+1 → COMPUTE k+1
      num_stages=2: overlap LOAD k+1 runs while COMPUTE k executes

    Implementation:
      Prologue: issue TMA for tile 0 before the main loop (fills one stage).
      Main loop: at each iteration, issue TMA for tile k+1 BEFORE consumer_wait
                 for tile k, so the TMA runs in the background while all 4
                 warps do WGMMA on tile k.
      The num_stages smem buffers form a ring; producer and consumer states
      track which stage to write/read via their .index field.

    SMEM cost: num_stages × (sX + sW1 + sW2).
      For tile_m=64, tile_n=128, tile_k=64 and num_stages=2:
        2 × (8192 + 16384 + 16384) = 81920 bytes ≈ 80 KB  (H100 limit: 228 KB)
    """

    def __init__(self, tile_m: int = 64, tile_n: int = 128, tile_k: int = 64,
                 num_stages: int = 2):
        self.tile_m = tile_m
        self.tile_n = tile_n
        self.tile_k = tile_k
        self.num_stages = num_stages
        self.shared_storage = None

    def _make_tma_atom(self, tensor, smem_layout_staged, tile_mn):
        op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
        smem_layout_single = cute.slice_(smem_layout_staged, (None, None, 0))
        return cute.nvgpu.cpasync.make_tiled_tma_atom(op, tensor, smem_layout_single, tile_mn)

    def _tma_partition(self, tma_atom, s_staged, g_tiled):
        s_tma = cute.group_modes(s_staged, 0, 2)
        g_tma = cute.group_modes(g_tiled,  0, 2)
        return cute.nvgpu.cpasync.tma_partition(tma_atom, 0, cute.make_layout(1), s_tma, g_tma)

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

        tma_atom_x,  tma_tensor_x  = self._make_tma_atom(mX,  smem_layout_a, (self.tile_m, self.tile_k))
        tma_atom_w1, tma_tensor_w1 = self._make_tma_atom(mW1, smem_layout_b, (self.tile_n, self.tile_k))
        tma_atom_w2, tma_tensor_w2 = self._make_tma_atom(mW2, smem_layout_b, (self.tile_n, self.tile_k))

        @cute.struct
        class SharedStorage:
            mainloop_pipeline_array_ptr: cute.struct.MemRange[Int64, self.num_stages * 2]
            sX:  cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_a)], 1024]
            sW1: cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_b)], 1024]
            sW2: cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_b)], 1024]
        self.shared_storage = SharedStorage

        self.kernel(
            tma_atom_x,  tma_tensor_x,
            tma_atom_w1, tma_tensor_w1,
            tma_atom_w2, tma_tensor_w2,
            mOut, tiled_mma, smem_layout_a, smem_layout_b,
        ).launch(grid=(self._grid_m, self._grid_n, 1), block=(128, 1, 1))

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

        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_x)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_w1)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_w2)

        smem     = cutlass.utils.SmemAllocator()
        storage  = smem.allocate(self.shared_storage)
        mbar_ptr = storage.mainloop_pipeline_array_ptr.data_ptr()

        sX  = storage.sX.get_tensor(smem_layout_a.outer, swizzle=smem_layout_a.inner)
        sW1 = storage.sW1.get_tensor(smem_layout_b.outer, swizzle=smem_layout_b.inner)
        sW2 = storage.sW2.get_tensor(smem_layout_b.outer, swizzle=smem_layout_b.inner)

        a_smem_single  = cute.slice_(smem_layout_a, (None, None, 0))
        b_smem_single  = cute.slice_(smem_layout_b, (None, None, 0))
        tma_copy_bytes = (cute.size_in_bytes(BFloat16, a_smem_single)
                        + cute.size_in_bytes(BFloat16, b_smem_single) * 2)

        pipeline_ws = pipeline.PipelineTmaAsync.create(
            barrier_storage=mbar_ptr,
            num_stages=self.num_stages,
            tx_count=tma_copy_bytes,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 4),
        )
        pipeline_init_arrive()
        pipeline_init_wait()

        gX_tiled  = cute.local_tile(mX_tma,  (TILE_M, TILE_K), (bm, None))
        gW1_tiled = cute.local_tile(mW1_tma, (TILE_N, TILE_K), (bn, None))
        gW2_tiled = cute.local_tile(mW2_tma, (TILE_N, TILE_K), (bn, None))
        gOut      = cute.local_tile(mOut,    (TILE_M, TILE_N), (bm, bn))

        k_tile_count = cute.size(gX_tiled, mode=[2])

        tAsX,  tAgX  = self._tma_partition(tma_atom_x,  sX,  gX_tiled)
        tAsW1, tAgW1 = self._tma_partition(tma_atom_w1, sW1, gW1_tiled)
        tAsW2, tAgW2 = self._tma_partition(tma_atom_w2, sW2, gW2_tiled)

        thr_mma  = tiled_mma.get_slice(tidx)
        tCgOut   = thr_mma.partition_C(gOut)
        gate_acc = cute.make_rmem_tensor(tCgOut.shape, Float32)
        up_acc   = cute.make_rmem_tensor(tCgOut.shape, Float32)

        tCrX  = tiled_mma.make_fragment_A(thr_mma.partition_A(sX))
        tCrW1 = tiled_mma.make_fragment_B(thr_mma.partition_B(sW1))
        tCrW2 = tiled_mma.make_fragment_B(thr_mma.partition_B(sW2))

        MMA_K        = 16
        num_k_blocks = TILE_K // MMA_K

        producer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, self.num_stages)
        consumer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Consumer, self.num_stages)

        for i in range(cute.size(gate_acc)):
            gate_acc[i] = Float32(0.0)
            up_acc[i]   = Float32(0.0)
        tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

        # ── Prologue: issue TMA for tile 0 before entering the main loop ──────
        # This fills the first pipeline stage so the main loop can immediately
        # start issuing tile 1 and then overlap it with computing tile 0.
        if warp_idx == 0:
            pipeline_ws.producer_acquire(producer_state)
            tma_bar = pipeline_ws.producer_get_barrier(producer_state)
            cute.copy(tma_atom_x,  tAgX[ (None, producer_state.count)],
                      tAsX[ (None, producer_state.index)], tma_bar_ptr=tma_bar)
            cute.copy(tma_atom_w1, tAgW1[(None, producer_state.count)],
                      tAsW1[(None, producer_state.index)], tma_bar_ptr=tma_bar)
            cute.copy(tma_atom_w2, tAgW2[(None, producer_state.count)],
                      tAsW2[(None, producer_state.index)], tma_bar_ptr=tma_bar)
            pipeline_ws.producer_commit(producer_state)
            producer_state.advance()

        # ── Main K-loop ───────────────────────────────────────────────────────
        for k_tile in cutlass.range(k_tile_count, unroll=1):
            # Issue TMA for the NEXT tile before consumer_wait for the CURRENT
            # tile so the TMA runs in parallel with the upcoming WGMMA.
            # The conditional skips the issue on the last iteration (no tile k+1).
            if warp_idx == 0:
                if k_tile + 1 < k_tile_count:
                    pipeline_ws.producer_acquire(producer_state)
                    tma_bar = pipeline_ws.producer_get_barrier(producer_state)
                    cute.copy(tma_atom_x,  tAgX[ (None, producer_state.count)],
                              tAsX[ (None, producer_state.index)], tma_bar_ptr=tma_bar)
                    cute.copy(tma_atom_w1, tAgW1[(None, producer_state.count)],
                              tAsW1[(None, producer_state.index)], tma_bar_ptr=tma_bar)
                    cute.copy(tma_atom_w2, tAgW2[(None, producer_state.count)],
                              tAsW2[(None, producer_state.index)], tma_bar_ptr=tma_bar)
                    pipeline_ws.producer_commit(producer_state)
                    producer_state.advance()

            # Wait for the current tile (loaded in prologue or previous iteration).
            # By the time consumer_wait returns, the TMA for the next tile is
            # already in flight — hiding memory latency behind WGMMA.
            pipeline_ws.consumer_wait(consumer_state)
            cute.nvgpu.warpgroup.fence()

            for k_block_idx in cutlass.range(num_k_blocks, unroll_full=True):
                k_coord = (None, None, k_block_idx, consumer_state.index)
                cute.gemm(tiled_mma, gate_acc, tCrX[k_coord], tCrW1[k_coord], gate_acc)
                cute.gemm(tiled_mma, up_acc,   tCrX[k_coord], tCrW2[k_coord], up_acc)

            cute.nvgpu.warpgroup.commit_group()
            cute.nvgpu.warpgroup.wait_group(0)
            pipeline_ws.consumer_release(consumer_state)
            consumer_state.advance()

        # ── Epilogue ──────────────────────────────────────────────────────────
        for i in range(cute.size(gate_acc)):
            tCgOut[i] = BFloat16(silu_f32(gate_acc[i]) * up_acc[i])


# ── Python wrapper ────────────────────────────────────────────────────────────

_kernel_cache = {}

def swiglu_cutedsl_pipelined(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    tokens, d_model = x.shape
    hidden_dim = w1.shape[0]
    out = torch.empty(tokens, hidden_dim, dtype=x.dtype, device=x.device)

    def _wrap(t):
        return (from_dlpack(t, assumed_align=16)
                .mark_compact_shape_dynamic(mode=0, stride_order=(0, 1)))

    mX, mW1, mW2, mOut = _wrap(x), _wrap(w1), _wrap(w2), _wrap(out)

    key = (tokens, d_model, hidden_dim, x.dtype)
    if key not in _kernel_cache:
        op = SwiGLUHopperTMAPipelined()
        op._grid_m = (tokens     + op.tile_m - 1) // op.tile_m
        op._grid_n = (hidden_dim + op.tile_n - 1) // op.tile_n
        _kernel_cache[key] = cute.compile(op, mX, mW1, mW2, mOut)

    _kernel_cache[key](mX, mW1, mW2, mOut)
    return out
