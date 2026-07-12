# Day-0 readiness gate

This is the canonical go/no-go checklist before powering on or provisioning
Cube or any Raspberry Pi for this project. It distinguishes repository design
from physical proof. Every blocking row must have an owner, a completed status,
and linked evidence before startup approval is granted.

## Status vocabulary

- `DESIGN-COMPLETE` — repository contract exists; hardware/runtime proof is
  still absent.
- `PROVISIONED` — the specific external resource or configuration was created.
- `PHYSICALLY-VERIFIED` — evidence was collected from the real hardware/LAN.
- `BLOCKED` — required evidence or an owner is missing; startup is prohibited.
- `NOT-REQUIRED` — intentionally deferred and not a prerequisite for base
  cluster startup.

The initial repository state is intentionally mostly `BLOCKED`. Do not replace
that status with optimism or an inferred result.

## Canonical checklist

| Area | Owner | Status | Required evidence | Blocks startup? |
|---|---|---|---|---|
| LAN subnet, fixed addresses, DHCP reservations, and DNS | Unassigned | BLOCKED | Confirmed reservation table and DNS resolution for Cube and all Pis | Yes |
| sops-nix mechanism and age recovery access | Unassigned | DESIGN-COMPLETE / BLOCKED | Encrypted cluster payload, tested decryption, private-key recovery path | Yes |
| Cube OS and persistent K3s storage | Unassigned | DESIGN-COMPLETE / BLOCKED | Hardware/media inventory and mounted persistent target | Yes |
| Pi boot/data media and power/cooling | Unassigned | DESIGN-COMPLETE / BLOCKED | Inventory for each Pi and physical inspection evidence | Yes |
| ARM64 image/build process | Unassigned | DESIGN-COMPLETE / BLOCKED | Reproducible image/build result and selected image identifier | Yes |
| Cube NixOS/K3s server configuration | Unassigned | DESIGN-COMPLETE / BLOCKED | Evaluated configuration, pinned K3s version, stable API address | Yes |
| pi-01 worker configuration | Unassigned | DESIGN-COMPLETE / BLOCKED | Node-specific build/configuration and preflight evidence | Yes |
| pi-02 worker configuration | Unassigned | DESIGN-COMPLETE / BLOCKED | Node-specific build/configuration and preflight evidence | Yes |
| pi-03 worker configuration | Unassigned | DESIGN-COMPLETE / BLOCKED | Node-specific build/configuration and preflight evidence | Yes |
| pi-04 worker configuration | Unassigned | DESIGN-COMPLETE / BLOCKED | Node-specific build/configuration and preflight evidence | Yes |
| K3s version and upgrade/rollback procedure | Unassigned | DESIGN-COMPLETE | Version policy, lockfile review, and upgrade backup procedure | Yes |
| Verification scripts and test evidence plan | Unassigned | DESIGN-COMPLETE | Local validation output and approved physical-test procedure | Yes |
| Backup destination and restore path | Unassigned | DESIGN-COMPLETE / BLOCKED | Encrypted destination, age-key recovery, and restore-test record | Yes |
| Rollback and recovery contacts | Unassigned | BLOCKED | Named operator, recovery contact, and escalation path | Yes |
| Explicit physical-startup approval | Unassigned | BLOCKED | Human approval recorded after all blocking rows are verified | Yes |

## Current repository evidence

The following are design evidence, not physical readiness:

- [LAN plan](../networking/lan-plan.md)
- [Secret contract](secrets.md)
- [Storage and recovery contract](storage.md)
- [Pi preflight checklist](pi-preflight.md)
- [Validation commands](validation.md)
- [Offline-control-plane test design](offline-test-workload.md)
- [K3s version policy](../k3s/version-policy.md)
- [Service-mesh evaluation](service-mesh.md)
- [Future ingress design](../ingress/design.md)
- [Node inventory worksheet](pi-node-inventory.md)

Repository validation and CI passing do not change a physical row to
`PHYSICALLY-VERIFIED`.

## Downstream decision tracks

The readiness gate affects the execution of these open issues:

- [#16 ARM64 image and provisioning path](https://github.com/alexhraber/pi-cluster/issues/16)
- [#17 future redundant ingress selection](https://github.com/alexhraber/pi-cluster/issues/17)
- [#18 service-mesh measurement and decision](https://github.com/alexhraber/pi-cluster/issues/18)

Issues #16–#18 may perform design work in safe environments, but physical
provisioning, ingress deployment, or mesh experiments require this checklist
to be complete and explicitly approved. Ingress and service mesh are not
required to start the base cluster and remain deferred.

## Startup rule

Do not power on Cube or any Pi for cluster startup, enable K3s, create/join a
cluster, or deploy a workload until every row marked “Yes” has a named owner,
status `PHYSICALLY-VERIFIED`, and evidence recorded. If evidence is missing,
the correct action is to remain blocked.
