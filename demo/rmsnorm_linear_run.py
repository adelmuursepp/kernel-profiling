import torch
from helion_kernels import RMSNormLinear
from helion_kernels.dump_ir import dump_ir
from triton.testing import do_bench

@torch.compile
def torch_kernel(a: torch.Tensor, b: torch.Tensor, eps: float=1e-5):
    a_rms = torch.nn.functional.rms_norm(a, normalized_shape=(a.shape[1],), eps=eps)
    return a_rms @ b.t()

if __name__ == '__main__':
    m, n, k = 4096, 4096, 4096
    a = torch.randn((m, k), dtype=torch.bfloat16, device='cuda')
    b = torch.randn((n, k), dtype=torch.bfloat16, device='cuda')
    compiled_rmsnorm_linear = RMSNormLinear.compile(a, b.t())

    result = compiled_rmsnorm_linear(a, b.t())

    ms_1 = do_bench(lambda: compiled_rmsnorm_linear(a, b.t()))
    ms_2 = do_bench(lambda: torch_kernel(a, b))
    print(f'{ms_1}, {ms_2}, {ms_2 / ms_1}')

    RMSNormLinear.dump_ir(compiled_rmsnorm_linear, (a, b.t(), 1e-5))
    # dump_ir(compiled_rmsnorm_linear, (a, b.t(), 1e-5), RMSNormLinear._tensors_to_key(a, b.t()))