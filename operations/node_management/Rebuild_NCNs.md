# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure, or some other issue with the node has occurred that warrants rebuilding the node.

## Prerequisites

* The system is fully installed and has transitioned off of the LiveCD.

* Set variables with the name of the node being rebuilt and its corresponding xname.
  
  Set NODE to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
  Set XNAME to the xname of that node.
  
  ```bash
  ncn# NODE=ncn-w00n
  ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
  ncn# echo $XNAME
  ```

## Procedure

The following is a high-level overview of the NCN rebuild workflow:

1. Prepare Node
   
   There is a different procedure for each type of node (worker, master, and storage).
   Only follow the steps in the section for the node type that is being rebuilt:

   * [Prepare Worker Nodes](Rebuild_NCNs/Prepare_Worker_Nodes.md)
   * [Prepare Master Nodes](Rebuild_NCNs/Prepare_Master_Nodes.md)
   * [Prepare Storage Nodes](Rebuild_NCNs/Prepare_Storage_Nodes.md)

2. Identify Nodes and Update Metadata
   
   Same procedure for all node types. 
   See [Identify Nodes and Update Metadata](Rebuild_NCNs/Identify_Nodes_and_Update_Metadata.md).

3. Wipe Disks
   
   Same for master and worker nodes, but different for storage nodes.
   See [Wipe Disks](Rebuild_NCNs/Wipe_Disks.md).

4. Power Cycle Node
   
   Same procedure for all node types.
   See [Power Cycle and Rebuild Nodes](Rebuild_NCNs/Power_Cycle_and_Rebuild_Nodes.md).

5. Rebuild Storage Node
   
   Only needed for storage nodes.
   See [Re-add Storage Node to Ceph](Rebuild_NCNs/Re-add_Storage_Node_to_Ceph.md).

6. Validate `BOOTRAID` Artifacts
   
   Must be run from ncn-m001.
   See [Validate Boot Raid](Rebuild_NCNs/Validate_Boot_Raid.md).

7. Validate Nodes
   
   There is a different procedure for each type of node (worker, master, and storage):

   * [Post Rebuild Worker Node Validation](Rebuild_NCNs/Post_Rebuild_Worker_Node_Validation.md)
   * [Post Rebuild Master Node Validation](Rebuild_NCNs/Post_Rebuild_Master_Node_Validation.md)
   * [Post Rebuild Storage Node Validation](Rebuild_NCNs/Post_Rebuild_Storage_Node_Validation.md)

8. Final Validation
   
   After completing all of the steps, run the **Final Validation** steps.
   See [Post NCN Rebuild Validation](Rebuild_NCNs/Post_NCN_Rebuild_Validation.md).


