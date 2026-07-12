#!/usr/bin/env bash
set -euo pipefail

: "${NODE:?set NODE to pi-01, pi-02, pi-03, or pi-04}"
: "${IMAGE:?set IMAGE to the exact compressed image path}"
: "${MEDIA_BY_ID:?set MEDIA_BY_ID to /dev/disk/by-id/<device>}"
case "$NODE" in pi-01|pi-02|pi-03|pi-04) ;; *) printf 'invalid NODE: %s\n' "$NODE" >&2; exit 2 ;; esac
case "$IMAGE" in *.img.zst) ;; *) printf 'IMAGE must be a .img.zst file\n' >&2; exit 2 ;; esac
case "$MEDIA_BY_ID" in /dev/disk/by-id/*) ;; *) printf 'MEDIA_BY_ID must use /dev/disk/by-id\n' >&2; exit 2 ;; esac
test -f "$IMAGE" || { printf 'image not found: %s\n' "$IMAGE" >&2; exit 1; }
test -e "$MEDIA_BY_ID" || { printf 'media path not found: %s\n' "$MEDIA_BY_ID" >&2; exit 1; }
zstdcat "$IMAGE" >/dev/null
actual_sha256="$(sha256sum "$IMAGE" | awk '{print $1}')"
if [[ -n "${EXPECTED_SHA256:-}" && "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
  printf 'sha256 mismatch: expected %s, got %s\n' "$EXPECTED_SHA256" "$actual_sha256" >&2; exit 1
fi
resolved_media="$(readlink -f "$MEDIA_BY_ID")"
printf 'NODE=%s\nIMAGE=%s\nSHA256=%s\nMEDIA_BY_ID=%s\nRESOLVED_MEDIA=%s\n' "$NODE" "$IMAGE" "$actual_sha256" "$MEDIA_BY_ID" "$resolved_media"
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,MOUNTPOINTS "$resolved_media"
printf 'DRY_RUN no device was written\n'
printf 'DRY_RUN zstdcat %q | sudo dd of=%q bs=4M conv=fsync status=progress\n' "$IMAGE" "$MEDIA_BY_ID"
