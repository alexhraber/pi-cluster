# Pi host instances

Instantiate the worker module four times with stable hostnames and DHCP
reservations: `pi-01`, `pi-02`, `pi-03`, and `pi-04`. Use a minimal 64-bit
ARM64 NixOS image, no desktop, and persistent storage for
`/var/lib/rancher/k3s`. Each worker token is injected at activation time.
