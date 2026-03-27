import os
import torch
import helion
import helion.language as hl
from helion import Config


def _make_helion_kernel():
    @helion.kernel()
    def k(x1: torch.Tensor, x2: torch.Tensor) -> torch.Tensor:
        assert x1.shape == x2.shape
        out = torch.empty_like(x1)
        x1_flat = x1.view(-1)
        x2_flat = x2.view(-1)
        out_flat = out.view(-1)
        for tile in hl.tile(x1.numel()):
            a = x1_flat[tile].to(torch.float32)
            b = x2_flat[tile].to(torch.float32)
            silu_a = a * torch.sigmoid(a)
            out_flat[tile] = silu_a.to(x1.dtype) * x2_flat[tile]
        return out
    return k


CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")

_kernel_cache = {}


def _config_key(tokens, hidden_dim, dtype):
    return f"{tokens}_{hidden_dim}_{str(dtype).split('.')[-1]}"


def swiglu_helion(x1: torch.Tensor, x2: torch.Tensor) -> torch.Tensor:
    tokens, hidden_dim = x1.shape[0], x1.shape[1]
    key = _config_key(tokens, hidden_dim, x1.dtype)

    if key not in _kernel_cache:
        cache_path = os.path.join(CACHE_DIR, f"{key}.json")
        k = _make_helion_kernel()
        k.set_config(Config.load(cache_path))
        _kernel_cache[key] = k

    return _kernel_cache[key](x1, x2)
