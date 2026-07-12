{ lib, pkgs, config, k3sPkgs ? pkgs, ... }:
let cfg = config.piCluster.k3s.worker;
in {
  options.piCluster.k3s.worker = {
    enable = lib.mkEnableOption "a Pi K3s agent";
    nodeName = lib.mkOption { type = lib.types.str; };
    apiAddress = lib.mkOption { type = lib.types.str; };
    tokenFile = lib.mkOption { type = lib.types.path; description = "Runtime-only agent token file."; };
    package = lib.mkOption { type = lib.types.package; default = k3sPkgs.k3s; };
  };
  config = lib.mkIf cfg.enable {
    assertions = [ { assertion = lib.hasPrefix "pi-" cfg.nodeName; message = "Pi names must use pi-XX."; } ];
    networking.hostName = cfg.nodeName;
    environment.systemPackages = [ cfg.package ];
    services.k3s = { enable = true; role = "agent"; package = cfg.package; serverAddr = "https://${cfg.apiAddress}:6443"; tokenFile = cfg.tokenFile; extraFlags = [ "--node-name=${cfg.nodeName}" ]; };
    services.journald.extraConfig = "SystemMaxUse=64M\nRuntimeMaxUse=32M";
    services.timesyncd.enable = true;
    documentation.nixos.enable = false;
    environment.defaultPackages = [];
    boot.kernel.sysctl."vm.swappiness" = 10;
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    boot.kernel.sysctl."net.bridge.bridge-nf-call-iptables" = 1;
    boot.kernel.sysctl."net.bridge.bridge-nf-call-ip6tables" = 1;
  };
}
