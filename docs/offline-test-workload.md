# Offline-control-plane test workload

This is a design and test procedure only. It is intentionally outside the
default Kubernetes manifest root and must not be applied until the operator
approves a physical-cluster test window. It does not establish HA, automatic
rescheduling, or safe arbitrary worker reboots.

## Test artifacts

The manifests are under `kubernetes/tests/offline-control-plane/`:

- `offline-http-probe`: one small ARM64-compatible Nginx Pod exposed as
  NodePort 30080.
- `offline-persistence-probe`: one Pod pinned to `pi-01`, writing timestamps
  to a retained local volume at `/var/lib/pi-cluster/validation/persistence`.

The local volume is deliberately node-owned. It is a test of persistence and
loss semantics, not distributed storage.

## Preparation (future execution only)

1. Complete the Pi preflight checklist for all four workers.
2. Confirm the LAN plan and choose a Pi address for the NodePort test.
3. On pi-01, create and permission the local-volume path on the selected
   persistent filesystem; do not use this test to create production data.
4. Review image architecture, resource limits, NodePort policy, and the
   test-window rollback plan.
5. Render the manifests and inspect them before applying:

   `kubectl kustomize kubernetes/tests/offline-control-plane/`

6. Apply only during the approved test window:

   `kubectl apply -k kubernetes/tests/offline-control-plane/`

## Baseline proof

Record:

```bash
kubectl -n edge-validation get pods -o wide
kubectl -n edge-validation get svc,pv,pvc
curl --fail http://pi-01.lan:30080/
kubectl -n edge-validation exec deploy/offline-persistence-probe -- tail -n 3 /data/heartbeat.log
```

The HTTP request must succeed through a fixed Pi LAN address. The persistence
probe must be Running on pi-01 and show increasing timestamps.

## Cube-off test

1. Capture baseline Pod, node, Service, EndpointSlice, and event output.
2. Power Cube off through the planned operator procedure.
3. Every 30 seconds for at least 10 minutes, record the HTTP response and
   timestamp. Existing HTTP traffic should remain reachable through the Pi
   NodePort while the Pod and node stay healthy.
4. Do not run kubectl mutations during the outage. API access, scheduling,
   new reconciliation, and Endpoint programming are expected to be absent.
5. A failure of the already-running workload is a test failure, not evidence
   of HA; record whether the cause is Pod, node, CNI, DNS, or ingress state.

## Worker-reboot test during outage

With Cube still off, reboot pi-01 only if the test window explicitly accepts
the risk. Record HTTP behavior, Pod/container recovery, and the persistence
file after the node returns. Success means the expected workload returns with
its data intact; failure is an expected possible outcome that must be
classified. The test must not claim that Kubernetes can reschedule while Cube
is absent.

## Cube-return reconciliation

1. Boot Cube and wait for the stable API endpoint.
2. Wait for all four workers to reconnect.
3. Inspect Pods, EndpointSlices, node conditions, and sorted Events.
4. Confirm the local volume remains owned by pi-01 and that no unexpected Pod
   was scheduled on Cube.
5. Remove the test namespace and retained test volume after exporting the
   evidence; do not leave test state as an undeclared workload.

## Acceptance criteria

- Manifests render without applying them.
- Resource requests and limits are explicit and small enough for 1 GB Pis.
- LAN HTTP reachability, local persistence, Cube-off behavior, worker reboot,
  and post-return reconciliation each have measurable evidence.
- Any failure is classified rather than hidden behind a retry.
- No result implies control-plane HA or automatic failover.
