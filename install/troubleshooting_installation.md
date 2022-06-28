# Troubleshooting Installation Problems

The installation of the Cray System Management (CSM) product requires knowledge of the various nodes and
switches for the HPE Cray EX system. The procedures in this section should be referenced during the CSM install
for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

## Topics

1. [Reset root Password on a LiveCD USB](#reset-root-password-on-a-livecd-usb)
1. [PXE Boot Troubleshooting](#pxe-boot-troubleshooting)
1. [Restart Network Services and Interfaces on NCNs](#restart-network-services-and-interfaces-on-ncns)
1. [Utility Storage Node Installation Troubleshooting](#utility-storage-node-installation-troubleshooting)
1. [Ceph CSI Troubleshooting](#ceph-csi-troubleshooting)
1. [Postgres Troubleshooting](#postgres-troubleshooting)

## Reset `root` password on a LiveCD USB

If the `root` password on the LiveCD needs to be changed, then this procedure does the reset.

See [Reset root Password on a LiveCD USB](livecd/Reset_root_Password_on_a_LiveCD_USB.md)

## PXE Boot Troubleshooting

If a reinstall of the PIT node is needed, the data from the PIT node can be saved to the LiveCD USB and
the LiveCD USB can be rebuilt.

See [PXE Boot Troubleshooting](troubleshooting_pxe_boot.md)

## Restart Network Services and Interfaces on NCNs

If an NCN shows any of these problems, the network services and interfaces on that node might need to be restarted.

- Interfaces not showing up
- IP Addresses not applying
- Member/children interfaces not being included

See [Restart Network Services and Interfaces on NCNs](../operations/node_management/NCN_Network_Troubleshooting.md)

## Utility Storage Node Installation Troubleshooting

If there is a failure in the creation of Ceph storage on the utility storage nodes for one of these scenarios,
the Ceph storage might need to be reinitialized.

- Sometimes a large OSD can be created which is a concatenation of multiple devices, instead of one OSD per device

See [Utility Storage Node Installation Troubleshooting](troubleshooting_utility_storage_node_installation.md)

## Ceph CSI Troubleshooting

If there has been a failure to initialize all Ceph CSI components on `ncn-s001`, then the storage node
`cloud-init` may need to be rerun.

- Verify Ceph CSI
- Rerun Storage Node `cloud-init`

See [Ceph CSI Troubleshooting](troubleshooting_ceph_csi.md)

## Postgres Troubleshooting

- Timeout on `cray-sls-init-load` during Install CSM Services due to Postgres cluster in `SyncFailed` state

See [Troubleshoot Postgres Database](../operations/kubernetes/Troubleshoot_Postgres_Database.md#postgres-status-syncfailed)
