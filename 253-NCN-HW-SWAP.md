# NCN Hardware Swaps

This page will detail cases for various hardware changes.

- [Node Components](#node-components)
- [Nodes](#nodes)
    - [Rebooting Servers](#rebooting-nodes)
        - [CEPH](#ceph)
        - [Kubernetes](#kubernetes)
- [Safely Removing Nodes from Runtime](#safely-removing-nodes-from-runtime)
    - [Rebuilding CEPH NCNs](#rebuilding-ceph-ncns)
        - [Quorum](#quorum)
    - [Rebuilding K8s NCNs](#rebuilding-k8s-ncns)
        - [Master nodes](#master-nodes)
        - [Worker nodes](#worker-nodes)


<a name='node-components'></a>
# Node Components

Malfunctioning or disabled hardware may need to be removed, or upgrades may want to be installed.

For either case, certain hardware requires that the node be shutdown prior to operations.

| Component | Server Off | Rebuild Required |
| --- | --- | --- |
| cpu | Yes | No |
| ram | Yes | No |
| OS disks | No | No [^1] |
| Ephemeral disks | No | Yes |
| gpu | Yes | No |
| nic | Yes | Yes |

[^1]: If replacing **all** OS disks then a rebuild is required.

<a name='rebooting-nodes'></a>
### Rebooting Nodes

For operations that do not require a rebuild, a power off and cold boot will suffice.

<a name='ceph'></a>
#### CEPH

> **`STUB`** This is a stub that requires code snippets to step-wise replace a storage node (short of rebuilding everything).

<a name='kubernetes'></a>
#### Kubernetes

If the node can be powered off nicely by issuing a `poweroff` command on the CLi, then it will evict its containers
and unmount etcd. On power-up it will re-join.

If the node is unresponsive, you can alert the cluster that you will be rebooting it by evicing the node:
```bash
linux# kubectl drain ncn-w002
```

Then you can reboot, and nicely tell the node to add the node back.
```bash
linux# kubectl uncordon ncn-w002
```

<a name='nodes'></a>
# Nodes

Swapping a node for an entirely new node mandates a "rebuild" (or a "build" if this is the first use).

<a name='safely-removing-nodes-from-runtime'></a>
# Safely Removing Nodes from Runtime

<a name='rebuilding-ceph-ncns'></a>
## Rebuilding CEPH NCNs

> **`STUB`** This is a stub that requires code snippets to step-wise replace a storage node (short of rebuilding everything).

<a name='quorum'></a>
### Quorum

> **`STUB`** This is a stub that requires definition of constraints put on by the ceph cluster when rebuilding nodes.


<a name='rebuilding-k8s-ncns'></a>
## Rebuilding Kubernetes NCNs

<a name='master-nodes'></a>
### Master Nodes

If etcd has met quorum, if there are 3 master nodes active, then etcd must expunge the node we're rebuilding.

1. Evict etcd:
    > **`STUB`** This is a stub that requires code snippets to search-and-destroy OOM.
2. Follow the procedure for [worker nodes](#worker-nodes).


<a name='worker-nodes'></a>
### Worker Nodes

It is dangerous to run with 2 worker nodes or less, work must be done with diligence or pod clean-up will be necessary. Kubernetes pods will begin to throw Out-Of-Memory error after some time.

1. Drain the target worker node, issue the command from your laptop (if authenticated) or from an ingress node (such as ncn-m001):
    ```bash
    linux# kubectl drain ncn-w002
    linux# kubectl delete ncn-w002
    ```

2. Power down the node either in rack, or with `ipmitool`
    ```bash
    IPMI_PASSWORD=
    username=root
    ipmitool -I lanplus -U $username -E -H ncn-w002-mgmt power off
    ```
3. Now commence the operations on the node.

4. Once ready, power the node on in the rack or with `ipmitool`
    ```bash
    IPMI_PASSWORD=
    username=root
    ipmitool -I lanplus -U $username -E -H ncn-w002-mgmt power on
    ```
5. The node will netboot from sysmgmt services (kea/unbound/s3/bss).

> **`NOTE`** If sysmgmt services are not booting the NCN, and the LiveCD is still available. See [069 Toggle PXE Sources](./069-TOGGLE-PXE-SOURCES.md) for pivoting boot services temporarily back to the LiveCD.

6. The node will run cloud-init and will auto-join the cluster again. Monitor for status with:
    ```bash
    linux# kubectl get nodes -w 
    ```

Once your node returns to the cluster, the procedure is done.

<a name='cleaning-up-out-of-memory-pods'></a>
##### Cleaning up Out-Of-Memory Pods

> **`STUB`** This is a stub that requires code snippets to search-and-destroy OOM.
