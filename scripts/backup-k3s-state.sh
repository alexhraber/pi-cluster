#!/usr/bin/env bash
set -euo pipefail
umask 077
: "${BACKUP_DEST:?set BACKUP_DEST to encrypted storage outside Git}"
: "${AGE_RECIPIENT:?set AGE_RECIPIENT to the operator recovery recipient}"
test "$(id -u)" = 0
test ! -d "$BACKUP_DEST/.git"
case "$BACKUP_DEST" in /var/lib/rancher/k3s|/var/lib/rancher/k3s/*) echo "backup destination must not be live K3s state" >&2; exit 1 ;; esac
command -v age >/dev/null || { echo "age is required to encrypt backups" >&2; exit 1; }
stamp=$(date -u +%Y%m%dT%H%M%SZ)
out="$BACKUP_DEST/k3s-$stamp"
install -d -m 0700 "$out"
tmp=$(mktemp -d "$out/.plain.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
tar --xattrs --acls --numeric-owner -C /var/lib/rancher/k3s -czf "$tmp/server-state.tar.gz" server
age --encrypt --recipient "$AGE_RECIPIENT" --output "$out/server-state.tar.gz.age" "$tmp/server-state.tar.gz"
if [[ -n "${SOPS_FILE:-}" ]]; then
  test -f "$SOPS_FILE"
  install -m 0600 "$SOPS_FILE" "$out/cluster.yaml"
fi
if command -v k3s >/dev/null 2>&1; then
  k3s --version | head -n 1 > "$out/k3s-version"
else
  printf 'k3s-version=UNAVAILABLE\n' > "$out/k3s-version"
fi
cat > "$out/backup-manifest" <<EOF
format=1
created_at_utc=$stamp
source=/var/lib/rancher/k3s/server
server_archive=server-state.tar.gz.age
server_token=server/token
cluster_ca=server/tls/server-ca.crt
server_identity=server/tls/server.crt
restore_policy=isolated-only-until-operator-approval
EOF
sha256sum "$out"/* > "$out/SHA256SUMS"
chmod 0600 "$out"/*
echo "Created encrypted backup $out; run scripts/verify-k3s-backup.sh before considering it complete."
