# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure,
or some other issue with the node has occurred that warrants rebuilding the node.

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

Variables set with the name of the node being rebuilt and its component name (xname) are required.

- Set `NODE` to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
- Set `XNAME` to the component name (xname) of that node.

```bash
NODE=ncn-w00n
XNAME=$(ssh $NODE cat /etc/cray/xname)
echo $XNAME
```

## Procedure

Only follow the steps in the section for the node type that is being rebuilt.

### Worker node

#### Option 1

1. (`ncn-m001#`) Run `ncn-upgrade-worker-storage-nodes.sh` for `ncn-w001`.

   Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w001
   ```

   > **`NOTES:`**
     - The `root` user password for the node may need to be reset after it is rebooted.
     - See [Starting a new workflow after a failed workflow](../../argo/Using_Argo_Workflows.md) if this command fails and needs to be restarted.

#### Option 2 (Tech preview)

Multiple workers can be upgraded simultaneously by passing them as a comma-separated list into the rebuild script.

##### Restrictions

In some cases, it is not possible to upgrade all workers in one request. It is system administrator's responsibility to
make sure that the following conditions are met:

- If the system has more than five workers, then they cannot all be rebuilt with a single request.

    In this case, the rebuild should be split into multiple requests, with each request specifying no more than five workers.

- No single rebuild request should include all of the worker nodes that have DVS running on them.

##### Example

(`ncn-m001#`) An example of a single request to rebuild multiple worker nodes simultaneously:

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w002,ncn-w003,ncn-w004
```

### Master node

```bash
/usr/share/doc/csm/upgrade/scripts/rebuild/ncn-rebuild-master-nodes.sh ncn-m002
```

### Storage node

#### Option 1

Rebuild the storage node manually. See [Prepare storage nodes](Prepare_Storage_Nodes.md).

#### Option 2 (Tech preview)

Rebuild the storage node automatically. This rebuilds a storage node via argo workflows. See [Using the Argo UI](../operations/argo/Using_the_Argo_UI.md) and [Using Argo Workflows](../operations/argo/Using_Argo_Workflows.md) before starting the rebuild.

(`ncn-m001#`) Rebuild storage node ncn-s00x:

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s00x --rebuild
```

## Validation

After completing all of the steps, run the [Final Validation](Final_Validation_Steps.md) steps.
