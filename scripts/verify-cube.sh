#!/usr/bin/env bash
set -euo pipefail

evidence_dir="${EVIDENCE_DIR:-}"
if [[ -n "$evidence_dir" ]]; then install -d -m 0700 "$evidence_dir"; fi
kubectl cluster-info
kubectl get node cube -o wide
test "$(kubectl get node cube -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True
test "$(kubectl get node cube -o jsonpath='{.metadata.labels.kubernetes\.io/arch}')" = x86_64
kubectl get node cube -o jsonpath='{range .spec.taints[*]}{.key}={.effect}{"\n"}{end}' | grep -F 'node-role.kubernetes.io/control-plane=NoSchedule'
if kubectl get pods -A --field-selector spec.nodeName=cube --no-headers | awk '$1 != "kube-system" && NF { found = 1 } END { exit found }'; then :; else echo 'ordinary workload found on Cube' >&2; exit 1; fi
if [[ -n "$evidence_dir" ]]; then
  kubectl get node cube -o yaml > "$evidence_dir/cube.yaml"
  kubectl get pods -A -o wide > "$evidence_dir/cube-pods.txt"
  kubectl get events -A --sort-by=.lastTimestamp > "$evidence_dir/cube-events.txt"
fi
printf 'Cube control-plane verification passed\n'
