import torch
import torch.nn.functional as F


def attention_pytorch(q, k, v):
    return F.scaled_dot_product_attention(q, k, v, is_causal=False)
