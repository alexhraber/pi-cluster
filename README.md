# pi-cluster

Declarative foundation for a deliberately non-HA K3s edge cluster:

```text
cube (x86_64 NixOS, intermittent K3s server; never a workload node)
                    │ LAN / stable API address
        ┌───────────┼───────────┬───────────┐
     pi-01        pi-02       pi-03       pi-04
   ARM64 / 1 GB Raspberry Pi 3B+ K3s agents
```

The Pis are the persistent data plane. Existing Pods, kube-proxy/service
rules, Flannel state, and local processes continue to run during a Cube
outage, subject to the limitations in [the offline operating model](docs/offline-control-plane.md).
This repository is an infrastructure foundation only: it intentionally does
not install workloads, an ingress controller, a mesh, an operator, a GitOps
controller, distributed storage, or an observability stack.

## Repository map

- `nixos/` — Cube and Pi NixOS modules and host entrypoints.
- `k3s/` — pinned-version policy and server/agent configuration contracts.
- `kubernetes/` — empty-by-design manifest roots and future workload layout.
- `networking/` — LAN, CNI, DNS, and north-south invariants.
- `ingress/` — future redundant ingress placement contract.
- `mesh/` — service-mesh decision record; no mesh installation.
- `scripts/` — read-only and disruption-test verification tooling.
- `docs/` — architecture, operations, failure, backup, and recovery procedures.
- `secrets/` — encrypted-secret instructions and non-secret examples only.

Git contains desired configuration and procedures, never live runtime state;
see [docs/state-boundary.md](docs/state-boundary.md). This phase does not
prove that Cube or any Pi has been provisioned.

Start with [docs/architecture.md](docs/architecture.md), then follow
[docs/bootstrap.md](docs/bootstrap.md).
