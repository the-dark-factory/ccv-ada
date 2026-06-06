#!/usr/bin/env bash
#
# gen.sh — dump CCV's full C surface as Ada specs, deterministically, as a
# re-binding REFERENCE for the hand-authored binding in src/.
#
# STATUS (2026-06-06): this is a reference generator, NOT a byte-faithful
# reproducer of src/ (cf. box2d-ada/scripts/gen.sh, which IS byte-faithful and
# whose `git diff src/`-is-empty test applies).
#
# The crucial difference: ccv-ada's src/ is a HAND-AUTHORED idiomatic wrapper,
# not machine output. CHARTER.md scopes v0.1 to a curated ~12-function subset
# (cache lifecycle, read/write, colour-transform, flip, resample) surfaced as
# private Ccv.C imports behind opaque-typed public packages (Ccv, Ccv.Image,
# Ccv.Io) — see the doc-comment moat in those files. `-fdump-ada-spec` over the
# whole of ccv.h emits ~170 raw subprograms in a single path-named package
# (ccv_h) with C_Pass_By_Copy record types and stdint-typedef withs; that is NOT
# the shape of src/, and running this does NOT and MUST NOT overwrite src/.
#
# What this script IS: the deterministic way to (re)derive the complete CCV C
# surface as Ada, so that when CCV is re-vendored (or the v0.x subset grows) the
# author has a current, machine-true reference for signatures, enum values and
# record layouts to hand-adapt from — instead of reading ccv.h by eye. Output
# goes to generated/ (git-ignored, like a build artifact), leaving src/ — the
# moat — untouched.
#
# Why a separate generator compiler (gcc-15, not the Alire gcc): ccv.h pulls
# <stdio.h> (for getline et al.). The Alire-shipped GCC is built for an older
# darwin and its pre-fixed <stdio.h> no longer matches the macOS 26 SDK ('FILE'
# does not name a type), so it cannot fdump this header. A current-SDK-matched
# gcc (Homebrew gcc-15 by default) is used purely for the fdump step; the Ada in
# src/ still builds with the ordinary Alire toolchain (`alr build`). The default
# `MacOSX.sdk` symlink can be stale, so an explicit -isysroot to a real SDK is
# passed.
#
# Steps:
#   1. gcc-15 -fdump-ada-spec over ccv.h (which #includes nnc/ccv_nnc_tfb.h).
#   2. Keep the transitive with-closure from the CCV project-header roots
#      (ccv_h, ccv_nnc_tfb_h); drop the system-header spillover (stdio, pthread
#      types, the stdint typedef chain, …). The kept system specs are only the
#      stdint typedefs the surface actually names.
#
# Requirements: a current-SDK gcc with -fdump-ada-spec (override with GEN_GCC),
# and a CCV checkout (default ~/dev/ccv; override with CCV_SRC). CCV is NOT
# vendored into this crate (CHARTER non-goal): clone it once with
#   git clone https://github.com/liuliu/ccv ~/dev/ccv
# Pinned reference SHA at last bind: 2d70fad6f4465e12419b2b834427799ff8a58325
# ("Fix a loading issue", liuliu/ccv unstable, 2026-05-27).
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ccv_src="${CCV_SRC:-$HOME/dev/ccv}"
hdr="$ccv_src/lib/ccv.h"
[ -f "$hdr" ] || { echo "error: $hdr not found — clone CCV (git clone https://github.com/liuliu/ccv ~/dev/ccv) or set CCV_SRC" >&2; exit 1; }

gen_gcc="${GEN_GCC:-/opt/homebrew/bin/gcc-15}"
command -v "$gen_gcc" >/dev/null 2>&1 || gen_gcc="gcc-15"
command -v "$gen_gcc" >/dev/null 2>&1 || {
  echo "error: no fdump-capable gcc ($gen_gcc). Install one (brew install gcc) or set GEN_GCC." >&2; exit 1; }

# Explicit SDK sysroot: the default MacOSX.sdk symlink may be stale; pick a real
# one. gcc-15 needs a current SDK to resolve <stdio.h> & co. against macOS 26.
sysroot_flag=()
for sdk in /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk \
           /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk; do
  [ -d "$sdk" ] && { sysroot_flag=(-isysroot "$sdk"); break; }
done

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
echo ">> fdump-ada-spec over ccv.h  (gcc: $gen_gcc)"
# -c compiles the header as a TU; fdump emits the specs even on non-zero return.
( cd "$work" && "$gen_gcc" -c -fdump-ada-spec -I "$ccv_src/lib" "${sysroot_flag[@]}" "$hdr" ) 2>/dev/null || true

cd "$work"
compgen -G "ccv_h.ads" >/dev/null || { echo "error: fdump produced no ccv_h.ads" >&2; exit 1; }

# Transitive with-closure from the CCV project-header roots. Follow `with X;`
# only to generated specs present here (lowercase, single-unit names); runtime
# units (Interfaces.C, System, …) have dots or no local file and drop out, as do
# the per-subprogram aspect clauses (with Convention => …, with Import => …)
# which awk maps to nonexistent convention.ads/import.ads.
keep=()
for f in ccv_h.ads ccv_nnc_tfb_h.ads; do [ -f "$f" ] && keep+=("$f"); done
in_keep(){ local x="$1" k; for k in "${keep[@]}"; do [ "$k" = "$x" ] && return 0; done; return 1; }
changed=1
while [ "$changed" = 1 ]; do changed=0
  for f in "${keep[@]}"; do
    while IFS= read -r c; do [ -n "$c" ] || continue
      if [ -f "$c" ] && ! in_keep "$c"; then keep+=("$c"); changed=1; fi
    done < <(awk 'tolower($1)=="with"{w=$2;sub(/;.*/,"",w);print tolower(w)".ads"}' "$f")
  done
done

# Emit to generated/ — a git-ignored reference tree, NEVER src/ (the moat).
dest="$repo_root/generated"
mkdir -p "$dest"
rm -f "$dest"/*.ads
for f in "${keep[@]}"; do cp "$f" "$dest/"; done

all_n=$(ls -1 *.ads | wc -l | tr -d ' ')
echo ">> kept ${#keep[@]} of $all_n generated specs (pruned $((all_n-${#keep[@]})) system-closure spillovers) into generated/:"
printf '%s\n' "${keep[@]}" | sort | sed 's/^/   /'
echo ">> src/ is the hand-authored binding and was NOT touched; generated/ is a re-bind reference only."
