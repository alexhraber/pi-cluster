# Controlled first-start runbook

This is the execution order for the first physical cluster startup. It is not
authorization to power on hardware. Stop if any precondition or verification
step fails. Do not substitute successful node registration for offline
durability, storage recovery, ingress redundancy, or service-mesh proof.

## Entry gate

Before step 1, the operator must have:

- every blocking row in the Day-0 readiness document marked
  PHYSICALLY-VERIFIED with linked evidence;
- explicit human startup approval and a named recovery contact;
- final image hashes, LAN reservations, encrypted secret/recovery-key access,
  pinned K3s version, and backup destination;
- an evidence directory outside Git with restricted permissions.

If any item is missing, record BLOCKED and stop. The repository cannot infer
physical approval from a passing CI run.

## Ordered procedure

1. Start Cube only. Do not start the Pis or deploy workloads.
2. From a trusted admin host, confirm cube.lan, TCP 6443, the pinned K3s
   version, API/TLS identity, datastore mount, server token secret, and the
   node-role.kubernetes.io/control-plane:NoSchedule taint. Run:

   ~~~bash
   EVIDENCE_DIR=/path/outside/repo/cube-first-start ./scripts/verify-cube.sh
   ~~~

   Ordinary workloads must never be placed on Cube.

3. Start only pi-01. Confirm its image hash, hostname, ARM64 architecture,
   cgroup mode, storage, time, network identity, and hardware-only preflight.
   Apply nixos-rebuild switch --flake .#pi-01 only after that evidence is
   accepted. Enable/join the K3s agent, then verify its stable node name,
   arm64 label, Flannel pod, and local runtime.
4. Repeat step 3 for pi-02, pi-03, and pi-04, one node at a time. A failed
   node is removed from the sequence; do not proceed by weakening a check.
5. After all four workers are Ready, run verify-cluster.sh again and retain
   the node, CNI, pod, and event evidence. Confirm Cube is unschedulable and
   all four worker architecture labels are arm64.
6. Take the first encrypted backup and independently run
   verify-k3s-backup.sh. Record its destination, digest, K3s version, and
   recovery-key access outside Git.
7. Deploy only the existing offline-control-plane test workload. During its
   test window, run verify-offline.sh with
   CONFIRM_CUBE_POWEROFF=YES and an evidence directory. Verify the workload
   remains reachable and that an already-assigned container can restart locally
   while Cube is off.
8. Boot Cube, run verify-reconnect.sh, inspect events, and record the
   reconciliation interval. Then run verify-worker-reboot.sh for one worker
   during a separate planned outage with explicit confirmation.
9. Only after all evidence passes may the test workload remain. Ingress,
   service mesh, operators, distributed storage, and production workloads stay
   deferred.

## Stop conditions and recovery

Stop for API/TLS mismatch, missing token or backup, wrong architecture/name,
missing Flannel, ordinary Cube workload, failed reachability, unexpected
storage mutation, node loss, or unreconciled events. Restore from the tested
backup only in an isolated compatible-version environment first; never restore
over live /var/lib/rancher/k3s as part of this runbook. A NixOS rollback is not
a Kubernetes datastore rollback.

## Proof boundary

This runbook and its scripts prove an executable procedure and safety gates.
They do not prove that the physical cluster works. Physical completion requires
the real four-node evidence bundle, backup/recovery evidence, outage and reboot
drills, and explicit operator sign-off.
