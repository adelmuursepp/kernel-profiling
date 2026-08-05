import torch
import helion.language as hl


def matmul_kernel(
    x: Tensor,
    y: Tensor,
    epilogue: Callable[[Tensor, tuple[Tensor, ...]], Tensor] = lambda acc, tile: acc,
) -> Tensor:
    """
    Performs matrix multiplication of x and y with an optional epilogue function.
    Args:
        x (Tensor): Left matrix of shape [m, k].
        y (Tensor): Right matrix of shape [k, n].
        epilogue (Callable, optional): Function applied to the accumulator and tile indices
            after the matmul. Defaults to identity (no change).
    Returns:
        Tensor: Resulting matrix of shape [m, n].
    """
    y = y.t()
    m, k = x.size()
    k2, n = y.size()
    assert k == k2, f"size mismatch {k} != {k2}"
    out = torch.empty(
        [m, n], dtype=torch.promote_types(x.dtype, y.dtype), device=x.device
    )
    for tile_m, tile_n in hl.tile([m, n]):
        acc = hl.zeros([tile_m, tile_n], dtype=torch.float32)
        for tile_k in hl.tile(k):
            acc = torch.addmm(acc, x[tile_m, tile_k], y[tile_k, tile_n])
        out[tile_m, tile_n] = epilogue(acc, (tile_m, tile_n))
    return out


def rmsnorm_lin_kernel(
    x: torch.Tensor,
    y: torch.Tensor,
    eps: float=1e-5,
) -> torch.Tensor:
    """
    performs rmsnorm(x) y
    x is (m, k), y is (k, n)
    """
    y = y.t()
    m, k = x.size()
    k2, n = y.size()
    out = torch.empty(
        [m, n], dtype=x.dtype, device=x.device
    )
    for tile_m, tile_n in hl.tile([m, n]):
        acc = hl.zeros([tile_m, tile_n], dtype=torch.float32)
        sum_acc = hl.zeros([tile_m], dtype=torch.float32)
        for tile_k in hl.tile(k):
            xTile = x[tile_m, tile_k]
            acc = torch.addmm(acc, xTile, y[tile_k, tile_n])
            
            # This is taken from rmsnorm tutorial
            x_squared = xTile * xTile
            sum_acc += torch.sum(x_squared, dim=-1)

        inv_rms = torch.rsqrt((sum_acc / k) + eps)
        normalized = acc * inv_rms[:, None]
        out[tile_m, tile_n] = normalized
    return out

def swiglu_kernel(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
    """
    performs swiglu
    expects (m, k), (n, k), (n, k) inputs
    x is (m, k)
    w1, w2 are (k, n)
    """
    w1, w2 = w1.t(), w2.t()
    m = x.shape[0]
    n = w1.shape[1]
    out = torch.empty((m, n), dtype=x.dtype, device=x.device)
    for tile_i, tile_j in hl.tile([m, n]):
        gate_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32) 
        up_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        for tile_k in hl.tile(x.shape[1]):
            xTile = x[tile_i, tile_k]
            gate_acc = torch.addmm(gate_acc, xTile, w1[tile_k, tile_j])
            up_acc = torch.addmm(up_acc, xTile, w2[tile_k, tile_j])
        silu_gate = gate_acc * torch.sigmoid(gate_acc)
        # Convert to BF16 before writing to out
        out[tile_i, tile_j] = (silu_gate * up_acc).to(x.dtype)
    return out

# TODO untested
def lora_kernel(
    x: torch.Tensor,
    W: torch.Tensor,
    A: torch.Tensor,
    B: torch.Tensor,  # pre-computed x @ B.T, passed in to keep @ outside helion
) -> torch.Tensor:
    """
    Computes xW * (xA)B

    x: m, k
    w: n, k --> k, n
    A: lora_dim, k --> k, lora_dim
    B: n, lora_dim --> lora_dim, n
    """
    w = w.t()
    B = B.t()
    m, k = x.shape
    n = W.shape[1]
    xA = x @ A.t() # m, lora_dim
    out = torch.empty(m, n, dtype=x.dtype, device=x.device)
    
    for tile_i, tile_j in hl.tile([m, n]):
        acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        for tile_k in hl.tile(k):
            acc = torch.addmm(acc, x[tile_i, tile_k], W[tile_k, tile_j])
        acc = torch.addmm(acc, xA[tile_i, :], B[:, tile_j])
        out[tile_i, tile_j] = acc.to(x.dtype)
    return out