# ada-ccv — charter

Ada bindings to Liu Liu's CCV (C-based Computer Vision library).
The Dark Factory's third binding in the open-source Ada line —
following ada-imgui and ada-stb.

## Why CCV first (and not OpenCV)

The community wishlist on ada-lang.io asks for OpenCV *or* CCV.
We picked CCV first for technical and pragmatic reasons:

- **OpenCV 4.x has removed its legacy C headers** — discovered
  by direct probe of `/opt/homebrew/include/opencv4/`. Modern
  OpenCV is C++-only at the public-API level. Binding it from
  Ada requires either writing or vendoring a cimgui-style C
  shim layer, which is a project in its own right (weeks of
  work before any Ada code lands).
- **CCV is genuinely pure-C at the public API.** Its `lib/`
  directory is `.c` files; `ccv.h` is a clean C header.
  GitHub identifies the wider repo as C++ because of the NNC
  (Neural Net Compiler) subsystem; the core CV library is C.
- **CCV is alive.** Last commit on `unstable` branch:
  the day before this charter (2026-05-26). 7,200+ stars.
  Liu Liu is actively maintaining at ~5 commits/day cadence.
- **BSD-3-Clause** upstream, clean to bind from.
- **Smaller scope than OpenCV.** ~159 functions in the core
  header, ~618 total symbols in the built archive (the
  archive bundles NNC too). v0.1 binds a useful subset; we
  don't have to commit to a 2000-function surface.
- **Modest install footprint.** Total clone: 315MB. Built
  `libccv.a`: 8.4MB. OpenCV's full install on Bill was 145MB
  in `/opt/homebrew/Cellar/opencv` + ~1.5GB of deps.

OpenCV is still on the binding-line roadmap — but as a
deliberate longer arc, not a fast-ship target.

## Non-goals

- Binding all 618 symbols of libccv.a. Many are NNC-subsystem
  internals; some are deep algorithms (DPM, ICF, TLD) that have
  big surface and narrow audience. v0.1 picks a useful subset.
- Binding the NNC (neural-net compiler) subsystem. That's an
  inference framework in its own right — separate Ada binding
  if there's demand. Not in scope for v0.1.
- Vendoring CCV's source into the Ada crate. Build it from
  upstream (`liuliu/ccv`); link the resulting `libccv.a`.
- Tracking CCV's `unstable` branch in lockstep. Pin to a
  specific commit at vendor time, document version.

## v0.1 scope

The bread-and-butter of an image-processing binding:

- **Lifecycle**: ccv_enable_default_cache, ccv_drain_cache
  (CCV uses a global LRU cache for derived images)
- **Image I/O** (`ccv_io.c`):
  - `ccv_read` — load PNG/JPG/BMP/RAW from path or memory
  - `ccv_write` — write to path
- **Basic processing** (`ccv_basic.c`):
  - `ccv_sobel`, `ccv_gradient`, `ccv_hog` (histogram of
    oriented gradients), `ccv_canny` (edge detection)
- **Image processing** (`ccv_image_processing.c`):
  - `ccv_color_transform` (color space conversion)
  - `ccv_saturation`, `ccv_contrast`, `ccv_brightness`
  - `ccv_blur`
- **Resampling** (`ccv_resample.c`):
  - `ccv_resample` (downsample / upsample / nearest /
    cubic / area)
  - `ccv_sample_down`, `ccv_sample_up`
- **Geometric transforms** (`ccv_transform.c`):
  - `ccv_decimal_slice`, `ccv_perspective_transform`,
    `ccv_flip`

That's roughly **40–50 functions** — comparable to
`Stb.Image`'s ~15 + room to grow. Bindable in days.

Future v0.2+ surface (queued, not in scope now):

- Feature detectors: SIFT, MSER, SWT, DAISY, ICF
- Classifiers: BBF, DPM, SCD
- Tracking: TLD
- Sparse coding, ConvNet (the pre-NNC neural net code)

## Build shape

- CCV is **not** in homebrew. We clone upstream + run
  `./configure && make` to produce `libccv.a`. Documented in
  the crate's build instructions.
- `ada_ccv.gpr` links against `libccv.a`. Linker switches
  propagate via `Linker_Options` (matches ada-imgui's pattern).
- macOS-specific: link against the Accelerate framework
  (CCV uses Apple's BLAS via Accelerate when available).
- Linux: link against system BLAS + pthread.
- Windows: TBD — CCV's makefile supports it but we'll
  document install path when someone actually asks.

## Repository layout (planned)

```
ada-ccv/
├── CHARTER.md           — this
├── README.md            — public-facing one-pager
├── THANKS.md            — dedication, matches ada-imgui/ada-stb
├── LICENSE              — MIT
├── alire.toml           — crate metadata
├── ada_ccv.gpr          — GPR build file
├── src/
│   ├── ccv.ads          — top-level package, lifecycle
│   ├── ccv-types.ads    — ccv_dense_matrix_t wrapper, Size, etc.
│   ├── ccv-io.ads       — image read/write
│   ├── ccv-basic.ads    — sobel/gradient/hog/canny
│   ├── ccv-image.ads    — colour/saturation/contrast/blur
│   ├── ccv-resample.ads — resize/sample_down/sample_up
│   ├── ccv-transform.ads — flip/slice/perspective
│   └── ccv-c.ads        — thin extern "C" surface (internal)
├── examples/
│   ├── grayscale/       — load PNG, color_transform to gray, write
│   └── edges/           — load PNG, canny edges, write result
└── tests/
    └── (gnattest harness, expands with the binding)
```

## What v0.1 doesn't yet do

- **GPU acceleration.** CCV has CUDA + Metal Performance Shader
  paths under flags. The v0.1 binding uses the CPU build only.
  GPU comes via either a build-time switch or a separate crate
  variant if asked.
- **Async / threaded.** CCV's API is largely synchronous;
  threading happens at libdispatch level (GCD on Apple). The
  Ada binding inherits this — single-threaded use is safe;
  multi-threaded callers should use one ccv-cache per task.
- **Pythonic ndarray ergonomics.** v0.1 surfaces CCV's native
  `ccv_dense_matrix_t` as an opaque pointer wrapped in an Ada
  record. v2 may add a slicing layer that looks like Ada's
  built-in 2D arrays.

## Threats to deliverability

- **CCV is on the `unstable` branch by default.** Pinning to
  a specific commit at vendor time is the mitigation; users
  who track upstream will eventually hit breaking changes and
  the binding will need updates. Plan for periodic re-bind
  cycles.
- **NNC subsystem in the archive.** libccv.a includes NNC
  whether we want it or not (Makefile dependency). This is
  fine for linkage — Ada users get NNC bonus capabilities
  even though we don't bind them — but increases the
  required link surface. Could revisit by stripping the
  NNC dependency in a custom Makefile patch.
- **No homebrew formula.** Users have to clone + build
  CCV themselves before our Ada binding's example runs.
  Documented in the build instructions; not a blocker but
  a friction point. v2 could submit a brew formula.

— Pawl
