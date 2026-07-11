{ lib, pkgs, config, k3sPkgs ? pkgs, ... }:
let cfg = config.piCluster.k3s.server;
in {
  options.piCluster.k3s.server = {
    enable = lib.mkEnableOption "the Cube K3s server";
    package = lib.mkOption { type = lib.types.package; default = k3sPkgs.k3s; };
    nodeName = lib.mkOption { type = lib.types.str; default = "cube"; };
    advertiseAddress = lib.mkOption { type = lib.types.str; description = "Stable LAN API address."; };
    tokenFile = lib.mkOption { type = lib.types.path; description = "Runtime secret path, never plaintext in Nix."; };
    extraServerArgs = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
  };
  config = lib.mkIf cfg.enable {
    assertions = [ { assertion = cfg.advertiseAddress != ""; message = "Set Cube's stable LAN API address."; } ];
    networking.hostName = cfg.nodeName;
    environment.systemPackages = [ cfg.package pkgs.kubectl ];
    services.k3s = {
      enable = true; role = "server"; package = cfg.package; tokenFile = cfg.tokenFile;
      serverAddr = "https://${cfg.advertiseAddress}:6443";
      extraFlags = [ "--node-name=${cfg.nodeName}" "--node-taint=node-role.kubernetes.io/control-plane:NoSchedule" "--disable=traefik" "--disable=servicelb" "--disable=local-storage" "--flannel-backend=vxlan" "--write-kubeconfig-mode=0640" ] ++ cfg.extraServerArgs;
    };
    # K3s owns this persistent identity/datastore boundary across generations.
    systemd.tmpfiles.rules = [ "d /var/lib/rancher/k3s 0700 root root -" "d /etc/k3s 0700 root root -" ];
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    boot.kernel.sysctl."net.bridge.bridge-nf-call-iptables" = 1;
    boot.kernel.sysctl."net.bridge.bridge-nf-call-ip6tables" = 1;
  };
}
