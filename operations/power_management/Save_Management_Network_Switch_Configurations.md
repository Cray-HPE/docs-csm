# Save Management Network Switch Configuration Settings

Switches must be powered on and operating. This procedure is optional if switch configurations have not changed.

**Optional Task:** Save management network switch configurations before removing power from cabinets or the CDU. Management switch names are listed in the `/etc/hosts` file.

## Save switch configs

### Aruba Switch and HPE Server Systems

On Aruba-based systems all management network switches will be Aruba and the following procedure.
For each switch:

1. Run the command below
1. Execute the `write memory` command
1. Exit the switch shell

Example:

 ```bash
for switch in $(awk '{print $2}' /etc/hosts | grep 'sw-'); do echo  "switch ${switch}:" ; ssh admin@$switch; done
 ```

### Dell and Mellanox Switch and Gigabyte/Intel Server Systems

On Dell and Mellanox based systems, all spine and any leaf switches will be Mellanox. Any leaf-bmc and cdu switches will be Dell. The overall procedure is the same but the specifics of execution are slightly different.

1. Run the command below
2. Enter `enable` mode (Mellanox only)
3. Execute the `write memory` command
4. Exit the switch shell

Example:

 ```bash
for switch in $(awk '{print $2}' /etc/hosts | grep 'sw-'); do echo  "switch ${switch}:" ; ssh admin@$switch; done
 ```

### Edge Routers and Storage Switches

Save configuration settings on Edge Router switches (Arista, Aruba or Juniper) that connect customer storage networks to the Slingshot network if these switches exist in the site and the configurations have changed.
Edge switches are accessible from the ClusterStor management network and the CSM management network.

Example:

 ```bash
 ssh admin@cls01053n00
 admin@cls01053n00 password:

 ssh r0-100gb-sw01
 enable
 write memory
 exit
 ```

## Next Step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
