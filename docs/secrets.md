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

## Operator prerequisites

Before provisioning, an operator must:

1. Create an age keypair and keep the private key outside Git and the Nix
   store, preferably in a password manager or hardware-backed store.
2. Create a local `.sops.yaml` from the example and set the public recipient.
3. Create a temporary plaintext input containing server and agent tokens with
   restrictive permissions.
4. Encrypt it to `secrets/cluster.yaml` with sops, verify decryption, and
   destroy the plaintext input.
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
through separate protected channels. The K3s datastore, cluster CA, server
token, and worker identities remain runtime recovery assets as described in
[backup-recovery.md](backup-recovery.md). A Git checkout alone cannot recover
a cluster without the age private key and runtime state.

## Review and scanning

Review every secret change for recipient/key scope and diff shape. Run secret
scanning before commit and inspect staged files. The repository ignores
plaintext secret paths, backups, kubeconfigs, certificates, and databases, but
`.gitignore` is only a guardrail; staged-file review is mandatory.
