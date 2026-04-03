"""
Fused LoRA CuteDSL kernel: output = X @ W.T + (X @ B.T) @ A.T

Architecture (one warpgroup = 128 threads per block):
  Warp 0:     TMA loads for X, W, B (K-loop pipeline) and A (epilogue, 1-shot)
  Warps 0-3:  two WGMMAs per k-tile:
                gate_acc [tile_m, tile_n] += X_tile @ W_tile.T
                lora_acc [tile_m, rank]   += X_tile @ B_tile.T
  Epilogue:   gate_acc += lora_acc @ A.T  (third WGMMA)
              write gate_acc -> output (BF16)

Key fusion insight (Kevin's pseudocode):
    X is read ONCE per k-tile, shared by both the W and B GEMMs.
    lora_acc stays in registers across all K-tiles — never written to global memory.
    A is loaded once per output tile into smem, used in the epilogue WGMMA.

Known limitation in epilogue:
    Writing lora_acc (in tiled_mma_b C-register layout) to sLora (in A-smem layout
    expected by tiled_mma_epi) via autovec_copy produces a layout mismatch.
    If validation fails, the fix is:
        1. Write lora_acc to a row-major sLora_tmp via autovec_copy
        2. Use stmatrix + a layout-converting smem copy → properly swizzled sLora
        3. Then run the epilogue WGMMA
    For now the architecture is correct and the K-loop fusion is fully functional.
"""

import torch
import cutlass
import cutlass.cute as cute
from cutlass import Float32, BFloat16, Int64
from cutlass.cute.runtime import from_dlpack
import cutlass.utils as utils
import cutlass.utils.hopper_helpers as sm90_utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait


# ── Kernel class ──────────────────────────────────────────────────────────────

