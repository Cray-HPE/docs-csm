# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure, or some other issue with the node has occurred that warrants rebuilding the node.

## Overview

The following is a high-level overview of the NCN rebuild workflow:

1. Prepare node

    This step uses a different procedure for each type of node (worker, master, and storage).

1. Identify node and update metadata

    This step uses the same procedure for all node types.

1. Wipe disks

    This step uses the same procedure for master and worker nodes, but different for storage nodes.

1. Power cycle node

    This step uses the same procedure for all node types.

1. Rebuild storage node

    This step is only needed for storage nodes.

1. Validate `BOOTRAID` artifacts

    This step is run from `ncn-m001`.

1. Validation

    This step uses a different procedure for each type of node (worker, master, and storage).

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

Several of the commands in this section require shell variables set with the name of the node being rebuilt and its component name (xname).

Set `NODE` to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
Set `XNAME` to the component name (xname) of that node.

For example:

```bash
ncn# NODE=ncn-w00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

## Procedure

* [Rebuild worker node](Rebuild_NCNs/Prepare_Worker_Nodes.md)
* [Rebuild master node](Rebuild_NCNs/Prepare_Master_Nodes.md)
* [Rebuild storage node](Rebuild_NCNs/Prepare_Storage_Nodes.md)

## Validation

After completing all of the steps, perform the [Final Validation](Rebuild_NCNs/Final_Validation_Steps.md) procedure.
