# Git and runtime state boundary

## Git contains

Desired NixOS and K3s configuration, pinned versions and lockfiles,
workload manifests, scripts, encrypted secret declarations, architecture,
backup, and recovery procedures.

## Git does not contain

`/var/lib/rancher/k3s`, live SQLite or etcd data, plaintext tokens, cluster
certificates, node passwords, plaintext kubeconfigs, persistent application
data, or raw backups. `.gitignore` is a safety net, not the boundary: review
staged files before every commit.

The server token, cluster CA/server identity, worker identities, and datastore
are runtime recovery assets. They must be backed up to encrypted offline
storage, never copied into this repository.
