# Save Management Network Switch Configuration Settings

Switches must be powered on and operating. This procedure is optional if switch configurations have not changed.

**Optional Task:** Save management network switch configurations before removing power from cabinets or the CDU. Management switch names are listed in the `/etc/hosts` file.

## Obtain the list of switches

From the command line on any NCN run:

```bash
ncn# grep 'sw-' /etc/hosts
```

Example output:

```
10.252.0.2 sw-spine-001
10.252.0.3 sw-spine-002
10.252.0.4 sw-leaf-001
ncn-m001:~ #
```

## Save switch configs

### Aruba Switch and HPE Server Systems

On Aruba-based systems all management network switches will be Aruba and the following procedure.
For each switch:

1. `ssh` to the switch
1. Execute the `write memory` command
1. Exit the switch shell

Example:

 ```bash
 ncn# ssh admin@sw-spine-001.nmn
 admin@sw-spine-001 password:
 sw-spine-001# write memory
 sw-spine-001# exit
 ```

### Dell and Mellanox Switch and Gigabyte/Intel Server Systems

On Dell and Mellanox based systems, all spine and any leaf switches will be Mellanox. Any leaf-bmc and cdu switches will be Dell. The overall procedure is the same but the specifics of execution are slightly different.

1. `ssh` to the switch
1. Enter `enable` mode (Mellanox only)
1. Execute the `write memory` command
1. Exit the switch shell

Mellanox Example:

 ```bash
 ncn# ssh admin@sw-spine-001.nmn
 admin@sw-spine-001 password:
 sw-spine-001# enable
 sw-spine-001# write memory
 sw-spine-001# exit
 ```

Dell Example:

 ```bash
 ncn# ssh admin@sw-leaf-bmc-001
 admin@sw-leaf-bmc-001s password:
 sw-leaf-001# write memory
 sw-leaf-001# exit
 ```

### Edge Routers and Storage Switches

Save configuration settings on Edge Router switches (Arista, Aruba or Juniper) that connect customer storage networks to the Slingshot network if these switches exist in the site and the configurations have changed.
Edge switches are accessible from the ClusterStor management network and the CSM management network.

Example:

 ```bash
 ncn# ssh admin@cls01053n00
 admin@cls01053n00 password:

 cls01053n00# ssh r0-100gb-sw01
 r0-100gb-sw01# enable
 r0-100gb-sw01# write memory
 r0-100gb-sw01# exit
 ```

## Next Step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
