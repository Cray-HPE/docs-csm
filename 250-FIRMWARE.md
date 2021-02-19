## Warning

**WARNING:** Non-compute nodes (NCNs) should be locked with the HSM locking API to ensure they are not unintentionally updated by FAS. Research "*009-NCN-LOCKING*" for more information. Failure to lock the NCNs could result in unintentional update of the NCNs if FAS is not used correctly; this will lead to system instability problems.

# Node Firmware

Firmware and BIOS updates may be necessary before an install can start.

During runtime (e.g. post CSM-install), firmware is upgraded using FAS.

New systems, or systems upgrading from prior versions of shasta, must meet the minimum specs defined in these pages:
- [Network Firmware](251-FIRMWARE-NETWORK.md)
- [Node Firmware](252-FIRMWARE-NODE.md)

> **`NOTE`** Only network devices and non-compute nodes upgrade firmware prior to a shasta-1.4.x install or upgrade. Other devices, such as compute nodes, provision upgrades from [FAS](#firmware-action-service-for-runtime).

## LiveCD Availability for Bootstrap

The LiveCD serves firmware for bootstrapping devices and servers to enable a CRAY install.

Devices can use SCP or HTTP to fetch firmware from the LiveCD USB stick, or from the remote ISO.

- http://pit/fw/
- http://pit.nmn/fw/
- http://pit.hmn/fw/
- http://pit.can/fw/
- `scp://<username>:<password>@pit/var/www/fw/`

> Any interface of the LiveCD may be used in place of the above DNS names.

## Firmware Action Service for Runtime

The Firmware Action Service (FAS) tracks and performs actions (upgrade, downgrade, restore, create.snapshot) on system firmware.

FAS is a runtime service deployed in Kubernetes.

#### Fresh Install

Fresh installs on bare-metal use FAS for upgrading compute node firmware.