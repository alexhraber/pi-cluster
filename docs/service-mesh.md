# Service-mesh evaluation and decision

Status: no mesh approved for this phase; no mesh installed.

The cluster is a persistent edge data plane with 1 GB Raspberry Pi 3B+ nodes
and an intermittent single-server control plane. A service mesh is not a
prerequisite for the base cluster, ingress design, or offline-control-plane
tests. This document is the adoption gate for a future experiment; it is not
permission to install a mesh in production.

## Decision

Use **no mesh** for the initial cluster and for all workloads until a separate
measurement run proves a concrete requirement that the base Kubernetes
networking and workload-level TLS cannot satisfy. This is a conservative
decision based on the current evidence boundary: no physical Pi has been
provisioned, and no mesh candidate has been measured on the target image.

The no-mesh baseline has no per-Pod proxy, no mesh control plane, no mesh CA,
no identity expiry dependency, and no mesh-specific restart path. Its outage
behavior is therefore the behavior already specified in
[the offline-control-plane model](offline-control-plane.md).

Linkerd and Istio ambient remain technically possible experiments, not
approved production choices. Popularity or vendor claims cannot replace the
measurements below.

## Candidate comparison

| Option | Data-plane shape | Control-plane and identity dependency | Decision |
|---|---|---|---|
| No mesh | Kubernetes Service/CNI only | None beyond the existing K3s contracts | **Selected now** |
| Linkerd | One Rust proxy sidecar per meshed Pod plus Linkerd control-plane components | Proxies use Linkerd identity and destination services. Existing proxies can continue with cached configuration during API/control-plane loss, but new proxies cannot become usable and new service discovery can be stale. Workload certificates rotate automatically; the issuer and trust anchor require an explicit expiry/rotation plan. | Candidate only if measured overhead and recovery pass |
| Istio ambient | One ztunnel per node, plus optional waypoint proxies for L7 policy | ztunnel receives xDS configuration and workload certificates from istiod. Ambient removes the per-Pod sidecar but retains node-level data-plane overhead, control-plane dependency, CA identity, and waypoint cost when L7 features are needed. | Candidate only if L4-only scope and measured budget pass |
| Istio sidecars | Envoy proxy per meshed Pod plus istiod | Per-Pod proxy memory and CPU multiply with every workload; this is outside the 1 GB Pi budget for the initial foundation. | Rejected for this cluster |

Istio ambient is not treated as “free sidecars.” Its current architecture still
uses a ztunnel on each node and xDS/certificate exchange with istiod. Linkerd’s
small proxy is promising, but a proxy that is small in isolation does not make
the complete control plane, certificates, Pod startup, and aggregate node
headroom free.

## Measurement protocol

The results must be collected on a real Raspberry Pi 3B+ using the selected
ARM64 NixOS image, the pinned K3s version, the same Flannel configuration, and
the same cgroup mode intended for production. An emulated or x86 benchmark
may validate manifests, but it is not acceptable performance evidence.

Run each candidate in a fresh, disposable test cluster or an isolated test
window, in this order:

1. **Baseline:** no mesh, the test workload, and the normal repository
   verification workload.
2. **Linkerd:** install only into the test cluster, mesh only the test
   namespace, and record control-plane plus sidecar overhead.
3. **Istio ambient:** reset the test cluster, install ambient components, use
   L4-only ztunnel first, and measure a waypoint separately if L7 policy is
   required.
4. Remove the candidate and repeat the baseline reachability test. Do not
   compare a warmed node against a cold node without recording the difference.

For every run, record node name, OS/image hash, kernel, K3s version, mesh/chart
versions, workload image digests, replica count, request rate, payload size,
duration, and timestamp. Capture at idle and under representative load:

| Measure | Required evidence |
|---|---|
| Node memory | `MemAvailable`, cgroup memory current/peak, and RSS for every mesh/control-plane container |
| Node CPU | per-container CPU and node CPU saturation; include Flannel and K3s overhead |
| Pod startup | time from Pod creation to Ready, with and without mesh injection/ambient enrollment |
| Traffic | request rate, p50/p95/p99 latency, error rate, connection resets, and TCP behavior |
| Data-plane recovery | existing connections, new connections, and proxy/ztunnel restart behavior while Cube is off |
| API recovery | time from Cube return to healthy control-plane discovery and reconciled routes |
| Identity | certificate issuer, trust anchor, workload certificate TTL, renewal window, and expiry behavior |
| Node headroom | minimum `MemAvailable` and whether the kernel OOM killer, eviction, or swap pressure occurred |

Use a consistent command set where available:

```sh
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get events -A --sort-by=.lastTimestamp
free -m
cat /proc/pressure/memory
cat /proc/pressure/cpu
crictl stats --output table
```

