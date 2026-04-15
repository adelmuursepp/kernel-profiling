"""
Autotunes helion LoRA kernels (dot and addmm variants) for each shape in
LORA_CONFIGS and saves the best config to autotune_cache/<key>.json.

Output files:
    autotune_cache/lora_512_4096_4096_16_bfloat16_dot.json
    autotune_cache/lora_512_4096_4096_16_bfloat16_addmm.json
    ...

"""

import os


import torch
import helion
from common import LORA_CONFIGS, config_key
from helion_common import VARIANTS

CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")

if __name__ == "__main__":
    os.makedirs(CACHE_DIR, exist_ok=True)

    for variant_name, kernel_fn in VARIANTS:
        for tokens, in_dim, out_dim, rank, dtype in LORA_CONFIGS:
            key = config_key(tokens, in_dim, out_dim, rank, dtype, variant=variant_name)
            cache_path = os.path.join(CACHE_DIR, f"{key}.json")

            if os.path.exists(cache_path):
                print(f"Skipping {key} (cache exists)")
                continue

            print(f"Autotuning {key} ...")

            x = torch.randn(tokens,  in_dim,  device="cuda", dtype=dtype)
            W = torch.randn(out_dim, in_dim,  device="cuda", dtype=dtype)
            A = torch.randn(out_dim, rank,    device="cuda", dtype=dtype)
            B = torch.randn(rank,    in_dim,  device="cuda", dtype=dtype)
            xA = x @ B.T  # pre-compute outside helion kernel

            best_config = helion.kernel()(kernel_fn).autotune((x, W, A, xA))
            best_config.save(cache_path)

            print(f"  Saved -> {cache_path}")
