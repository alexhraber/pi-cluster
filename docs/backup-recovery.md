# Backup and recovery

Before every K3s upgrade, run `scripts/backup-k3s-state.sh` as root on Cube to
an encrypted destination outside Git. Preserve:

- the K3s datastore under `/var/lib/rancher/k3s/server/db/`;
- the server token;
- cluster CA and server identity under the K3s data directory;
- each worker's `/var/lib/rancher/k3s/agent/` identity and local volume data;
- a tested copy of the exact Nix flake lock and host configuration.

The backup must be encrypted, access-controlled, integrity-checked, and
periodically restore-tested on an isolated machine. Never put its output in
the repository. Declarative Git content can recreate configuration, not live
datastore state or application data.

Recovery order: restore compatible Cube OS and pinned K3s package; restore
server identity/token and datastore; start the server at the same stable API
address; verify CA/API identity; reconnect workers; inspect Events and only
then resume changes. A NixOS generation rollback alone cannot undo a K3s
datastore schema migration or restore deleted runtime state.