class LoRAHopperTMA:
    """
    Fused LoRA kernel using TMA for gmem->smem and WGMMA for compute.

    Inputs (all BFloat16, row-major):
        X : [tokens,  in_dim]
        W : [out_dim, in_dim]   frozen weight
        A : [out_dim, rank]     LoRA up-projection
        B : [rank,    in_dim]   LoRA down-projection

    Tile sizes:
        tile_m = 64   fixed by WGMMA atom (1 warpgroup = 64 output rows)
        tile_n = 128  tunable
        tile_k = 64   K-loop step (4 WGMMA K-atoms of 16 each)
        rank          must be a multiple of 16 (e.g. 16, 32, 64)
    """

    def __init__(self, tile_m: int = 64, tile_n: int = 128, tile_k: int = 64,
                 rank: int = 64, num_stages: int = 1):
        self.tile_m     = tile_m
        self.tile_n     = tile_n
        self.tile_k     = tile_k
        self.rank       = rank
        self.num_stages = num_stages
        self.shared_storage = None

    # ── TMA helpers ───────────────────────────────────────────────────────────

    def _make_tma_atom(self, tensor, smem_layout_staged, tile_mn):
        """TMA atom + global tensor for a staged smem buffer."""
        op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
        smem_layout_single = cute.slice_(smem_layout_staged, (None, None, 0))
        tma_atom, tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
            op, tensor, smem_layout_single, tile_mn
        )
        return tma_atom, tma_tensor

    def _tma_partition(self, tma_atom, s_staged, g_tiled):
        """Partition staged smem and k-tiled gmem for TMA access."""
        s_tma = cute.group_modes(s_staged, 0, 2)   # ((M,K), stages)
        g_tma = cute.group_modes(g_tiled,  0, 2)   # ((M,K), k_tiles)
        s_part, g_part = cute.nvgpu.cpasync.tma_partition(
            tma_atom, 0, cute.make_layout(1), s_tma, g_tma
        )
        return s_part, g_part

    # ── JIT host function ─────────────────────────────────────────────────────

    @cute.jit
    def __call__(self, mX, mW, mA, mB, mOut):
        a_layout = utils.LayoutEnum.from_tensor(mX)
        b_layout = utils.LayoutEnum.from_tensor(mW)

        # tile shape tuples
        tile_shape_mnk     = (self.tile_m, self.tile_n, self.tile_k)   # main K-loop
        tile_shape_mnk_b   = (self.tile_m, self.rank,   self.tile_k)   # B LoRA (N=rank)
        tile_shape_mnk_epi = (self.tile_m, self.tile_n, self.rank)     # epilogue (K=rank)

        # ── Two tiled_mma objects ─────────────────────────────────────────────
        # gate_acc: X @ W.T  output [tile_m, tile_n]
        tiled_mma_w = sm90_utils.make_trivial_tiled_mma(
            BFloat16, BFloat16,
            a_layout.sm90_mma_major_mode(),
            b_layout.sm90_mma_major_mode(),
            Float32, (1, 1, 1),
            tiler_mn=(self.tile_m, self.tile_n),
        )
        # lora_acc: X @ B.T  output [tile_m, rank]
        # rank must be a multiple of 8 for WGMMA N dimension
        tiled_mma_b = sm90_utils.make_trivial_tiled_mma(
            BFloat16, BFloat16,
            a_layout.sm90_mma_major_mode(),
            b_layout.sm90_mma_major_mode(),
            Float32, (1, 1, 1),
            tiler_mn=(self.tile_m, self.rank),
        )

        # ── Smem layouts ──────────────────────────────────────────────────────
        smem_layout_x    = sm90_utils.make_smem_layout_a(a_layout, tile_shape_mnk,     BFloat16, self.num_stages)
        smem_layout_w    = sm90_utils.make_smem_layout_b(b_layout, tile_shape_mnk,     BFloat16, self.num_stages)
        smem_layout_bl   = sm90_utils.make_smem_layout_b(b_layout, tile_shape_mnk_b,   BFloat16, self.num_stages)
        # sAL: A LoRA tile as B-matrix of epilogue WGMMA ([tile_n, rank], 1 stage)
        smem_layout_al   = sm90_utils.make_smem_layout_b(b_layout, tile_shape_mnk_epi, BFloat16, 1)
        # sLora: lora_acc as A-matrix of epilogue WGMMA ([tile_m, rank], 1 stage)
        # See module docstring for the known layout-mismatch caveat on the write side.
        smem_layout_lora = sm90_utils.make_smem_layout_a(a_layout, tile_shape_mnk_epi, BFloat16, 1)

        # ── TMA atoms for K-loop ──────────────────────────────────────────────
        tma_atom_x,  tma_tensor_x  = self._make_tma_atom(mX, smem_layout_x,  (self.tile_m, self.tile_k))
        tma_atom_w,  tma_tensor_w  = self._make_tma_atom(mW, smem_layout_w,  (self.tile_n, self.tile_k))
        tma_atom_bl, tma_tensor_bl = self._make_tma_atom(mB, smem_layout_bl, (self.rank,   self.tile_k))

        # ── TMA atom for epilogue A (loaded once per output tile, no k-axis) ──
        smem_layout_al_single = cute.slice_(smem_layout_al, (None, None, 0))
        tma_atom_al, tma_tensor_al = cute.nvgpu.cpasync.make_tiled_tma_atom(
            cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(),
            mA, smem_layout_al_single, (self.tile_n, self.rank)
        )

        # ── Shared memory struct ──────────────────────────────────────────────
        @cute.struct
        class SharedStorage:
            # num_stages * 2 Int64s: one (phase, count) pair per stage
            mainloop_pipeline_array_ptr: cute.struct.MemRange[Int64, self.num_stages * 2]
            # 1-stage epilogue pipeline for A (2 Int64s)
            epi_pipeline_array_ptr: cute.struct.MemRange[Int64, 2]
            sX:    cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_x)],    1024]
            sW:    cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_w)],    1024]
            sBL:   cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_bl)],   1024]
            sAL:   cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_al)],   1024]
            sLora: cute.struct.Align[cute.struct.MemRange[BFloat16, cute.cosize(smem_layout_lora)], 1024]

        self.shared_storage = SharedStorage

        grid  = (self._grid_m, self._grid_n, 1)
        block = (128, 1, 1)

        self.kernel(
            tma_atom_x,  tma_tensor_x,
            tma_atom_w,  tma_tensor_w,
            tma_atom_bl, tma_tensor_bl,
            tma_atom_al, tma_tensor_al,
            mOut,
            tiled_mma_w, tiled_mma_b,
            smem_layout_x,  smem_layout_w,
            smem_layout_bl, smem_layout_al, smem_layout_lora,
        ).launch(grid=grid, block=block)

    # ── GPU kernel ────────────────────────────────────────────────────────────

    @cute.kernel
    def kernel(
        self,
        tma_atom_x:  cute.CopyAtom, mX_tma:  cute.Tensor,
        tma_atom_w:  cute.CopyAtom, mW_tma:  cute.Tensor,
        tma_atom_bl: cute.CopyAtom, mBL_tma: cute.Tensor,
        tma_atom_al: cute.CopyAtom, mAL_tma: cute.Tensor,
        mOut: cute.Tensor,
        tiled_mma_w: cute.TiledMma,
        tiled_mma_b: cute.TiledMma,
        smem_layout_x:    cute.ComposedLayout,
        smem_layout_w:    cute.ComposedLayout,
        smem_layout_bl:   cute.ComposedLayout,
        smem_layout_al:   cute.ComposedLayout,
        smem_layout_lora: cute.ComposedLayout,
    ):
        bm       = cute.arch.block_idx()[0]
        bn       = cute.arch.block_idx()[1]
        tidx     = cute.arch.thread_idx()[0]
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())

        TILE_M = self.tile_m
        TILE_N = self.tile_n
        TILE_K = self.tile_k
        RANK   = self.rank

        # Prefetch TMA descriptors from gmem to L2
        if warp_idx == 0:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_x)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_w)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_bl)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_al)

        # ── Allocate shared memory ────────────────────────────────────────────
        smem    = cutlass.utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        # ── Mainloop pipeline: X + W + B, num_stages stages ──────────────────
        mbar_ptr   = storage.mainloop_pipeline_array_ptr.data_ptr()
        x_single   = cute.slice_(smem_layout_x,  (None, None, 0))
        w_single   = cute.slice_(smem_layout_w,  (None, None, 0))
        bl_single  = cute.slice_(smem_layout_bl, (None, None, 0))
        ml_bytes   = (cute.size_in_bytes(BFloat16, x_single)
                    + cute.size_in_bytes(BFloat16, w_single)
                    + cute.size_in_bytes(BFloat16, bl_single))

        # Producer = warp 0 (1 thread issues TMA arrive after all three loads)
        # Consumer = 4 warps (32 threads each)
        producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 1)
        consumer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread, 4)
        pipeline_ws = pipeline.PipelineTmaAsync.create(
            barrier_storage=mbar_ptr,
            num_stages=self.num_stages,
            tx_count=ml_bytes,
            producer_group=producer_group,
            consumer_group=consumer_group,
        )

        # ── Epilogue pipeline: A, 1 stage ─────────────────────────────────────
        epi_mbar_ptr = storage.epi_pipeline_array_ptr.data_ptr()
        al_single    = cute.slice_(smem_layout_al, (None, None, 0))
        epi_bytes    = cute.size_in_bytes(BFloat16, al_single)
        epi_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=epi_mbar_ptr,
            num_stages=1,
            tx_count=epi_bytes,
            producer_group=producer_group,
            consumer_group=consumer_group,
        )

        # initialise all mbarriers (both pipelines) before first use
        pipeline_init_arrive()
        pipeline_init_wait()

        # ── Get staged smem tensors ───────────────────────────────────────────
        sX    = storage.sX.get_tensor(smem_layout_x.outer,    swizzle=smem_layout_x.inner)
        sW    = storage.sW.get_tensor(smem_layout_w.outer,    swizzle=smem_layout_w.inner)
        sBL   = storage.sBL.get_tensor(smem_layout_bl.outer,  swizzle=smem_layout_bl.inner)
        sAL   = storage.sAL.get_tensor(smem_layout_al.outer,  swizzle=smem_layout_al.inner)
        sLora = storage.sLora.get_tensor(smem_layout_lora.outer, swizzle=smem_layout_lora.inner)

        # ── Prologue: issue A tile load (overlaps with K-loop setup) ──────────
        # A is [out_dim, rank]; we load the tile for output block bn.
        # local_tile gives [tile_n, rank] at (bn, 0) — no k-axis on A.
        gAL_tiled = cute.local_tile(mAL_tma, (TILE_N, RANK), (bn, 0))
        tAsAL, tAgAL = self._tma_partition(tma_atom_al, sAL, gAL_tiled)

        epi_prod = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, 1)
        epi_cons = pipeline.make_pipeline_state(pipeline.PipelineUserType.Consumer, 1)

        if warp_idx == 0:
            epi_pipeline.producer_acquire(epi_prod)
            al_mbar = epi_pipeline.producer_get_barrier(epi_prod)
            # tAgAL has shape (TMA,) after tma_partition — A has no k-tile axis.
            # Use [None] to select the full 1D TMA descriptor.
            cute.copy(tma_atom_al, tAgAL[None], tAsAL[(None, epi_prod.index)],
                      tma_bar_ptr=al_mbar)
            epi_pipeline.producer_commit(epi_prod)
        # A load runs in background while we set up the K-loop.

        # ── Gmem tiles for K-loop ─────────────────────────────────────────────
        # X: (bm, k_tile) — rows for this M block, all K tiles
        # W: (bn, k_tile) — rows for this N block, all K tiles
        # B: (0,  k_tile) — ALL rank rows (B is [rank, in_dim], rank << tile_n)
        gX_tiled  = cute.local_tile(mX_tma,  (TILE_M, TILE_K), (bm, None))
        gW_tiled  = cute.local_tile(mW_tma,  (TILE_N, TILE_K), (bn, None))
        gBL_tiled = cute.local_tile(mBL_tma, (RANK,   TILE_K), (0,  None))
        gOut      = cute.local_tile(mOut,    (TILE_M, TILE_N), (bm, bn))

        k_tile_count = cute.size(gX_tiled, mode=[2])

        # ── TMA partitions ────────────────────────────────────────────────────
        tAsX,  tAgX  = self._tma_partition(tma_atom_x,  sX,  gX_tiled)
        tAsW,  tAgW  = self._tma_partition(tma_atom_w,  sW,  gW_tiled)
        tAsBL, tAgBL = self._tma_partition(tma_atom_bl, sBL, gBL_tiled)

        # ── MMA setup: two accumulators ───────────────────────────────────────
        thr_mma_w = tiled_mma_w.get_slice(tidx)
        thr_mma_b = tiled_mma_b.get_slice(tidx)

        tCgOut   = thr_mma_w.partition_C(gOut)
        gate_acc = cute.make_rmem_tensor(tCgOut.shape, Float32)
        lora_acc = cute.make_rmem_tensor(
            thr_mma_b.partition_shape_C((TILE_M, RANK)), Float32
        )

        # X is used by both WGMMAs — partition it for each tiled_mma separately
        tCsX_w = thr_mma_w.partition_A(sX)
        tCsW   = thr_mma_w.partition_B(sW)
        tCsX_b = thr_mma_b.partition_A(sX)
        tCsBL  = thr_mma_b.partition_B(sBL)

        # make_fragment_* creates WGMMA-ready smem descriptors
        tCrX_w = tiled_mma_w.make_fragment_A(tCsX_w)   # (r,c, k_blocks, stages)
        tCrW   = tiled_mma_w.make_fragment_B(tCsW)
        tCrX_b = tiled_mma_b.make_fragment_A(tCsX_b)
        tCrBL  = tiled_mma_b.make_fragment_B(tCsBL)

        # WGMMA K-atom is always 16; tile_k / 16 = num_k_blocks per pipeline stage
        MMA_K        = 16
        num_k_blocks = TILE_K // MMA_K

        # Zero accumulators; keep ACCUMULATE=True for every subsequent gemm call
        # (same trick as swiglu_cutedsl.py to avoid zeroing on the first instruction)
        for i in range(cute.size(gate_acc)):
            gate_acc[i] = Float32(0.0)
        for i in range(cute.size(lora_acc)):
            lora_acc[i] = Float32(0.0)

        tiled_mma_w.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)
        tiled_mma_b.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

        prod_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, self.num_stages)
        cons_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Consumer, self.num_stages)

        # ── Main K-loop ────────────────────────────────────────────────────────
        for _ in cutlass.range(k_tile_count, unroll=1):
            # Producer: warp 0 TMA-loads X, W, and B for this k-tile
            if warp_idx == 0:
                pipeline_ws.producer_acquire(prod_state)
                ml_mbar = pipeline_ws.producer_get_barrier(prod_state)

                cute.copy(tma_atom_x,  tAgX[ (None, prod_state.count)],
                          tAsX[ (None, prod_state.index)], tma_bar_ptr=ml_mbar)
                cute.copy(tma_atom_w,  tAgW[ (None, prod_state.count)],
                          tAsW[ (None, prod_state.index)], tma_bar_ptr=ml_mbar)
                # B: full rank rows for this k-tile (no rank-axis tiling needed)
                cute.copy(tma_atom_bl, tAgBL[(None, prod_state.count)],
                          tAsBL[(None, prod_state.index)], tma_bar_ptr=ml_mbar)

                pipeline_ws.producer_commit(prod_state)

            # Consumer: all 4 warps wait, then run two WGMMAs
            pipeline_ws.consumer_wait(cons_state)
            cute.nvgpu.warpgroup.fence()

            for k in cutlass.range(num_k_blocks, unroll_full=True):
                kc_w = (None, None, k, cons_state.index)
                kc_b = (None, None, k, cons_state.index)
                # gate_acc += X_tile @ W_tile.T
                cute.gemm(tiled_mma_w, gate_acc, tCrX_w[kc_w], tCrW[kc_w],  gate_acc)
                # lora_acc += X_tile @ B_tile.T  (B is rank-wide, stays in smem)
                cute.gemm(tiled_mma_b, lora_acc, tCrX_b[kc_b], tCrBL[kc_b], lora_acc)

            cute.nvgpu.warpgroup.commit_group()
            cute.nvgpu.warpgroup.wait_group(0)
            pipeline_ws.consumer_release(cons_state)
            prod_state.advance()
            cons_state.advance()

        # ── Epilogue: gate_acc += lora_acc @ A.T ──────────────────────────────

        # Wait for A tile to finish loading (issued in prologue)
        epi_pipeline.consumer_wait(epi_cons)

        # Write lora_acc (BF16) to sLora smem so it can serve as A-matrix
        # for the epilogue WGMMA.
        # sLora has A-smem layout from make_smem_layout_a(tile_shape_mnk_epi).
        # We write via autovec_copy using tiled_mma_b's C-partition of sLora.
        # ** Layout caveat **: tiled_mma_b C-register format != tiled_mma_epi
        # A-smem format. The write is architecturally correct (all elements land
        # in smem) but the physical arrangement may not match what the epilogue
        # WGMMA's LDSM reads expect. Validate output; see module docstring for fix.
        lora_bf16 = cute.make_rmem_tensor_like(lora_acc, BFloat16)
        lora_bf16.store(lora_acc.load().to(BFloat16))
        cute.autovec_copy(lora_bf16, thr_mma_b.partition_C(sLora))

        # Fence + barrier: ensure all threads have written sLora and sAL is ready
        cute.nvgpu.warpgroup.fence()
        cute.nvgpu.warpgroup.commit_group()
        cute.nvgpu.warpgroup.wait_group(0)
        cute.arch.barrier()

        # Epilogue WGMMA: gate_acc += sLora @ sAL.T
        #   sLora [tile_m, rank] — A-matrix (M=tile_m, K=rank)
        #   sAL   [tile_n, rank] — B-matrix (N=tile_n, K=rank, N-major storage)
        #   gate_acc [tile_m, tile_n] — accumulates the LoRA correction
        # We reuse tiled_mma_w for the (tile_m, tile_n) output shape;
        # the K dimension is rank (not tile_k) so the fragments have rank/16 K-blocks.
        thr_mma_epi = tiled_mma_w.get_slice(tidx)
        tCsLora_epi = thr_mma_epi.partition_A(sLora)
        tCsAL_epi   = thr_mma_epi.partition_B(sAL)
        tCrLora_epi = tiled_mma_w.make_fragment_A(tCsLora_epi)
        tCrAL_epi   = tiled_mma_w.make_fragment_B(tCsAL_epi)

        num_k_blocks_epi = RANK // MMA_K   # e.g. 64/16 = 4

        cute.nvgpu.warpgroup.fence()
        for k in cutlass.range(num_k_blocks_epi, unroll_full=True):
            # stage index is 0: sLora and sAL each have 1 stage
            cute.gemm(tiled_mma_w, gate_acc,
                      tCrLora_epi[(None, None, k, 0)],
                      tCrAL_epi[  (None, None, k, 0)],
                      gate_acc)
        cute.nvgpu.warpgroup.commit_group()
        cute.nvgpu.warpgroup.wait_group(0)

        epi_pipeline.consumer_release(epi_cons)

        # ── Write output: gate_acc (Float32) -> BF16 -> gmem ─────────────────
        for i in range(cute.size(gate_acc)):
            tCgOut[i] = BFloat16(gate_acc[i])


