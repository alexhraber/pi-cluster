# Architecture

Cube is one intermittent x86_64 K3s server and the four Pis are ARM64 agents.
Cube is tainted `NoSchedule`; it is an ignition source and scheduler, not a
workload node. This is a single-server cluster, not HA.

The authoritative runtime state is split deliberately: Git owns desired
configuration; K3s owns live control-plane state under `/var/lib/rancher/k3s`;
each worker owns its agent identity and local container/runtime state; future
applications own their persistent data on explicitly selected media.

## Invariants

1. Workers must route already-assigned traffic without a Cube dependency.
2. No service may use Cube as a north-south router.
3. Every secret is supplied at activation time by agenix, sops-nix, or an
   equivalent root-only mechanism; this repository does not assume either is
   installed.
4. Every future workload has resource requests/limits suitable for 1 GB Pis.
5. A change is not physically proven until the outage/reboot tests in
   `scripts/` have been run against the real cluster.

## Deferred decisions

The proposed LAN addresses, DNS names, reservations, and north-south exposure
policy are recorded in [networking/lan-plan.md](../networking/lan-plan.md).
The address range remains an operator-verified assumption until the physical
LAN is checked. Storage medium/filesystem, ingress implementation details, and
mesh choice still require facts from the actual LAN and measurements on Pi 3B+.
