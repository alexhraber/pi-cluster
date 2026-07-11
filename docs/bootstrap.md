# Bootstrap sequence

1. Choose and reserve the Cube and four Pi LAN addresses; publish `cube.lan`
   through LAN DNS.
2. Provision Cube with NixOS, an encrypted runtime secret mechanism, the
   pinned flake, and `nixos/hosts/cube/configuration.nix`.
3. Confirm the server is tainted and has no workload Pods.
4. Provision each minimal ARM64 Pi with its unique hostname, address
   reservation, persistent K3s agent directory, and runtime token.
5. Run `scripts/verify-cluster.sh` from a trusted admin host.
6. Perform the outage and worker-reboot drills before adding any workload.

These commands require adaptation to the actual NixOS host layout and secret
tool. This repository intentionally does not assume agenix or sops-nix is
already configured.
