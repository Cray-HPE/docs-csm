### Fresh Install

1. Upgrade switch firmware to specified firmware version, this info is located on the  [update management network firmware page](../management_network/update_management_network_firmware.md)
1. If the system had a previous version of CSM on it, you need to backup custom configuration and credential configuration.  This procedure can be found on the [backup custom config](../backup_custom_config.md) page.
1. If the switches have any configuration, it is recommenced to do factory reset before any configuration.  These procedures can be found in the [user guides](./user_guides.md)
1. If upgrading/downgrading to a different CSM version it is recommended to backup the current config on the switch itself, this process can be found on the [config management](../config_management.md) page.  This is page is intended for internal use only.
1. Generate switch configs and apply via out of band management connection or console connection.
1. Run [network tests](./network_tests.md) against the management network.
### Upgrade

1. Upgrade switch firmware to specified firmware version, this info is located on the  [update management network firmware page](../management_network/update_management_network_firmware.md)
1. Generate switch configs.  This may require reformatting parts of the SHCD.
1. Run `canu validate` and compare the configs
1. If custom config exists use the `--override` function from CANU so that this config does not get overwritten.

### Reinstall

1. If the switches are reinstalling to the same CSM version no configuration changes should be required.
1. Run [network tests](./network_tests.md) against the management network.

### Added hardware

1. Generate CANU configs and run `canu validate ` to see what config needs to be added or changed.
1. Run [network tests](./network_tests.md) against the management network.