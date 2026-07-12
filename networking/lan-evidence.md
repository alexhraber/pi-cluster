# LAN verification evidence

This is an operator evidence template, not a claim that the proposed LAN is
available. Replace every proposed value with the actual verified value before
startup. Keep router credentials, private keys, and unrelated household or
corporate network data outside Git.

## Automated checks

Run from the intended admin network after the nodes have booted but before
K3s is enabled:

```bash
CUBE_IP=<verified-cube-ip> \
PI_IPS=<verified-pi-01-ip>,<verified-pi-02-ip>,<verified-pi-03-ip>,<verified-pi-04-ip> \
scripts/check-lan-prerequisites.sh
```

After Cube's NixOS configuration is active, repeat with `MODE=api` to test
TCP 6443:

```bash
MODE=api CUBE_IP=<verified-cube-ip> \
PI_IPS=<verified-pi-01-ip>,<verified-pi-02-ip>,<verified-pi-03-ip>,<verified-pi-04-ip> \
scripts/check-lan-prerequisites.sh
```

The script checks exact DNS answers, local routes, ICMP reachability, optional
admin-host NTP, and the API port in API mode. It deliberately prints manual
requirements for DHCP, firewall, switch topology, and UDP VXLAN rather than
claiming those facts from a local route check.

## Required network matrix

| Protocol/port | Source | Destination | Purpose | Evidence |
|---|---|---|---|---|
| TCP 6443 | all agents | Cube | K3s supervisor/API | Firewall rule and API-mode script output |
| UDP 8472 | all five nodes | all five nodes | Flannel VXLAN | Firewall rule plus node-pair test |
| TCP 10250 | all nodes | all nodes | Optional metrics-server/kubelet access | Not required until metrics are approved |
| TCP 2379-2380 | none | none | HA embedded etcd only | Must remain closed; this is not HA |

K3s's selected Flannel VXLAN backend requires node-to-node UDP 8472. Keep it
restricted to the trusted LAN; do not expose it to the broader network.

## Operator evidence record

| Fact | Verified value/evidence | Date | Operator |
|---|---|---|---|
| LAN subnet and router | TBD | TBD | TBD |
| Cube DHCP reservation | TBD | TBD | TBD |
| pi-01 DHCP reservation | TBD | TBD | TBD |
| pi-02 DHCP reservation | TBD | TBD | TBD |
| pi-03 DHCP reservation | TBD | TBD | TBD |
| pi-04 DHCP reservation | TBD | TBD | TBD |
| DNS answers from admin network | TBD | TBD | TBD |
| TCP 6443 firewall path | TBD | TBD | TBD |
| UDP 8472 node-pair path | TBD | TBD | TBD |
| Switch ports/topology | TBD | TBD | TBD |
| NTP on Cube and Pis | TBD | TBD | TBD |

Do not mark the LAN Day-0 row `PHYSICALLY-VERIFIED` until the table has
external reservation/firewall evidence and the automated output hash recorded
in the operator evidence store.
