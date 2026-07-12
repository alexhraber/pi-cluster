#!/usr/bin/env bash
set -euo pipefail
umask 077
: "${BACKUP_DEST:?set BACKUP_DEST to encrypted storage outside Git}"
: "${AGE_RECIPIENT:?set AGE_RECIPIENT to the operator recovery recipient}"
: "${EXPECTED_NODE:?set EXPECTED_NODE to pi-01, pi-02, pi-03, or pi-04}"
test "$(id -u)" = 0
test ! -d "$BACKUP_DEST/.git"
case "$BACKUP_DEST" in /var/lib/rancher/k3s|/var/lib/rancher/k3s/*) echo "backup destination must not be live K3s state" >&2; exit 1 ;; esac
case "$EXPECTED_NODE" in pi-01|pi-02|pi-03|pi-04) ;; *) echo "invalid EXPECTED_NODE" >&2; exit 2 ;; esac
test "$(hostname -s)" = "$EXPECTED_NODE"
command -v age >/dev/null || { echo "age is required to encrypt backups" >&2; exit 1; }
node=$(hostname -s)
stamp=$(date -u +%Y%m%dT%H%M%SZ)
out="$BACKUP_DEST/$node-$stamp"
install -d -m 0700 "$out"
tmp=$(mktemp -d "$out/.plain.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
tar --xattrs --acls --numeric-owner -C /var/lib/rancher/k3s -czf "$tmp/agent-state.tar.gz" agent
age --encrypt --recipient "$AGE_RECIPIENT" --output "$out/agent-state.tar.gz.age" "$tmp/agent-state.tar.gz"
cat > "$out/backup-manifest" <<EOF
format=1
created_at_utc=$stamp
node=$EXPECTED_NODE
source=/var/lib/rancher/k3s/agent
agent_archive=agent-state.tar.gz.age
agent_identity=agent/client-kubelet.crt
restore_policy=isolated-only-until-operator-approval
EOF
sha256sum "$out"/* > "$out/SHA256SUMS"
chmod 0600 "$out"/*
echo "Created encrypted worker backup $out; run scripts/verify-k3s-backup.sh before considering it complete."
