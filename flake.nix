{
  description = "Declarative pi-cluster edge K3s foundation";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Separate lock input: normal Cube upgrades cannot silently change K3s.
    nixpkgs-k3s.url = "github:NixOS/nixpkgs/nixos-24.11";
    # This revision explicitly tests against NixOS 24.11.
    sops-nix.url = "github:Mic92/sops-nix?rev=74b9fe5d7ff2d7301ad1550ab9a1a792745a9713";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nixpkgs-k3s, sops-nix }:
    let systems = [ "x86_64-linux" "aarch64-linux" ];
        forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
        inputs = { inherit self nixpkgs nixpkgs-k3s sops-nix; };
        mkClusterArgs = system: { inherit inputs; k3sPkgs = import nixpkgs-k3s { inherit system; }; };
    in {
      nixosModules.k3s-server = import ./nixos/modules/k3s-server.nix;
      nixosModules.k3s-worker = import ./nixos/modules/k3s-worker.nix;
      nixosConfigurations = {
        cube = nixpkgs.lib.nixosSystem { system = "x86_64-linux"; modules = [ ./nixos/hardware/cube-generic.nix ./nixos/hosts/cube/configuration.nix ]; specialArgs = mkClusterArgs "x86_64-linux"; };
        pi-01 = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/hardware/pi-generic.nix ./nixos/hosts/pi-01.nix ]; specialArgs = mkClusterArgs "aarch64-linux"; };
        pi-02 = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/hardware/pi-generic.nix ./nixos/hosts/pi-02.nix ]; specialArgs = mkClusterArgs "aarch64-linux"; };
        pi-03 = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/hardware/pi-generic.nix ./nixos/hosts/pi-03.nix ]; specialArgs = mkClusterArgs "aarch64-linux"; };
        pi-04 = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/hardware/pi-generic.nix ./nixos/hosts/pi-04.nix ]; specialArgs = mkClusterArgs "aarch64-linux"; };
        pi-01-image = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/images/pi-sd-aarch64.nix ({ networking.hostName = "pi-01"; }) ]; };
        pi-02-image = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/images/pi-sd-aarch64.nix ({ networking.hostName = "pi-02"; }) ]; };
        pi-03-image = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/images/pi-sd-aarch64.nix ({ networking.hostName = "pi-03"; }) ]; };
        pi-04-image = nixpkgs.lib.nixosSystem { system = "aarch64-linux"; modules = [ ./nixos/images/pi-sd-aarch64.nix ({ networking.hostName = "pi-04"; }) ]; };
      };
      checks = forAllSystems (system: {
        nixos-module-eval = import ./nixos/eval.nix { inherit system nixpkgs nixpkgs-k3s sops-nix; };
      });
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShellNoCC {
            packages = [ pkgs.age pkgs.sops pkgs.gitleaks pkgs.kubectl pkgs.shellcheck pkgs.yamllint ];
          };
        });
    };
}
