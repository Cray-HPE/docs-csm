# Switch Replacement in the VSX Cluster

Replace the VSX primary or the VSX secondary with the following steps.

1. Make sure all cables are labelled with clear identification.
1. Unplug power and all fibers and copper cables.
1. Un-rack the failing unit and rack the replacement unit.
1. Power-up the unit.
1. Restore switch firmware (see note below) and configuration.
1. SSH/Console to the replacement switch and shutdown all ports.

## Example: 8320, 8325

```text
Switch# config
Switch(config)# interface 1/1/1-1/1/52 shutdown
```

> **NOTE:** Restoring firmware is required only if replacing the primary VSX member. Otherwise, restore the configuration because VSX sync would force automatic
> software upgrade on secondary member.

* Re-cable
* SSH/Console to the replacement switch and re-enable all ports:

The switch should now enable the VSX ports. Once VSX sync is completed, all ports should get enabled after hold-down timer has expired.

> **NOTE:** If replacing the secondary member and a software upgrade was not done prior to enabling the ports, there will be a reboot on the secondary unit after it has detected
> the primary VSX member and received new software from it before normal ports would come up.

[Back to Index](../index.md)
