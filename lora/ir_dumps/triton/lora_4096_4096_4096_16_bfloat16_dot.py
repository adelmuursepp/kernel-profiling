from __future__ import annotations

import torch
import helion
import triton
import triton.language as tl
from helion.runtime import default_launcher as _default_launcher

_BLOCK_SIZE_0 = tl.constexpr(256)
_BLOCK_SIZE_1 = tl.constexpr(128)
_BLOCK_SIZE_2 = tl.constexpr(64)
# src[helion_common.py:5]: def lora_kernel_fn_dot(
# src[helion_common.py:6]:     x: torch.Tensor,
# src[helion_common.py:7]:     W: torch.Tensor,
# src[helion_common.py:5-20]: ...
helion.runtime.set_triton_allocator()

@triton.jit
def _helion_lora_kernel_fn_dot(x, W, xA, A, out, _NUM_SM: tl.constexpr, _RDIM_SIZE_3: tl.constexpr):
    # src[helion_common.py:17]: acc = hl.dot(x[tile_i, tile_k], W[tile_j, tile_k].T, acc=acc)  # acc += x @ W.T
    x_desc = tl.make_tensor_descriptor(x, [4096, 4096], [4096, 1], [_BLOCK_SIZE_0, _BLOCK_SIZE_2])
    # src[helion_common.py:14]: for tile_i, tile_j in hl.tile([tokens, out_dim]):
    # src[helion_common.py:15]:     acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
    # src[helion_common.py:16]:     for tile_k in hl.tile(x.shape[1]):
    # src[helion_common.py:14-19]: ...
    total_pids = tl.cdiv(4096, _BLOCK_SIZE_0) * tl.cdiv(4096, _BLOCK_SIZE_1)
    block_size = tl.cdiv(total_pids, _NUM_SM)
    start_pid = tl.program_id(0) * block_size
    end_pid = start_pid + block_size
    if end_pid > total_pids:
        end_pid = total_pids
    for virtual_pid in tl.range(start_pid, end_pid, loop_unroll_factor=2, num_stages=1, disallow_acc_multi_buffer=True, flatten=False):
        # src[helion_common.py:14]: for tile_i, tile_j in hl.tile([tokens, out_dim]):
        num_pid_m = tl.cdiv(4096, _BLOCK_SIZE_0)
        num_pid_n = tl.cdiv(4096, _BLOCK_SIZE_1)
        inner_2d_pid = virtual_pid
        num_pid_in_group = 8 * num_pid_n
        group_id = inner_2d_pid // num_pid_in_group
        first_pid_m = group_id * 8
        group_size_m = min(num_pid_m - first_pid_m, 8)
        pid_0 = first_pid_m + inner_2d_pid % num_pid_in_group % group_size_m
        pid_1 = inner_2d_pid % num_pid_in_group // group_size_m
        offset_0 = pid_0 * _BLOCK_SIZE_0
        indices_0 = (offset_0 + tl.arange(0, _BLOCK_SIZE_0)).to(tl.int32)
        offset_1 = pid_1 * _BLOCK_SIZE_1
        indices_1 = (offset_1 + tl.arange(0, _BLOCK_SIZE_1)).to(tl.int32)
        indices_3 = tl.arange(0, _RDIM_SIZE_3).to(tl.int32)
        # src[helion_common.py:15]: acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
        acc = tl.full([_BLOCK_SIZE_0, _BLOCK_SIZE_1], 0.0, tl.float32)
        # src[helion_common.py:16]: for tile_k in hl.tile(x.shape[1]):
        # src[helion_common.py:17]:     acc = hl.dot(x[tile_i, tile_k], W[tile_j, tile_k].T, acc=acc)  # acc += x @ W.T
        for offset_2 in tl.range(0, 4096, _BLOCK_SIZE_2, loop_unroll_factor=1, num_stages=4, flatten=True):
            indices_2 = offset_2 + tl.arange(0, _BLOCK_SIZE_2).to(tl.int32)
            acc_copy = acc
            acc_copy_0 = acc_copy
            # src[helion_common.py:17]: acc = hl.dot(x[tile_i, tile_k], W[tile_j, tile_k].T, acc=acc)  # acc += x @ W.T
            load = x_desc.load([offset_0, offset_2])
            load_1 = tl.load(W + (indices_1[:, None] * 4096 + indices_2[None, :] * 1), None)
            permute = tl.permute(load_1, [1, 0])
            acc = tl.dot(tl.cast(load, tl.bfloat16), tl.cast(permute, tl.bfloat16), acc=acc_copy_0, input_precision='tf32', out_dtype=tl.float32)
        # src[helion_common.py:18]: acc = hl.dot(xA[tile_i, :], A[tile_j, :].T, acc=acc)  # acc += xA @ A.T
        load_2 = tl.load(xA + (indices_0[:, None] * 16 + indices_3[None, :] * 1), None, eviction_policy='evict_last')
        load_3 = tl.load(A + (indices_1[:, None] * 16 + indices_3[None, :] * 1), None, eviction_policy='evict_last')
        permute_1 = tl.permute(load_3, [1, 0])
        acc_2 = tl.dot(tl.cast(load_2, tl.bfloat16), tl.cast(permute_1, tl.bfloat16), acc=acc, input_precision='tf32', out_dtype=tl.float32)
        # src[helion_common.py:19]: out[tile_i, tile_j] = acc.to(x.dtype)
        v_0 = tl.cast(acc_2, tl.bfloat16)
        tl.store(out + (indices_0[:, None] * 4096 + indices_1[None, :] * 1), v_0, None)

def lora_kernel_fn_dot(x: torch.Tensor, W: torch.Tensor, A: torch.Tensor, xA: torch.Tensor, *, _launcher=_default_launcher):
    # src[helion_common.py:11]: tokens = x.shape[0]
    tokens = x.shape[0]
    # src[helion_common.py:12]: out_dim = W.shape[0]
    out_dim = W.shape[0]
    # src[helion_common.py:13]: out = torch.empty(tokens, out_dim, dtype=x.dtype, device=x.device)
    out = torch.empty(tokens, out_dim, dtype=x.dtype, device=x.device)
    # src[helion_common.py:14]: for tile_i, tile_j in hl.tile([tokens, out_dim]):
    _NUM_SM = helion.runtime.get_num_sm(x.device)
    _RDIM_SIZE_3 = 16
    # src[helion_common.py:14]: for tile_i, tile_j in hl.tile([tokens, out_dim]):
    # src[helion_common.py:15]:     acc = hl.zeros([tile_i, tile_j], dtype=torch.float32)
    # src[helion_common.py:16]:     for tile_k in hl.tile(x.shape[1]):
    # src[helion_common.py:14-19]: ...
    _launcher(_helion_lora_kernel_fn_dot, (_NUM_SM,), x, W, xA, A, out, _NUM_SM, _RDIM_SIZE_3, num_warps=8, num_stages=5, maxnreg=256)
    # src[helion_common.py:20]: return out
    return out