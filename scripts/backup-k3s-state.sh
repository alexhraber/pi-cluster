#!/usr/bin/env bash
set -euo pipefail
: "${BACKUP_DEST:?set BACKUP_DEST to encrypted storage outside Git}"
test "$(id -u)" = 0
test ! -d "$BACKUP_DEST/.git"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
out="$BACKUP_DEST/k3s-$stamp"
install -d -m 0700 "$out"
tar --xattrs --acls --numeric-owner -C /var/lib/rancher/k3s -czf "$out/server-state.tar.gz" server
cp -a /run/secrets/k3s-server-token "$out/server-token"
chmod 0600 "$out/server-token"
sha256sum "$out/server-state.tar.gz" "$out/server-token" > "$out/SHA256SUMS"
echo "Created $out; encrypt and transfer it before considering the backup complete."
