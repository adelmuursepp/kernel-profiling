"""
Validation tests for lora_cutedsl.py

Run on the SSH machine with:
    python test_cutedsl.py

Tests (in order):
    1. test_pytorch_ref     – reference math: X@W.T + (X@B.T)@A.T
    2. test_lora_small      – lora_cutedsl on a small shape (tokens=64, dims=64, rank=16)
    3. test_lora_rank16     – lora_cutedsl with rank=16 (single MMA K-block in epilogue)
    4. test_lora_rank64     – lora_cutedsl with rank=64 (four MMA K-blocks)
    5. test_lora_configs    – lora_cutedsl over all LORA_CONFIGS shapes

The epilogue WGMMA (lora_acc @ A.T) is the most likely failure point due to the
known autovec_copy layout mismatch (see lora_cutedsl.py module docstring).
If tests 2-5 fail, run with VERBOSE=1 to see element-wise diagnostics.
"""

import torch
from lora_cutedsl import lora_cutedsl
from lora_pytorch import lora_pytorch
from common import LORA_CONFIGS


# ── Helpers ───────────────────────────────────────────────────────────────────

def ref(x, W, A, B):
    # Reference: pytorch eager in BF16, same precision as the kernel.
    # Pure FP32 reference (x.float() @ W.float().T + ...) diverges at large
    # dims because intermediate BF16 rounding compounds — same issue as swiglu.
    return lora_pytorch(x, W, A, B)


def check(actual: torch.Tensor, expected: torch.Tensor, name: str, atol=0.1) -> bool:
    diff    = (actual.float() - expected.float()).abs()
    max_err = diff.max().item()
    n_wrong = (diff >= atol).sum().item()
    passed  = n_wrong == 0
    status  = "PASSED" if passed else "FAILED"
    print(f"  [{status}] {name}: max_err={max_err:.4f}  wrong={n_wrong}/{actual.numel()}")

    if not passed:
        wrong_idx = diff.ge(atol).nonzero(as_tuple=False)[:8]
        print(f"  First wrong elements (idx | actual | expected | diff):")
        for idx in wrong_idx:
            coord = tuple(idx.tolist())
            a = actual[coord].item()
            e = expected[coord].item()
            print(f"    {coord}  {a:+.4f}  {e:+.4f}  {abs(a-e):.4f}")

        buckets = [0.1, 0.5, 1.0, 2.0, 4.0, float("inf")]
        labels  = ["<0.1", "0.1-0.5", "0.5-1", "1-2", "2-4", ">=4"]
        prev = 0.0
        print(f"  Error distribution:")
        for label, hi in zip(labels, buckets):
            count = ((diff >= prev) & (diff < hi)).sum().item()
            if count:
                print(f"    {label}: {count}")
            prev = hi

    return passed


def make_inputs(tokens, in_dim, out_dim, rank, dtype, seed=42):
    torch.manual_seed(seed)
    x = torch.randn(tokens,  in_dim,  device="cuda", dtype=dtype)
    W = torch.randn(out_dim, in_dim,  device="cuda", dtype=dtype)
    A = torch.randn(out_dim, rank,    device="cuda", dtype=dtype)
    B = torch.randn(rank,    in_dim,  device="cuda", dtype=dtype)
    return x, W, A, B


# ── Tests ─────────────────────────────────────────────────────────────────────

def test_pytorch_ref():
    """Sanity check: lora_pytorch matches float32 reference."""
    print("test_pytorch_ref")
    x, W, A, B = make_inputs(128, 64, 64, 16, torch.bfloat16)

    # Float32 reference — small dims so rounding doesn't compound
    fp32_ref = (x.float() @ W.float().T + x.float() @ B.float().T @ A.float().T).bfloat16()
    bf16_ref = lora_pytorch(x, W, A, B)

    diff = (fp32_ref.float() - bf16_ref.float()).abs()
    passed = diff.max().item() < 0.1
    status = "PASSED" if passed else "FAILED"
    print(f"  [{status}] pytorch vs fp32: max_diff={diff.max().item():.4f}")
    return passed


def test_lora_small():
    """Smallest possible shape — fast smoke test, easier to debug."""
    print("test_lora_small")
    tokens, in_dim, out_dim, rank = 64, 64, 64, 16
    dtype = torch.bfloat16

    x, W, A, B = make_inputs(tokens, in_dim, out_dim, rank, dtype)
    expected = ref(x, W, A, B)
    actual   = lora_cutedsl(x, W, A, B)

    return check(actual, expected, f"tokens={tokens} in={in_dim} out={out_dim} rank={rank}")


def test_lora_rank16():
    """rank=16: single MMA K-block in epilogue WGMMA."""
    print("test_lora_rank16")
    tokens, in_dim, out_dim, rank = 512, 4096, 4096, 16
    dtype = torch.bfloat16

    x, W, A, B = make_inputs(tokens, in_dim, out_dim, rank, dtype)
    expected = ref(x, W, A, B)
    actual   = lora_cutedsl(x, W, A, B)

    return check(actual, expected, f"tokens={tokens} in={in_dim} out={out_dim} rank={rank}")


def test_lora_rank64():
    """rank=64: four MMA K-blocks in epilogue WGMMA."""
    print("test_lora_rank64")
    tokens, in_dim, out_dim, rank = 2048, 4096, 4096, 64
    dtype = torch.bfloat16

    x, W, A, B = make_inputs(tokens, in_dim, out_dim, rank, dtype)
    expected = ref(x, W, A, B)
    actual   = lora_cutedsl(x, W, A, B)

    return check(actual, expected, f"tokens={tokens} in={in_dim} out={out_dim} rank={rank}")


def test_lora_configs():
    """All LORA_CONFIGS shapes from common.py."""
    print("test_lora_configs")
    results = []
    for tokens, in_dim, out_dim, rank, dtype in LORA_CONFIGS:
        x, W, A, B = make_inputs(tokens, in_dim, out_dim, rank, dtype)
        expected = ref(x, W, A, B)
        actual   = lora_cutedsl(x, W, A, B)
        name = f"tokens={tokens} in={in_dim} out={out_dim} rank={rank}"
        results.append(check(actual, expected, name))
    return all(results)


# ── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    tests = [
        test_pytorch_ref,
        test_lora_small,
        test_lora_rank16,
        test_lora_rank64,
        test_lora_configs,
    ]

    passed = 0
    failed = 0
    for t in tests:
        try:
            ok = t()
        except Exception as e:
            print(f"  [ERROR] {t.__name__}: {e}")
            import traceback; traceback.print_exc()
            ok = False
        if ok:
            passed += 1
        else:
            failed += 1
        print()

    print(f"{'='*50}")
    print(f"Results: {passed} passed, {failed} failed")
    if failed:
        print("See diagnostics above. Most likely cause: epilogue WGMMA layout mismatch.")
        print("Fix: replace autovec_copy with stmatrix R2S + layout-converting smem copy.")
