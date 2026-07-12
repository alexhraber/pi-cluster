# Future redundant ingress design

Status: design-complete, not installed.

This document selects the future north-south HTTP(S) path for workloads that
are intentionally exposed to the LAN. It is a deployment contract, not proof
that the physical LAN or Raspberry Pis are ready. The base cluster remains
usable without ingress.

## Decision

Use two replicas of the open-source Traefik Kubernetes ingress controller,
pinned to `pi-01` and `pi-02`. Expose the controller through the same fixed
NodePorts on both workers:

| Protocol | NodePort | LAN targets |
|---|---:|---|
| HTTP | 30080 | `pi-01.lan`, `pi-02.lan` |
| HTTPS | 30443 | `pi-01.lan`, `pi-02.lan` |

LAN DNS publishes both Pi addresses for the selected ingress name. Clients
must tolerate trying the second address when one Pi is unavailable. The LAN
router remains the default gateway; Cube is never a transit hop, virtual IP
owner, NAT device, or ingress dependency.

The eventual controller configuration must include:

- an explicit IngressClass or GatewayClass owned by this installation;
- two replicas with required anti-affinity and node selectors for `pi-01` and
  `pi-02`;
- `externalTrafficPolicy: Local` so the controller can preserve the client
  source address and avoid forwarding a request to a remote node;
- bounded CPU and memory requests/limits, with the limits below as the first
  measurement budget;
- readiness and liveness probes that test the controller process, plus a LAN
  check that tests each fixed Pi address independently;
- no dashboard or public management endpoint;
- explicit route allow-listing and TLS policy per workload;
- a documented removal command and a rollback to the prior NodePort/direct
  diagnostic path.

Traefik is selected because it supports the Kubernetes Ingress contract and
can watch Kubernetes resources through its in-cluster service account. Its
last accepted dynamic configuration can continue serving while the API
server is unavailable; a later configuration change cannot reconcile until
Cube returns. The selection does not grant a claim about unmeasured Pi
performance.

## Alternatives considered

| Candidate | Decision | Reason in this cluster |
|---|---|---|
| Traefik OSS | **Selected for a future install** | One small controller image, native Kubernetes Ingress/Gateway options, two ordinary replicas, and no separate control-plane product. Requires measuring RSS and reload behavior on the real Pis. |
| Ingress-NGINX | Rejected for new work | Familiar and capable, but the upstream project documents retirement and the end of security fixes after March 2026. It is not a suitable new foundation for this repository. |
| HAProxy Ingress | Deferred alternative | A credible low-overhead option, but it introduces a second controller choice without a measured advantage in this cluster. Reconsider only if the Traefik gate fails or HAProxy wins a repeatable Pi benchmark. |
| Host-level HAProxy/NGINX | Rejected as the primary path | It can be very small, but configuration, TLS, and backend discovery would leave Kubernetes ownership and create a second declaration/control path. It remains a diagnostic escape hatch, not the production contract. |
| Cube-owned VIP or reverse proxy | Rejected | It violates the offline-control-plane requirement and makes LAN exposure unavailable whenever Cube is powered off. |
| MetalLB or another load-balancer/operator stack | Deferred | It adds another control-plane-dependent component and is unnecessary while clients can target two fixed Pi addresses. |

## Resource and measurement gate

No physical resource measurement exists yet. The following are explicit
acceptance thresholds for the first installation, not claims about current
usage:

| Budget per Traefik replica | Initial value |
|---|---:|
| CPU request / limit | 25m / 200m |
| Memory request / limit | 48Mi / 128Mi |
| Idle RSS target | <= 64Mi after 10 minutes |
| Loaded RSS ceiling | <= 96Mi during the representative HTTP(S) test |
| Controller restart budget | no more than 1 unexpected restart during a 30-minute test |

Before installation, run a representative route test on Pi 3B+ hardware with
the repository's actual image, TLS mode, access-log setting, and expected
number of routes. Record container RSS, node available memory, CPU, request
latency, error rate, and behavior during API loss. Do not hide memory pressure
by setting an unlimited limit. If either replica exceeds the loaded RSS
ceiling, causes node memory pressure, or fails the offline test, stop and
re-evaluate Traefik against HAProxy Ingress before exposing a workload.

