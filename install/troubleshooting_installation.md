# Troubleshooting Installation Problems

The installation of the Cray System Management (CSM) product requires knowledge of the various nodes and
switches for the HPE Cray EX system. The procedures in this section should be referenced during the CSM install
for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

## Topics

- [Reset `root` password on a LiveCD USB](#reset-root-password-on-a-livecd-usb)
- [PXE boot troubleshooting](#pxe-boot-troubleshooting)
- [Restart network services and interfaces on NCNs](#restart-network-services-and-interfaces-on-ncns)
- [Utility storage node installation troubleshooting](#utility-storage-node-installation-troubleshooting)
- [Ceph CSI troubleshooting](#ceph-csi-troubleshooting)
- [Postgres troubleshooting](#postgres-troubleshooting)

## Reset `root` password on a LiveCD USB

If the `root` password on the LiveCD needs to be changed, then see
[Reset `root` Password on a LiveCD USB](livecd/Reset_root_Password_on_a_LiveCD_USB.md).

## PXE boot troubleshooting

See [Troubleshooting PXE Boot](troubleshooting_pxe_boot.md).

## Restart network services and interfaces on NCNs

If an NCN shows any of these problems, then the network services and interfaces on that node might need to be restarted:

- Interfaces not showing up
- IP addresses not applying
- Member/child interfaces not being included

See [Restart network services and interfaces on NCNs](../operations/node_management/NCN_Network_Troubleshooting.md#restart-network-services-and-interfaces).

## Utility storage node installation troubleshooting

Rarely, a Ceph OSD pool fails to enable an application. If `cloud-init` on `ncn-s001` is stuck 'Sleeping for five seconds waiting Ceph to be healthy...',
then it may be necessary to manually enable the Ceph pool application.

See [Troubleshooting Utility Storage Node Installation](troubleshooting_utility_storage_node_installation.md).

## Ceph CSI troubleshooting

If there has been a failure to initialize all Ceph CSI components on `ncn-s001`, then the storage node
`cloud-init` may need to be rerun.

See [Troubleshooting Ceph CSI](troubleshooting_ceph_csi.md).

## Postgres troubleshooting

- Timeout on `cray-sls-init-load` during Install CSM Services due to Postgres cluster in `SyncFailed` state

See [Postgres status `SyncFailed`](../operations/kubernetes/Troubleshoot_Postgres_Database.md#postgres-status-syncfailed).
