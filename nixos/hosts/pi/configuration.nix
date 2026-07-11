{ inputs, ... }:
{ imports = [ inputs.self.nixosModules.k3s-worker ];
  # Instantiate four copies, changing only nodeName and its LAN reservation.
  piCluster.k3s.worker = { enable = true; nodeName = "pi-01"; apiAddress = "cube.lan"; tokenFile = "/run/secrets/k3s-agent-token"; };
}
