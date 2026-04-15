import os
import torch
import helion
from helion import Config
from common import config_key
from helion_common import lora_kernel_fn_dot, lora_kernel_fn_addmm

CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")

_kernel_cache = {}


def _get(kernel_fn, tokens, in_dim, out_dim, rank, dtype, variant):
    key = config_key(tokens, in_dim, out_dim, rank, dtype, variant=variant)
    if key not in _kernel_cache:
        cache_path = os.path.join(CACHE_DIR, f"{key}.json")
        _kernel_cache[key] = helion.kernel(config=Config.load(cache_path))(kernel_fn)
    return _kernel_cache[key]


def lora_helion_dot(x: torch.Tensor, W: torch.Tensor, A: torch.Tensor, B: torch.Tensor) -> torch.Tensor:
    tokens, in_dim = x.shape
    out_dim, rank = W.shape[0], B.shape[0]
    xA = x @ B.T  # pre-compute outside helion kernel
    return _get(lora_kernel_fn_dot, tokens, in_dim, out_dim, rank, x.dtype, "dot")(x, W, A, xA)


def lora_helion_addmm(x: torch.Tensor, W: torch.Tensor, A: torch.Tensor, B: torch.Tensor) -> torch.Tensor:
    tokens, in_dim = x.shape
    out_dim, rank = W.shape[0], B.shape[0]
    xA = x @ B.T  # pre-compute outside helion kernel
    return _get(lora_kernel_fn_addmm, tokens, in_dim, out_dim, rank, x.dtype, "addmm")(x, W, A, xA)
