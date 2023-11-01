# Fresh Install

Use this procedure for either a first-time install or in the event a previous CSM was wiped and requires a new install.

***Before continuing with install***, make sure that CANU is running the most current version:

[Install/Upgrade CANU](canu_install_update.md)

## Procedure

> **CAUTION:** All of the following steps should be done using an out-of-band connection. This process is disruptive and will require downtime.

1. Upgrade switch firmware to specified firmware version.

   Refer to [Update Management Network Firmware](firmware/update_management_network_firmware.md).

1. If the system had a previous version of CSM on it, you need to backup all custom configuration and credential configuration.

   Refer to [Backup a Custom Configuration](backup_custom_configurations.md).

1. If the switches have any configuration, it is recommenced to erase it before adding any new configuration.

   Refer to [Wipe Management Switch Configuration](wipe_mgmt_switches.md).

1. Validate the SHCD.

   The SHCD defines the topology of a Shasta system, this is needed when generating switch configurations.
   Refer to [Validate the SHCD](validate_shcd.md).

1. Validate cabling between SHCD generated data and actual switch configuration.

   Refer to [Validate Cabling](validate_cabling.md).

1. Generate the switch configuration file(s).

   Refer to [Generate Switch Configurations](generate_switch_configs.md).

1. Apply the configuration to switch.

   Refer to [Apply Switch Configurations](apply_switch_configurations.md).

1. Apply the custom configuration to switch, which includes site connection and credential info.

   Refer to one of the following procedures:

1. Setup connection to the site.

   Refer to [Setup Site Connection](../customer_accessible_networks/Customer_Accessible_Networks.md).

1. Check the differences between the generated configurations and the configurations on the system.

    Refer to [Validate Switch Configurations](validate_switch_configs.md).

1. Run a suite of tests against the management network switches.

    Refer to [Network Tests](network_tests.md).
