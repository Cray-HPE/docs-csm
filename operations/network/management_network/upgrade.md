# Upgrade

Upgrading to a new CSM version without CANU generated switch configs.

To check if the management network is using generated switch configs, log onto a management switch, and if you see a banner with a `CANU version` that means the switch config has been generated.
```
###############################################################################
# CSM version:  1.0
# CANU version: 1.1.10
###############################################################################
```
To upgrade from CSM 1.0 preconfig (switch configs generated) to CSM 1.2 use this page [Management Network 1.0 (1.2 Preconfig) to 1.2](1.0_to_1.2_upgrade.md)

If the configs have not been generated you will need to follow the steps below.

:exclamation: All of these steps should be done using an out of band connection. This process is disruptive and will require downtime :exclamation: 

1. [Collect data](collect_data.md)
    - Collect system data.
1. [Update management network firmware](update_management_network_firmware.md)
    - Upgrade switch firmware to specified firmware version.
1. [Backup custom config](backup_custom_config.md)
    - If the system had a previous version of CSM on it, you need to backup all custom configuration and credential configuration.  This procedure can be found on the.
1. [Config management](config_management.md)
    - Backup switch configs.
1. [Validate the SHCD](validate_shcd.md)
    - The SHCD defines the topology of a Shasta system, this is needed when generating switch configs.
1. [Generate switch configs](generate_switch_configs.md)
    - Generate the switch configuration file(s)
1. [Wipe mgmt switches](wipe_mgmt_switches.md)
    - If the switches have any configuration, it is recommenced to erase it before any configuration.
1. [Apply switch configs](apply_switch_configs.md)  
    - Applying the configuration to switch.
1. [Apply custom switch configs](apply_custom_config_1.0.md)  
    - Applying the custom configuration to switch.
1. [Validate switch configs](validate_switch_configs.md) 
    - Checks differences between generated configs and the configs on the system.
1. [Network tests](network_tests.md)
    - Run a suite of tests against the management network switches.