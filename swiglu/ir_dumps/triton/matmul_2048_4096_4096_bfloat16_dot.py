from __future__ import annotations

import torch
import helion
import triton
import triton.language as tl
from helion.runtime import default_launcher as _default_launcher

_BLOCK_SIZE_1 = tl.constexpr(64)
_BLOCK_SIZE_0 = tl.constexpr(128)
_BLOCK_SIZE_2 = tl.constexpr(64)
# src[helion_common.py:9]: def swiglu_kernel_fn_dot(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor) -> torch.Tensor:
# src[helion_common.py:10]:     tokens = x.shape[0]
# src[helion_common.py:11]:     hidden_dim = w1.shape[0]
# src[helion_common.py:9-22]: ...
helion.runtime.set_triton_allocator()

@triton.jit
def _helion_swiglu_kernel_fn_dot(x, w1, w2, out):
    # src[helion_common.py:17]: x_tile = x[tile_i, tile_k]
    x_desc = tl.make_tensor_descriptor(x, [2048, 4096], [4096, 1], [_BLOCK_SIZE_0, _BLOCK_SIZE_2])
    # src[helion_common.py:19]: up_acc   = hl.dot(x_tile, w2[tile_j, tile_k].T, acc=up_acc)
    w2_desc = tl.make_tensor_descriptor(w2, [4096, 4096], [4096, 1], [_BLOCK_SIZE_1, _BLOCK_SIZE_2])
    # src[helion_common.py:13]: for tile_i, tile_j in hl.tile([tokens, hidden_dim]):
    num_pid_m = tl.cdiv(4096, _BLOCK_SIZE_1)
    num_pid_n = tl.cdiv(2048, _BLOCK_SIZE_0)
    inner_2d_pid = tl.program_id(0)
    num_pid_in_group = 2 * num_pid_n
    group_id = inner_2d_pid // num_pid_in_group
    first_pid_m = group_id * 2
    group_size_m = min(num_pid_m - first_pid_m, 2)
    pid_0 = first_pid_m + inner_2d_pid % num_pid_in_group % group_size_m
    pid_1 = inner_2d_pid % num_pid_in_group // group_size_m
    offset_1 = pid_0 * _BLOCK_SIZE_1
    indices_1 = (offset_1 + tl.arange(0, _BLOCK_SIZE_1)).to(tl.int32)
    offset_0 = pid_1 * _BLOCK_SIZE_0
    indices_0 = (offset_0 + tl.arange(0, _BLOCK_SIZE_0)).to(tl.int32)
    # src[helion_common.py:14]: gate_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
    gate_acc = tl.full([_BLOCK_SIZE_0, _BLOCK_SIZE_1], 0.0, tl.float32)
    # src[helion_common.py:15]: up_acc   = hl.zeros([tile_i, tile_j], dtype=torch.float32)
    up_acc = tl.full([_BLOCK_SIZE_0, _BLOCK_SIZE_1], 0.0, tl.float32)
    # src[helion_common.py:16]: for tile_k in hl.tile(x.shape[1]):
    # src[helion_common.py:17]:     x_tile = x[tile_i, tile_k]
    # src[helion_common.py:18]:     gate_acc = hl.dot(x_tile, w1[tile_j, tile_k].T, acc=gate_acc)
    # src[helion_common.py:16-19]: ...
    for offset_2 in tl.range(0, 4096, _BLOCK_SIZE_2, num_stages=4, disallow_acc_multi_buffer=True, flatten=False):
        indices_2 = offset_2 + tl.arange(0, _BLOCK_SIZE_2).to(tl.int32)
        gate_acc_copy = gate_acc
        up_acc_copy = up_acc
        gate_acc_copy_0 = gate_acc_copy
        up_acc_copy_0 = up_acc_copy
        # src[helion_common.py:17]: x_tile = x[tile_i, tile_k]
        x_tile = x_desc.load([offset_0, offset_2])
        # src[helion_common.py:18]: gate_acc = hl.dot(x_tile, w1[tile_j, tile_k].T, acc=gate_acc)
        load_1 = tl.load(w1 + (indices_1[:, None] * 4096 + indices_2[None, :] * 1), None, eviction_policy='evict_last')
        permute = tl.permute(load_1, [1, 0])
        gate_acc = tl.dot(tl.cast(x_tile, tl.bfloat16), tl.cast(permute, tl.bfloat16), acc=gate_acc_copy_0, input_precision='tf32', out_dtype=tl.float32)
        # src[helion_common.py:19]: up_acc   = hl.dot(x_tile, w2[tile_j, tile_k].T, acc=up_acc)
        load_2 = w2_desc.load([offset_1, offset_2])
        permute_1 = tl.permute(load_2, [1, 0])
        up_acc = tl.dot(tl.cast(x_tile, tl.bfloat16), tl.cast(permute_1, tl.bfloat16), acc=up_acc_copy_0, input_precision='tf32', out_dtype=tl.float32)
    # src[helion_common.py:20]: silu_gate = gate_acc * torch.sigmoid(gate_acc)
    v_0 = tl.cast(gate_acc, tl.float32)
    v_1 = tl.sigmoid(v_0)
    v_2 = gate_acc * v_1
    # src[helion_common.py:21]: out[tile_i, tile_j] = (silu_gate * up_acc).to(x.dtype)
    v_3 = v_2 * up_acc
    v_4 = tl.cast(v_3, tl.bfloat16)
    tl.store(out + (indices_0[:, None] * 4096 + indices_1[None, :] * 1), v_4, None)

def swiglu_kernel_fn_dot(x: torch.Tensor, w1: torch.Tensor, w2: torch.Tensor, *, _launcher=_default_launcher):
    # src[helion_common.py:10]: tokens = x.shape[0]
    tokens = x.shape[0]
    # src[helion_common.py:11]: hidden_dim = w1.shape[0]
    hidden_dim = w1.shape[0]
    # src[helion_common.py:12]: out = torch.empty(tokens, hidden_dim, dtype=x.dtype, device=x.device)
    out = torch.empty(tokens, hidden_dim, dtype=x.dtype, device=x.device)
    # src[helion_common.py:13]: for tile_i, tile_j in hl.tile([tokens, hidden_dim]):
    _BLOCK_SIZE_1 = 64
    _BLOCK_SIZE_0 = 128
    # src[helion_common.py:13]: for tile_i, tile_j in hl.tile([tokens, hidden_dim]):
    # src[helion_common.py:14]:     gate_acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
    # src[helion_common.py:15]:     up_acc   = hl.zeros([tile_i, tile_j], dtype=torch.float32)
    # src[helion_common.py:13-21]: ...
    _launcher(_helion_swiglu_kernel_fn_dot, (triton.cdiv(4096, _BLOCK_SIZE_1) * triton.cdiv(2048, _BLOCK_SIZE_0),), x, w1, w2, out, num_warps=4, num_stages=3)
    # src[helion_common.py:22]: return out
    return out