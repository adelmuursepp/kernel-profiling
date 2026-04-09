import torch
import helion.language as hl


def config_key(tokens, d_model, hidden_dim, dtype, variant="dot"):
    return f"matmul_{tokens}_{d_model}_{hidden_dim}_{str(dtype).split('.')[-1]}_{variant}"


def swiglu_kernel_fn_dot(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    tokens = x.shape[0]
    hidden_dim = w1.shape[0]
    out = torch.empty(tokens, hidden_dim, dtype=x.dtype, device=x.device)
    for tile_i, tile_j in hl.tile([tokens, hidden_dim]):
        gate_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        up_acc   = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        for tile_k in hl.tile(x.shape[1]):
            gate_acc = hl.dot(x[tile_i, tile_k], w1[tile_j, tile_k].T, acc=gate_acc)
            up_acc   = hl.dot(x[tile_i, tile_k], w2[tile_j, tile_k].T, acc=up_acc)
        silu_gate = gate_acc * torch.sigmoid(gate_acc)
        out[tile_i, tile_j] = (silu_gate * up_acc).to(x.dtype)
    return out

# Helion with torch.addmm
def swiglu_kernel_fn_addmm(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    tokens = x.shape[0]
    hidden_dim = w1.shape[0]
    out = torch.empty(tokens, hidden_dim, dtype=x.dtype, device=x.device)
    for tile_i, tile_j in hl.tile([tokens, hidden_dim]):
        gate_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32) 
        up_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        for tile_k in hl.tile(x.shape[1]):
            gate_acc = torch.addmm(gate_acc, x[tile_i, tile_k], w1[tile_j, tile_k].T)
            up_acc = torch.addmm(up_acc, x[tile_i, tile_k], w2[tile_j, tile_k].T)
        silu_gate = gate_acc * torch.sigmoid(gate_acc)
        # Convert to BF16 before writing to out
        out[tile_i, tile_j] = (silu_gate * up_acc).to(x.dtype)
    return out

VARIANTS = [
    ("dot", swiglu_kernel_fn_dot), 
    ("addmm", swiglu_kernel_fn_addmm)
]
