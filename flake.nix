{
  description = "Declarative pi-cluster edge K3s foundation";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Separate lock input: normal Cube upgrades cannot silently change K3s.
    nixpkgs-k3s.url = "github:NixOS/nixpkgs/nixos-24.11";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nixpkgs-k3s, sops-nix }:
    let systems = [ "x86_64-linux" "aarch64-linux" ];
        forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      nixosModules.k3s-server = import ./nixos/modules/k3s-server.nix;
      nixosModules.k3s-worker = import ./nixos/modules/k3s-worker.nix;
      checks = forAllSystems (system: {
        nixos-module-eval = import ./nixos/eval.nix { inherit system nixpkgs nixpkgs-k3s sops-nix; };
      });
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShellNoCC {
            packages = [ pkgs.age pkgs.gitleaks pkgs.kubectl pkgs.shellcheck pkgs.yamllint ];
          };
        });
    };
}
