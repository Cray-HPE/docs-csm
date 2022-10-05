# Rolling Upgrades using BOS

> **`NOTE`** This section is for BOS V2 only.

<!-- -->
> **`NOTE`** This feature is the replacement for CRUS, which was deprecated in CSM 1.2.0.

BOS V2 allows users to stage boot artifacts, configuration, and an operation such as a reboot.
The workload manager can later trigger the operation through BOS to apply that staged information, allowing rolling updates when nodes have no job running on them.

## Workflow

1. A sysadmin configures the workload manager to call the `applystaged` endpoint of BOS, along with sending a payload containing the `xnames` of the components to be operated on.  For more information on the endpoint and payload see [Applying a Staged State](./Stage_Changes_with_BOS.md#applying-a-staged-state)

    > **`NOTE`** The boot artifacts and configuration staged with BOS will not be applied if the node is rebooted outside BOS.
    This is because BOS is caching the staged boot information and configuration internally, but not updating BSS and CFS until immediately before it boots or reboots the nodes.

1. A sysadmin stages all of the boot information through BOS V2 by creating a session with the `staged` parameter.
BOS will cache the boot artifacts and configuration and associate that information with the specified nodes. These nodes will not be booted or rebooted as a part of this staging.
For more information on staging sessions, see [Creating a Staged Session](./Stage_Changes_with_BOS.md#creating-a-staged-session)

1. The sysadmin indicates to the workload manager that a node reboot is needed.

1. The workload manager calls the `applystaged` endpoint for each node when it is ready.
BOS then copies the information staged for these components into their desired state, and BOS starts to operate on the nodes and attempts to make their actual state match their new desired state.

## Using staged sessions with Slurm

Slurm can be configured to call a reboot script using the `RebootProgram` value in the `slurm.conf` file.
See the [Slurm documentation](https://slurm.schedmd.com/slurm.conf.html#OPT_RebootProgram) for more information on configuring this value.
Once this configuration is in place and a staged session has been created, admins can issue a `scontrol reboot` command to Slurm.
Slurm will then use the reboot script to call the BOS `applystaged` endpoint.
