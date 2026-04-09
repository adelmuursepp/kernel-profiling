import torch
import torch.nn.functional as F

# Reference notes it has implementation for FA2 
# but can also optimized to memory efficient attention
@torch.compile
def attention_pytorch_compile(q, k, v):
    return F.scaled_dot_product_attention(q, k, v, is_causal=False)
