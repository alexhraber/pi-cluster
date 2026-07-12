# Verification contract

The scripts are intentionally small wrappers around `kubectl`, `ssh`, and
`systemctl`. They are checks to run against the real cluster, not simulators.

Run `scripts/verify-cluster.sh` for worker connectivity, architecture labels,
and Cube taint. Run `scripts/verify-offline.sh` with a real workload and a
known Pi address during a planned Cube shutdown. Run
`scripts/verify-reconnect.sh` after Cube boots. Use
`scripts/verify-worker-reboot.sh` to test a selected worker during an outage.

The outage and reboot scripts require explicit confirmation and an evidence
directory outside Git before they can power off Cube or reboot a worker.

The result must record timestamp, K3s version, node kernel, CNI mode, DNS
configuration, workload name, and exact failure/recovery times.
`verify-cluster.sh` can write a sanitized node/pod/event evidence bundle when
EVIDENCE_DIR is provided.
