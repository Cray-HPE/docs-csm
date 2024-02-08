# Save Management Network Switch Configuration Settings

Switches must be powered on and operating. This procedure is optional if switch configurations have not changed.

**Optional Task:** Save management network switch configurations before removing power from cabinets or the CDU. Management switch names are listed in the `/etc/hosts` file.

## Save switch configs

### Aruba Switch and HPE Server Systems

On Aruba-based systems, all management network switches will be Aruba.

1. (`ncn-m#`) Connect to all management network switches.

   This loop will login to each switch as the admin username. Provide the password for that username. While logged in to each switch, some commands will be issued.  Then after typing `exit`, the loop will login to the next switch.

    ```bash
    for switch in $(awk '{print $2}' /etc/hosts | grep 'sw-'); do echo  "switch ${switch}:" ; ssh admin@$switch; done
    ```

   Commands to issue on each switch:

   ```bash
   write memory
   exit
   ```

   Example output:

   ```bash
   switch sw-spine-001:
   admin@sw-spine-001's password: 
   ###############################################################################
   # CSM version:  1.3
   # CANU version: 1.6.20
   ###############################################################################

   Last login: 2024-01-29 00:58:44 from 100.113.129.22
   User "admin" has logged in 2 times in the past 30 days
   sw-spine-001# write memory
   Copying configuration: [Success]
   sw-spine-001# exit
   Connection to sw-spine-001 closed.
   switch sw-spine-002:
   admin@sw-spine-002's password: 
   ###############################################################################
   # CSM version:  1.3
   # CANU version: 1.6.20
   ###############################################################################

   Last login: 2024-01-29 01:01:44 from 100.113.129.22
   User "admin" has logged in 1 times in the past 30 days
   sw-spine-002# write memory
   Copying configuration: [Success]
   sw-spine-002# exit
   Connection to sw-spine-002 closed.
   ...
    ```

### Dell and Mellanox Switch and Gigabyte/Intel Server Systems

On Dell and Mellanox based systems, all spine and any leaf switches will be Mellanox. Any Leaf-BMC and CDU switches will be Dell.

1. (`ncn-m#`) Connect to all management network switches.

   This loop will login to each switch as the admin username. Provide the password for that username. While logged in to each switch, some commands will be issued.  Then after typing `exit`, the loop will login to the next switch.

    ```bash
    for switch in $(awk '{print $2}' /etc/hosts | grep 'sw-'); do echo  "switch ${switch}:" ; ssh admin@$switch; done
    ```

   For a Mellanox switch:

   **Note:** Depending on the firmware version, some Mellanox switches may identify themselves as "NVIDIA Onyx".

   ```bash
   enable
   write memory
   exit
   ```

   For a Dell switch:

   ```bash
   write memory
   exit
   ```

   Example output:

   ```bash
   switch sw-spine-001:
   NVIDIA Onyx Switch Management
   Password: 
   Last login: Thu Jul 19 12:21:16 UTC 2001 from 10.254.1.14 on pts/0
   Number of total successful connections since last 1 days: 98

   ###############################################################################
   # CSM version:  1.3
   # CANU version: 1.6.20
   ###############################################################################

   sw-spine-001 [mlag-domain: standby] > enable
   sw-spine-001 [mlag-domain: standby] # write memory
   sw-spine-001 [mlag-domain: standby] # exit
   Connection to sw-spine-001 closed.
   ...
   switch sw-leaf-bmc-001:
   Debian GNU/Linux 9

   Dell EMC Networking Operating System (OS10)
   admin@sw-leaf-bmc-001's password: 
   Linux sw-leaf-bmc-001 4.9.189 #1 SMP Debian 4.9.189-3+deb9u2 x86_64
   ###############################################################################
   # CSM version:  1.3
   # CANU version: 1.6.20
   ###############################################################################
   sw-leaf-bmc-001# write memory
   sw-leaf-bmc-001# exit
   Session terminated for user admin on line vty 0 ( 10.254.1.12 )
   Connection to sw-leaf-bmc-001 closed.
   ...
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
