{ inputs, ... }:
{ imports = [ inputs.self.nixosModules.k3s-worker inputs.sops-nix.nixosModules.sops ];
  # Instantiate four copies, changing only nodeName and its LAN reservation.
  sops.defaultSopsFile = "${builtins.toString ../../..}/secrets/cluster.yaml";
  sops.secrets.k3s-agent-token = { key = "k3s/agent-token"; owner = "root"; group = "root"; mode = "0400"; };
  piCluster.k3s.worker = { enable = true; nodeName = "pi-01"; apiAddress = "cube.lan"; tokenFile = "/run/secrets/k3s-agent-token"; };
  systemd.services.k3s = { after = [ "sops-install-secrets.service" ]; wants = [ "sops-install-secrets.service" ]; };
}
