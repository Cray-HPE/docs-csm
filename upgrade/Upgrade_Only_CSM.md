# Upgrade only CSM

This procedure describes how to upgrade Cray Systems Management (CSM) software on a CSM-only system
without additional HPE Cray EX software products installed.

After the upgrade of CSM software, the CSM health checks will validate the system before doing any
other operational tasks like the check and update of firmware on system components.

1. [Prepare for upgrade](#1-prepare-for-upgrade)
1. [Upgrade management nodes and CSM services](#2-upgrade-management-nodes-and-csm-services)
1. [Validate CSM health](#3-validate-csm-health-during-upgrade)
1. [Check and update firmware](#4-check-and-update-firmware)
1. [Upgrade complete](#5-upgrade-complete)

Note: If problems are encountered during the upgrade, some of the topics do have their own troubleshooting
sections, but there is also a general troubleshooting topic.

- If IMS image creation CFS jobs fail, see [Known Issue: IMS image creation failure](../troubleshooting/known_issues/ims_image_creation_failure.md) for a possible workaround.

- On some systems, Ceph can begin to exhibit latency over time, and if this occurs it can eventually cause services like `slurm` and services that are backed by `etcd` clusters to exhibit slowness and possible timeouts.
  See [Known Issue: Ceph OSD latency](../troubleshooting/known_issues/ceph_osd_latency.md) for a workaround.

## 1. Prepare for upgrade

See [Prepare for Upgrade](prepare_for_upgrade.md).

## 2. Upgrade management nodes and CSM services

The upgrade of CSM software will do a controlled, rolling reboot of all management nodes before updating the CSM services.

The upgrade is a guided process starting with [Upgrade Management Nodes and CSM Services](Upgrade_Management_Nodes_and_CSM_Services.md).

## 3. Validate CSM health during upgrade

See [Validate CSM Health During Upgrade](Validate_CSM_Health_During_Upgrade.md).

## 4. Check and update firmware

Check and update firmware if not already at the correct versions.
Make sure the latest version of the HPE Cray EX HPC Firmware Pack (HFP) has been installed.
Follow the procedures for updating firmware with the Firmware Action Service (FAS) document
[Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md).

## 5. Upgrade complete

After completion of the validation of CSM health, the CSM product stream has been fully upgraded and
configured.
