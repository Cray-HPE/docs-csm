# NCN Hardware Swaps

This page will detail cases for various hardware changes.

- [Server Components](#server-components)
- [Servers](#servers)
    - [Rebooting Servers](#rebooting-servers)
        - [CEPH](#ceph)
        - [Kubernetes](#kubernetes)
- [Safely Removing Nodes from Runtime](#safely-removing-nodes-from-runtime)
    - [Rebuilding CEPH NCNs](#rebuilding-ceph-ncns)
        - [Quorum](#quorum)
    - [Rebuilding K8s NCNs](#rebuilding-k8s-ncns)
        - [Masters](#master-servers)
        - [Workers](#worker-servers)


<a name='server-components'></a>
# Server Components

Malfunctioning or disabled hardware may need to be removed, or upgrades may want to be installed.

For either case, certain hardware requires that the server be shutdown prior to operations.

| Component | Server Off | Rebuild Required |
| --- | --- | --- |
| cpu | Yes | No |
| ram | Yes | No |
| OS disks | No | No [^1] |
| Ephemeral disks | No | Yes |
| gpu | Yes | No |
| nic | Yes | Yes |

[^1]: If replacing **all** OS disks then a rebuild is required.

<a name='rebooting-servers'></a>
### Rebooting Servers

For operations that do not require a rebuild, a power off and cold boot will suffice.

<a name='ceph'></a>
#### CEPH

> **`STUB`** This is a stub that requires code snippets to step-wise replace a storage node (short of rebuilding everything).

<a name='kubernetes'></a>
#### Kubernetes

If the server can be powered off nicely by issuing a `poweroff` command on the CLi, then it will evict its containers
and unmount etcd. On power-up it will re-join.

If the server is unresponsive, you can alert the cluster that you will be rebooting it by evicing the node:
```bash
linux# kubectl drain ncn-w002
```

Then you can reboot, and nicely tell the server to add the node back.
```bash
linux# kubectl uncordon ncn-w002
```

<a name='servers'></a>
# Servers

Swapping a server for an entirely new server mandates a "rebuild" (or a "build" if this is the first use).

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

<a name='master-servers'></a>
### Master Servers

If etcd has met quorum, if there are 3 managers active, then etcd must expunge the server we're rebuilding.

1. Evict etcd:
    > **`STUB`** This is a stub that requires code snippets to search-and-destroy OOM.
2. Follow the procedure for [worker servers](#worker-servers).


<a name='worker-servers'></a>
### Worker Servers

It is dangerous to run with 2 workers or less, work must be done with diligence or pod clean-up will be necessary. Kubernetes pods will begin to throw Out-Of-Memory error after some time.

1. Drain the target worker, issue the command from your laptop (if authenticated) or from an ingress node (such as ncn-m001):
    ```bash
    linux# kubectl drain ncn-w002
    linux# kubectl delete ncn-w002
    ```

2. Power down the server either in rack, or with `ipmitool`
    ```bash
    IPMI_PASSWORD=
    username=root
    ipmitool -I lanplus -U $username -E -H ncn-w002-mgmt power off
    ipmitool 
    ```
3. Now commence the operations on the server.

4. Once ready, power the server on in the rack or with `ipmitool`
    ```bash
    IPMI_PASSWORD=
    username=root
    ipmitool -I lanplus -U $username -E -H ncn-w002-mgmt power on
    ```
5. The server will netboot from sysmgmt services (kea/unbound/s3/bss).

> **`NOTE`** If sysmgmt services are not booting the NCN, and the LiveCD is still available. See [069 Toggle PXE Sources](./069-TOGGLE-PXE-SOURCES.md) for pivoting boot services temporarily back to the LiveCD.

6. The node will run cloud-init and will auto-join the cluster again. Monitor for status with:
    ```bash
    linux# kubectl get nodes -w 
    ```

Once your node returns to the cluster, the procedure is done.

<a name='cleaning-up-out-of-memory-pods'></a>
##### Cleaning up Out-Of-Memory Pods

> **`STUB`** This is a stub that requires code snippets to search-and-destroy OOM.
