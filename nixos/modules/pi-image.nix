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
  # The bootstrap image has no committed credential. Access is intentionally
  # provisioned by the operator during the post-image NixOS switch.
  users.allowNoPasswordLogin = true;
  security.sudo.wheelNeedsPassword = false;
  boot.kernel.sysctl."vm.swappiness" = 10;
}
