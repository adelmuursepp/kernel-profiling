import torch

# Configs aligned with profile_script.py:
# https://github.com/dungwoong/fused_kernels_cutedsl/blob/main/flashattention/attempt6_epi_pipeline/profile_script.py
# total_tokens = 16384 fixed, batch = total_tokens // seq_len, num_heads = 16

# (batch, num_heads, seq_len, head_dim, dtype)
ATTENTION_CONFIGS = [
    (32, 16,  512,  64, torch.bfloat16),
    (32, 16,  512, 128, torch.bfloat16),
    (16, 16, 1024,  64, torch.bfloat16),
    (16, 16, 1024, 128, torch.bfloat16),
    ( 8, 16, 2048,  64, torch.bfloat16),
    ( 8, 16, 2048, 128, torch.bfloat16),
    ( 4, 16, 4096,  64, torch.bfloat16),
    ( 4, 16, 4096, 128, torch.bfloat16),
    ( 2, 16, 8192,  64, torch.bfloat16),
    ( 2, 16, 8192, 128, torch.bfloat16),
]
