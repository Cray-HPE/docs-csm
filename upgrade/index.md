# Upgrade CSM

The process for upgrading Cray Systems Management (CSM) has many steps in multiple procedures which should be done in a specific order.

After the upgrade of CSM software, the CSM health checks will validate the system before doing any other operational
tasks like the check and update of firmware on system components. Once the CSM upgrade has completed, other
product streams for the HPE Cray EX system can be installed or upgraded.

## Topics

1. [Prepare for Upgrade](#prepare_for_upgrade)
1. [Upgrade Management Nodes and CSM Services](#upgrade_management_nodes_csm_services)
1. [Update Management Network](#update_management_network)
1. [Validate CSM Health](#validate_csm_health)
1. [Update Firmware with FAS](#update_firmware_with_fas)
1. [Next Topic](#next_topic)

Note: If problems are encountered during the upgrade, some of the topics do have their own troubleshooting
sections, but there is also a general troubleshooting topic.

<a name="prepare_for_upgrade"></a>
## Prepare For Upgrade

See [Prepare for Upgrade](prepare_for_upgrade.md)

<a name="upgrade_management_nodes_csm_services"></a>
## Upgrade Management Nodes and CSM Services

The procedure you follow depends on the new CSM version to which you are upgrading:
   
* Upgrading **to CSM 1.0.0**

    The upgrade of CSM software will do a controlled, rolling reboot of all management nodes before updating the CSM services.

    The upgrade is a guided process starting with [Upgrade Management Nodes and CSM Services](1.0/README.md).

* Upgrading **to CSM 1.0.1**
   
    **IMPORTANT**: You must already be at CSM 1.0.0 in order to upgrade to CSM 1.0.1.
  
    The upgrade is a guided process starting with [CSM 1.0.1 Patch Installation Instructions](1.0.1/README.md).

<a name="update_management_network"></a>
## Update Management Network

**IMPORTANT**: Only do this step if upgrading from CSM 0.9 (Shasta 1.4). If upgrading from CSM 1.0 (Shasta 1.5), skip this step.

There are new features and functions with Shasta v1.5. Some of these changes were available as patches and hotfixes
for Shasta v1.4, so may already be applied.
* Static Lags from the CDU switches to the CMMs (Aruba and Dell).
* HPE Apollo node port config, requires a trunk port to the iLO.
* BGP TFTP static route removal (Aruba).
* BGP passive neighbors (Aruba and Mellanox)

See [Update Management Network](update_management_network.md)

<a name="validate_csm_health"></a>
## Validate CSM Health

> **`IMPORTANT:`** Wait at least 15 minutes after completing the previous steps to let the updated
> CSM Kubernetes resources initialize and start.
  
It is always recommended to run all possible CSM health validation procedures. At a minimum, run the
following validation checks to ensure that everything is still working properly after the upgrade.
  
> **`IMPORTANT:`** If your site does not use UAIs, skip UAS and UAI validation. If you do use
> UAIs, there are products that configure UAS like Cray Analytics and Cray Programming Environment that
> must be working correctly with UAIs and should be validated and corrected (the procedures for this are
> beyond the scope of this document) prior to validating UAS and UAI. Failures in UAI creation that result
> from incorrect or incomplete installation of these products will generally take the form of UAIs stuck in
> waiting state trying to set up volume mounts.
  
1. [Platform Health Checks](../operations/validate_csm_health.md#platform-health-checks)
2. [Hardware Management Services Health Checks](../operations/validate_csm_health.md#hms-health-checks)
3. [Software Management Services Validation Utility](../operations/validate_csm_health.md#sms-health-checks)
4. [Validate UAS and UAI Functionality](../operations/validate_csm_health.md#uas-uai-validate)
  
See [Validate CSM Health](../operations/validate_csm_health.md)
  
<a name="update_firmware_with_fas"></a>
## Update Firmware with FAS

See [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md)

<a name="next_topic"></a>
## Next Topic

After completion of the firmware update with FAS, the CSM product stream has been fully upgraded and
configured. Refer to the 1.5 _HPE Cray EX System Software Getting Started Guide S-8000_ 
on the HPE Customer Support Center at https://www.hpe.com/support/ex-gsg 
more information on other product streams to be upgraded and configured after CSM.
