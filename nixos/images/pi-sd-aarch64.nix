{ modulesPath, ... }:
{
  imports = [
    ./pi-base.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
}
