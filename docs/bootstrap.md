# Bootstrap sequence

Do not begin this sequence until [day0-readiness.md](day0-readiness.md) has
every blocking row physically verified and has explicit human approval. This
document describes the eventual order; it is not authorization to start
hardware now.

1. Choose and reserve the Cube and four Pi LAN addresses; publish `cube.lan`
   through LAN DNS.
2. Provision Cube with NixOS, an encrypted runtime secret mechanism, the
   pinned flake, and `nixosConfigurations.cube` after replacing the generic
   Cube hardware module with the workstation's generated hardware file. Add
   the final reserved Cube IP to the server TLS SAN list before activation.
3. Confirm the server is tainted and has no workload Pods.
4. Provision each minimal ARM64 Pi with its unique hostname, address
   reservation, persistent K3s agent directory, and the same server token used
   by Cube, according to the explicit token contract.
5. Run `scripts/verify-cluster.sh` from a trusted admin host.
6. Perform the outage and worker-reboot drills before adding any workload.

These commands require adaptation to the actual NixOS host layout and secret
tool. This repository intentionally does not assume agenix or sops-nix is
already configured.
