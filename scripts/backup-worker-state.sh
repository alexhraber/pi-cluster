#!/usr/bin/env bash
set -euo pipefail
: "${BACKUP_DEST:?set BACKUP_DEST to encrypted storage outside Git}"
: "${AGE_RECIPIENT:?set AGE_RECIPIENT to the operator recovery recipient}"
test "$(id -u)" = 0
test ! -d "$BACKUP_DEST/.git"
command -v age >/dev/null || { echo "age is required to encrypt backups" >&2; exit 1; }
node=$(hostname -s)
stamp=$(date -u +%Y%m%dT%H%M%SZ)
out="$BACKUP_DEST/$node-$stamp"
install -d -m 0700 "$out"
tmp=$(mktemp -d "$out/.plain.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
tar --xattrs --acls --numeric-owner -C /var/lib/rancher/k3s -czf "$tmp/agent-state.tar.gz" agent
age --encrypt --recipient "$AGE_RECIPIENT" --output "$out/agent-state.tar.gz.age" "$tmp/agent-state.tar.gz"
sha256sum "$out"/* > "$out/SHA256SUMS"
echo "Created encrypted worker backup $out; copy it to a second protected location before considering it complete."
