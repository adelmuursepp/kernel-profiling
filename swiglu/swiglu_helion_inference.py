import os
import torch
import helion
from helion import Config
from helion_common import config_key, swiglu_kernel_fn_dot, swiglu_kernel_fn_addmm

CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")

_kernel_cache = {}


def swiglu_helion_dot(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    tokens, d_model = x.shape
    hidden_dim = w1.shape[0]
    key = config_key(tokens, d_model, hidden_dim, x.dtype, variant="dot")

    if key not in _kernel_cache:
        cache_path = os.path.join(CACHE_DIR, f"{key}.json")
        # Sometimes helion does not finish autotuning for the largest configurations
        if not os.path.exists(cache_path):
            raise FileNotFoundError(f"No autotune cache for {key}, run autotune first")
        _kernel_cache[key] = helion.kernel(config=Config.load(cache_path))(swiglu_kernel_fn_dot)

    return _kernel_cache[key](x, w1, w2)


def swiglu_helion_addmm(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    tokens, d_model = x.shape
    hidden_dim = w1.shape[0]
    key = config_key(tokens, d_model, hidden_dim, x.dtype, variant="addmm")

    if key not in _kernel_cache:
        cache_path = os.path.join(CACHE_DIR, f"{key}.json")
        # Sometimes helion does not finish autotuning for the largest configurations
        if not os.path.exists(cache_path):
            raise FileNotFoundError(f"No autotune cache for {key}, run autotune first")
        _kernel_cache[key] = helion.kernel(config=Config.load(cache_path))(swiglu_kernel_fn_addmm)

    return _kernel_cache[key](x, w1, w2)