If `crictl` or PSI is unavailable on the selected image, record that as a
measurement limitation and use the image's supported cgroup and runtime
interfaces. Do not install an observability stack merely to perform this
decision.

## Acceptance thresholds

These thresholds are the pre-deployment gate, not measured results. A
candidate must pass both idle and loaded tests on every Pi that would run its
data plane:

| Gate | Required result |
|---|---|
| Memory headroom | At least 256 MiB `MemAvailable` at idle and 128 MiB under representative load; no OOM, eviction, or sustained swap pressure |
| Mesh overhead | No more than 128 MiB additional RSS per Pi for the candidate’s node/control-plane data plane; sidecar cost must be reported separately per Pod |
| CPU | No sustained CPU saturation attributable to the mesh; report p95 utilization and throttling |
| Startup | No more than 20% increase in test workload time-to-Ready versus the no-mesh baseline |
| Traffic | p99 latency increase no greater than 10% and no new error/reset class under the representative test |
| Outage | Existing meshed traffic remains within the documented candidate semantics while Cube is off; certificate expiry during the outage is a failure |
| Recovery | Workers and mesh components reconnect, renew identity, and converge after Cube returns without manual secret reconstruction |

If a candidate fails any gate, select no mesh and record the failure. Passing
the gates does not authorize installation; it permits a separate issue to
propose a narrowly scoped pilot.

## Control-plane outage and identity semantics

### Linkerd

Linkerd workload certificates are short-lived and automatically refreshed,
while the identity issuer and trust anchor have separate expiry/rotation
responsibilities. The default issuer/trust-anchor setup must not be allowed to
expire during a planned Cube outage. A test must record what happens to:

- an already-running proxy with cached service discovery;
- a newly restarted proxy while the API and identity service are unavailable;
- a new Service or EndpointSlice created while the control plane is absent;
- workload certificate renewal when the issuer is unavailable;
- issuer rotation and trust-anchor rotation, including required proxy and
  control-plane restarts.

The Linkerd rollback is to remove injection from the test namespace, restart
the affected workloads to remove proxies, verify direct Kubernetes Service
traffic, and uninstall only from the disposable test cluster. No production
namespace may be annotated until this rollback is rehearsed.

### Istio ambient

Ambient ztunnels receive xDS configuration from istiod and obtain workload
certificates for ServiceAccount identities on their nodes. A Cube outage must
therefore be tested separately for existing ztunnel state, new workload
identity, certificate rotation, and a ztunnel restart. L4-only ambient and
L7 waypoint behavior are separate measurements; a waypoint is not included in
the low-overhead claim for ztunnel alone.

The ambient rollback is to remove the ambient labels and waypoint references,
wait for direct CNI/Kubernetes routing to be verified, then remove the
candidate from the disposable cluster. Because ambient changes node-level
traffic interception, the rollback must include a worker reboot test and a
Cube-off test before any production pilot.

### No mesh

No mesh has no mesh identity or certificate rotation. Workload-level TLS may
still have its own certificate and outage requirements, which remain the
application owner’s responsibility. Removing a future no-mesh experiment is
the base state: remove only the workload-level configuration and rerun the
existing Service, Flannel, ingress, and offline-control-plane checks.

## Required proof before a future pilot

The future pilot issue must attach raw, non-secret measurement summaries and
the exact manifest/chart values used. It must prove:

1. Baseline, Linkerd, and ambient measurements are from comparable runs.
2. Per-node memory headroom remains above the threshold on all affected Pis.
3. Existing traffic, new traffic, proxy/ztunnel restart, worker reboot, and
   Cube outage behavior are recorded.
4. Certificate and identity expiry/rotation are tested before planned outages.
5. Rollback returns to the no-mesh path without stranding traffic.
6. The selected mesh does not become a hidden requirement for ingress, DNS,
   Flannel, persistent storage, or worker recovery.

Until then, the repository must contain no mesh manifests, CRDs, Helm
repositories, injected workload annotations, mesh secrets, or mesh operators.

## References

- [Linkerd automatic mTLS and identity certificates](https://linkerd.io/docs/features/automatic-mtls/)
- [Linkerd control-plane and trust-anchor rotation](https://linkerd.io/2.18/tasks/automatically-rotating-control-plane-tls-credentials/)
- [Linkerd outage behavior](https://linkerd.io/faq/)
- [Istio ambient overview](https://istio.io/latest/docs/ambient/overview/)
- [Istio ambient control-plane architecture](https://istio.io/latest/docs/ambient/architecture/control-plane/)
- [Istio ambient data-plane identity](https://istio.io/latest/docs/ambient/architecture/data-plane/)
