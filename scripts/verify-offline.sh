#!/usr/bin/env bash
set -euo pipefail
: "${URL:?set URL to a selected Pi-reachable workload endpoint}"
: "${CUBE_SSH:?set CUBE_SSH to the Cube SSH target}"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
ssh "$CUBE_SSH" 'sudo systemctl poweroff'
trap 'echo "Cube is powered off; boot it manually after this test"' EXIT
sleep "${WAIT_SECONDS:-20}"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
