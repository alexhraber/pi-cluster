{ ... }:
{
  # Replace or extend this with generated hardware facts per actual board.
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.timeout = 1;
  hardware.enableRedistributableFirmware = true;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  system.stateVersion = "24.11";
}
