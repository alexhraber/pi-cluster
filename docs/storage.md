# Storage and recovery contract

## Selected baseline

This is the pre-provisioning baseline. Hardware must be checked against it;
the repository does not claim that any media has been purchased or tested.

| Node/data | Selected medium | Owner | Persistence boundary | Loss consequence |
|---|---|---|---|---|
| Cube OS | Internal SSD/NVMe | NixOS | System generation and root filesystem | Rebuild requires K3s recovery assets |
| Cube K3s | Persistent directory on the internal SSD/NVMe | K3s server | `/var/lib/rancher/k3s` | Control-plane identity/datastore recovery required |
| Pi OS | High-endurance industrial microSD | NixOS | Boot and immutable/config state | Reimage and reconnect; local runtime may be lost |
| Pi K3s agent | Persistent `/var/lib/rancher/k3s` on the Pi boot/data filesystem | K3s agent | Agent identity and local container state | Reboot/node loss can strand local workloads |
| Pi application data | Dedicated USB SSD per workload, when required | Application owner | Explicit workload volume | Node-bound data loss unless separately backed up |
| K3s backup | Encrypted removable/offline storage | Operator | Age-encrypted recovery archive | Restore requires archive and age private key |

The Pi 3B+ baseline uses high-endurance microSD for boot because it is the
most portable starting point. Write-heavy or valuable application data must
not default to that card; use a separately powered, tested USB SSD and an
application-specific backup. USB boot or moving K3s state to USB is a later
measured hardware decision, not an implicit assumption.

## Ownership and boundaries

- Git owns declarations, versions, scripts, and encrypted secret payloads.
- Cube owns the single K3s server datastore, CA, server identity, and server
  token under `/var/lib/rancher/k3s` and the runtime secret path.
- Each Pi owns its agent identity, image/cache state, and node-local volumes.
- Each workload owns the backup and restore semantics of its application data.
- The operator owns encrypted backup media, age private keys, retention, and
  restore evidence.

There is no distributed storage or automatic cross-Pi replication in this
phase. A Pi loss does not make a local volume available on another Pi.

## Backup destination and retention

The primary destination is an encrypted removable/offline drive that is not
permanently mounted on Cube. Maintain a second encrypted copy at a separate
location when the data value justifies it. Proposed retention is seven daily,
four weekly, and three monthly recovery points; the operator must adjust this
to the actual data and risk profile.

Backups are created with `scripts/backup-k3s-state.sh` on Cube and
`scripts/backup-worker-state.sh` on each Pi. Both require an age recipient and
produce encrypted archives plus checksums. They refuse Git working trees as a
destination. No raw backup is committed.

## Restore testing

Restore tests must run on isolated replacement storage, never over the live
cluster. At least quarterly and before a K3s version change, verify that:

1. encrypted archives decrypt with the recovery key;
2. checksums match;
3. Cube state restores with a compatible pinned K3s version;
4. the server token, CA, and API identity are preserved;
5. a worker identity archive is readable and its node can be reimaged safely;
6. application owners can restore their own data separately.

Record the restore date, source archive, K3s version, result, and unresolved
limitations outside the repository or in a sanitized operational record.
