{ pkgs, ... }:
{
  # Image stage only: no K3s, no sops-nix, no cluster token, and no workload.
  services.openssh.enable = true;
  services.timesyncd.enable = true;
  documentation.nixos.enable = false;
  environment.defaultPackages = [];
  environment.systemPackages = [ pkgs.curl pkgs.git pkgs.htop pkgs.kubectl ];
  services.journald.extraConfig = "SystemMaxUse=64M\nRuntimeMaxUse=32M";
  boot.kernel.sysctl."vm.swappiness" = 10;
  networking.firewall.allowedTCPPorts = [ 22 ];
  system.stateVersion = "24.11";
}
