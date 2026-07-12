#!/usr/bin/env bash
set -euo pipefail

: "${URL:?set URL to a selected Pi-reachable workload endpoint}"
: "${CUBE_SSH:?set CUBE_SSH to the Cube SSH target}"
: "${CONFIRM_CUBE_POWEROFF:?set CONFIRM_CUBE_POWEROFF=YES to run the destructive outage drill}"
test "$CONFIRM_CUBE_POWEROFF" = YES
evidence_dir="${EVIDENCE_DIR:?set EVIDENCE_DIR outside Git for test evidence}"
install -d -m 0700 "$evidence_dir"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
date -u +%Y-%m-%dT%H:%M:%SZ > "$evidence_dir/cube-online-before.txt"
ssh "$CUBE_SSH" 'sudo systemctl poweroff'
trap 'echo "Cube is powered off; boot it manually after this test"' EXIT
sleep "${WAIT_SECONDS:-20}"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
date -u +%Y-%m-%dT%H:%M:%SZ > "$evidence_dir/workload-reachable-cube-off.txt"
