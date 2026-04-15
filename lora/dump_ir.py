"""
Dumps all IR representations of lora helion kernels for analysis.

Output structure:
  ir_dumps/triton/<key>.py    — helion-generated Triton code
  ir_dumps/ttir/<key>.ttir    — Triton IR (MLIR)
  ir_dumps/ttgir/<key>.ttgir  — Triton GPU IR
  ir_dumps/llir/<key>.ll      — LLVM IR / NVVM IR
  ir_dumps/ptx/<key>.ptx      — PTX assembly

"""

import importlib.util
import inspect
import os
import traceback

import torch
import triton
from triton.compiler import ASTSource
import helion
from helion import Config

from common import LORA_CONFIGS, config_key
from helion_common import VARIANTS

CACHE_DIR = os.path.join(os.path.dirname(__file__), "autotune_cache")
OUT_DIR   = os.path.join(os.path.dirname(__file__), "ir_dumps")

DTYPE_TO_TRITON = {
    torch.bfloat16: "*bf16",
    torch.float16:  "*fp16",
    torch.float32:  "*fp32",
}


def write_file(subdir, filename, content):
    path = os.path.join(OUT_DIR, subdir)
    os.makedirs(path, exist_ok=True)
    full_path = os.path.join(path, filename)
    mode = "wb" if isinstance(content, bytes) else "w"
    with open(full_path, mode) as f:
        f.write(content)
    print(f"  [{subdir:<5}]  {full_path}")


def _is_wrapper(k, v):
    if k.startswith("_") or not callable(v):
        return False
    try:
        return "_launcher" in inspect.signature(v).parameters
    except (ValueError, TypeError):
        return False


def dump_ir(kernel_fn, sample_args, config, key):
    # Triton code
    bound = helion.kernel(config=config, static_shapes=True)(kernel_fn).bind(sample_args)
    triton_code = bound.to_triton_code()
    write_file("triton", f"{key}.py", triton_code)

    # Load from file so @triton.jit can call inspect.getsourcelines
    triton_path = os.path.join(OUT_DIR, "triton", f"{key}.py")
    spec = importlib.util.spec_from_file_location(key, triton_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    jit_fn = next(v for k, v in vars(mod).items() if k.startswith("_helion_"))

    # Intercept the Python wrapper's _launcher to capture actual constexpr
    # values (e.g. _NUM_SM, _RDIM_SIZE_*) that helion passes at runtime.
    captured = {}
    def capturing_launcher(fn, grid, *args, **kwargs):
        captured["args"] = args

    wrapper_fn = next(v for k, v in vars(mod).items() if _is_wrapper(k, v))
    wrapper_fn(*sample_args, _launcher=capturing_launcher)

    dtype = sample_args[0].dtype
    ptr_type = DTYPE_TO_TRITON[dtype]
    signature = {}
    constexprs = {}
    for i, (name, _) in enumerate(inspect.signature(jit_fn.fn).parameters.items()):
        val = captured["args"][i]
        if isinstance(val, int):
            constexprs[name] = val
        else:
            signature[name] = ptr_type

    try:
        target = triton.runtime.driver.active.get_current_target()
        src = ASTSource(fn=jit_fn, signature=signature, constexprs=constexprs)
        compiled = triton.compile(src, target=target)

        if "ttir"  in compiled.asm: write_file("ttir",  f"{key}.ttir",  compiled.asm["ttir"])
        if "ttgir" in compiled.asm: write_file("ttgir", f"{key}.ttgir", compiled.asm["ttgir"])
        if "llir"  in compiled.asm: write_file("llir",  f"{key}.ll",    compiled.asm["llir"])
        if "ptx"   in compiled.asm: write_file("ptx",   f"{key}.ptx",   compiled.asm["ptx"])
    except Exception:
        traceback.print_exc()


def make_sample_args(tokens, in_dim, out_dim, rank, dtype):
    x  = torch.randn(tokens,  in_dim,  device="cuda", dtype=dtype)
    W  = torch.randn(out_dim, in_dim,  device="cuda", dtype=dtype)
    A  = torch.randn(out_dim, rank,    device="cuda", dtype=dtype)
    xA = (x @ torch.randn(in_dim, rank, device="cuda", dtype=dtype)).to(dtype)
    return x, W, A, xA


if __name__ == "__main__":
    for variant_name, kernel_fn in VARIANTS:
        for tokens, in_dim, out_dim, rank, dtype in LORA_CONFIGS:
            key = config_key(tokens, in_dim, out_dim, rank, dtype, variant=variant_name)
            cache_path = os.path.join(CACHE_DIR, f"{key}.json")
            if not os.path.exists(cache_path):
                print(f"skip {key} (no autotune cache)")
                continue
            print(f"\n{key}")
            dump_ir(kernel_fn, make_sample_args(tokens, in_dim, out_dim, rank, dtype),
                    Config.load(cache_path), key)

    print(f"\nAll outputs written to {OUT_DIR}")
