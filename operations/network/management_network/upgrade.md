# Upgrade Switches From 1.0 to 1.2 Preconfig

Use the following procedure to upgrade switches from 1.0 to 1.2 preconfig.

To check if the management network is using generated switch configs, log onto a management switch and check for a banner with a `CANU version`. This indicates the switch config has been generated.

```
###############################################################################
# CSM version:  1.0
# CANU version: 1.1.10
###############################################################################
```

To upgrade from CSM 1.2 preconfig (switch configs generated) to CSM 1.2, use the [Management Network 1.0 (1.2 Preconfig) to 1.2](1.0_to_1.2_upgrade.md) procedure.

If the configs have not been generated, follow the procedure below.

## Procedure

> **CAUTION:** All of these steps should be done using an out-of-band connection. This process is disruptive and will require downtime.
>
> **CAUTION:** This procedure must be done in coordination with the CSM network team.

1. Collect system data.

   Refer to [Collect data](collect_data.md).

1. Upgrade switch firmware to specified firmware version.

   Refer to [Update Management Network Firmware](firmware/update_management_network_firmware.md).

1. If the system had a previous version of CSM on it, you need to backup all custom configuration and credential configuration.

   Refer to [Backup a Custom Configuration](backup_custom_config.md).

1. Backup switch configs.

   Refer to [Configuration Management](config_management.md).

1. Validate the SHCD.

   The SHCD defines the topology of a Shasta system, this is needed when generating switch configs.
   Refer to [Validate the SHCD](validate_shcd.md).

1. Validate cabling between SHCD generated data and actual switch configuration.

   Refer to [Validate Cabling](validate_cabling.md).

1. Generate the switch configuration file(s).

   Refer to [Generate Switch Configs](generate_switch_configs.md).

1. If the switches have any configuration, it is recommenced to erase it before any configuration.

   Refer to [Wipe Management Switch Config](wipe_mgmt_switches.md).

1. Apply the configuration to switch.

    Refer to [Apply Switch Configs](apply_switch_configs.md).

1. Apply the custom configuration to switch, which includes site connection and credential information.

    Refer to one of the following procedures:

    - [Apply Custom Switch Configs 1.0](apply_custom_config_1.0.md)
    - [Apply Custom Switch Configs 1.2](apply_custom_config_1.2.md)

1. Check the differences between the generated configurations and the configurations on the system.

    Refer to [Validate Switch Configs](validate_switch_configs.md).

1. Run a suite of tests against the management network switches.

    Refer to [Network Tests](network_tests.md).
