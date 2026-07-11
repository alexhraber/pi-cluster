#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Ready node/pi-01 node/pi-02 node/pi-03 node/pi-04 --timeout=120s
kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -80
kubectl get nodes -o wide
