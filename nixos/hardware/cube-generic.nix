{ ... }:
{
  # Evaluation-safe defaults only. Replace these with the actual Cube
  # hardware-generated file before applying the system to the workstation.
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  boot.loader.grub.device = "nodev";
  system.stateVersion = "24.11";
}
