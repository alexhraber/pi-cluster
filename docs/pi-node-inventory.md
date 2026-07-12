# Node inventory

Fill one row for Cube and one row per Pi after physical inspection. Keep
operator credentials, secret material, raw command output, and private network
details that are not needed for reproducibility outside Git.

| Node | Board | ARM64 image/build | Kernel | Firmware | MAC | Proposed IP | Actual IP | Boot/data media | Root free space | Power/cooling evidence | Preflight date | Operator | Status |
|---|---|---|---|---|---|---|---|---|---:|---|---|---|---|
| cube | x86_64 NixOS workstation | N/A | TBD | TBD | TBD | 192.168.50.10 | TBD | Internal SSD/NVMe TBD | TBD | TBD | TBD | TBD | BLOCKED |
| pi-01 | Raspberry Pi 3B+ | TBD | TBD | TBD | TBD | 192.168.50.11 | TBD | TBD | TBD | TBD | TBD | TBD | BLOCKED |
| pi-02 | Raspberry Pi 3B+ | TBD | TBD | TBD | TBD | 192.168.50.12 | TBD | TBD | TBD | TBD | TBD | TBD | BLOCKED |
| pi-03 | Raspberry Pi 3B+ | TBD | TBD | TBD | TBD | 192.168.50.13 | TBD | TBD | TBD | TBD | TBD | TBD | BLOCKED |
| pi-04 | Raspberry Pi 3B+ | TBD | TBD | TBD | TBD | 192.168.50.14 | TBD | TBD | TBD | TBD | TBD | TBD | BLOCKED |

`BLOCKED` is intentional until the actual hardware, LAN reservation, and
preflight evidence exist. The proposed addresses come from
[the LAN plan](../networking/lan-plan.md) and still require confirmation.

## Collection procedure

Run the read-only collector locally on each machine after the intended image
boots, before enabling or joining K3s:

```bash
INSPECTOR=<operator> EXPECTED_NODE=pi-01 scripts/collect-node-inventory.sh \
  | tee /tmp/pi-01-inventory.txt
```

Use `EXPECTED_NODE=cube` on Cube. Keep the raw output in the operator evidence
store, review it for unnecessary serial/address detail, and copy only the
sanitized facts needed to complete the table. The collector does not write
devices, enable services, change networking, read secrets, or contact the
Kubernetes API.

The output is evidence, not automatic acceptance. Independently compare:

- the MAC address to the router/DHCP reservation;
- the board model, revision, and firmware to the physical board;
- the block-device identity and capacity to the labeled media;
- the power supply, cable, enclosure, cooling, and switch port by inspection;
- the actual address and hostname to the intended inventory row.

Do not mark a row `PHYSICALLY-VERIFIED` from command output alone. Attach the
inspection date, operator, sanitized output hash, reservation evidence, and
power/cooling/media evidence. Any disagreement or missing field remains
`BLOCKED`.
