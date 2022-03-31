# Alpha Framework to Add, Remove, Replace or Move NCNs

Add, Remove, Replace or Move worker, storage or master node (NCN). Use this procedure in the event that:

- Worker, storage or master nodes are being replaced and the MAC address is changing.
- Worker or storage nodes are being added.
- Worker, storage or master nodes are being moved to a different cabinet.

The following workflows are available:

- [Prerequisites](#prerequisites)
- [Add Worker, Storage or Master NCNs](#add-worker-storage-master)
   - [Add NCN Prerequisites](#add-ncn-prerequisites)
   - [Add NCN Procedure](#add-ncn-procedure)
- [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)
   - [Remove NCN Prerequisites](#remove-ncn-prerequisites)
   - [Remove NCN Procedure](#remove-ncn-procedure)
- [Replace or Move Worker, Storage or Master NCNs](#replace-worker-storage-master)

<a name="prerequisites"></a>
### Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

All activities required for site maintenance are complete.

The latest docs-csm RPM has been installed on the master nodes.

1. Run ncn_add_remove_replace_ncn_pre-req.py to adjust the network.

   ```bash
   ncn-m# cd /usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/
   ncn-m# ./ncn_add_remove_replace_ncn_pre-req.py 
   ```

   1. Script will ask 3 questions:

      1. How many NCNs would you like to remove?  Do not include NCNs to be add or moved.

      2. How many NCNs would you like to move? Do not include NCNs to be add or remove.

      3. How many NCNs would you like to add? Do not include NCNs to be removed or moved.

   2. When adding new NCNs, there will be network configuration changes that will impact changing IPs on computes. __**That will require DVS restart to update the IPs in the DVS node_map.**__

   3. ncn_add_remove_replace_ncn_pre-req.py will make the network adjustments and will list the xnames that will need to be rebooted after DVS is restarted. See example below:

      ```bash
      Please restart DVS and rebooting the following nodes:["x3000c0s1b0n0", "x3000c0s19b3", "x3000c0s19b1n0", "x3000c0s19b3n0"]
      prerequisite to prepare NCNs for removal, move and add
      Network expansion COMPLETED
      Log and backup of SLS, BSS and SMD can be found at: /tmp/ncn_task_backups2022-02-25_22-59-06
      ncn-m# 
      ```

<a name="add-worker-storage-master"></a>
## Add Worker, Storage or Master NCNs

Use this procedure to add a worker, storage or master non-compute node (NCN).

<a name="add-ncn-prerequisites"></a>
### Add NCN Prerequisites

For several of the commands in this section, you will need to have variables set with the name of the node being added and its xname.
Set NODE to the hostname of the node being added (e.g. `ncn-w001`, `ncn-s002`, etc).

```bash
ncn# NODE=ncn-x00n
```

If the component name (xname) is known, set it now. Otherwise it will be determined in a later step.

```bash
ncn# XNAME=<xname>
ncn# echo $XNAME
```

**IMPORTANT:** Ensure the node being added to the system has been properly configured. If the node being added to the system has not been perviously in the system several settings need to be verified. 
*  Ensure that the NCN device to be added has been racked and cabled per the SHCD.
*  Ensure the NCN BMC is configure with the expected root user credentials.
   
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
*  If adding an NCN that was not previously in the system, follow the [Access and Update the Settings for Replacement NCNs](Access_and_Update_the_Settings_for_Replacement_NCNs.md).
*  Ensure the NCN BMC is configured to use DHCP. (This does not apply to the BMC for ncn-m001 since it is statically configured for the site.)
*  Ensure the NCN is configured to boot over the PCIe NICs instead of the Onboard 1 Gig NICs using the [Switch PXE Boot from Onboard NIC to PCIe](../../instal/../install/switch_pxe_boot_from_onboard_nic_to_pcie.md) procedure.

*   If adding an HPE NCN, ensure IPMI is enabled.

   1. Check to see if IPMI is enabled:
      ```bash
      ncn# export IPMI_PASSWORD=changeme
      ncn# curl -k -u root:$IPMI_PASSWORD https://NCN_NODE-mgmt/redfish/v1/Managers/1/NetworkProtocol | jq .IPMI
      ```

      Expected output:
      ```json
      {
         "Port": 623,
         "ProtocolEnabled": true
      }
      ```

   2. If disabled is disabled, then enable IPMI:
      ```bash
      ncn# curl -k -u root:$IPMI_PASSWORD -X PATCH \
         -H 'Content-Type: application/json' \
         -d '{"IPMI": {"Port": 623, "ProtocolEnabled": true}}' \
         https://NCN_NODE-mgmt/redfish/v1/Managers/1/NetworkProtocol | jq
      ```

      Expected output:
      ```
      {
         "error": {
            "code": "iLO.0.10.ExtendedInfo",
            "message": "See @Message.ExtendedInfo for more information.",
            "@Message.ExtendedInfo": [
               {
               "MessageId": "iLO.2.14.ResetRequired"
               }
            ]
         }
      }
      ```

   3. If disabled IPMI was disabled, then restart the BMC:
      ```bash
      ncn# curl -k -u root:$IPMI_PASSWORD -X POST \
         -H 'Content-Type: application/json' \
         -d '{"ResetType": "GracefulRestart"}' \
         https://NCN_NODE-mgmt/redfish/v1/Managers/1/Actions/Manager.Reset | jq
      ```

      Expected output:
      ```json
      {
         "error": {
            "code": "iLO.0.10.ExtendedInfo",
            "message": "See @Message.ExtendedInfo for more information.",
            "@Message.ExtendedInfo": [
               {
               "MessageId": "iLO.2.14.ResetInProgress"
               }
            ]
         }
         }
      ```
<a name="add-ncn-procedure"></a>
### Add NCN Procedure

The following is a high-level overview of the add NCN workflow:

1. [Allocate NCN IP Addresses](Add_Remove_Replace_NCNs/Allocate_NCN_IP_Addresses.md)

2. [Add Switch Config](Add_Remove_Replace_NCNs/Add_Switch_Config.md)

3. [Add NCN data](Add_Remove_Replace_NCNs/Add_NCN_Data.md) for SLS, BSS and HSM

4. [Update Firmware](Add_Remove_Replace_NCNs/Update_Firmware.md) via FAS

5. [Boot NCN and Configure](Add_Remove_Replace_NCNs/Boot_NCN.md)

6. [Redeploy Services](Add_Remove_Replace_NCNs/Redeploy_Services.md)

7. [Validate NCN](Add_Remove_Replace_NCNs/Validate_NCN.md)

8. [Validate Health](Add_Remove_Replace_NCNs/Validate_Health.md)

<a name="remove-worker-storage-master"></a>
## Remove Worker, Storage or Master NCNs

Use this procedure to remove a worker, storage or master node (NCN).

<a name="remove-ncn-prerequisites"></a>
### Remove NCN Prerequisites

Open two sessions, one on the node that is to be removed and another on a different master or worker node.
For several of the commands in this section, you will need to have variables set with the name of the node being removed and its xname.
Set NODE to the hostname of the node being removed (e.g. `ncn-w001`, `ncn-s002`, etc).
Set XNAME to the xname of that node.

```bash
ncn# NODE=ncn-x00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```
<a name="remove-ncn-procedure"></a>
### Remove NCN Procedure

The following is a high-level overview of the remove NCN workflow:

1. [Remove NCN from Role, Wipe the Disks and Power Down](Add_Remove_Replace_NCNs/Remove_NCN_from_Role.md)

2. [Remove NCN data](Add_Remove_Replace_NCNs/Remove_NCN_Data.md) from SLS, BSS and HSM

3. [Remove Switch Config](Add_Remove_Replace_NCNs/Remove_Switch_Config.md)

4. [Redeploy Services](Add_Remove_Replace_NCNs/Redeploy_Services.md)

5. [Validate Health](Add_Remove_Replace_NCNs/Validate_Health.md)

**IMPORTANT:** Update the SHCD to remove the device. This is only needed if no NCN device will be added back to same location with the same cabling.

<a name="replace-worker-storage-master"></a>
## Replace or Move Worker, Storage or Master NCNs

Replacing an NCN is defined as removing an NCN of a given type and adding a different NCN of the same type but with different MAC addresses back into the same cabinet slot.
Moving an NCN is defined as removing an NCN of a given type from one cabinet and adding it back into a different cabinet.

Use the [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master) followed by the [Add Worker, Storage or Master NCNs](#add-worker-storage-master) to replace a worker, storage or master node (NCN). Generally scaling master nodes is not recommended since it can cause Etcd latency.

### Procedure

The following is a high-level overview of the replace NCN workflow:

1. [Remove Worker, Storage or Master NCNs](#remove-worker-storage-master)

2. [Add Worker, Storage or Master NCNs](#add-worker-storage-master)

