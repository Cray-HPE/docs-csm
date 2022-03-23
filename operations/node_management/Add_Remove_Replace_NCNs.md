# Alpha Framework to Add, Remove or Replace NCNs

- [Prerequisites](#prerequisites)
- [Add Worker, Storage or Master NCNs](#add-worker-storage-master)
- [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)
- [Replace or Move Worker, Storage or Master NCNs](#replace-worker-storage-master)

<a name="prerequisites"></a>
### Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

1. All activities required for site maintenance are complete.

2. Run the ncn_add_remove_replace_ncn_pre-req.py

   1. Script will ask 3 questions:

      1. How many NCNs would you like to remove?  Do not include NCNs to be add or moved.

      2. How many NCNs would you like to move? Do not include NCNs to be add or remove.

      3. How many NCNs would you like to add? Do not include NCNs to be removed or moved.

3. When adding new NCNs, there will be network configuration changes that will impact changing IPs on computes.  __**That will require DVS restart to update the IPs in the DVS node_map.**__

4. ncn_add_remove_replace_ncn_pre-req.py will make the network adjustments and will list the xnames that will need to be rebooted after DVS is restarted.  See exmple below:
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

If the XNAME is known, set it now. Otherwise it will be determined in a later step.

```bash
ncn# XNAME=<xname>
ncn# echo $XNAME
```

**Important** if the node being added to the system TODO... want to make sure it is already setup
* If adding a NCN that was not previously in the system follow the [Access and Update the Settings for Replacement NCNs](Access_and_Update_the_Settings_for_Replacement_NCNs.md).
* Ensure the NCN BMC is configured to use DHCP.
* Ensure the NCN is configured to boot over the PCIe NICs instead of the Onboard 1 Gig NICs using the [Switch PXE Boot from Onboard NIC to PCIe](../../instal/../install/switch_pxe_boot_from_onboard_nic_to_pcie.md) procedure.
* Ensure the NCN BMC is configure with the expected root user credentials.
   
   The NCN BMC credentials needs to match the current global air-cooled BMC default credentials. This can be viewed with the following command:
    ```bash
    ncn-m# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    ncn-m# kubectl -n vault exec -it cray-vault-0 -c vault -- env \
      VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 \
      vault kv get secret/reds-creds/defaults
    ```

    Example output:
    ```bash
    ==== Data ====
    Key     Value
    ---     -----
    Cray    map[password:foobar username:root] 
    ```

* If adding an HPE NCN, ensure IPMI is enabled. 

### Procedure

The following is a high-level overview of the add NCN workflow:

1. [Validate SHCD](Add_Remove_Replace_NCNs/Validate_SHCD.md#validate-shcd-before-adding-ncn)

2. [Allocate NCN IP Addresses](Add_Remove_Replace_NCNs/Allocate_NCN_IP_Addresses.md)

3. [Update Networking](Add_Remove_Replace_NCNs/Update_Networking.md#update-networking-to-add-ncn)

4. [Add NCN data](Add_Remove_Replace_NCNs/Add_NCN_Data.md) for SLS, BSS and HSM

5. [Update Firmware](Add_Remove_Replace_NCNs/Update_Firmware.md) via FAS

6. [Boot NCN](Add_Remove_Replace_NCNs/Boot_NCN.md)

7. [Validation](Add_Remove_Replace_NCNs/Validation.md)

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

The following is a high-level overview of the remove NCN workflow:

1. [Remove NCN from Role](Add_Remove_Replace_NCNs/Remove_NCN_from_Role.md)

2. [Remove NCN data](Add_Remove_Replace_NCNs/Remove_NCN_Data.md) from SLS, BSS and HSM

3. [Update Networking](Add_Remove_Replace_NCNs/Update_Networking.md#update-networking-to-remove-ncn)

4. [Validate SHCD](Add_Remove_Replace_NCNs/Validate_SHCD.md#validate-shcd-after-removing-ncn)

5. [Validation](Add_Remove_Replace_NCNs/Validation.md)


<a name="replace-worker-storage-master"></a>
## Replace or Move Worker, Storage or Master NCNs

Replacing an NCN is defined as removing an NCN of a given type and adding a different NCN of the same type back into the same cabinet slot.
Moving an NCN is defined as removing an NCN of a given type from one cabinet and adding it back into a different cabinet.

Use the [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master) followed by the [Add Worker, Storage or Master NCNs](#add-worker-storage-master) to replace a worker, storage or master node (NCN). Generally scaling master nodes is not recommended since it can cause Etcd latency.

### Procedure

The following is a high-level overview of the replace NCN workflow:

1. [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)

2. [Add Worker, Storage or Master NCNs](#add-worker-storage-master)

