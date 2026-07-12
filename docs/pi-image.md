# Raspberry Pi image path

The repository defines a minimal 64-bit NixOS SD image for each Pi. The image
does not contain K3s, cluster secrets, workloads, ingress, a service mesh, or
persistent application data. Those are applied only after the hardware
preflight gate passes.

## Rehearsal sequence

Build all four `aarch64-linux` outputs without creating a `result` symlink:

```bash
./scripts/build-pi-images.sh
```

The script validates each compressed archive and prints its SHA-256 digest.
Copy each artifact path and digest into [pi-flash-manifest.yaml](pi-flash-manifest.yaml)
under operator control. Do not commit the image itself.

Before any device write, identify the exact removable device by stable ID and
perform the mandatory read-only rehearsal:

```bash
NODE=pi-01 IMAGE=/path/to/nixos-sd-image.img.zst \
  MEDIA_BY_ID=/dev/disk/by-id/usb-EXACT-MEDIA \
  EXPECTED_SHA256=... ./scripts/flash-pi-dry-run.sh
```

This checks the digest and archive, prints `lsblk` identity information, and
prints the eventual write command without invoking `dd`. A human must review
the resolved device and approve the write. The manifest remains
`NOT_PHYSICALLY_RUN` until real evidence exists.

After an approved write and first boot, collect inventory and run the
hardware-only gate before applying cluster configuration:

```bash
sudo EXPECTED_NODE=pi-01 EXPECTED_API=cube.lan MODE=hardware-only \
  ./scripts/pi-preflight.sh
./scripts/collect-node-inventory.sh pi-01
nixos-rebuild switch --flake .#pi-01 --target-host <pi-01-admin-address>
```

Repeat per node. Post-image configuration is the first point at which node
identity, encrypted runtime secrets, and K3s agent state are introduced. Do
not enable or join K3s as part of image rehearsal.

## Evidence and rollback

Record outside Git or in the non-secret manifest: image path and digest, media
`/dev/disk/by-id` and serial, MAC address, hostname, kernel, firmware,
preflight output hash, operator, and timestamp. If a node fails the gate,
remove it from service, preserve its evidence, and either reapply the matching
NixOS node configuration or reimage the media from a newly verified artifact.
Reimage is destructive: confirm the stable media ID again and repeat the dry
run. Back up application data before replacing media. This procedure does not
claim any physical node has been provisioned.
