# Offline-control-plane operating model

## Cube powered off

Usually continues: already-running containers, kubelet/container-runtime
restarts for already-assigned Pods, pod-to-pod traffic through Flannel, and
Service routing rules already programmed on workers. LAN clients can reach a
workload only if its path uses a Pi address/host port and the workload itself
does not need a missing dependency.

Stops or degrades: Kubernetes API calls, scheduling, new reconciliation,
rolling updates, admission, new Service/Endpoint programming, controller
repair, cluster DNS changes, secret/config rollout, and certificate/token
rotation driven by the server. New Pods requiring API admission should be
treated as unavailable. This is not a promise that every kubelet restart is
offline-safe.

## When Cube returns

Workers retry the stable API endpoint automatically. The server reads its
persistent datastore and reconciles observed state. Expect stale status and
bursty reconciliation while nodes reconnect. Inspect Events and controller
logs; do not assume a successful TCP connection proves workload convergence.

## Failure cases

- Worker reboot during outage: local Pods return only if their runtime and
  volumes recover without API-dependent setup; test this explicitly.
- Worker loss: its Pods are not rescheduled elsewhere until control-plane
  reconciliation resumes; there is no HA guarantee.
- CNI state: existing VXLAN state may continue, but a reboot or changed
  interfaces can require the server for reprogramming.
- DNS: LAN DNS and open connections are separate from cluster DNS. Avoid
  hard-coding fragile names in long-running edge processes.
- Ingress: only a Pi-local/redundant ingress path survives Cube loss.
- Persistent storage: local volumes are node-bound; a Pi loss is data loss
  unless the application has its own backup/replication design.
- Certificates: expired kubelet, API, TLS, or workload certificates can stop
  recovery; monitor expiry before planned Cube downtime.
- Service mesh identity: a mesh may require control-plane-issued identity;
  outages and expiry must be proven before adoption.

There is no implication of HA, automatic failover of the control plane, or
safe arbitrary mutation while Cube is unavailable.
