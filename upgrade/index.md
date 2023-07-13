# Upgrade CSM

The process for upgrading Cray Systems Management (CSM) has many steps in multiple procedures which should be done in a specific order.

After the upgrade of CSM software, the CSM health checks will validate the system before doing any other operational
tasks like the check and update of firmware on system components. Once the CSM upgrade has completed, other
product streams for the HPE Cray EX system can be installed or upgraded.

1. [Prepare for upgrade](#prepare_for_upgrade)
1. [Upgrade management nodes and CSM services](#upgrade_management_nodes_csm_services)
1. [Validate CSM health](#validate_csm_health)
1. [Next topic](#next_topic)

Note: If problems are encountered during the upgrade, some of the topics do have their own troubleshooting
sections, but there is also a general troubleshooting topic.

1. <a name="prepare_for_upgrade"></a>Prepare for upgrade

    See [Prepare for Upgrade](prepare_for_upgrade.md)

1. <a name="upgrade_management_nodes_csm_services"></a>Upgrade management nodes and CSM services

    The upgrade of CSM software will do a controlled, rolling reboot of all management nodes before updating the CSM services.

    The upgrade is a guided process starting with [Upgrade Management Nodes and CSM Services](1.2/README.md).

1. <a name="validate_csm_health"></a>Validate CSM health

     **NOTE:**

     * Before performing the health validation, be sure that at least 15 minutes have elapsed
       since the CSM services were upgraded. This allows the various Kubernetes resources to
       initialize and start.
     * If the site does not use UAIs, skip UAS and UAI validation. If UAIs are used, there are
       products that configure UAS like Cray Analytics and Cray Programming Environment that
       must be working correctly with UAIs, and should be validated (the procedures for this are
       beyond the scope of this document) prior to validating UAS and UAI. Failures in UAI creation that result
       from incorrect or incomplete installation of these products will generally take the form of UAIs stuck in
       waiting state trying to set up volume mounts.
     * Performing the [Booting CSM `barebones` image](../operations/validate_csm_health.md#booting-csm-barebones-image) test may be skipped if no compute nodes are available
       (that is, if all compute nodes are active running application workloads).

     See [Validate CSM Health](../operations/validate_csm_health.md)

1. <a name="next_topic"></a>Next topic

    After completion of the validation of CSM health, the CSM product stream has been fully upgraded and configured.
    Refer to the [`HPE Cray EX System Software Getting Started Guide (S-8000) 22.07`](http://www.hpe.com/support/ex-gsg-042120221040)
    on the HPE Customer Support Center for more information on other product streams to be upgraded and configured after CSM.

    > **Note:** If a newer version of the HPE Cray EX HPC Firmware Pack (HFP) is available, then the next step
    would be to install HFP which will inform the Firmware Action Services (FAS) of the newest firmware
    available. Once FAS is aware that new firmware is available, then see
    [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md).
