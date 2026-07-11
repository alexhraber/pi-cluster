#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Ready node/pi-01 node/pi-02 node/pi-03 node/pi-04 --timeout=30s
kubectl get nodes -o wide
test "$(kubectl get node cube -o jsonpath='{.metadata.labels.kubernetes\\.io/arch}')" = x86_64
for n in pi-01 pi-02 pi-03 pi-04; do test "$(kubectl get node "$n" -o jsonpath='{.metadata.labels.kubernetes\\.io/arch}')" = arm64; done
kubectl get node cube -o jsonpath='{range .spec.taints[*]}{.key}={.effect}{"\\n"}{end}' | grep -F 'node-role.kubernetes.io/control-plane=NoSchedule'
