import os
import torch
import helion
from helion import Config
from helion_common import config_key, attention_kernel_fn

CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")

_kernel_cache = {}


def attention_helion(q: torch.Tensor, k: torch.Tensor, v: torch.Tensor) -> torch.Tensor:
    batch, num_heads, seq_len, head_dim = q.shape
    key = config_key(batch, num_heads, seq_len, head_dim, q.dtype, variant="flash")

    if key not in _kernel_cache:
        cache_path = os.path.join(CACHE_DIR, f"{key}.json")
        # Sometimes helion does not finish autotuning for the largest configurations
        if not os.path.exists(cache_path):
            raise FileNotFoundError(f"No autotune cache for {key}, run autotune first")
        _kernel_cache[key] = helion.kernel(config=Config.load(cache_path), static_shapes=True)(attention_kernel_fn)

    return _kernel_cache[key](q, k, v)
