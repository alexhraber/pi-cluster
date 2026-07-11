# ARM64 Pi image and provisioning path

## Selected strategy

Build minimal 64-bit NixOS SD images from the pinned flake using the native
NixOS `sd-image-aarch64` module. The image stage contains SSH, time
synchronization, minimal diagnostics, and no K3s, sops-nix, cluster token,
kubeconfig, desktop, workload, ingress, operator, or mesh.

The image outputs are node-specific for stable hostnames:

- `nixosConfigurations.pi-01-image`
- `nixosConfigurations.pi-02-image`
- `nixosConfigurations.pi-03-image`
- `nixosConfigurations.pi-04-image`

The post-image configurations are separate:

- `nixosConfigurations.pi-01` through `pi-04` add each K3s agent and runtime
  sops-nix token path.
- The image must boot and pass preflight before the post-image configuration
  is applied.

## Build and write (future operator action)

Run from a trusted x86_64 NixOS workstation after Day-0 readiness approval:

```bash
nix build .#nixosConfigurations.pi-01-image.config.system.build.sdImage
ls -lh result/sd-image/
sha256sum result/sd-image/*
zstdcat result/sd-image/*.img.zst | sudo dd of=/dev/disk/by-id/<pi-01-media> bs=4M conv=fsync status=progress
sync
```

Repeat for each node-specific image and record the output hash in the node
inventory. Verify the target device before writing; the command is destructive
to the selected media.

The image build itself does not require a secret payload and must not receive
one. Do not write an image to hardware until the Day-0 checklist is approved.

## First boot and node configuration

1. Boot the Pi from the approved high-endurance media.
2. Confirm the expected hostname, ARM64 architecture, SSH access, time sync,
   storage, power/cooling, DNS, and route using `scripts/pi-preflight.sh`.
3. Record the image hash, kernel, firmware, MAC, address reservation, and
   complete preflight output.
4. From the operator workstation, apply the corresponding node configuration
   only after the preflight is `PHYSICALLY-VERIFIED`:

   `nixos-rebuild switch --flake .#pi-01 --target-host <pi-01-admin-address>`

5. Confirm the sops-nix encrypted payload and age-key access are available to
   activation. The K3s agent is not considered ready until the secret exists.
6. Run the cluster verification procedure after the explicit worker-join
   approval. The image path itself never joins K3s.

## Firmware and rollback assumptions

- Use a 64-bit-compatible Pi 3B+ firmware/bootloader and record its version.
- Keep the prior known-good image and node configuration until the new image
  passes preflight.
- If a node fails preflight, remove its media, restore the prior image, and
  record the failure; do not troubleshoot by joining the cluster.
- If post-image configuration fails, boot the image-stage system again and
  preserve the worker's prior identity and data according to the recovery
  procedure.

## Proof boundary

Reproducible image evaluation/build proves repository output reproducibility,
not hardware compatibility. Physical readiness requires the Day-0 checklist,
Pi preflight evidence, actual media/hash records, and explicit operator
approval. Issues #17 and #18 remain blocked from physical execution until that
gate is complete.
