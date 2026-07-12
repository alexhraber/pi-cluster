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
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      piImage = nodeName: nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./nixos/modules/pi-image.nix
          { networking.hostName = nodeName; }
        ];
      };
      piConfig = nodeName: nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inputs = { inherit self sops-nix; }; };
        modules = [ ./nixos/hosts/${nodeName}.nix ];
      };
    in {
      nixosConfigurations = {
        pi-01-image = piImage "pi-01";
        pi-02-image = piImage "pi-02";
        pi-03-image = piImage "pi-03";
        pi-04-image = piImage "pi-04";
        pi-01 = piConfig "pi-01";
        pi-02 = piConfig "pi-02";
        pi-03 = piConfig "pi-03";
        pi-04 = piConfig "pi-04";
      };
      nixosModules.k3s-server = import ./nixos/modules/k3s-server.nix;
      nixosModules.k3s-worker = import ./nixos/modules/k3s-worker.nix;
      checks = forAllSystems (system: {
        nixos-module-eval = import ./nixos/eval.nix { inherit system nixpkgs nixpkgs-k3s sops-nix; };
      });
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShellNoCC {
            packages = [ pkgs.age pkgs.gitleaks pkgs.kubectl pkgs.shellcheck pkgs.yamllint pkgs.zstd ];
          };
        });
    };
}
