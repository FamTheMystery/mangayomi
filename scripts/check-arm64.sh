#!/usr/bin/env bash
set -euo pipefail

binary="${1:-build/linux/arm64/release/bundle/mangayomi}"
[[ -f "$binary" ]] || { printf 'ERROR: missing file: %s\n' "$binary" >&2; exit 1; }

file_output="$(file -Lb "$binary")"
printf '%s: %s\n' "$binary" "$file_output"
grep -Eqi 'ELF 64-bit.*(ARM aarch64|AArch64)' <<< "$file_output" || {
  printf 'ERROR: %s is not an AArch64 ELF binary.\n' "$binary" >&2
  exit 1
}

bundle="$(dirname -- "$binary")"
while IFS= read -r native_file; do
  native_output="$(file -Lb "$native_file")"
  grep -Eqi 'ELF 64-bit.*(ARM aarch64|AArch64)' <<< "$native_output" || {
    printf 'ERROR: non-AArch64 native library: %s (%s)\n' "$native_file" "$native_output" >&2
    exit 1
  }
done < <(find "$bundle" -type f \( -name '*.so' -o -name '*.so.*' \) -print)

printf 'ARM64 verification passed for %s\n' "$bundle"