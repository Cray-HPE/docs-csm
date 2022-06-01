# Troubleshooting Installation Problems

The installation of the Cray System Management (CSM) product requires knowledge of the various nodes and
switches for the HPE Cray EX system. The procedures in this section should be referenced during the CSM install
for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

## Topics

   1. [Reset root Password on LiveCD](#reset_root_password_on_LiveCD)
   1. [Reinstall LiveCD](#reinstall_livecd)
   1. [PXE Boot Troubleshooting](#pxe_boot_troubleshooting)
   1. [Wipe NCN Disks for Reinstallation](#wipe_ncn_disks_for_reinstallation)
   1. [Restart Network Services and Interfaces on NCNs](#restart_network_services_and_interfaces_on_ncns)
   1. [Utility Storage Node Installation Troubleshooting](#utility_storage_node_installation_troubleshooting)
   1. [Ceph CSI Troubleshooting](#ceph_csi_troubleshooting)
   1. [Safeguards for CSM NCN Upgrades](#safeguards_for_csm_ncn_upgrades)
   1. [Postgres Troubleshooting](#postgres_troubleshooting)
   1. [CSM Services Install Fails Because of Missing Secret](#csm_installation_failure_missing_secret)

## Details

   <a name="reset_root_password_on_LiveCD"></a>

   1. Reset root Password on LiveCD

      If the root password on the LiveCD needs to be changed, then this procedure does the reset.

      See [Reset root Password on LiveCD](reset_root_password_on_LiveCD.md)
   <a name="reinstall_livecd"></a>

   1. Reinstall LiveCD

      If a reinstall of the PIT node is needed, the data from the PIT node can be saved to the LiveCD USB and
      the LiveCD USB can be rebuilt.

      See [Reinstall LiveCD](reinstall_livecd.md)
   <a name="pxe_boot_troubleshooting"></a>

   1. PXE Boot Troubleshooting

      If a reinstall of the PIT node is needed, the data from the PIT node can be saved to the LiveCD USB and
      the LiveCD USB can be rebuilt.

      See [PXE Boot Troubleshooting](pxe_boot_troubleshooting.md)
   <a name="wipe_ncn_disks_for_reinstallation"></a>

   1. Wipe NCN Disks for Reinstallation

      If it has been determined an NCN did not properly configure its storage while trying to
      [Deploy Management Nodes](deploy_management_nodes.md) during the install, then the
      storage should be wiped so the node can be redeployed.

      See [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md)
   <a name="restart_network_services_and_interfaces_on_ncns"></a>

   1. Restart Network Services and Interfaces on NCNs

      If an NCN shows any of these problems, the network services and interfaces on that node might need to be restarted.
         * Interfaces not showing up
         * IP Addresses not applying
         * Member/children interfaces not being included

      See [Restart Network Services and Interfaces on NCNs](restart_network_services_and_interfaces_on_ncns.md)
   <a name="utility_storage_node_installation_troubleshooting"></a>

   1. Utility Storage Node Installation Troubleshooting

      If there is a failure in the creation of Ceph storage on the utility storage nodes for one of these scenarios,
      the Ceph storage might need to be reinitialized.
         * Sometimes a large OSD can be created which is a concatenation of multiple devices, instead of one OSD per device

      See [Utility Storage Node Installation Troubleshooting](utility_storage_node_installation_troubleshooting.md)
   <a name="ceph_csi_troubleshooting"></a>

   1. Ceph CSI Troubleshooting

      If there has been a failure to initialize all Ceph CSI components on `ncn-s001`, then the storage node
      `cloud-init` may need to be rerun.
         * Verify Ceph CSI
         * Rerun Storage Node `cloud-init`

      See [Ceph CSI Troubleshooting](ceph_csi_troubleshooting.md)
   <a name="safeguards_for_csm_ncn_upgrades"></a>

   1. Safeguards for CSM NCN Upgrades

      If a reinstall or upgrade is being done, there might be a reason to use one of these safeguards.
         * Preserve Ceph on Utility Storage Nodes
         * Protect RAID Configuration on Management Nodes

      See [Safeguards for CSM NCN Upgrades](safeguards_for_csm_ncn_upgrades.md)

   <a name="postgres_troubleshooting"></a>

   1. Postgres Troubleshooting

      * Timeout on `cray-sls-init-load` during Install CSM Services due to Postgres cluster in `SyncFailed` state

      See [Troubleshoot Postgres Database](../operations//kubernetes/Troubleshoot_Postgres_Database.md#syncfailed)
   <a name="csm_installation_failure_missing_secret"></a>

   1. CSM Services Install Fails Because of Missing Secret

      If a new installation is failing with a missing `admin-client-auth` secret, then see
      [CSM Services Install Fails Because of Missing Secret](csm_installation_failure.md).
