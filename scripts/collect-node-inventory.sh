#!/usr/bin/env bash
set -euo pipefail

: "${EXPECTED_NODE:?set EXPECTED_NODE to cube or pi-01 through pi-04}"
: "${INSPECTOR:=UNSET}"

first_readable() {
  local path
  for path in "$@"; do
    if [[ -r "$path" ]]; then
      tr '\0' '\n' < "$path" | sed '/^$/d' | head -n 1
      return 0
    fi
  done
  printf 'TBD\n'
}

printf 'inventory_version=1\n'
printf 'collected_at_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'inspector=%s\n' "$INSPECTOR"
printf 'expected_node=%s\n' "$EXPECTED_NODE"
printf 'hostname=%s\n' "$(hostname -s)"
printf 'architecture=%s\n' "$(uname -m)"
printf 'kernel=%s\n' "$(uname -r)"
printf 'model=%s\n' "$(first_readable /sys/firmware/devicetree/base/model /sys/devices/virtual/dmi/id/product_name)"
printf 'board_serial=%s\n' "$(first_readable /sys/firmware/devicetree/base/serial /sys/devices/virtual/dmi/id/product_serial)"
printf 'memory_kib=%s\n' "$(awk '/MemTotal:/ { print $2; exit }' /proc/meminfo)"
printf 'cgroup_mode=%s\n' "$(stat -fc %T /sys/fs/cgroup)"
if command -v findmnt >/dev/null 2>&1; then
  printf 'root_filesystem=%s\n' "$(findmnt -n -o SOURCE,FSTYPE,TARGET / | tr '\n' ' ')"
else
  printf 'root_filesystem=TBD\n'
fi
printf 'root_free_bytes=%s\n' "$(df --output=avail -B1 / | tail -n 1 | tr -dc '0-9')"

printf 'network_mac_addresses=\n'
for address in /sys/class/net/*/address; do
  interface="${address%/address}"
  interface="${interface##*/}"
  [[ "$interface" == "lo" ]] || printf '  %s=%s\n' "$interface" "$(tr -d '\n' < "$address")"
done

if command -v ip >/dev/null 2>&1; then
  printf 'network_ipv4_addresses=\n'
  ip -o -4 addr show scope global | awk '{ print "  " $2 "=" $4 }'
  printf 'network_default_routes=\n'
  ip -4 route show default | sed 's/^/  /'
fi

printf 'block_devices=\n'
if command -v lsblk >/dev/null 2>&1; then
  lsblk -dn -o NAME,SIZE,MODEL,SERIAL,TRAN | sed 's/^/  /'
else
  printf '  TBD\n'
fi

printf 'firmware=\n'
if command -v vcgencmd >/dev/null 2>&1; then
  printf '  version=%s\n' "$(vcgencmd version | tr '\n' ' ')"
else
  printf '  version=TBD\n'
fi

printf 'temperature_c=\n'
if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
  awk '{ printf "%.1f\n", $1 / 1000 }' /sys/class/thermal/thermal_zone0/temp
else
  printf 'TBD\n'
fi

printf 'virtualization=%s\n' "$(systemd-detect-virt 2>/dev/null || printf 'TBD')"
printf 'notes=Review output against physical board, power, cooling, switch-port, reservation, and media evidence before recording facts in Git.\n'
