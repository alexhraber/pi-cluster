{ lib, pkgs, ... }:
{
  # Bootstrap image only: cluster identity and runtime secrets are applied later.
  system.stateVersion = "24.11";
  sdImage.compressImage = true;
  networking.useDHCP = lib.mkDefault true;
  services.openssh.enable = true;
  services.timesyncd.enable = true;
  documentation.nixos.enable = false;
  environment.defaultPackages = [];
  environment.systemPackages = [ pkgs.curl pkgs.git ];
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;
  boot.kernel.sysctl."vm.swappiness" = 10;
}
