# Encrypted secrets only

The real `cluster.yaml` and `.sops.yaml` are operator-managed and must not be
committed in plaintext. Use [docs/secrets.md](../docs/secrets.md) to create an
encrypted sops-nix payload containing `k3s.server-token` and `k3s.agent-token`.

The encrypted file belongs at `secrets/cluster.yaml`; this repository does not
ship a placeholder token or a private age key.
