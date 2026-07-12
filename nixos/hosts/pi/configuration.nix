{ inputs, lib, ... }:
{ imports = [ inputs.self.nixosModules.k3s-worker inputs.sops-nix.nixosModules.sops ];
  # Instantiate four copies, changing only nodeName and its LAN reservation.
  sops.defaultSopsFile = "${builtins.toString ../../..}/secrets/cluster.yaml";
  # K3s agents intentionally use the same server token as the first server.
  sops.secrets.k3s-agent-token = lib.mkIf (builtins.pathExists ../../../secrets/cluster.yaml) { key = "k3s/server-token"; owner = "root"; group = "root"; mode = "0400"; };
  piCluster.k3s.worker = { enable = true; nodeName = "pi-01"; apiAddress = "cube.lan"; tokenFile = "/run/secrets/k3s-agent-token"; };
  systemd.services.k3s = { after = [ "sops-install-secrets.service" ]; wants = [ "sops-install-secrets.service" ]; };
}
