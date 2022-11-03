# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure,
or some other issue with the node has occurred that warrants rebuilding the node.

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

Variables set with the name of the node being rebuilt and its component name (xname) are required.

- Set `NODE` to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
- Set `XNAME` to the component name (xname) of that node.

```bash
ncn# NODE=ncn-w00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

## Procedure

Only follow the steps in the section for the node type that is being rebuilt.

***NOTE*** After rebuilding an NCN, kernel dump will need to be fixed. See [Kernel Dump Hotfix](../../../scripts/hotfixes/kdump/README.md) for more information.

### Worker node

1. Make sure that not all pods of `ingressgateway-hmn` or `spire-server` are running on the same worker node.

    For either of those two deployments, if all pods are running on a single worker node, then use the
    `/opt/cray/platform-utils/move_pod.sh` script to move at least one pod to a different worker node.

1. Rebuild the node.

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/rebuild/ncn-rebuild-worker-nodes.sh ncn-w001
    ```

### Master node

```bash
ncn# /usr/share/doc/csm/upgrade/1.2/scripts/rebuild/ncn-rebuild-master-nodes.sh ncn-m002
```

### Storage node

See [Prepare storage nodes](Prepare_Storage_Nodes.md).

## Validation

After completing all of the steps, run the [Final Validation](Final_Validation_Steps.md) steps.
