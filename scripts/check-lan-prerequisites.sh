#!/usr/bin/env bash
set -euo pipefail

: "${CUBE_IP:?set CUBE_IP to the verified Cube address}"
: "${PI_IPS:?set PI_IPS to four comma-separated verified Pi addresses}"
: "${CUBE_HOST:=cube.lan}"
: "${PI_HOSTS:=pi-01.lan,pi-02.lan,pi-03.lan,pi-04.lan}"
: "${MODE:=preflight}"

case "$MODE" in
  preflight|api) ;;
  *) printf 'MODE must be preflight or api\n' >&2; exit 2 ;;
esac

IFS=, read -r -a pi_ips <<< "$PI_IPS"
IFS=, read -r -a pi_hosts <<< "$PI_HOSTS"
[[ "${#pi_ips[@]}" -eq 4 ]] || { printf 'PI_IPS must contain four addresses\n' >&2; exit 2; }
[[ "${#pi_hosts[@]}" -eq 4 ]] || { printf 'PI_HOSTS must contain four names\n' >&2; exit 2; }

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

resolve_exact() {
  local host="$1" expected="$2"
  getent ahostsv4 "$host" | awk '{ print $1 }' | sort -u | grep -Fxq "$expected"
}

route_exists() { ip route get "$1" >/dev/null 2>&1; }
ping_host() { ping -c 1 -W 1 "$1" >/dev/null 2>&1; }
# The single quotes are intentional: the inner bash expands its positional args.
# shellcheck disable=SC2016
tcp_api_check() { timeout 3 bash -c 'exec 3<>"/dev/tcp/$1/6443"' _ "$1"; }

check "Cube DNS matches verified address" resolve_exact "$CUBE_HOST" "$CUBE_IP"
check "route to Cube" route_exists "$CUBE_IP"
check "Cube LAN reachability" ping_host "$CUBE_IP"

for index in 0 1 2 3; do
  check "${pi_hosts[$index]} DNS matches verified address" resolve_exact "${pi_hosts[$index]}" "${pi_ips[$index]}"
  check "route to ${pi_hosts[$index]}" route_exists "${pi_ips[$index]}"
  check "${pi_hosts[$index]} LAN reachability" ping_host "${pi_ips[$index]}"
done

if command -v timedatectl >/dev/null 2>&1; then
  check "admin host NTP synchronized" test "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = yes
else
  printf 'WARN  timedatectl unavailable; verify NTP on every node separately\n'
fi

if [[ "$MODE" == "api" ]]; then
  check "Cube K3s API TCP 6443" tcp_api_check "$CUBE_IP"
else
  printf 'INFO  preflight mode: Cube API port check deferred\n'
fi

printf 'MANUAL  verify DHCP reservations, subnet availability, switch paths, and firewall rules\n'
printf 'MANUAL  verify TCP 6443 from every node to Cube\n'
printf 'MANUAL  verify UDP 8472 between every node pair for Flannel VXLAN\n'
printf 'MANUAL  do not expose UDP 8472 beyond the trusted LAN\n'
printf 'RESULT pass=%s fail=%s mode=%s\n' "$pass" "$fail" "$MODE"
test "$fail" -eq 0
