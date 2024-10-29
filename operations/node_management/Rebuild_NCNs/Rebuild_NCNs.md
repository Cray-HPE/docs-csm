# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure,
or some other issue with the node has occurred that warrants rebuilding the node.

- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
- [Validation](#validation)

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

(`ncn#`) Variables set with the name of the node being rebuilt and its component name (xname) are required.

- Set `NODE` to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
- Set `XNAME` to the component name (xname) of that node.

```bash
NODE=ncn-w00n
XNAME=$(ssh $NODE cat /etc/cray/xname)
echo $XNAME
```

## Procedure

Only follow the steps in the section for the node type that is being rebuilt.

> **`NOTE:`** (`ncn#`) If the CSM version is 1.6.0 or lower, then restart the `goss-servers` service on the rebuilt node after it has been rebuilt.
> This is necessary because of a timing issue that is fixed in CSM 1.6.1.
> The service restart will cause no harm if done on CSM 1.6.1 or higher, but it is unnecessary.
>
> ```bash
> ssh "${NODE}" 'systemctl restart goss-servers'
> ```

- [Worker node](#worker-node)
- [Master node](#master-node)
- [Storage node](#storage-node)

### Worker node

#### Option 1

(`ncn-m001#`) Run `ncn-upgrade-worker-storage-nodes.sh` for `ncn-w001`.

Follow output of the script carefully. The script will pause for manual interaction.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w001
```

> **`NOTES:`**
>
> - The `root` user password for the node may need to be reset after it is rebooted.
> - See [Starting a new workflow after a failed workflow](../../argo/Using_Argo_Workflows.md) if this command fails and needs to be restarted.

#### Option 2 (Tech preview)

Multiple workers can be upgraded simultaneously by passing them as a comma-separated list into the rebuild script.

##### Restrictions

In some cases, it is not possible to upgrade all workers in one request. It is system administrator's responsibility to
make sure that the following conditions are met:

- If the system has more than five workers, then they cannot all be rebuilt with a single request.

    In this case, the rebuild should be split into multiple requests, with each request specifying no more than five workers.

- No single rebuild request should include all of the worker nodes that have DVS running on them. For High Availability, DVS requires at least two workers running DVS and CPS at all times.

- When rebuilding worker nodes which are running DVS, it is not recommended to simultaneously reboot compute nodes. This is to avoid restarting DVS clients and servers at the same time.

##### Example

(`ncn-m001#`) An example of a single request to rebuild multiple worker nodes simultaneously:

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w002,ncn-w003,ncn-w004
```

### Master node

Master node rebuilds require that the environment variables `CSM_RELEASE` and `CSM_ARTI_DIR` be set on the node where the rebuild script is executed.

(`ncn-m#`) Set the `CSM_RELEASE` and `CSM_ARTI_DIR` environment variables. Replace `1.4.0` with the correct CSM release version:

```bash
export CSM_RELEASE=1.4.0
export CSM_ARTI_DIR="/etc/cray/upgrade/csm/csm-${CSM_RELEASE}/tarball/csm-${CSM_RELEASE}"
```

> **`NOTES:`**
>
> - If the `/etc/cray/upgrade/csm/` directory is empty, create an empty directory at the same path. Download and extract CSM tarball to that directory.
> - Update the value of `CSM_ARTI_DIR` with the newly created directory above.
> - Download and install/upgrade the **latest** documentation on `ncn-m001` at path `/root/<rpm>`. See [Check for Latest Documentation](../../../update_product_stream/README.md#check-for-latest-documentation).
> - Ensure the `/etc/cray/upgrade/csm/` directory is `ceph` mount using the command below (its output should show `ceph` as the type):

```bash
mount | grep /etc/cray/upgrade/csm
```

> - Steps to download CSM tarball are at [Update Product Stream](../../../update_product_stream/README.md).
> - If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../../kubernetes/encryption/README.md),
then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading.
The directory needs to be restored after the node has been rebuilt and the `kube-apiserver` on the node should be restarted.
See [Kubernetes `kube-apiserver` Failing](../../../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.
> - This script should be run from `ncn-m001` when rebuilding `ncn-m002` or `ncn-m003`.

(`ncn-m#`) Rebuild the desired master node. Replace `ncn-m002` with the desired node to rebuild:

```bash
/usr/share/doc/csm/upgrade/scripts/rebuild/ncn-rebuild-master-nodes.sh ncn-m002
```

> **`NOTES:`**
>
> - This script should be run from `ncn-m002` when rebuilding `ncn-m001`.
> - This script should be run from `ncn-m001` when rebuilding `ncn-m002` or `ncn-m003`.

### Storage node

Follow each step below:

1. [Prepare Storage Nodes](Prepare_Storage_Nodes.md)
1. [Identify Nodes and Update Metadata](Identify_Nodes_and_Update_Metadata.md)
1. [Power Cycle and Rebuild Nodes](Power_Cycle_and_Rebuild_Nodes.md)
1. [Re-add Storage Node to Ceph](Re-add_Storage_Node_to_Ceph.md)
1. [Validate Boot Loader](Validate_Boot_Loader.md)
1. [Storage Node Validation](Post_Rebuild_Storage_Node_Validation.md)

## Validation

After completing all of the steps, run the [Final Validation](Final_Validation_Steps.md) steps.
