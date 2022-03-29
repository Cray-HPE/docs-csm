# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure, or some other issue with the node has occurred that warrants rebuilding the node.

The following is a high-level overview of the NCN rebuild workflow:

1. Prepare Node
    * There is a different procedure for each type of node (worker, master, and storage)
2. Identify Node and Update Metadata
    * Same procedure for all node types
3. Wipe Disks
    * Same for master and worker nodes, but different for storage nodes
4. Power Cycle Node
    * Same procedure for all node types
5. Rebuild Storage Node
    * Only needed for storage nodes
6. Validate `BOOTRAID` Artifacts
    * Run from ncn-m001
7. Validation
    * There is a different procedure for each type of node (worker, master, and storage)

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

Variables set with the name of the node being rebuilt and its component name (xname) are required for several of the commands in this section.

Set NODE to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
Set `XNAME` to the component name (xname) of that node.

```bash
ncn# NODE=ncn-w00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

## Procedure

Choose the appropriate node type in the **Prepare Node** section below.

### Prepare Node

Only follow the steps in the section for the node type that is being rebuilt:

* Worker node

  ```
  ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/rebuild/ncn-rebuild-worker-nodes.sh ncn-w001
  ```

* Master node

  ```
  ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/rebuild/ncn-rebuild-master-nodes.sh ncn-m002
  ```

* [Storage node](Prepare_Storage_Nodes.md)

## Validation

After completing all of the steps, run the [Final Validation](Final_Validation_Steps.md) steps.