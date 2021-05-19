# Upgrade CSM

The upgrade of the CSM product stream has many steps in multiple procedures which should be done in a 
specific order.

The information below is not yet correct for a general upgrade workflow.  Until it is, the upgrade should
start with [CSM 1.4 to 1.5 Upgrade Process](1.0/README.md) which is in the 1.0 subdirectory from this file.

The upgrade of CSM software and nodes can be validated with health checks before doing operational tasks
like the check and update of firmware on system components.  Once the CSM upgrade has completed, other 
product streams for the HPE Cray EX system can be installed or upgraded.

### Topics:

   1. [Prepare for Upgrade](#prepare_for_upgrade)
   1. [Update Management Network Configuration](#update_management_network)
   1. [Upgrade Management Nodes](#upgrade_management_nodes)
   1. [Upgrade CSM Services](#upgrade_csm_services)
   1. [Restore from Backup](#restore_from_backup)
   1. [Validate CSM Health](#validate_csm_health)
   1. [Update Firmware with FAS](#update_firmware_with_fas)
   1. [Next Topic](#next_topic)
   1. [Troubleshooting Upgrade Problems](#troubleshooting_upgrade)

The topics in this chapter need to be done as part of an ordered procedure so are shown here with numbered topics.

Note: If problems are encountered during the upgrade, some of the topics do have their own troubleshooting
sections, but there is also a general troubleshooting topic.

## Details

   <a name="prepare_for_upgrade"></a>

   1. Prepare for Upgrade
      
      See [Prepare for Upgrade](prepare_for_upgrade.md)
   <a name="update_management_network"></a>

   1. Update Management Network Configuration
      
      See [Update Management Network Configuration](update_management_network.md)
   <a name="upgrade_management_nodes"></a>

   1. Upgrade Management Nodes
      
      See [Upgrade Management Nodes](upgrade_management_nodes.md)
   <a name="upgrade_csm_services"></a>

   1. Upgrade CSM Services
      
      See [Upgrade CSM Services](upgrade_csm_services.md)
   <a name="restore_from_backup"></a>

   1. Restore from Backup
      
      See [Restore from Backup](restore_from_backup.md)
   <a name="validate_csm_health"></a>

   1. Validate CSM Health
      
      See [Validate CSM Health](../operations/validate_csm_health.md)
   <a name="update_firmware_with_fas"></a>

   1. Update Firmware with FAS
      
      See [Update Firmware with FAS](../operations/update_firmware_with_fas.md)
   <a name="next_topic"></a>

   1. Next Topic

      After completion of the firmware update with FAS, the CSM product stream has been fully upgraded and
      configured.  Refer to the _HPE Cray EX Installation and Configuration Guide 1.5 S-8000_ for other product streams
      to be upgraded and configured after CSM.
   <a name="troubleshooting_upgrade"></a>

   1. Troubleshooting Upgrade Problems

      The upgrade of the Cray System Management (CSM) product requires knowledge of the various nodes and
      switches for the HPE Cray EX system. The procedures in this section should be referenced during the CSM upgrade
      for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

      See [Troubleshooting Upgrade Problems](troubleshooting_upgrade.md))

