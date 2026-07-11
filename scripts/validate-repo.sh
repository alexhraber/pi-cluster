#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

echo "== shell syntax =="
mapfile -t shell_files < <(find scripts -type f -name '*.sh' -print | sort)
test "${#shell_files[@]}" -gt 0
bash -n "${shell_files[@]}"
shellcheck "${shell_files[@]}"

echo "== YAML =="
yamllint -d relaxed .github kubernetes secrets

echo "== Kubernetes manifests =="
kubectl kustomize kubernetes/base >/dev/null

echo "== forbidden tracked runtime paths =="
if git ls-files | rg -n '(^|/)(backups?|runtime|kubeconfig[^/]*|.*\.kubeconfig|.*\.sqlite3?|.*\.db|.*\.token|.*\.crt)$'; then
  echo "tracked runtime or credential path found" >&2
  exit 1
fi

echo "== secret scan =="
gitleaks detect --source . --redact --no-banner --exit-code 1

echo "repository quality gates passed"
