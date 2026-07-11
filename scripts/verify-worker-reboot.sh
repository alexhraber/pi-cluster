#!/usr/bin/env bash
set -euo pipefail
: "${WORKER_SSH:?set WORKER_SSH to the Pi under test}"
: "${URL:?set URL to a workload reachable through another known path}"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
ssh "$WORKER_SSH" 'sudo systemctl reboot'
sleep "${WAIT_SECONDS:-60}"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
