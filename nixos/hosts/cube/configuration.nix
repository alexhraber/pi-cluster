{ inputs, lib, ... }:
{ imports = [ inputs.self.nixosModules.k3s-server inputs.sops-nix.nixosModules.sops ];
  # String path keeps evaluation possible before the operator creates the
  # encrypted payload; activation remains blocked until it exists.
  sops.defaultSopsFile = "${builtins.toString ../../..}/secrets/cluster.yaml";
  sops.secrets.k3s-server-token = lib.mkIf (builtins.pathExists ../../../secrets/cluster.yaml) { key = "k3s/server-token"; owner = "root"; group = "root"; mode = "0400"; };
  # Add the final reserved Cube IP to tlsSans before startup.
  # Agents intentionally use the same recovery-critical server token.
  piCluster.k3s.server = { enable = true; nodeName = "cube"; advertiseAddress = "cube.lan"; tlsSans = [ "cube.lan" ]; tokenFile = "/run/secrets/k3s-server-token"; };
  systemd.services.k3s = { after = [ "sops-install-secrets.service" ]; wants = [ "sops-install-secrets.service" ]; };
}
