# Fresh Install

Use this procedure for either a first-time install or in the event a previous CSM was wiped and requires a new install.

## Procedure

> **CAUTION:** All of the following steps should be done using an out-of-band connection. This process is disruptive and will require downtime.

1. Upgrade switch firmware to specified firmware version.
   
   Refer to [Update Management Network Firmware](firmware/update_management_network_firmware.md).
  
2. If the system had a previous version of CSM on it, you need to backup all custom configuration and credential configuration.
   
   Refer to [Backup a Custom Configuration](backup_custom_config.md).
  
3. If the switches have any configuration, it is recommenced to erase it before adding any new configuration.
   
   Refer to [Wipe Management Switch Config](wipe_mgmt_switches.md).

4. Validate the SHCD.
   
   The SHCD defines the topology of a Shasta system, this is needed when generating switch configs.
   Refer to [Validate the SHCD](validate_shcd.md).

5. Validate cabling between SHCD generated data and actual switch configuration.
   
   Refer to [Validate Cabling](validate_cabling.md).

6. Generate the switch configuration file(s).
   
   Refer to [Generate Switch Configs](generate_switch_configs.md).

7. Apply the configuration to switch.
    
   Refer to [Apply Switch Configs](apply_switch_configs.md).

8. Apply the custom configuration to switch, which includes site connection and credential info.
    
   Refer to one of the following procedures:

   - [Apply Custom Switch Configs 1.0](apply_custom_config_1.0.md)
   - [Apply Custom Switch Configs 1.2](apply_custom_config_1.2.md)

9. Setup connection to the site.
   
   Refer to [Setup Site Connection](../customer_access_network/Customer_Access_Network_CAN.md).
  
10. Check the differences between the generated configs and the configs on the system.
   
    Refer to [Validate Switch Configs](validate_switch_configs.md). 

11. Run a suite of tests against the management network switches.
   
    Refer to [Network Tests](network_tests.md).
