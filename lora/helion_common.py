import torch
import helion.language as hl


def lora_kernel_fn_dot(
    x: torch.Tensor,
    W: torch.Tensor,
    A: torch.Tensor,
    xA: torch.Tensor,  # pre-computed x @ B.T, passed in to keep @ outside helion
) -> torch.Tensor:
    tokens = x.shape[0]
    out_dim = W.shape[0]
    out = torch.empty(tokens, out_dim, dtype=x.dtype, device=x.device)
    for tile_i, tile_j in hl.tile([tokens, out_dim]):
        acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        for tile_k in hl.tile(x.shape[1]):
            acc = hl.dot(x[tile_i, tile_k], W[tile_j, tile_k].T, acc=acc)  # acc += x @ W.T
        acc = hl.dot(xA[tile_i, :], A[tile_j, :].T, acc=acc)  # acc += xA @ A.T
        out[tile_i, tile_j] = acc.to(x.dtype)
    return out


def lora_kernel_fn_addmm(
    x: torch.Tensor,
    W: torch.Tensor,
    A: torch.Tensor,
    xA: torch.Tensor,  # pre-computed x @ B.T, passed in to keep @ outside helion
) -> torch.Tensor:
    tokens = x.shape[0]
    out_dim = W.shape[0]
    out = torch.empty(tokens, out_dim, dtype=x.dtype, device=x.device)
    for tile_i, tile_j in hl.tile([tokens, out_dim]):
        acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        for tile_k in hl.tile(x.shape[1]):
            acc = torch.addmm(acc, x[tile_i, tile_k], W[tile_j, tile_k].T)  # acc += x @ W.T
        acc = torch.addmm(acc, xA[tile_i, :], A[tile_j, :].T)  # acc += xA @ A.T
        out[tile_i, tile_j] = acc.to(x.dtype)
    return out


VARIANTS = [
    ("dot", lora_kernel_fn_dot),
    ("addmm", lora_kernel_fn_addmm),
]
