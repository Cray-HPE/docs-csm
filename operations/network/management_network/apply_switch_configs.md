# Apply Switch Configs

This process is generally straight forward and requires the user to copy and paste the generated switch configuration into the terminal.

All ports will be shutdown before applying switch configuration. If the port is in the SHCD and being used, it will be enabled when the configuration is applied.

There are some caveats that are mentioned below.

#### Prerequisites

- Switch without any configuration
    - [Wipe Mgmt Switches](wipe_mgmt_switches.md)
- Generated Switch configs
    - [Generate Switch Config](generate_switch_configs.md)

### Aruba

1. Shutdown all ports. Use `show int physical` to see the range of ports.

    ```
    switch(config)# int 1/1/1-1/1/52
    switch(config-if-<1/1/1-1/1/52# shut
    ```

1. Enter `auto-confirm` before pasting in the configuration. This will automatically accept prompts.

    ```
    switch(config)# auto-confirm
    ```

1. Paste in the generated config.


### Dell

1. Shut down all ports.

    ```
    sw-leaf-bmc-001(config)# interface range ethernet 1/1/1-1/1/52
    sw-leaf-bmc-001(conf-range-eth1/1/1-1/1/52)# shut
    ```

1. Paste in the generated config.

    - When pasting in the config be sure that all the commands were accepted. In some cases you will need to back out of the current config context and back to global configuration for the commands to work as intended.
    - `banner motd` will need to be manually applied.

      For example:

      ```
      sw-leaf-bmc-001(config)# router ospf 1
      sw-leaf-bmc-001(config-router-ospf-1)# router-id 10.2.0.4
      sw-leaf-bmc-001(config-router-ospf-1)# router-id ospf 2 vrf Customer
      % Error: Illegal parameter.
      sw-leaf-bmc-001(config-router-ospf-1)# router-id 10.2.0.4
      ```

      To fix:

      ```
      sw-leaf-bmc-001(config)# router ospf 1
      sw-leaf-bmc-001(config-router-ospf-1)# router-id 10.2.0.4
      sw-leaf-bmc-001(config-router-ospf-1)# exit
      sw-leaf-bmc-001(config)# router ospf 2 vrf Customer
      sw-leaf-bmc-001(config-router-ospf-2)# router-id 10.2.0.4
      ```

### Mellanox

Verify that `no cli default prefix-modes enable` is configured on the switch before applying any configuration.

```
sw-spine-001 [mlag-domain: standby] (config) # no cli default prefix-modes enable
```

### Write memory

Save the configuration once the configuration is applied.

Refer to the [Saving Config](saving_config.md) procedure.
