{ system, nixpkgs, nixpkgs-k3s }:
let
  pkgs = import nixpkgs { inherit system; };
  k3sPkgs = import nixpkgs-k3s { inherit system; };
  lib = pkgs.lib;
  server = lib.nixosSystem { inherit system; modules = [ (import ./modules/k3s-server.nix) ({ piCluster.k3s.server = { enable = true; advertiseAddress = "192.0.2.10"; tokenFile = "/run/secrets/k3s-server-token"; }; }) ]; specialArgs = { inherit k3sPkgs; }; };
  worker = lib.nixosSystem { inherit system; modules = [ (import ./modules/k3s-worker.nix) ({ piCluster.k3s.worker = { enable = true; nodeName = "pi-01"; apiAddress = "192.0.2.10"; tokenFile = "/run/secrets/k3s-agent-token"; }; }) ]; };
in pkgs.runCommand "pi-cluster-nixos-module-eval" {} '' touch $out ''
