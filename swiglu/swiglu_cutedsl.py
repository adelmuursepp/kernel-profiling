import torch
import cutlass
import cutlass.cute as cute
from cutlass import Float32, BFloat16, Int32
from cutlass.cute.runtime import from_dlpack

# cute.math.exp2 is the modern CuteDSL API for fast 2^x (uses ex2.approx.ftz.f32 under the hood).
# cute.arch.exp2 (PTX inline assembly version) is now deprecated in favour of cute.math.exp2.
# Reference: https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/cute/arch/nvvm_wrappers.py
# Example of cute.math.exp2 used in Flash Attention:
# https://github.com/NVIDIA/cutlass/blob/main/examples/python/CuTeDSL/ampere/flash_attention_v2.py


def silu_f32(x: Float32) -> Float32:
    """
    SiLU(x) = x * sigmoid(x)

    sigmoid(x) = 1 / (1 + exp(-x))
               = 1 / (1 + 2^(-x * log2(e)))   [since exp(a) = 2^(a*log2(e))]

    cute.math.exp2(a, fastmath=True) computes 2^a using the GPU's fast
    ex2.approx.ftz.f32 hardware instruction.
    """
    LOG2_E = Float32(1.4426950408889634)
    exp_neg_x = cute.math.exp2(x * Float32(-1.0) * LOG2_E, fastmath=True)
    sigmoid_x = Float32(1.0) / (Float32(1.0) + exp_neg_x)
    return x * sigmoid_x


@cute.kernel
def swiglu_kernel_bf16(x1: cute.Tensor, x2: cute.Tensor, out: cute.Tensor, N: Int32):
    tid = cute.arch.thread_idx()[0] + cute.arch.block_idx()[0] * cute.arch.block_dim()[0]
    if tid < N:
        x = Float32(x1[tid])
        y = Float32(x2[tid])
        out[tid] = BFloat16(silu_f32(x) * y)


@cute.kernel
def swiglu_kernel_f32(x1: cute.Tensor, x2: cute.Tensor, out: cute.Tensor, N: Int32):
    tid = cute.arch.thread_idx()[0] + cute.arch.block_idx()[0] * cute.arch.block_dim()[0]
    if tid < N:
        x = Float32(x1[tid])
        y = Float32(x2[tid])
        out[tid] = silu_f32(x) * y


@cute.jit
def run_swiglu_bf16(x1: cute.Tensor, x2: cute.Tensor, out: cute.Tensor, N: Int32):
    BLOCK = 256
    grid = ((N + BLOCK - 1) // BLOCK, 1, 1)
    swiglu_kernel_bf16(x1, x2, out, N).launch(grid=grid, block=(BLOCK, 1, 1))


@cute.jit
def run_swiglu_f32(x1: cute.Tensor, x2: cute.Tensor, out: cute.Tensor, N: Int32):
    BLOCK = 256
    grid = ((N + BLOCK - 1) // BLOCK, 1, 1)
    swiglu_kernel_f32(x1, x2, out, N).launch(grid=grid, block=(BLOCK, 1, 1))


_compiled_cache = {}


def swiglu_cutedsl(x1_torch: torch.Tensor, x2_torch: torch.Tensor) -> torch.Tensor:
    N = x1_torch.numel()
    out_torch = torch.empty_like(x1_torch)

    x1 = from_dlpack(x1_torch.view(-1))
    x2 = from_dlpack(x2_torch.view(-1))
    out = from_dlpack(out_torch.view(-1))

    cache_key = (N, x1_torch.dtype)
    if cache_key not in _compiled_cache:
        if x1_torch.dtype == torch.bfloat16:
            fn = cute.compile(run_swiglu_bf16, x1, x2, out, Int32(N))
        else:
            fn = cute.compile(run_swiglu_f32, x1, x2, out, Int32(N))
        _compiled_cache[cache_key] = fn

    _compiled_cache[cache_key](x1, x2, out, Int32(N))
    return out_torch
