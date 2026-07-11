{ inputs, ... }:
{ imports = [ (import ./hosts/pi/configuration.nix { inherit inputs; }) ];
  piCluster.k3s.worker.nodeName = "pi-03";
}
