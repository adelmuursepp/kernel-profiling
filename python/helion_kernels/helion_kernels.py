import torch
import helion.language as hl


def rmsnorm_lin_kernel(
    x: torch.Tensor,
    y: torch.Tensor,
    eps: float=1e-5,
) -> torch.Tensor:
    """
    performs rmsnorm(x) y
    x is (m, k), y is (k, n)
    """
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
    x is (m, k)
    w1, w2 are (k, n)
    """
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

def lora_kernel(
    x: torch.Tensor,
    W: torch.Tensor,
    A: torch.Tensor,
    B: torch.Tensor,  # pre-computed x @ B.T, passed in to keep @ outside helion
) -> torch.Tensor:
    """
    Computes xW * (xA)B

    x: m, k
    w: k, n
    A: k, lora_dim
    B: lora_dim, n
    """
    m, k = x.shape
    n = W.shape[1]
    xA = x @ A # m x lora_dim
    out = torch.empty(m, n, dtype=x.dtype, device=x.device)
    
    for tile_i, tile_j in hl.tile([m, n]):
        acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        for tile_k in hl.tile(k):
            acc = torch.addmm(acc, x[tile_i, tile_k], W[tile_k, tile_j])
        acc = torch.addmm(acc, xA[tile_i, :], B[:, tile_j])
        out[tile_i, tile_j] = acc.to(x.dtype)
    return out