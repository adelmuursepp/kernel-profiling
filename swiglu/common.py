import torch

MATMUL_CONFIGS = [
    (512,   4096, 4096, torch.bfloat16),
    (2048,  4096, 4096, torch.bfloat16),
    (8192,  4096, 4096, torch.bfloat16),
    (8192,  8192, 8192, torch.bfloat16),
    (32768, 4096, 8192, torch.bfloat16),
    (65536, 4096, 8192, torch.bfloat16),
]



