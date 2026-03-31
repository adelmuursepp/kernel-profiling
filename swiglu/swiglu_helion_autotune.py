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
from configs import MATMUL_CONFIGS

CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")

@helion.kernel()
def swiglu_helion_autotune(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    tokens = x.shape[0]
    hidden_dim = w1.shape[0]
    out = torch.empty(tokens, hidden_dim, dtype = x.dtype, device = x.device)
    
    # x is split in [tile_i, tile_k]
    # w1 and w2 transposed have the tile [tile_k, tile_j]
    # for the output tile [tile_i, tile_j]

    # Split x, w1 and w2 into tiles
    for tile_i, tile_j in hl.tile([tokens, hidden_dim]):
        gate_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)  # standard to convert to f32 for matmuls
        up_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)

        # Go over k columns in x and k rows in w1/w2 for matmul
        for tile_k in hl.tile(x.shape[1]):
            x_tile = x[tile_i, tile_k].to(torch.float32)
            gate_acc = gate_acc + x_tile @ w1[tile_j, tile_k].to(torch.float32).T
            up_acc = up_acc + x_tile @ w2[tile_j, tile_k].to(torch.float32).T

        silu_gate = gate_acc * torch.sigmoid(gate_acc)
        out[tile_i, tile_j] = (silu_gate * up_acc).to(x.dtype)      # convert back to x datatype
    return out

def config_key(tokens, d_model, hidden_dim, dtype):
    return f"matmul_{tokens}_{d_model}_{hidden_dim}_{str(dtype).split('.')[-1]}"

if __name__ == "__main__":
    os.makedirs(CACHE_DIR, exist_ok=True)

    for tokens, d_model, hidden_dim, dtype in MATMUL_CONFIGS:
        key = config_key(tokens, d_model,  hidden_dim, dtype)
        cache_path = os.path.join(CACHE_DIR, f"{key}.json")

        print(f"Autotuning {key} ...")

        x = torch.randn(tokens, d_model, device="cuda", dtype=dtype)
        w1 = torch.randn(hidden_dim, d_model, device="cuda", dtype=dtype)
        w2 = torch.randn(hidden_dim, d_model, device="cuda", dtype=dtype)

        best_config = swiglu_helion_autotune.autotune((x, w1, w2))
        best_config.save(cache_path)

        print(f"  Saved -> {cache_path}")

