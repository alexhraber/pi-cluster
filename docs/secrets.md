# Secret-management contract

## Decision

This repository selects [sops-nix](https://github.com/Mic92/sops-nix) with age
recipients. Encrypted YAML is the Git-managed declaration; sops-nix decrypts
only at activation time into root-owned files under `/run/secrets`.

The Cube and Pi host snippets import sops-nix and reference these runtime paths:

- Cube: `/run/secrets/k3s-server-token`, key `k3s/server-token`.
- Pi workers: `/run/secrets/k3s-agent-token`, key `k3s/server-token`.

The agent token intentionally equals the server token. This follows K3s's
default token behavior and keeps the single recovery-critical token aligned
with the datastore backup. A future separate agent token requires explicit
server `--agent-token` wiring and a separate recovery procedure.

The K3s service is ordered after `sops-install-secrets.service`, so it cannot
start before the token file has been materialized. Secret values never become
Nix derivation inputs.

## Operator preparation command

Run this from the repository's Nix development shell on the trusted operator
workstation:

```bash
nix develop --accept-flake-config
AGE_KEY_FILE="$HOME/.config/pi-cluster/age.key" scripts/prepare-secrets.sh
```

The script creates the age key outside the repository if it does not exist,
creates the ignored local `secrets/.sops.yaml`, reads the shared K3s token from
`/dev/tty` without accepting it as a command-line argument, creates
`secrets/cluster.yaml`, and decrypts the result only to `/dev/null` for a
controlled verification. It refuses to overwrite an existing payload. It
does not start K3s or alter any machine.

After the command succeeds:

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/pi-cluster/age.key" \
  sops --decrypt secrets/cluster.yaml >/dev/null
git diff -- secrets/cluster.yaml
git check-ignore -v "$HOME/.config/pi-cluster/age.key" secrets/.sops.yaml
```

The encrypted payload may be committed. Never redirect decrypted output to a
file, paste the token into a shell command, or add the age private key to Git.

## Operator prerequisites

Before provisioning, an operator must:

1. Create an age keypair and keep the private key outside Git and the Nix
   store, preferably in a password manager or hardware-backed store.
2. Create a local `.sops.yaml` from the example and set the public recipient.
3. Run `scripts/prepare-secrets.sh` and confirm the shared-token contract.
4. Store a protected recovery copy of the age private key through a separate
   channel, such as a password manager or offline encrypted media.
5. Make the age private key available only to the activation operation on the
   intended host.

No plaintext secret, kubeconfig, certificate, private age key, or temporary
input may be committed.

## Rotation

Rotate tokens during a maintenance window: create a new encrypted payload,
deploy it to Cube, update workers in a controlled sequence, verify
reconnection, and retain the prior encrypted backup only for the documented
recovery window. Token rotation does not rotate the cluster CA or existing
worker identity.

## Backup and recovery

Back up the encrypted sops file, age recipient metadata, and private age key
through separate protected channels. Verify the encrypted payload can be
decrypted with the recovery copy without writing plaintext to disk. The K3s datastore, cluster CA, server
token, and worker identities remain runtime recovery assets as described in
[backup-recovery.md](backup-recovery.md). A Git checkout alone cannot recover
a cluster without the age private key and runtime state.

## Review and scanning

Review every secret change for recipient/key scope and diff shape. Run secret
scanning before commit and inspect staged files. The repository ignores
plaintext secret paths, backups, kubeconfigs, certificates, and databases, but
`.gitignore` is only a guardrail; staged-file review is mandatory.
