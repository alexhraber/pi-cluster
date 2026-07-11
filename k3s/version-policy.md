# K3s version policy

K3s is pinned by the separate `nixpkgs-k3s` flake input in `flake.nix` and its
`flake.lock`. The Cube module imports K3s from that input, not from the
ordinary system input. A routine NixOS update therefore cannot silently
change K3s.

Intentional upgrade procedure:

1. Read release notes and check ARM64 compatibility.
2. Back up the datastore and token with `scripts/backup-k3s-state.sh`.
3. Update only `nixpkgs-k3s`, review the lockfile and evaluate the module.
4. Apply the Cube generation, then verify API access, all agents, and workloads.
5. Keep the backup until migration and rollback decisions are complete.

Rolling back a NixOS generation after a datastore migration is not a valid
Kubernetes rollback by itself. Restore a compatible datastore snapshot and
identity material only according to the K3s release migration rules.
