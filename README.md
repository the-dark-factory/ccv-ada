# ccv-ada

Ada bindings to [Liu Liu's CCV](https://github.com/liuliu/ccv), a
modern C-based computer vision library.

Picked as the **first computer-vision binding** for The Dark
Factory's Ada line. The community wishlist asked for OpenCV or
CCV; CCV is the modern-pure-C, BSD-3, actively-maintained
option, and gets us into people's hands fastest.

Alire crate: **`df_ccv`**.

This is a **binding**, not a verified component: a careful,
hand-written Ada bridge to CCV's C — not a proof of it. v0.1
binds a curated, useful subset (cache lifecycle, image read/write,
colour-transform, flip, resample) behind idiomatic Ada packages
with an opaque `Matrix` type. See [CHARTER.md](CHARTER.md) for
the scope and roadmap.

## Status

Early (v0.1). The bound subset works end-to-end: load a PNG,
colour-transform / flip / resample it, write it back. A broader
surface (feature detectors, classifiers) is future work.

## Build & test

Requires GNAT + GPRbuild (e.g. via [Alire](https://alire.ada.dev/)),
plus a built `libccv.a` to link against. CCV is **not** vendored
into this crate and is **not** in Homebrew — clone and build it
once from upstream:

```sh
git clone https://github.com/liuliu/ccv ~/dev/ccv
cd ~/dev/ccv/lib
PKG_CONFIG_PATH=/opt/homebrew/lib/pkgconfig \
  CPPFLAGS="-I/opt/homebrew/include" \
  LDFLAGS="-L/opt/homebrew/lib" ./configure
make lib
```

CCV must be built with `HAVE_LIBPNG` + `HAVE_LIBJPEG` detected,
or PNG/JPG reads silently return NULL matrices. The reference
bind is pinned to CCV commit
`2d70fad6f4465e12419b2b834427799ff8a58325` ("Fix a loading
issue", unstable branch, 2026-05-27).

`df_ccv.gpr` finds `libccv.a` via the `CCV_LIB_DIR` environment
variable (defaults to `~/dev/ccv/lib`). Then:

```sh
alr build                    # compile the Ada binding (static library)
cd examples/transform && gprbuild -P transform.gpr && ./transform   # smoke
```

On macOS the Alire-shipped gcc needs the Xcode SDK; the GPR's
linker options carry `-Wl,-syslibroot,…` plus `-framework
Accelerate` (CCV's BLAS path) and `-lpng -ljpeg`.

## Regenerating the binding

Unlike the byte-reproducible `*_ada` bindings (e.g. `box2d-ada`,
whose `src/*.ads` is pure `-fdump-ada-spec` output and where
`git diff src/` after a regen is the correctness test),
**`ccv-ada`'s `src/` is hand-authored** — an idiomatic wrapper
over a curated subset, not machine output. So there is no
byte-faithful reproducer of `src/`, and `scripts/gen.sh` does
**not** overwrite it.

What `scripts/gen.sh` does provide is the deterministic way to
re-derive CCV's **full C surface** as Ada specs — a reference to
hand-adapt from when CCV is re-vendored or the bound subset grows:

```sh
./scripts/gen.sh
```

It runs `gcc -fdump-ada-spec` over `ccv.h` (via Homebrew
**gcc-15** with an explicit `-isysroot`, because the Alire gcc
cannot fdump CCV's `<stdio.h>`-pulling header against the macOS 26
SDK — `'FILE' does not name a type`), then keeps exactly the
transitive `with`-closure from the CCV project-header roots
(`ccv_h`, `ccv_nnc_tfb_h`) and drops the system-header spillover.
Output lands in `generated/` (git-ignored, like a build artifact),
leaving the hand-written `src/` untouched. Override the compiler
with `GEN_GCC=` and the CCV checkout with `CCV_SRC=`.

## Layout

| Path | What |
|------|------|
| `src/ccv*.ads`, `src/ccv*.adb` | **hand-authored** idiomatic binding (opaque `Matrix`, `Ccv` / `Ccv.Image` / `Ccv.Io` + private `Ccv.C` imports) |
| `examples/transform/` | load → transform → write smoke demo + C reference |
| `scripts/gen.sh` | re-derives CCV's full C surface into `generated/` as a hand-binding reference (not a `src/` reproducer) |
| `generated/` | machine output of `gen.sh` (git-ignored) |
| `df_ccv.gpr` | GPR; links `libccv.a` via `CCV_LIB_DIR` |
| (external) `~/dev/ccv` | upstream CCV clone — built, not vendored (CHARTER non-goal) |

## License

MIT — for the Ada binding layer. CCV upstream is BSD-3-Clause.

## Thanks

Dedicated to the Ada community who have answered countless
questions, corrected countless mistakes, and saved countless
hours of head-scratching over the decades. See
[THANKS.md](THANKS.md).
