# Alpha Framework to Add, Remove or Replace NCNs

- [Prerequisites](#prerequisites)
- [Add Worker, Storage or Master NCNs](#add-worker-storage-master)
- [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)
- [Replace or Move Worker, Storage or Master NCNs](#replace-worker-storage-master)

<a name="prerequisites"></a>
### Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

1. All activities required for site maintenence are complete.

1. Run the ncn_add_remove_replace_ncn_pre-req.py

   1. Script will ask 3 questions:

      1. How many NCNs would you like to remove?  Do not include NCNs to be add or moved.

      2. How many NCNs would you like to move? Do not include NCNs to be add or remove.

      3. How many NCNs would you like to add? Do not include NCNs to be removed or moved.

2. When adding new NCNs, there will be network configuration changes that will impact changing IPs on computes.  __**That will require DVS restart to update the IPs in the DVS node_map.**__

3. ncn_add_remove_replace_ncn_pre-req.py will make the network adjustments and will list the xnames that will need to be rebooted after DVS is restarted.  See exmple below:
   ```bash
   Please restart DVS and rebooting the following nodes:["x3000c0s1b0n0", "x3000c0s19b3", "x3000c0s19b1n0", "x3000c0s19b3n0"]
   prerequisite to prepare NCNs for removal, move and add
   COMPLETED
   Log and backup of SLS, BSS and SMD can be found at: /tmp/ncn_task_backups2022-02-25_22-59-06
   ncn-m001:~/ # 
   ```

<a name="add-worker-storage-master"></a>
## Add Worker, Storage or Master NCNs

Use this procedure to add a worker, storage or master non-compute node (NCN).

<a name="add-prerequisites"></a>
### Prerequisites

For several of the commands in this section, you will need to have variables set with the name of the node being added and its xname.
Set NODE to the hostname of the node being added (e.g. `ncn-w001`, `ncn-s002`, etc).

```bash
ncn# NODE=ncn-x00n
```

Determine the xname of the NCN by referring to the HMN of the systems SHCD if it has not been determined yet yet.

   Sample row from the HMN tab of a SHCD:
   | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
   | --------------- | ----------------- | --------------------- | ----- | ------------ | ---- | ----------------- | ----------------- | ---------------------- | -------------------------- | ----- | ---------------------- |
   | wn01            | x3000             | u04                   | -     |              |      | j3                | sw-smn01          | x3000                  | u14                        | -     | j48                    |

   Xname format: xXcCsSbBnN
   |   |                |                       | Description
   | - | -------------- | --------------------- | ----------- 
   | X | Cabinet number | SourceRack (K20)      |
   | C | Chassis number |                       | For River nodes the chassis is 0.
   | S | Slot/Rack U    | Source Location (L20) | The Slot of the node is determined by the bottom most rack U that node occupies.
   | B | BMC number     |                       | For Management NCNs the BMC number is 0.
   | N | Node number    |                       | For Management NCNs the Node number is 0.

   From the sample HMN Row the corresponding NCN Node xname is x3000c0s4b0n0.

```bash
ncn# XNAME=<xname>
ncn# echo $XNAME
```

```bash
ncn-m# export XNAME=x3000c0s4b0n0
```
### Procedure

The following is a high-level overview of the NCN add workflow:

1. [Validate SHCD](Add_Remove_Replace_NCNs/Validate_SHCD.md#validate-shcd-before-adding-ncn)

2. [Update Networking](Add_Remove_Replace_NCNs/Update_Networking.md#update-networking-to-add-ncn)

3. [Add NCN data](Add_Remove_Replace_NCNs/Add_NCN_Data.md) for SLS, HMS and BSS

4. [Update Firmware](Add_Remove_Replace_NCNs/Update_Firmware.md) via FAS

5. [Boot NCN](Add_Remove_Replace_NCNs/Boot_NCN.md)

6. [Validation](Add_Remove_Replace_NCNs/Validation.md)

<a name="remove-worker-storage-master"></a>
## Remove Worker, Storage or Master NCNs

Use this procedure to remove a worker, storage or master node (NCN).

<a name="remove-prerequisites"></a>
### Prerequisites

For several of the commands in this section, you will need to have variables set with the name of the node being removed and its xname.
Set NODE to the hostname of the node being removed (e.g. `ncn-w001`, `ncn-s002`, etc).
Set XNAME to the xname of that node.

```bash
ncn# NODE=ncn-x00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

1. Run the ncn_add_remove_replace_ncn_pre-req.py
   1. Script will ask 3 questions:
      1. How many NCNs would you like to remove?  Do not include NCNs to be add or moved.

      2. How many NCNs would you like to move? Do not include NCNs to be add or remove.

      3. How many NCNs would you like to add? Do not include NCNs to be removed or moved.
2. When adding new NCNs, there will be network configuration changes that will impact changing IPs on computes.  __**That will require DVS restart to update the IPs in the DVS node_map.**__
3. ncn_add_remove_replace_ncn_pre-req.py will make the network adjustments and will list the xnames that will need to be rebooted after DVS is restarted.  See exmple below:
   ```bash
   Please restart DVS and rebooting the following nodes:["x3000c0s1b0n0", "x3000c0s19b3", "x3000c0s19b1n0", "x3000c0s19b3n0"]
   prerequisite to prepare NCNs for removal, move and add
   COMPLETED
   Log and backup of SLS, BSS and SMD can be found at: /tmp/ncn_task_backups2022-02-25_22-59-06
   ncn-m001:~/ # 
   ```

### Procedure

The following is a high-level overview of the NCN add workflow:

1. [Remove NCN from Role](Add_Remove_Replace_NCNs/Remove_NCN_from_Role.md)

2. [Remove NCN data](Add_Remove_Replace_NCNs/Remove_NCN_Data.md) from SLS, HMS and BSS

3. [Update Networking](Add_Remove_Replace_NCNs/Update_Networking.md#update-networking-to-remove-ncn)

4. [Validate SHCD](Add_Remove_Replace_NCNs/Validate_SHCD.md#validate-shcd-after-removing-ncn)

5. [Validation](Add_Remove_Replace_NCNs/Validation.md)


<a name="replace-worker-storage-master"></a>
## Replace or Move Worker, Storage or Master NCNs

Replacing an NCN is defined as removing an NCN of a given type and adding a different NCN of the same type back into the same cabinet slot.
Moving an NCN is defined as removing an NCN of a given type from one cabinet and adding it back into a different cabinet.

Use the [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master) followed by the [Add Worker, Storage or Master NCNs](#add-worker-storage-master) to replace a worker, storage or master node (NCN). Generally scaling master nodes is not recommended since it can cause Etcd latency.

### Procedure

1. [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)

2. [Add Worker, Storage or Master NCNs](#add-worker-storage-master)

