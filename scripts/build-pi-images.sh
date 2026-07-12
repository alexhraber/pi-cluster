#!/usr/bin/env bash
set -euo pipefail

usage() { printf 'Usage: %s [pi-01|pi-02|pi-03|pi-04 ...]\n' "$0"; }
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi
if (( $# )); then
  nodes=("$@")
else
  nodes=(pi-01 pi-02 pi-03 pi-04)
fi
for node in "${nodes[@]}"; do
  case "$node" in pi-01|pi-02|pi-03|pi-04) ;; *) printf 'unsupported node: %s\n' "$node" >&2; usage >&2; exit 2 ;; esac
done
command -v nix >/dev/null || { printf 'nix is required\n' >&2; exit 127; }

for node in "${nodes[@]}"; do
  attribute=".\#nixosConfigurations.${node}-image.config.system.build.sdImage"
  printf 'BUILD node=%s attribute=%s\n' "$node" "$attribute"
  image_path="$(nix --extra-experimental-features 'nix-command flakes' build --no-link --no-update-lock-file --print-out-paths "$attribute")"
  mapfile -t images < <(find "$image_path/sd-image" -maxdepth 1 -type f -name '*.img*' -print | sort)
  test "${#images[@]}" -eq 1 || { printf 'expected one image under %s/sd-image\n' "$image_path" >&2; exit 1; }
  image="${images[0]}"
  case "$image" in *.img.zst) zstdcat "$image" >/dev/null ;; *) printf 'unsupported image format: %s\n' "$image" >&2; exit 1 ;; esac
  sha256="$(sha256sum "$image" | awk '{print $1}')"
  printf 'IMAGE node=%s artifact=%s sha256=%s status=verified\n' "$node" "$image" "$sha256"
done
