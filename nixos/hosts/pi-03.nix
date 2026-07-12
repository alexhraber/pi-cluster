{ inputs, lib, ... }:
{ imports = [ (import ./pi/configuration.nix { inherit inputs lib; }) ];
  piCluster.k3s.worker.nodeName = lib.mkForce "pi-03";
}
