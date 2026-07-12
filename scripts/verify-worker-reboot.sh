#!/usr/bin/env bash
set -euo pipefail

: "${WORKER_SSH:?set WORKER_SSH to the Pi under test}"
: "${URL:?set URL to a workload reachable through another known path}"
: "${CONFIRM_WORKER_REBOOT:?set CONFIRM_WORKER_REBOOT=YES to run the destructive reboot drill}"
test "$CONFIRM_WORKER_REBOOT" = YES
evidence_dir="${EVIDENCE_DIR:?set EVIDENCE_DIR outside Git for test evidence}"
install -d -m 0700 "$evidence_dir"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
date -u +%Y-%m-%dT%H:%M:%SZ > "$evidence_dir/worker-online-before.txt"
ssh "$WORKER_SSH" 'sudo systemctl reboot'
sleep "${WAIT_SECONDS:-60}"
curl --fail --silent --show-error --connect-timeout 5 "$URL" >/dev/null
date -u +%Y-%m-%dT%H:%M:%SZ > "$evidence_dir/workload-reachable-after-worker-reboot.txt"
