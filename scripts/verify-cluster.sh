#!/usr/bin/env bash
set -euo pipefail

evidence_dir="${EVIDENCE_DIR:-}"
if [[ -n "$evidence_dir" ]]; then install -d -m 0700 "$evidence_dir"; fi
kubectl cluster-info
kubectl wait --for=condition=Ready node/pi-01 node/pi-02 node/pi-03 node/pi-04 --timeout="${NODE_READY_TIMEOUT:-120s}"
kubectl get nodes -o wide
test "$(kubectl get node cube -o jsonpath='{.metadata.labels.kubernetes\\.io/arch}')" = x86_64
for n in pi-01 pi-02 pi-03 pi-04; do test "$(kubectl get node "$n" -o jsonpath='{.metadata.labels.kubernetes\\.io/arch}')" = arm64; done
kubectl get node cube -o jsonpath='{range .spec.taints[*]}{.key}={.effect}{"\\n"}{end}' | grep -F 'node-role.kubernetes.io/control-plane=NoSchedule'
if kubectl get pods -A --field-selector spec.nodeName=cube --no-headers | awk '$1 != "kube-system" && NF { found = 1 } END { exit found }'; then :; else echo 'ordinary workload found on Cube' >&2; exit 1; fi
kubectl get pods -n kube-system -o wide -l k8s-app=kube-flannel
kubectl get events --all-namespaces --sort-by=.lastTimestamp | tail -80
if [[ -n "$evidence_dir" ]]; then
  kubectl get nodes -o json > "$evidence_dir/nodes.json"
  kubectl get pods -A -o wide > "$evidence_dir/pods.txt"
  kubectl get events -A --sort-by=.lastTimestamp > "$evidence_dir/events.txt"
fi
