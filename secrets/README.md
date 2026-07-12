# Encrypted secrets only

The real `cluster.yaml` and `.sops.yaml` are operator-managed and must not be
committed in plaintext. Use [docs/secrets.md](../docs/secrets.md) to create an
encrypted sops-nix payload containing `k3s.server-token`. The Pi agents use
that same token by deliberate design; a separate agent token requires explicit
server wiring and a separate recovery contract.

The encrypted file belongs at `secrets/cluster.yaml`; this repository does not
ship a placeholder token or a private age key. Run
`scripts/prepare-secrets.sh` from the Nix development shell to create the
operator-managed payload locally. Review the encrypted diff before committing
it; never commit the decrypted source or local `secrets/.sops.yaml`.