These limits are intentionally conservative for a 1 GB node, but they are
not a capacity guarantee. Workload requests and the controller budget must be
considered together.

## Placement, reachability, and source addresses

The controller service will use fixed NodePorts on `pi-01` and `pi-02`. The
LAN ingress hostname should resolve to both fixed addresses; it must not
resolve only to Cube and must not depend on cluster DNS. During the initial
deployment, operators should verify:

```text
LAN client -> pi-01 address:30080/30443 -> local Traefik replica -> Service
LAN client -> pi-02 address:30080/30443 -> local Traefik replica -> Service
```

`externalTrafficPolicy: Local` means a request sent to a node without a local
ready controller endpoint is not silently forwarded to another worker. DNS
health checking therefore matters: remove an unhealthy Pi from the LAN DNS
answer set, or require clients to retry the alternate address. DNS TTL must
be short enough for the LAN's failure expectations, but DNS is not a
substitute for an active health-check system.

The first implementation should use the LAN's existing DNS and DHCP/router
facilities. Do not add ExternalDNS, MetalLB, keepalived, or another operator
until a measured failure mode requires it and a separate issue approves it.

## Cube-off behavior

When Cube is off, an already-running Traefik replica can continue serving its
last accepted configuration, and the two fixed Pi paths remain independent
of the Kubernetes API. Existing Service and CNI state on the workers is part
of that path. The following stop or degrade until Cube returns:

- creating or changing Ingress/Gateway resources;
- controller discovery of new Services, EndpointSlices, or TLS Secrets;
- scheduling or replacing a controller Pod after a worker failure;
- certificate issuance or rotation that requires a controller/API workflow;
- Kubernetes status updates and reconciliation evidence.

A worker reboot during the outage is not promised to recover the ingress Pod:
the local runtime may restart an already-assigned container, but Kubernetes
reconciliation and a replacement assignment require the API. The surviving
ingress Pi should continue serving. If both ingress Pis are lost, LAN ingress
is unavailable until at least one returns and the workload/controller state
is recoverable.

When Cube returns, workers reconnect to the stable API address. The controller
reconciles current resources and may reload configuration in a burst. Inspect
Ingress/Gateway status, EndpointSlices, controller logs, and LAN probes; a
successful API connection alone is not convergence proof.

This is redundant ingress, not highly available Kubernetes control plane. It
does not reschedule workloads during a Cube outage, replicate persistent data,
or make a lost Pi's local volumes available elsewhere.

## TLS and source-address policy

TLS terminates at Traefik only for explicitly approved hostnames. The private
key and certificate are supplied as an encrypted Kubernetes Secret declaration
or an operator-approved recovery procedure. Plaintext keys, kubeconfigs,
tokens, and raw backups never enter Git. The ingress TLS Secret must be
included in the backup/restore rehearsal before the first production route.

Automatic certificate issuance is deferred. During the first deployment use a
known-good certificate and test expiry/replacement while Cube is available;
do not assume renewal succeeds during an outage. The selected policy must
preserve client source addresses at the controller boundary and must document
which proxy headers are trusted from the LAN.

## Installation gate and proof

This design is complete only as a repository decision. Installation requires a
separate approved change after the Day-0 checklist is physically verified.
That change must include pinned image/chart versions, rendered manifests,
resource values, TLS secret recovery evidence, and a rollback command.

The minimum physical proof is:

1. Both fixed Pi addresses answer the health endpoint independently.
2. A LAN client reaches the same selected workload through either address.
3. The client source address is recorded at the ingress boundary.
4. Powering off Cube does not interrupt existing requests or established
   routing; a planned configuration change correctly waits for Cube.
5. Rebooting one ingress Pi leaves the other path usable.
6. Removing one Pi from LAN DNS prevents new clients from being pinned to the
   failed address, subject to the documented DNS TTL.
7. Returning Cube produces expected controller and EndpointSlice reconciliation
   without duplicate or stale routes.

Until those tests are recorded, the repository should continue to describe
ingress as deferred and should not expose a production workload.

## Reference material

- [Traefik Kubernetes Ingress provider](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Traefik Kubernetes setup](https://doc.traefik.io/traefik/master/setup/kubernetes/)
- [Ingress-NGINX retirement notice](https://kubernetes.github.io/ingress-nginx/)
