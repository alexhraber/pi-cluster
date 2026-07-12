#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${BACKUP_DIR:?set BACKUP_DIR to one encrypted backup directory}"
: "${AGE_IDENTITY:?set AGE_IDENTITY to an offline age identity file}"
test -d "$BACKUP_DIR" && test ! -d "$BACKUP_DIR/.git"
test -f "$BACKUP_DIR/SHA256SUMS"
test -f "$BACKUP_DIR/backup-manifest"
test -f "$BACKUP_DIR/server-state.tar.gz.age" || test -f "$BACKUP_DIR/agent-state.tar.gz.age"
test -f "$AGE_IDENTITY"
command -v age >/dev/null || { echo "age is required" >&2; exit 1; }

(cd "$BACKUP_DIR" && sha256sum --check SHA256SUMS)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
if [[ -f "$BACKUP_DIR/server-state.tar.gz.age" ]]; then
  age --decrypt --identity "$AGE_IDENTITY" -o "$work/state.tar.gz" "$BACKUP_DIR/server-state.tar.gz.age"
  tar -tzf "$work/state.tar.gz" > "$work/contents"
  grep -Eq '^server/db(/|$)' "$work/contents" || { echo "missing server datastore" >&2; exit 1; }
  for required in server/token server/tls/server-ca.crt server/tls/server.crt; do
    grep -Fxq "$required" "$work/contents" || { echo "missing server recovery path: $required" >&2; exit 1; }
  done
  kind=server
else
  age --decrypt --identity "$AGE_IDENTITY" -o "$work/state.tar.gz" "$BACKUP_DIR/agent-state.tar.gz.age"
  tar -tzf "$work/state.tar.gz" > "$work/contents"
  grep -Eq '^agent/(client-kubelet|kubelet)' "$work/contents" || { echo "missing worker identity material" >&2; exit 1; }
  kind=worker
fi
printf 'VERIFIED kind=%s backup=%s\n' "$kind" "$BACKUP_DIR"
