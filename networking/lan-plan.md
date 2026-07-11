# Proposed LAN plan

This is the repository’s proposed address and naming contract. The `192.168.50.0/24`
range is an assumption, not a claim about the physical LAN. Confirm that it is
unused and reserve the addresses in the LAN DHCP service before provisioning.

| Role | Hostname | Proposed address | DNS name | Kubernetes role |
|---|---|---:|---|---|
| Control plane | `cube` | `192.168.50.10` | `cube.lan` | K3s server only |
| Worker | `pi-01` | `192.168.50.11` | `pi-01.lan` | ARM64 agent |
| Worker | `pi-02` | `192.168.50.12` | `pi-02.lan` | ARM64 agent |
| Worker | `pi-03` | `192.168.50.13` | `pi-03.lan` | ARM64 agent |
| Worker | `pi-04` | `192.168.50.14` | `pi-04.lan` | ARM64 agent |

## Required reservations

- Use DHCP reservations keyed to each machine’s stable hardware identity, or
  equivalent static addressing managed outside this repository.
- Do not use a changing DHCP lease for the K3s API endpoint.
- All nodes must resolve `cube.lan` to `192.168.50.10` and reach TCP 6443.
- Operators should resolve every Pi name from the LAN for SSH and diagnostics.
- The LAN/router remains the default north-south gateway; Cube is not a
  router, NAT device, or ingress hop.

## Workload exposure decision

The selected future production direction is documented in
[ingress/design.md](../ingress/design.md): two Traefik replicas on `pi-01`
and `pi-02`, fixed NodePorts, and LAN DNS answers for both fixed addresses.
No ingress controller is installed by this repository phase. Direct Pi host
ports are allowed only for early diagnostics and single-node tests; they are
not the production exposure contract.

Future ingress must tolerate Cube being off, preserve the selected client
traffic policy, and document what happens when either ingress Pi is lost.

## Cube outage behavior

While Cube is off, existing worker-local routing and already-programmed
Service rules continue to serve traffic when the path is Pi-local or uses the
future redundant ingress addresses. New API-dependent changes, scheduling,
Endpoint programming, and DNS changes stop until Cube returns. LAN DNS remains
an independent router/DNS concern and must not be hosted only on Cube.

## Pre-provisioning gate

Before startup, an operator must replace any incorrect assumptions with the
actual LAN values and record evidence that:

1. `192.168.50.0/24` is available or a different range has been selected.
2. All five reservations are installed.
3. `cube.lan` and the four Pi names resolve from the intended admin network.
4. Pi-to-Cube TCP 6443 is permitted, and LAN clients can reach selected Pi
   addresses without traversing Cube.
