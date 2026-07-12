#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${BACKUP_DIR:?set BACKUP_DIR to one encrypted backup directory}"
: "${AGE_IDENTITY:?set AGE_IDENTITY to an offline age identity file}"
: "${RESTORE_WORK_DIR:?set RESTORE_WORK_DIR to a new empty temporary directory}"
script_dir="$(dirname -- "$0")"
script_dir="$(cd "$script_dir" && pwd)"
test ! -e "$RESTORE_WORK_DIR"
case "$RESTORE_WORK_DIR" in /var/lib/rancher/k3s|/var/lib/rancher/k3s/*) echo "refusing live K3s restore path" >&2; exit 1 ;; esac
mkdir -m 0700 "$RESTORE_WORK_DIR"
trap 'rm -rf "$RESTORE_WORK_DIR"' EXIT

BACKUP_DIR="$BACKUP_DIR" AGE_IDENTITY="$AGE_IDENTITY" "$script_dir/verify-k3s-backup.sh"
if [[ -f "$BACKUP_DIR/server-state.tar.gz.age" ]]; then
  age --decrypt --identity "$AGE_IDENTITY" -o "$RESTORE_WORK_DIR/state.tar.gz" "$BACKUP_DIR/server-state.tar.gz.age"
  mkdir "$RESTORE_WORK_DIR/unpacked"
  tar --extract --file "$RESTORE_WORK_DIR/state.tar.gz" --directory "$RESTORE_WORK_DIR/unpacked"
  test -d "$RESTORE_WORK_DIR/unpacked/server/db"
  test -s "$RESTORE_WORK_DIR/unpacked/server/token"
  test -s "$RESTORE_WORK_DIR/unpacked/server/tls/server-ca.crt"
  test -s "$RESTORE_WORK_DIR/unpacked/server/tls/server.crt"
  printf 'RESTORE_REHEARSAL server identity and datastore material verified under %s\n' "$RESTORE_WORK_DIR"
else
  age --decrypt --identity "$AGE_IDENTITY" -o "$RESTORE_WORK_DIR/state.tar.gz" "$BACKUP_DIR/agent-state.tar.gz.age"
  mkdir "$RESTORE_WORK_DIR/unpacked"
  tar --extract --file "$RESTORE_WORK_DIR/state.tar.gz" --directory "$RESTORE_WORK_DIR/unpacked"
  test -d "$RESTORE_WORK_DIR/unpacked/agent"
  printf 'RESTORE_REHEARSAL worker identity verified under %s\n' "$RESTORE_WORK_DIR"
fi
printf 'No live K3s path was modified; API and worker reconnect require the documented isolated hardware test.\n'
