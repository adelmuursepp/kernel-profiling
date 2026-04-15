import math
import torch

from profile_utils import ExperimentOutput
from swiglu_pytorch import swiglu_pytorch
from swiglu_pytorch_compile import swiglu_pytorch_compile_separate, swiglu_pytorch_compile_stacked
from swiglu_cutedsl import swiglu_cutedsl
from swiglu_cutedsl_pipelined import swiglu_cutedsl_pipelined
from swiglu_helion_inference import swiglu_helion_dot, swiglu_helion_addmm

from common import MATMUL_CONFIGS

# ── fused_kernels_cutedsl_lib (SwigluSM90) 
from cutedsl_kernels.swiglu import SwigluSM90
from cutedsl_kernels.swiglu.attempt1.cdsl_fn_utils import make_fake_tensor
from cutlass.cute.runtime import from_dlpack
import cutlass.cute as cute
import cutlass as _cutlass

_fused_compile_cache = {}

def _get_fused_compiled(m, n, k):
    key = (m, n, k)
    if key not in _fused_compile_cache:
        gemm = SwigluSM90(
            tile_shape_mn=(128, 128),
            epi_tile_mn=(128, 32),
            cluster_shape_mnk=(2, 1, 1),
            atom_layout_mn=(2, 1),
            ab_stage=3,
            reuse_ab=False,
            is_persistent=True,
            gemm_n_prologue=0,
        )
        dtype = _cutlass.BFloat16
        div  = math.gcd(128 // dtype.width, k)
        divn = math.gcd(128 // dtype.width, n)
        x_fake = make_fake_tensor(dtype, (m, k), div)
        w_fake = make_fake_tensor(dtype, (n, k), div)
        v_fake = make_fake_tensor(dtype, (n, k), div)
        o_fake = make_fake_tensor(dtype, (m, n), divn)
        # make_fake_stream with use_tvm_ffi_env_stream=True bakes the CUDA
        # stream in via TVM FFI; compiled kernel is called without explicit stream.
        _fused_compile_cache[key] = cute.compile(
            gemm,
            x_fake, w_fake, v_fake, o_fake,
            cute.runtime.make_fake_stream(use_tvm_ffi_env_stream=True),
            options="--enable-tvm-ffi",
        )
    return _fused_compile_cache[key]

def _to_cute(t: torch.Tensor):
    return (
        from_dlpack(t.detach(), assumed_align=16, enable_tvm_ffi=True)
        .mark_compact_shape_dynamic(mode=0, stride_order=(0, 1))
    )

def swiglu_fused_cutedsl(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    m, k = x.shape
    n = w1.shape[0]
    out = torch.empty(m, n, dtype=x.dtype, device=x.device)
    compiled = _get_fused_compiled(m, n, k)
    compiled(_to_cute(x), _to_cute(w1), _to_cute(w2), _to_cute(out))
    return out


def get_ref(tokens, d_model, hidden_dim, dtype):
    torch.manual_seed(0)
    x  = torch.randn(tokens,     d_model,     device="cuda", dtype=dtype)
    w1 = torch.randn(hidden_dim, d_model,     device="cuda", dtype=dtype)
    w2 = torch.randn(hidden_dim, d_model,     device="cuda", dtype=dtype)
    xf, w1f, w2f = x.float(), w1.float(), w2.float()
    gate = xf @ w1f.T
    up   = xf @ w2f.T
    ref  = (gate * torch.sigmoid(gate) * up).to(dtype)
    return (x, w1, w2), ref


if __name__ == "__main__":
    import csv
    import os
    from datetime import datetime

    def swiglu_compile_stacked(x, w1, w2):
        W = torch.cat([w1, w2], dim=0)
        return swiglu_pytorch_compile_stacked(x, W)

    kernels = [
        ("pytorch_eager",            swiglu_pytorch),
        ("pytorch_compile_separate", swiglu_pytorch_compile_separate),
        ("pytorch_compile_stacked",  swiglu_compile_stacked),
        ("cutedsl",                  swiglu_cutedsl),
        ("cutedsl_pipelined",        swiglu_cutedsl_pipelined),
        ("fused_cutedsl",            swiglu_fused_cutedsl),
        ("helion_dot",               swiglu_helion_dot),
        ("helion_addmm",             swiglu_helion_addmm),
    ]

    results_dir = os.path.join(os.path.dirname(__file__), "results")
    os.makedirs(results_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = os.path.join(results_dir, f"results_{timestamp}.csv")

    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(ExperimentOutput.header())

        print(f"{'kernel':>25} {'tokens':>8} {'d_model':>8} {'hidden':>8} {'ms_median':>12} {'ms_mean':>10} {'ms_std':>8} {'max_abs':>10} {'rmse':>10}")
        print("-" * 110)

        for kernel_name, fn in kernels:
            for tokens, d_model, hidden_dim, dtype in MATMUL_CONFIGS:
                dtype_str = str(dtype).split(".")[-1]
                try:
                    tensors, ref = get_ref(tokens, d_model, hidden_dim, dtype)
                    result = ExperimentOutput(kernel_name, tokens, hidden_dim, d_model)
                    result.run(fn, tensors, ref)
                except FileNotFoundError as e:
                    print(f"{kernel_name:>25} {tokens:>8} {d_model:>8} {hidden_dim:>8} -- skipped: {e}")
                    continue
                writer.writerow(result.values())
                print(f"{kernel_name:>25} {tokens:>8} {d_model:>8} {hidden_dim:>8} {result.ms_median:>12.4f} {result.ms_mean:>10.4f} {result.ms_std:>8.4f} {result.max_abs:>10.6f} {result.rmse:>10.6f}")

    print(f"\nResults saved to {filename}")