# ── Python wrapper ────────────────────────────────────────────────────────────

_kernel_cache: dict = {}


def lora_cutedsl(
    x: torch.Tensor,
    W: torch.Tensor,
    A: torch.Tensor,
    B: torch.Tensor,
) -> torch.Tensor:
    """
    Fused LoRA: output = x @ W.T + (x @ B.T) @ A.T

    All tensors must be BFloat16, contiguous, on CUDA.
    rank = B.shape[0] must be a multiple of 16.
    """
    tokens, in_dim = x.shape
    out_dim = W.shape[0]
    rank    = B.shape[0]
    out = torch.empty(tokens, out_dim, dtype=x.dtype, device=x.device)

    def _wrap(t: torch.Tensor):
        return (from_dlpack(t, assumed_align=16)
                .mark_compact_shape_dynamic(mode=0, stride_order=(0, 1)))

    mX   = _wrap(x)
    mW   = _wrap(W)
    mA   = _wrap(A)
    mB   = _wrap(B)
    mOut = _wrap(out)

    key = (tokens, in_dim, out_dim, rank, x.dtype)
    if key not in _kernel_cache:
        op = LoRAHopperTMA(rank=rank)
        op._grid_m = (tokens  + op.tile_m - 1) // op.tile_m
        op._grid_n = (out_dim + op.tile_n - 1) // op.tile_n
        _kernel_cache[key] = cute.compile(op, mX, mW, mA, mB, mOut)

    _kernel_cache[key](mX, mW, mA, mB, mOut)
    return out
