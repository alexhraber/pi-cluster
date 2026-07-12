# Raspberry Pi preflight checklist

This checklist is for `pi-01`, `pi-02`, `pi-03`, and `pi-04` before K3s is
started. It is a hardware and operating-system gate, not a provisioning
procedure. Do not run the K3s service, join a cluster, or deploy workloads as
part of this checklist.

Use the safe inspection script from the repository on each node:

```bash
sudo env MODE=hardware-only EXPECTED_NODE=pi-01 scripts/pi-preflight.sh
```

Change only `EXPECTED_NODE` for the other three nodes. Save the complete
output with the inventory record in `docs/pi-node-inventory.md` or an
operator-controlled evidence store. A failed check blocks startup.

## Per-node checklist

| Check | Required condition | Evidence |
|---|---|---|
| Identity | Hostname matches `pi-01` through `pi-04`; DHCP reservation is recorded | Script output and LAN reservation |
| Architecture | `uname -m` is `aarch64` | Script output |
| Image | Minimal 64-bit Linux/NixOS image, no desktop environment | Image/build identifier and package review |
| Firmware | Pi firmware/bootloader is supported by the selected ARM64 image | Firmware output and image notes |
| SSH | Intended operator account works with key authentication and least privilege | Sanitized SSH test record |
| Time | NTP synchronization is active before K3s | Script output |
| Memory | 1 GB class board is recognized and the reserved headroom budget passes | Script output |
| CPU | Four-core Pi 3B+ class CPU is recognized; no unexpected throttling | Script output and thermal evidence |
| Storage | High-endurance boot media is identified, mounted, and has required free space | `findmnt`, `df`, and media inventory |
| Power/cooling | Stable supply, cable, enclosure, and cooling are recorded | Hardware inspection |
| Network link | Ethernet/Wi-Fi decision, link state, default route, and DNS are recorded | Script output and LAN evidence |
| API route | In `cluster` mode, `cube.lan` resolves and the Pi has a route toward Cube; hardware-only mode intentionally does not require Cube | Script output |
| Cgroups | cgroup v2 is available for the container runtime | Script output |
| K3s state | Persistent target for `/var/lib/rancher/k3s` is selected; it is not created by this checklist | Storage record |

## Resource budget

The Pi has 1 GB RAM. Before accepting the node, reserve headroom for the OS,
container runtime, CNI, kubelet, and filesystem cache. Future workloads must
declare requests and limits. This checklist does not define a workload
capacity guarantee; measured pressure during the first test workload remains
required.

## Evidence and status

The canonical blank inventory is [pi-node-inventory.md](pi-node-inventory.md).
Record the exact image, kernel, firmware, media serial, MAC address, proposed
LAN address, operator, timestamp, and script output hash. Do not record
passwords, private keys, tokens, or raw secret material.

## Explicit non-actions

This checklist does not:

- start or enable K3s;
- write `/var/lib/rancher/k3s`;
- create a cluster token or kubeconfig;
- join a worker to Cube;
- deploy a workload;
- claim that the physical cluster is ready without evidence for every node.
