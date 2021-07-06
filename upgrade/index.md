# Upgrade CSM

The upgrade process for Cray Systems Management (CSM) 0.9.4, which is part of Shasta v1.4.3,
to CSM 1.0, which is part of Shasta v1.5, has many steps in multiple procedures which should be done in a 
specific order.

After the upgrade of CSM software, the CSM health checks will validate the system before doing any other operational
tasks like the check and update of firmware on system components.  Once the CSM upgrade has completed, other 
product streams for the HPE Cray EX system can be installed or upgraded.

### Topics:

   1. [Prepare for Upgrade](#prepare_for_upgrade)
   1. [Update Management Network](#update_management_network)
   1. [Upgrade Management Nodes and CSM Services](#upgrade_management_nodes_csm_services)
   1. [Validate CSM Health](#validate_csm_health)
   1. [Update Firmware with FAS](#update_firmware_with_fas)
   1. [Next Topic](#next_topic)

Note: If problems are encountered during the upgrade, some of the topics do have their own troubleshooting
sections, but there is also a general troubleshooting topic.

## Details

<a name="prepare_for_upgrade"></a>
1. Prepare for Upgrade
      
   See [Prepare for Upgrade](prepare_for_upgrade.md)
<a name="update_management_network"></a>

1. Update Management Network 
      
   There are new features and functions with Shasta v1.5.  Some of these changes were available as patches and hotfixes
   for Shasta v1.4, so may already be applied.
   * Static Lags from the CDU switches to the CMMs (Aruba and Dell).
   * HPE Apollo node port config, requires a trunk port to the iLO.
   * BGP TFTP static route removal (Aruba).
   * BGP passive neighbors (Aruba and Mellanox)

   See [Update Management Network](update_management_network.md)
<a name="upgrade_management_nodes_csm_services"></a>

1. Upgrade Management Nodes and CSM Services
      
   The upgrade of CSM software will do a controlled, rolling reboot of all management nodes before updating the CSM services.
   * Prerequisites & Preflight Checks
   * Stage 1.  Ceph upgrade from Nautilus (14.2.x) to Octopus (15.2.x)
   * Stage 2. Ceph image upgrade
   * Stage 3. Kubernetes Upgrade from 1.18.6 to 1.19.9
   * Stage 4. CSM Service Upgrades

   See [Upgrade Management Nodes and CSM Services](1.0/README.md)
<a name="validate_csm_health"></a>

1. Validate CSM Health

   > **`IMPORTANT:`** Wait at least 15 minutes after 
   > [`upgrade.sh`](1.0/README.md#deploy-manifests) in stage 4 completes to let the various Kubernetes
   > resources get initialized and started.

   Run the following validation checks to ensure that everything is still working
   properly after the upgrade:

   1. [Platform Health Checks](../../operations/validate_csm_health.md#platform-health-checks)
   1. [Hardware Management Services Health Checks](../../operations/validate_csm_health.md#hms-health-checks)
   1. [Software Management Services Validation Utility](../../operations/validate_csm_health.md#sms-health-checks)
   1. [Validate UAS and UAI Functionality](../../operations/validate_csm_health.md#uas-uai-validate)

   Booting the barebones image on the compute nodes should be skipped if the compute nodes have been running
   application workload during the the CSM upgrade.
      
   See [Validate CSM Health](../operations/validate_csm_health.md)
<a name="update_firmware_with_fas"></a>

1. Update Firmware with FAS
      
   See [Update Firmware with FAS](../operations/update_firmware_with_fas.md)
<a name="next_topic"></a>

1. Next Topic

   After completion of the firmware update with FAS, the CSM product stream has been fully upgraded and
   configured.  Refer to the _HPE Cray EX Installation and Configuration Guide 1.5 S-8000_ for other product streams
   to be upgraded and configured after CSM.
