# Alpha Framework to Add, Remove or Replace NCNs

- [Add Worker, Storage or Master NCNs](#add-worker-storage-master)
- [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)
- [Replace Worker, Storage or Master NCNs](#replace-worker-storage-master)

<a name="add-worker-storage-master"></a>
## Add Worker, Storage or Master NCNs

Use this procedure to add a worker, storage or master non-compute node (NCN).

<a name="prerequisites"></a>
### Prerequisites

The system is fully installed and has transitioned off of the LiveCD.
For several of the commands in this section, you will need to have variables set with the name of the node being rebuilt and its xname.

Set NODE to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
Set XNAME to the xname of that node.

```bash
ncn# NODE=ncn-w00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

### Procedure

The following is a high-level overview of the NCN add workflow:

1. [Validate SHCD](Add_Remove_Replace_NCNs/Validate_SHCD.md#validate-shcd-before-adding-ncn)

2. [Update Networking](Add_Remove_Replace_NCNs/Update_Networking.md#update-networking-to-add-ncn)

3. [Update SLS](Add_Remove_Replace_NCNs/Update_SLS.md#update-sls-to-add-ncn)

4. [Update HMS](Add_Remove_Replace_NCNs/Update_HMS.md#update-hms-to-add-ncn)

5. [Update BSS](Add_Remove_Replace_NCNs/Update_BSS.md#update-bss-to-add-ncn)

6. [Update Firmware](Add_Remove_Replace_NCNs/Update_Firmware.md) via FAS

7. [Boot NCN](Add_Remove_Replace_NCNs/Boot_NCN.md)

8. [Validation](Add_Remove_Replace_NCNs/Validation.md#validate-added-ncn)


<a name="remove-worker-storage-master"></a>
## Remove Worker, Storage or Master NCNs

Use this procedure to remove a worker, storage or master node (NCN).

### Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

### Procedure

The following is a high-level overview of the NCN add workflow:

1. [Remove NCN from Role](Add_Remove_Replace_NCNs/Remove_NCN_from_Role.md)

2. [Update BSS](Add_Remove_Replace_NCNs/Update_BSS.md#update-bss-to-remove-ncn)

3. [Update HMS](Add_Remove_Replace_NCNs/Update_HMS.md#update-hms-to-remove-ncn)

4. [Update SLS](Add_Remove_Replace_NCNs/Update_SLS.md#update-sls-to-remove-ncn)

5. [Update Networking](Add_Remove_Replace_NCNs/Update_Networking.md#update-networking-to-remove-ncn)

6. [Validate SHCD](Add_Remove_Replace_NCNs/Validate_SHCD.md#validate-shcd-after-removing-ncn)

7. [Validation](Add_Remove_Replace_NCNs/Validation.md#validate-removed-ncn)


<a name="replace-worker-storage-master"></a>
## Replace Worker, Storage or Master NCNs

Use the [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master) followed by the [Add Worker, Storage or Master NCNs](#remove-worker-storage-master) to replace a worker, storage or master node (NCN). Generally scaling master nodes is not recommended since it can cause etcd latency.

### Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

### Procedure

1. [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)

2. [Add Worker, Storage or Master NCNs](#remove-worker-storage-master)

