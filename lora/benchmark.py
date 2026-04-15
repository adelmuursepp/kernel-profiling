import math
import torch

from profile_utils import ExperimentOutput
from lora_pytorch import lora_pytorch
from lora_pytorch_compile import lora_pytorch_compile
from lora_helion_inference import lora_helion_dot, lora_helion_addmm

from common import LORA_CONFIGS

# ── fused_kernels_cutedsl_lib (GemmSM90 LoRA) 
from cutedsl_kernels.lora.attempt1.gemm import GemmSM90
from cutedsl_kernels.lora.attempt1.cdsl_fn_utils import make_fake_tensor
from cutlass.cute.runtime import from_dlpack
import cutlass.cute as cute
import cutlass as _cutlass

_lora_compile_cache = {}

def _get_lora_compiled(tokens, out_dim, in_dim, rank):
    key = (tokens, out_dim, in_dim, rank)
    if key not in _lora_compile_cache:
        gemm = GemmSM90(
            tile_shape_mn=(128, 256),
            lora_dim=rank,
            epi_tile_mn=(128, 32),
            cluster_shape_mnk=(2, 1, 1),
            atom_layout_mn=(2, 1),
            ab_stage=3,
            reuse_ab=False,
            is_persistent=True,
            gemm_n_prologue=0,
        )
        dtype = _cutlass.BFloat16
        div  = math.gcd(128 // dtype.width, in_dim)
        divn = math.gcd(128 // dtype.width, out_dim)
        divr = math.gcd(128 // dtype.width, rank)
        x_fake   = make_fake_tensor(dtype, (tokens,  in_dim),  div)
        W_fake   = make_fake_tensor(dtype, (out_dim, in_dim),  div)
        xA_fake  = make_fake_tensor(dtype, (tokens,  rank),    divr)
        A_fake   = make_fake_tensor(dtype, (out_dim, rank),    divr)
        out_fake = make_fake_tensor(dtype, (tokens,  out_dim), divn)
        _lora_compile_cache[key] = cute.compile(
            gemm,
            x_fake, W_fake, xA_fake, A_fake, out_fake,
            cute.runtime.make_fake_stream(use_tvm_ffi_env_stream=True),
            options="--enable-tvm-ffi",
        )
    return _lora_compile_cache[key]

def _to_cute(t: torch.Tensor):
    return (
        from_dlpack(t.detach(), assumed_align=16, enable_tvm_ffi=True)
        .mark_compact_shape_dynamic(mode=0, stride_order=(0, 1))
    )

def lora_cutedsl(x: torch.Tensor, W: torch.Tensor, A: torch.Tensor, B: torch.Tensor) -> torch.Tensor:
    tokens, in_dim = x.shape
    out_dim = W.shape[0]
    rank = B.shape[0]
    xA = (x @ B.T).to(x.dtype)  # pre-compute outside kernel
    out = torch.empty(tokens, out_dim, dtype=x.dtype, device=x.device)
    compiled = _get_lora_compiled(tokens, out_dim, in_dim, rank)
    compiled(_to_cute(x), _to_cute(W), _to_cute(xA), _to_cute(A), _to_cute(out))
    return out


def get_ref(tokens, in_dim, out_dim, rank, dtype):
    torch.manual_seed(0)
    x = torch.randn(tokens,  in_dim,  device="cuda", dtype=dtype)
    W = torch.randn(out_dim, in_dim,  device="cuda", dtype=dtype)
    A = torch.randn(out_dim, rank,    device="cuda", dtype=dtype)
    B = torch.randn(rank,    in_dim,  device="cuda", dtype=dtype)
    xf, Wf, Af, Bf = x.float(), W.float(), A.float(), B.float()
    ref = (xf @ Wf.T + xf @ Bf.T @ Af.T).to(dtype)
    return (x, W, A, B), ref


if __name__ == "__main__":
    import csv
    import os
    from datetime import datetime

    kernels = [
        ("pytorch_eager",   lora_pytorch),
        ("pytorch_compile", lora_pytorch_compile),
        ("cutedsl",         lora_cutedsl),
        ("helion_dot",      lora_helion_dot),
        ("helion_addmm",    lora_helion_addmm),
    ]

    results_dir = os.path.join(os.path.dirname(__file__), "results")
    os.makedirs(results_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = os.path.join(results_dir, f"results_{timestamp}.csv")

    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(ExperimentOutput.header())

        print(f"{'kernel':>20} {'tokens':>8} {'in_dim':>8} {'out_dim':>8} {'rank':>6} {'ms_median':>12} {'ms_mean':>10} {'ms_std':>8} {'max_abs':>10} {'rmse':>10}")
        print("-" * 110)

        for kernel_name, fn in kernels:
            for tokens, in_dim, out_dim, rank, dtype in LORA_CONFIGS:
                try:
                    tensors, ref = get_ref(tokens, in_dim, out_dim, rank, dtype)
                    result = ExperimentOutput(kernel_name, tokens, out_dim, in_dim)
                    result.run(fn, tensors, ref)
                except FileNotFoundError as e:
                    print(f"{kernel_name:>20} {tokens:>8} {in_dim:>8} {out_dim:>8} {rank:>6} -- skipped: {e}")
                    continue
                writer.writerow(result.values())
                print(f"{kernel_name:>20} {tokens:>8} {in_dim:>8} {out_dim:>8} {rank:>6} {result.ms_median:>12.4f} {result.ms_mean:>10.4f} {result.ms_std:>8.4f} {result.max_abs:>10.6f} {result.rmse:>10.6f}")

    print(f"\nResults saved to {filename}")
