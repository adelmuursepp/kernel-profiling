import os

# Run each autotune candidate in a subprocess so a crashing config (e.g.
# cudaErrorIllegalAddress or PTXAS register overflow) doesn't kill the whole
# tuner. The best non-crashing config still gets saved.
os.environ.setdefault("HELION_AUTOTUNE_PRECOMPILE", "spawn")

import torch
import helion
from common import ATTENTION_CONFIGS
from helion_common import config_key, VARIANTS

CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")


if __name__ == "__main__":
    os.makedirs(CACHE_DIR, exist_ok=True)

    for variant_name, kernel_fn in VARIANTS:
        # Q, K, V do not change throughout for a kernel and gives speedup
        autotune_kernel = helion.kernel(static_shapes=True)(kernel_fn)

        for batch, num_heads, seq_len, head_dim, dtype in ATTENTION_CONFIGS:
            key = config_key(batch, num_heads, seq_len, head_dim, dtype, variant_name)
            cache_path = os.path.join(CACHE_DIR, f"{key}.json")

            if os.path.exists(cache_path):
                print(f"Skipping {key} (cache exists)")
                continue

            print(f"Autotuning {key} ...")

            q = torch.randn(batch, num_heads, seq_len, head_dim, device="cuda", dtype=dtype)
            k = torch.randn(batch, num_heads, seq_len, head_dim, device="cuda", dtype=dtype)
            v = torch.randn(batch, num_heads, seq_len, head_dim, device="cuda", dtype=dtype)

            best_config = autotune_kernel.autotune((q, k, v))
            best_config.save(cache_path)
            print(f"  Saved config -> {cache_path}")

            triton_path = os.path.join(CACHE_DIR, f"{key}_triton.py")
            try:
                triton_code = helion.kernel(config=best_config, static_shapes=True)(kernel_fn).bind((q, k, v)).to_triton_code()
                with open(triton_path, "w") as f:
                    f.write(triton_code)
                print(f"  Saved Triton -> {triton_path}")
            except Exception as e:
                print(f"  Could not save Triton code: {e}")
