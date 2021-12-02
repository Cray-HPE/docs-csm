# Upgrade CSM

The process for upgrading Cray Systems Management (CSM) has many steps in multiple procedures which should be done in a specific order.

After the upgrade of CSM software, the CSM health checks will validate the system before doing any other operational
tasks like the check and update of firmware on system components. Once the CSM upgrade has completed, other
product streams for the HPE Cray EX system can be installed or upgraded.

## Topics

1. [Prepare for Upgrade](#prepare_for_upgrade)
1. [Upgrade Management Nodes and CSM Services](#upgrade_management_nodes_csm_services)
1. [Validate CSM Health](#validate_csm_health)
1. [Next Topic](#next_topic)

Note: If problems are encountered during the upgrade, some of the topics do have their own troubleshooting
sections, but there is also a general troubleshooting topic.

## Details

<a name="prepare_for_upgrade"></a>

1. Prepare for Upgrade

    See [Prepare for Upgrade](prepare_for_upgrade.md)

   <a name="upgrade_management_nodes_csm_services"></a>

1. Upgrade Management Nodes and CSM Services

    The upgrade of CSM software will do a controlled, rolling reboot of all management nodes before updating the CSM services.

    The upgrade is a guided process Starting with [Upgrade Management Nodes and CSM Services](1.2/README.md)

    <a name="validate_csm_health"></a>

1. Validate CSM Health

     > **`IMPORTANT:`** Wait at least 15 minutes after
     > [`csm-service-upgrade.sh`](1.2/Stage_3.md) in stage 3 completes to let the various Kubernetes
     > resources get initialized and started.
  
     Run the following validation checks to ensure that everything is still working
     properly after the upgrade:
  
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
  
     Booting the barebones image on the compute nodes should be skipped if the compute nodes have been running
     application workload during the the CSM upgrade.
  
     See [Validate CSM Health](../operations/validate_csm_health.md)
  
    <a name="next_topic"></a>

1. Next Topic

    After completion of the validation of CSM health, the CSM product stream has been fully upgraded and
    configured. Refer to the 1.5 _HPE Cray EX System Software Getting Started Guide S-8000_ 
    on the HPE Customer Support Center at https://www.hpe.com/support/ex-gsg 
    more information on other product streams to be upgraded and configured after CSM.

    > **Note:** If a newer version of the HPE Cray EX HPC Firmware Pack (HFP) is available, then the next step
    would be to install HFP which will inform the Firmware Action Services (FAS) of the newest firmware
    available. Once FAS is aware that new firmware is available, then see
    [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md).
