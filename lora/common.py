import torch

# Typical LLM LoRA shapes:
#   tokens  = sequence length
#   in_dim  = input hidden size  (e.g. 4096 for LLaMA-7B)
#   out_dim = output hidden size (Q/K/V/O projections, MLP gates)
#   rank    = LoRA rank (small, e.g. 16 or 64)
LORA_CONFIGS = [
    (4096,   4096, 4096, 16,  torch.bfloat16), # same as for fused cutedsl kernel
    # (512,   4096, 4096, 16,  torch.bfloat16),
    # (2048,  4096, 4096, 16,  torch.bfloat16),
    # (2048,  4096, 4096, 64,  torch.bfloat16),
    # (8192,  4096, 4096, 64,  torch.bfloat16),
    # (8192,  8192, 8192, 64,  torch.bfloat16),
    # (32768, 4096, 8192, 64,  torch.bfloat16),
]


def config_key(tokens, in_dim, out_dim, rank, dtype, variant="dot"):
    return f"lora_{tokens}_{in_dim}_{out_dim}_{rank}_{str(dtype).split('.')[-1]}_{variant}"
