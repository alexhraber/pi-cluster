#!/usr/bin/env bash
set -euo pipefail

: "${1:?usage: collect-node-inventory.sh pi-01|pi-02|pi-03|pi-04}"
case "$1" in pi-01|pi-02|pi-03|pi-04) ;; *) printf 'invalid node: %s\n' "$1" >&2; exit 2 ;; esac
printf 'node=%s\n' "$1"
printf 'timestamp=%s\n' "$(date --iso-8601=seconds)"
printf 'hostname=%s\n' "$(hostname --fqdn)"
printf 'architecture=%s\n' "$(uname -m)"
printf 'kernel=%s\n' "$(uname -r)"
printf 'memory_kib=%s\n' "$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
printf 'root_filesystem=%s\n' "$(findmnt -no SOURCE,FSTYPE,SIZE,AVAIL /)"
printf 'mac_addresses=\n'
ip -brief link | awk '$1 != "lo" { print }'
printf 'storage=\n'
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,MOUNTPOINTS
