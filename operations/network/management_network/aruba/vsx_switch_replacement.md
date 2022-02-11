# Switch Replacement in the VSX Cluster

Replace the VSX primary or the VSX secondary with the following steps. 

1. Make sure all cables are labelled with clear identification. 
2. Unplug power and all fibers and copper cables. 
3. Un-rack the failing unit and rack the replacement unit. 
4. Power-up the unit. 
5. Restore switch firmware (see note below) and configuration. 
6. SSH/Console to the replacement switch and shutdown all ports.

## Example: 8320, 8325 

```bash
Switch# config
Switch(config)# interface 1/1/1-1/1/52 shutdown
``` 

> **NOTE:** Restoring firmware is required only if replacing the primary VSX member. Otherwise, restore the configuration as VSX sync would force automatic software upgrade on secondary member: 

   * Re-cable
   * SSH/Console to the replacement switch and re-enable all ports: 

## Example: 8320, 8325

```bash
Switch# config
Switch(config)# no interface 1/1/1-1/1/52 shutdown
``` 

The switch should now enable the VSX ports. Once VSX sync is completed, all ports should get enabled after hold-down timer has expired. 

> **NOTE:** If replacing the secondary member and a software upgrade wasn not done prior to enabling the ports, there will be a reboot on the secondary unit after it has detected the primary VSX member and gotten new software from it before normal ports would come up.

[Back to Index](../index.md)

