# Backup and recovery

The storage choices and ownership model are defined in
[storage.md](storage.md).

Before every K3s upgrade, run `scripts/backup-k3s-state.sh` as root on Cube to
an encrypted removable/offline destination outside Git. The destination must
not be a Git working tree, `/var/lib/rancher/k3s`, or a permanently exposed
Cube path. Preserve:

- the encrypted `secrets/cluster.yaml` payload and age-key recovery metadata;

- the K3s datastore under `/var/lib/rancher/k3s/server/db/`;
- the server token;
- cluster CA and server identity under the K3s data directory;
- each worker's `/var/lib/rancher/k3s/agent/` identity and local volume data;
- a tested copy of the exact Nix flake lock and host configuration.

The backup script emits an age-encrypted server archive, a non-secret manifest,
the pinned K3s version observation, and SHA-256 checksums. `SOPS_FILE`, when
provided, is the encrypted SOPS payload—not a decrypted secret. The output
must be copied to a second protected location, and its recovery age identity
must be held offline with the named recovery contact. Never put its output in
the repository. Declarative Git content can recreate configuration, not live
datastore state or application data.

Verify a backup from an independent machine or mounted offline media:

```bash
BACKUP_DIR=/media/recovery/k3s-<timestamp> \
  AGE_IDENTITY=/run/recovery/cluster-backup.agekey \
  ./scripts/verify-k3s-backup.sh
```

The verification checks checksums, decrypts the archive outside the cluster,
and requires the datastore, server token, CA, and server certificate. For each
Pi, run the worker backup with its expected name and verify the encrypted agent
identity archive with the same command.

Perform a restore rehearsal into a new temporary directory, never a live K3s
path:

```bash
BACKUP_DIR=/media/recovery/k3s-<timestamp> \
  AGE_IDENTITY=/run/recovery/cluster-backup.agekey \
  RESTORE_WORK_DIR=/tmp/pi-cluster-restore-<timestamp> \
  ./scripts/restore-k3s-backup-test.sh
```

This proves that the backup can be decrypted and that API identity, datastore,
or worker identity material can be reconstructed. Starting a compatible
pinned K3s instance against that extracted directory and proving worker
reconnect remains an explicit isolated-machine/hardware test; repository
validation does not perform it.

The proposed retention is seven daily, four weekly, and three monthly
recovery points. Back up before every K3s upgrade and at least weekly when Cube
is available. Restore-test at least quarterly and before a K3s version change.

Recovery order: restore compatible Cube OS and pinned K3s package; restore
server identity/token and datastore; start the server at the same stable API
address; verify CA/API identity; reconnect workers; inspect Events and only
then resume changes. A NixOS generation rollback alone cannot undo a K3s
datastore schema migration or restore deleted runtime state.

## Day-0 evidence record

Record the encrypted destination, retention policy, checksum and decrypt
verification result, recovery-key location, restore-test timestamp, K3s
version, and recovery contact in the operator evidence store. Do not put the
backup, age private key, token, certificates, kubeconfig, or application data
in Git. Until that evidence exists, the Day-0 recovery row remains `BLOCKED`.
