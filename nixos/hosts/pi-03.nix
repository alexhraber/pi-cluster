{ inputs, ... }:
{ imports = [ (import ./pi/configuration.nix { inherit inputs; }) ];
  piCluster.k3s.worker.nodeName = "pi-03";
}
