# Remove Roles

## Description

Remove master, worker or storage NCN from current roles. Select the procedure below based on the node type, then complete the remaining wipe the drives and power off the node steps.

## Procedure

**IMPORTANT:** The following procedures assume you have set the variables from [the prerequisites section](../Add_Remove_Replace.md#remove-prerequisites)

- [Master node](#master-node-remove-roles)
- [Worker node](#worker-node-remove-roles)
- [Storage node](#storage-node-remove-roles)
- [Wipe the drives](#wipe-the-drives)
- [Power off the node](#power-off-the-node)


<a name="master-node-remove-roles"></a>
## Master Node Remove Roles

### Step 1 - Remove the node from the Kubernetes cluster.

**IMPORTANT:** Run this command from a node ***NOT*** being deleted.

  ```bash
  ncn-mw# kubectl delete node $NODE
  ```

### Step 2 - Remove the Node from Etcd.

1. Determine the member ID of the master node being removed.

    * Run the following command and find the line with the name of the master being removed. Note the member ID and IP address for use in subsequent steps.
      * The ***member ID*** is the alphanumeric string in the first field of that line.
      * The ***IP address*** is in the URL in the fourth field in the line.

    On any master node:

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt  --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member list
    ```

1. Remove the master node from the etcd cluster backing Kubernetes.

    Replace the `<MEMBER_ID>` value with the value returned in the previous sub-step.

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member remove <MEMBER_ID>
    ```

### Step 3 - Stop kubelet and containerd services ***on the master node being removed***.

  ```bash
  systemctl stop kubelet.service
  systemctl stop containerd.service
  ```

### Step 4 - Stop Etcd service ***on the master node being removed***.

  ```bash
  systemctl stop etcd.service
  ```

### Step 5 - Remove Etcd data directory ***on the master node being removed***.

  ```bash
  rm -rf /var/lib/etcd
  ```

  The master node role removal is complete; proceed to [wipe the drives](#wipe-the-drives).

<a name="worker-node-remove-roles"></a>
## Worker Node Remove Roles

### Step 1 - Drain the node to clear any pods running on the node.

**IMPORTANT:** The following command will cordon and drain the node.

Run the following:

  ```bash
  ncn-mw# kubectl drain --ignore-daemonsets --delete-local-data $NODE
  ```

* You may run into pods that cannot be gracefully evicted due to Pod Disruption Budgets (PDB), for example:

    ```screen
      error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
    ```

* In this case, there are some options. First, if the service is scalable, you can increase the scale to start up another pod on another node, and then the drain will be able to delete it. However, it will probably be necessary to force the deletion of the pod:

    ```bash
    ncn-mw# kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
    ```

* This will delete the offending pod, and Kubernetes should schedule a replacement on another node. You can then rerun the `kubectl drain` command, and it should report that the node is drained

### Step 2 - Remove the node from the Kubernetes cluster after the node is drained.

  ```bash
  ncn-mw# kubectl delete node $NODE
  ```
### Step 3 - Ensure all pods are stopped.

  ```bash
  ncn-mw# kubectl get pods -A -o wide | grep $NODE
  ```

  If no pods are returned, proceed to the next step, otherwise wait for any remaining pods to Terminate.

### Step 4 - Ensure there are no mapped rbd devices ***on the worker node being removed***.

  ```bash
  rbd showmapped
  ```

  If no devices are returned, then the worker node role removal is complete; proceed to [wipe the drives](#wipe-the-drives). If mapped devices still exist, re-check Step 3, then Step 4 again. If devices are still mapped, they can be forceability unmapped using `rbd unmap -o force /dev/rbd#`, where /dev/rbd# is the device that is still returned as mapped.

<a name="storage-node-remove-roles"></a>
## Storage Node Procedure

Follow [Remove Ceph Node](../../utility_storage/Remove_Ceph_Node.md) to remove Ceph role from the storage node.

Once the storage node role removal is complete; proceed to [wipe the drives](#wipe-the-drives).

<a name="wipe-the-drives"></a>
## Wipe the Drives

Follow [Full Wipe](../../../install/wipe_ncn_disks_for_reinstallation.md#3-full-wipe) Procedure to wipe the drives on the NCN that is being removed.

Once the wipe of the drives is complete; proceed to [power off the node](#power-off-the-node).

<a name="power-off-the-node"></a>
## Power Off the Node

**IMPORTANT:** Run these commands from a node ***NOT*** being powered off.

1. Set the BMC variable to the hostname of the BMC of the node being powered off.

    ```bash
    BMC=${NODE}-mgmt
    ```

2. Export the root password of the BMC.

    ```bash
    export IPMI_PASSWORD=changeme
    ```

3. Power off the node.

     ```bash
     ipmitool -I lanplus -U root -E -H $BMC chassis power off
     ```

4. Verify that the node is off.

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis power status
    ```

    * Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing any further commands.

