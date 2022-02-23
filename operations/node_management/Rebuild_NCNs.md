# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure, or some other issue with the node has occurred that warrants rebuilding the node.

The following is a high-level overview of the NCN rebuild workflow:

1. Prepare Node
    * There is a different procedure for each type of node (worker, master, and storage).
2. Identify Node and Update Metadata
    * Same procedure for all node types.
3. Wipe Disks
    * Same for master and worker nodes, but different for storage nodes.
4. Power Cycle Node
    * Same procedure for all node types.
5. Rebuild Storage Node
    * Only needed for storage nodes
6. Validate `BOOTRAID` artifacts
    * Run from ncn-m001
7. Validation
    * There is a different procedure for each type of node (worker, master, and storage).

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

For several of the commands in this section, you will need to have variables set with the name of the node being rebuilt and its xname.

Set NODE to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
Set XNAME to the xname of that node.

```bash
ncn# NODE=ncn-w00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

## Procedure

   Choose the appropriate node type in the **Prepare Node** section

### Prepare Node (prepare_node)

Only follow the steps in the section for the node type that is being rebuilt:

* [Worker node](Rebuild_NCNs/Prepare_Worker_Nodes.md)
* [Master node](Rebuild_NCNs/Prepare_Master_Nodes.md)
* [Storage node](Rebuild_NCNs/Prepare_Storage_Nodes.md)

## Validation

After you have completed all the steps, then please run the **Final Validation** steps.

[Final Validation](rebuild_ncns/../Rebuild_NCNs/Final_Validation_Steps.md)