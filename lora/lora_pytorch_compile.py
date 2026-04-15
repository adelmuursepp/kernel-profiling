import torch
import torch.nn.functional as F


@torch.compile
def lora_pytorch_compile(x, W, A, B):
    xA = F.linear(x, B)        # lora(x, w, a, b): xA = x @ a
    base = F.linear(x, W)      # fn: acc += x @ w
    return base + F.linear(xA, A)  # fn: acc += xA @ b
