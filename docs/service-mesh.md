# Service-mesh evaluation (not installed)

The decision criterion is measured resident memory and failure behavior on
1 GB Pi 3B+ nodes, not popularity. Establish a baseline with the chosen K3s
version, then measure idle and loaded RSS, CPU, Pod startup latency, and
control-plane-offline behavior over a representative workload set.

| Option | Expected shape | Control-plane concern | Initial decision |
|---|---|---|---|
| No mesh | zero proxy/control-plane overhead | none | **Recommended now** |
| Linkerd | lightweight per-Pod proxy plus control plane | identity/policy/telemetry recovery must be tested | Re-evaluate after baseline |
| Istio ambient | node/namespace dataplane plus control plane | ambient components and identity still need recovery proof | Re-evaluate only with measured budget |
| Istio sidecars | proxy per Pod | likely too expensive and multiplies memory pressure | Defer/reject for Pi 3B+ |

No mesh is the only option whose offline behavior is already represented by
the base K3s design. A later proposal must include measured per-node headroom,
identity TTL/rotation, behavior when the control plane is absent, and a
rollback that does not strand traffic.
