{ inputs, ... }:
{ imports = [ inputs.self.nixosModules.k3s-server ];
  piCluster.k3s.server = { enable = true; nodeName = "cube"; advertiseAddress = "cube.lan"; tokenFile = "/run/secrets/k3s-server-token"; };
}
