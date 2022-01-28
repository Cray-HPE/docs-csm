# Start guide

### Fresh Install

:exclamation: All of these steps should be done using an out of band connection. This process is disruptive and will require downtime :exclamation:  

1. Collect system data. [collect data](collect_data.md)
1. Upgrade switch firmware to specified firmware version, this info is located on the  [update management network firmware page](update_management_network_firmware.md)
1. If the system had a previous version of CSM on it, you need to backup custom configuration and credential configuration.  This procedure can be found on the [backup custom config](backup_custom_config.md) page.
1. If upgrading/downgrading to a different CSM version it is recommended to backup the current config on the switch itself, this process can be found on the [config management](config_management.md) page. 
1. If the switches have any configuration, it is recommenced to erase it before any configuration.  These procedures can be found on the [wipe mgmt switches](wipe_mgmt_switches.md) page.
1. [Validate the SHCD](validate_shcd.md)
1. Generate switch configs and apply via out of band management connection or console connection.  An example on how to generate switch configs can be found on the [generate switch configs](generate_switch_configs.md) page.
1. Apply the switch configs. [apply switch configs](apply_switch_configs.md).  This includes [generated switch configs](generate_switch_configs.md) and [manual switch configs](manual_switch_config.md)
1. validate that the switch configs match what is generated.  [validate switch configs](validate_switch_configs.md)
1. Run [network tests](network_tests.md) against the management network.
### Upgrade

1. Collect system data. [collect data](collect_data.md)
1. Upgrade switch firmware to specified firmware version, this info is located on the  [update management network firmware page](update_management_network_firmware.md)
1. [Validate the SHCD](validate_shcd.md)
1. Generate switch configs.  An example on how to generate switch configs can be found on the [generate switch configs](generate_switch_configs.md) page.
1. Use the `canu validate` feature to apply the switch configs.  [validate switch configs](validate_switch_configs.md)
1. If custom config exists use the `--override` function from CANU so that this config does not get overwritten.
1. Run [network tests](network_tests.md) against the management network.

### Reinstall

1. If the switches are reinstalling to the same CSM version no configuration changes should be required.
1. validate that the switch configs match what is generated.  [validate switch configs](validate_switch_configs.md)
1. Run [network tests](network_tests.md) against the management network.

### Added hardware

1. [Validate the SHCD](validate_shcd.md) to ensure that the cabling is correct.
1. [generate switch configs](generate_switch_configs.md)
1. [validate switch configs](validate_switch_configs.md) to see what configuration changes are needed.
1. Run [network tests](network_tests.md) against the management network.