#!/usr/bin/env bash
set -euo pipefail

: "${EXPECTED_NODE:?set EXPECTED_NODE to pi-01, pi-02, pi-03, or pi-04}"
: "${EXPECTED_API:?set EXPECTED_API to the stable Cube DNS name}"

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

check "ARM64 architecture" test "$(uname -m)" = aarch64
check "stable hostname" test "$(hostname -s)" = "$EXPECTED_NODE"
check "cgroup v2" test "$(stat -fc %T /sys/fs/cgroup)" = cgroup2fs
check "default route" sh -c 'ip route show default | grep -q .'
api_ip="$(getent ahostsv4 "$EXPECTED_API" 2>/dev/null | awk 'NR == 1 { print $1 }')"
check "Cube DNS resolution" test -n "$api_ip"
if [[ -n "$api_ip" ]]; then
  check "route toward Cube" sh -c 'ip route get "$1" >/dev/null' sh "$api_ip"
else
  printf 'FAIL  route toward Cube (DNS did not produce an IPv4 address)\n' >&2
  fail=$((fail + 1))
fi
check "SSH service active" systemctl is-active --quiet sshd.service
check "NTP synchronized" sh -c 'test "$(timedatectl show -p NTPSynchronized --value)" = yes'
check "root filesystem mounted" mountpoint -q /
check "root filesystem space" sh -c 'test "$(df --output=avail -B1G / | tail -n 1 | tr -dc 0-9)" -ge 8'
check "minimum memory headroom" sh -c 'test "$(awk "/MemTotal:/ {print \$2}" /proc/meminfo)" -ge 700000'
check "no display manager" sh -c '! systemctl is-enabled --quiet display-manager.service 2>/dev/null'

if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
  check "thermal headroom" sh -c 'test "$(cat /sys/class/thermal/thermal_zone0/temp)" -lt 80000'
else
  printf 'WARN  thermal sensor unavailable; record manual cooling evidence\n'
fi

printf 'RESULT pass=%s fail=%s node=%s api=%s\n' "$pass" "$fail" "$EXPECTED_NODE" "$EXPECTED_API"
test "$fail" -eq 0
