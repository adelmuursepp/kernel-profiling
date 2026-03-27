"""
Output files:
    autotune_cache/512_4096_bfloat16.json
    autotune_cache/2048_4096_float32.json
    ...
"""

import os
import torch
import helion
import helion.language as hl
from helion import Config


@helion.kernel()
def swiglu_helion_autotune(x1: torch.Tensor, x2: torch.Tensor) -> torch.Tensor:
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


CACHE_DIR = "autotune_cache"

CONFIGS = [
    (512,   4096,  torch.bfloat16),
    (2048,  4096,  torch.float32),
    (2048,  4096,  torch.bfloat16),
    (8192,  4096,  torch.bfloat16),
    (8192,  8192,  torch.bfloat16),
    (32768, 8192,  torch.bfloat16),
    (65536, 8192,  torch.bfloat16),
]


def config_key(tokens, hidden_dim, dtype):
    return f"{tokens}_{hidden_dim}_{str(dtype).split('.')[-1]}"


if __name__ == "__main__":
    os.makedirs(CACHE_DIR, exist_ok=True)

    for tokens, hidden_dim, dtype in CONFIGS:
        key = config_key(tokens, hidden_dim, dtype)
        cache_path = os.path.join(CACHE_DIR, f"{key}.json")

        print(f"Autotuning {key} ...")

        x1 = torch.randn(tokens, hidden_dim, device="cuda", dtype=dtype)
        x2 = torch.randn(tokens, hidden_dim, device="cuda", dtype=dtype)

        best_config = swiglu_helion_autotune.autotune((x1, x2))
        best_config.save(cache_path)

        print(f"  Saved -> {cache_path}")
