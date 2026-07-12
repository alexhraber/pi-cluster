#!/usr/bin/env bash
set -euo pipefail

: "${EXPECTED_NODE:?set EXPECTED_NODE to pi-01, pi-02, pi-03, or pi-04}"
: "${MODE:=hardware-only}"

if [[ "$MODE" == "cluster" ]]; then
  : "${EXPECTED_API:?set EXPECTED_API to the stable Cube DNS name}"
elif [[ "$MODE" != "hardware-only" ]]; then
  printf 'MODE must be hardware-only or cluster\n' >&2
  exit 2
fi

pass=0
fail=0
check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS  %s\n' "$name"
    pass=$((pass + 1))
  else
    printf 'FAIL  %s\n' "$name" >&2
    fail=$((fail + 1))
  fi
}
route_check() { ip route get "$1" >/dev/null; }
ntp_check() { test "$(timedatectl show -p NTPSynchronized --value)" = yes; }
space_check() { test "$(df --output=avail -B1G / | tail -n 1 | tr -dc 0-9)" -ge 8; }
memory_check() { test "$(awk '/MemTotal:/ {print $2}' /proc/meminfo)" -ge 700000; }
thermal_check() { test "$(cat /sys/class/thermal/thermal_zone0/temp)" -lt 80000; }

check "ARM64 architecture" test "$(uname -m)" = aarch64
check "stable hostname" test "$(hostname -s)" = "$EXPECTED_NODE"
check "cgroup v2" test "$(stat -fc %T /sys/fs/cgroup)" = cgroup2fs
check "default route" sh -c 'ip route show default | grep -q .'
if [[ "$MODE" == "cluster" ]]; then
  api_ip="$(getent ahostsv4 "$EXPECTED_API" 2>/dev/null | awk 'NR == 1 { print $1 }')"
  check "Cube DNS resolution" test -n "$api_ip"
  if [[ -n "$api_ip" ]]; then
    check "route toward Cube" route_check "$api_ip"
  else
    printf 'FAIL  route toward Cube (DNS did not produce an IPv4 address)\n' >&2
    fail=$((fail + 1))
  fi
else
  printf 'INFO  hardware-only mode: Cube DNS/API checks deferred\n'
fi
check "SSH service active" systemctl is-active --quiet sshd.service
check "NTP synchronized" ntp_check
check "root filesystem mounted" mountpoint -q /
check "root filesystem space" space_check
check "minimum memory headroom" memory_check
check "no display manager" sh -c '! systemctl is-enabled --quiet display-manager.service 2>/dev/null'

if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
  check "thermal headroom" thermal_check
else
  printf 'WARN  thermal sensor unavailable; record manual cooling evidence\n'
fi

printf 'RESULT pass=%s fail=%s node=%s mode=%s\n' "$pass" "$fail" "$EXPECTED_NODE" "$MODE"
test "$fail" -eq 0
