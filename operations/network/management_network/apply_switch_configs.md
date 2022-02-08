# Apply Switch Configs

#### Prerequisites 
- Custom switch config backed up. 
    - [Manual Switch Config](manual_switch_config.md)
- Switch without any configuration.
    - [Wipe Mgmt Switches](wipe_mgmt_switches.md)
- Generated Switch configs.
    - [Generate Switch Config](generate_switch_configs.md)

This process is generally straight forward and requires the user to copy and paste the generated switch configuration and custom configuration into the terminal.

There are some caveats that are mentioned below.
### Aruba
- Be sure to type `auto-confirm` before pasting in the configuration.
This will automatically accept prompts.

    `switch(config)# auto-confirm`


### Dell
- When pasting in the config be sure that all the commands were accepted.  In some cases you will need to back out of the current config context and back to global configuration for the commands to work as intended.

An example

```
sw-leaf-bmc-001(config)# router ospf 1
sw-leaf-bmc-001(config-router-ospf-1)# router-id 10.2.0.4
sw-leaf-bmc-001(config-router-ospf-1)# router-id ospf 2 vrf Customer
% Error: Illegal parameter.
sw-leaf-bmc-001(config-router-ospf-1)# router-id 10.2.0.4
```
To fix
```
sw-leaf-bmc-001(config)# router ospf 1
sw-leaf-bmc-001(config-router-ospf-1)# router-id 10.2.0.4
sw-leaf-bmc-001(config-router-ospf-1)# exit
sw-leaf-bmc-001(config)# router ospf 2 vrf Customer
sw-leaf-bmc-001(config-router-ospf-2)# router-id 10.2.0.4
```

### Mellanox
- Make sure that `no cli default prefix-modes enable` is configured on the switch before applying any configuration.
```
sw-spine-001 [mlag-domain: standby] (config) # no cli default prefix-modes enable
```

#### Be sure to `write memory` after the configuration has been applied.