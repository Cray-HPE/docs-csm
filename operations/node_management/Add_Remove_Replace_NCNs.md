# Alpha Framework to Add, Remove, Replace, or Move NCNs

Add, remove, replace, or move non-compute nodes (NCNs). This applies to worker, storage, or master nodes. Use this procedure in the event that:

* Worker, storage, or master nodes are being replaced and the MAC address is changing.
* Worker or storage nodes are being added.
* Worker, storage, or master nodes are being moved to a different cabinet.

**IMPORTANT:** Always maintain at least two of the first three worker, storage, and master nodes when adding, removing, replacing, or moving NCNs.

The following workflows are available:

* [Prerequisites](#prerequisites)
* [Add Worker, Storage, or Master NCNs](#add-worker-storage-master)
  * [Add NCN Prerequisites](#add-ncn-prerequisites)
  * [Add NCN Procedure](#add-ncn-procedure)
* [Remove Worker, Storage, or Master NCNs](#remove-worker-storage-master)
  * [Remove NCN Prerequisites](#remove-ncn-prerequisites)
  * [Remove NCN Procedure](#remove-ncn-procedure)
* [Replace or Move Worker, Storage, or Master NCNs](#replace-worker-storage-master)

<a name="prerequisites"></a>

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

All activities required for site maintenance are complete.

The latest `docs-csm` RPM has been installed on the master nodes. See [Check for Latest Documentation](../../update_product_stream/index.md#documentation)

1. Run `ncn_add_pre-req.py` to adjust the network.

   ```bash
   ncn-m# cd /usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/
   ncn-m# ./ncn_add_pre-req.py 
   ```

   The script will ask the following question:

   ```text
   How many NCNs would you like to add? Do not include NCNs to be removed or moved.
   ```

   Example output:

   ```text
    The prerequisite script prepares adding NCNs by adjusting SLS network configurations.


    Please enter answer as an integer.
    How many NCNs would you like to add? Do not include NCNs to be removed or moved.
    10

    You are about to make DESTRUCTIVE changes to the system and will need to restart DVS.

    If you are sure you want to proceed.  Please type: PROCEED

    If you want to stop.  Type: exit or press ctrl-c

    PROCEED

    Checking HMN.
    last_reserved_ip: 10.254.1.20    start_dhcp_pool:10.254.1.26
    The space between last_reserved_ip and start_dhcp_pool is 6 IP.

    There is not enough static IP space to add an NCN.Adjusting DHCP pool start.
    {'HMN': {'10.254.1.33', '10.254.1.35', '10.254.1.36', '10.254.1.38', '10.254.1.34', '10.254.1.39', '10.254.1.22', '10.254.1.29', '10.254.1.40', '10.254.1.27', 
             '10.254.1.21', '10.254.1.28', '10.254.1.26', '10.254.1.30', '10.254.1.31', '10.254.1.32', '10.254.1.25', '10.254.1.24', '10.254.1.23', '10.254.1.37'}}

    add_ncn_count: 10
    ip_dhcp_pool_start:
    {'MTL': '10.1.1.17', 'NMN': '10.252.1.20', 'CAN': '10.102.4.22', 'HMN': '10.254.1.26'}
    new_ip_dhcp_pool_start: 
    {'HMN': '10.254.1.47'}


    Checking CAN.
    last_reserved_ip: 10.102.4.14    start_dhcp_pool:10.102.4.22
    The space between last_reserved_ip and start_dhcp_pool is 8 IP.

    There is not enough static IP space to add an NCN.Adjusting DHCP pool start.
    {'HMN': {'10.254.1.33', '10.254.1.35', '10.254.1.36', '10.254.1.38', '10.254.1.34', '10.254.1.39', '10.254.1.22', '10.254.1.29', '10.254.1.40', '10.254.1.27', 
             '10.254.1.21', '10.254.1.28', '10.254.1.26', '10.254.1.30', '10.254.1.31', '10.254.1.32', '10.254.1.25', '10.254.1.24', '10.254.1.23', '10.254.1.37'}, 
     'CAN': {'10.102.4.23', '10.102.4.15', '10.102.4.16', '10.102.4.24', '10.102.4.19', '10.102.4.21', '10.102.4.20', '10.102.4.17', '10.102.4.22', '10.102.4.18'}}

    add_ncn_count: 10
    ip_dhcp_pool_start:
    {'MTL': '10.1.1.17', 'NMN': '10.252.1.20', 'CAN': '10.102.4.22', 'HMN': '10.254.1.26'}
    new_ip_dhcp_pool_start: 
    {'HMN': '10.254.1.47', 'CAN': '10.102.4.33'}


    Checking MTL.
    last_reserved_ip: 10.1.1.10    start_dhcp_pool:10.1.1.17
    The space between last_reserved_ip and start_dhcp_pool is 7 IP.

    There is not enough static IP space to add an NCN.Adjusting DHCP pool start.
    {'HMN': {'10.254.1.33', '10.254.1.35', '10.254.1.36', '10.254.1.38', '10.254.1.34', '10.254.1.39', '10.254.1.22', '10.254.1.29', '10.254.1.40', '10.254.1.27', 
             '10.254.1.21', '10.254.1.28', '10.254.1.26', '10.254.1.30', '10.254.1.31', '10.254.1.32', '10.254.1.25', '10.254.1.24', '10.254.1.23', '10.254.1.37'}, 
     'CAN': {'10.102.4.23', '10.102.4.15', '10.102.4.16', '10.102.4.24', '10.102.4.19', '10.102.4.21', '10.102.4.20', '10.102.4.17', '10.102.4.22', '10.102.4.18'}, 
     'MTL': {'10.1.1.16', '10.1.1.18', '10.1.1.20', '10.1.1.12', '10.1.1.17', '10.1.1.13', '10.1.1.19', '10.1.1.15', '10.1.1.14', '10.1.1.11'}}

    add_ncn_count: 10
    ip_dhcp_pool_start:
    {'MTL': '10.1.1.17', 'NMN': '10.252.1.20', 'CAN': '10.102.4.22', 'HMN': '10.254.1.26'}
    new_ip_dhcp_pool_start: 
    {'HMN': '10.254.1.47', 'CAN': '10.102.4.33', 'MTL': '10.1.1.28'}


    Checking NMN.
    last_reserved_ip: 10.252.1.12    start_dhcp_pool:10.252.1.20
    The space between last_reserved_ip and start_dhcp_pool is 8 IP.

    There is not enough static IP space to add an NCN.Adjusting DHCP pool start.
    {'HMN': {'10.254.1.33', '10.254.1.35', '10.254.1.36', '10.254.1.38', '10.254.1.34', '10.254.1.39', '10.254.1.22', '10.254.1.29', '10.254.1.40', '10.254.1.27', 
             '10.254.1.21', '10.254.1.28', '10.254.1.26', '10.254.1.30', '10.254.1.31', '10.254.1.32', '10.254.1.25', '10.254.1.24', '10.254.1.23', '10.254.1.37'}, 
     'CAN': {'10.102.4.23', '10.102.4.15', '10.102.4.16', '10.102.4.24', '10.102.4.19', '10.102.4.21', '10.102.4.20', '10.102.4.17', '10.102.4.22', '10.102.4.18'}, 
     'MTL': {'10.1.1.16', '10.1.1.18', '10.1.1.20', '10.1.1.12', '10.1.1.17', '10.1.1.13', '10.1.1.19', '10.1.1.15', '10.1.1.14', '10.1.1.11'}, 
     'NMN': {'10.252.1.21', '10.252.1.14', '10.252.1.19', '10.252.1.18', '10.252.1.16', '10.252.1.15', '10.252.1.13', '10.252.1.22', '10.252.1.20', '10.252.1.17'}}

    add_ncn_count: 10
    ip_dhcp_pool_start:
    {'MTL': '10.1.1.17', 'NMN': '10.252.1.20', 'CAN': '10.102.4.22', 'HMN': '10.254.1.26'}
    new_ip_dhcp_pool_start: 
    {'HMN': '10.254.1.47', 'CAN': '10.102.4.33', 'MTL': '10.1.1.28', 'NMN': '10.252.1.31'}

    2022-04-01 21:21:08,859 - __main__ - WARNING - Deleting {"ID": "a4bf013efa5d", "MACAddress": "a4:bf:01:3e:fa:5d", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:08,859 - __main__ - WARNING - Deleting 10.254.1.39 from kea active leases.
    2022-04-01 21:21:08,930 - __main__ - WARNING - Deleting {"ID": "a4bf0138ed46", "MACAddress": "a4:bf:01:38:ed:46", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:08,931 - __main__ - WARNING - Deleting 10.254.1.29 from kea active leases.
    2022-04-01 21:21:09,001 - __main__ - WARNING - Deleting {"ID": "a4bf013ef0c6", "MACAddress": "a4:bf:01:3e:f0:c6", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,001 - __main__ - WARNING - Deleting 10.254.1.27 from kea active leases.
    2022-04-01 21:21:09,067 - __main__ - WARNING - Deleting {"ID": "a4bf01656337", "MACAddress": "a4:bf:01:65:63:37", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,068 - __main__ - WARNING - Deleting 10.254.1.28 from kea active leases.
    2022-04-01 21:21:09,117 - __main__ - WARNING - Deleting {"ID": "a4bf01656854", "MACAddress": "a4:bf:01:65:68:54", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,118 - __main__ - WARNING - Deleting 10.254.1.26 from kea active leases.
    2022-04-01 21:21:09,229 - __main__ - WARNING - Deleting {"ID": "a4bf013eeb53", "MACAddress": "a4:bf:01:3e:eb:53", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,229 - __main__ - WARNING - Deleting 10.254.1.25 from kea active leases.
    2022-04-01 21:21:09,327 - __main__ - WARNING - Deleting {"ID": "a4bf013edd72", "MACAddress": "a4:bf:01:3e:dd:72", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,327 - __main__ - WARNING - Deleting 10.254.1.37 from kea active leases.
    2022-04-01 21:21:09,703 - __main__ - WARNING - Deleting {"ID": "a4bf013edd6e", "MACAddress": "a4:bf:01:3e:dd:6e", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,703 - __main__ - WARNING - Deleting 10.252.1.21 from kea active leases.
    2022-04-01 21:21:09,869 - __main__ - WARNING - Deleting {"ID": "a4bf013ef0c2", "MACAddress": "a4:bf:01:3e:f0:c2", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,870 - __main__ - WARNING - Deleting 10.252.1.22 from kea active leases.
    2022-04-01 21:21:09,934 - __main__ - WARNING - Deleting {"ID": "a4bf013eeb4f", "MACAddress": "a4:bf:01:3e:eb:4f", "IPAddress": []} from SMD EthernetInterfaces.
    2022-04-01 21:21:09,935 - __main__ - WARNING - Deleting 10.252.1.20 from kea active leases.
    Please restart DVS and rebooting the following nodes before proceeding to the next step.:["x3000c0s21b4", "x3000c0s19b0", "x3000c0s21b3", "x3000c0s21b1", "x3000c0s21b2", "x3000c0s21b2n0", "x3000c0s21b3n0", "x3000c0s21b1n0"]
    prerequisite to prepare NCNs for removal, move and add
    Network expansion COMPLETED
    Log and backup of SLS, BSS and SMD can be found at: /tmp/ncn_task_backups2022-04-01_21-21-04

    Restarting cray-dhcp-kea
   ```

   1. When adding new NCNs, there will be network configuration changes that will impact changing IP addresses on computes. **That will require DVS restart to update the IP addresses in the DVS `node_map`.**

   1. `ncn_add_pre-req.py` will make the network adjustments and will list the component names (xnames) that will need to be rebooted after DVS is restarted. See example below:

      ```text
      Please restart DVS and rebooting the following nodes before proceeding to the next step.:["x3000c0s21b4", "x3000c0s19b0", "x3000c0s21b3", "x3000c0s21b1", "x3000c0s21b2", "x3000c0s21b2n0", "x3000c0s21b3n0", "x3000c0s21b1n0"]
      prerequisite to prepare NCNs for removal, move and add
      Network expansion COMPLETED
      Log and backup of SLS, BSS and SMD can be found at: /tmp/ncn_task_backups2022-04-01_21-21-04
      ```

<a name="add-worker-storage-master"></a>

## Add Worker, Storage, or Master NCNs

Use this procedure to add a worker, storage, or master NCN.

<a name="add-ncn-prerequisites"></a>

### Add NCN Prerequisites

For several of the commands in this section, variables must be set with the name of the node being added and its component name (xname).
Set `NODE` to the hostname of the node being added (for example `ncn-w001`, `ncn-s002`, etc).

```bash
ncn# NODE=ncn-x00n
```

If the component name (xname) is known, set it now. Otherwise it will be determined in a later step.

```bash
ncn# XNAME=<xname>
ncn# echo $XNAME
```

**IMPORTANT:** Ensure that the node being added to the system has been properly configured. If the node being added to the system has not been previously in the system, several settings need to be verified.

* Ensure that the NCN device to be added has been racked and cabled per the SHCD.
* Ensure the NCN BMC is configured with the expected root user credentials.

   The NCN BMC credentials need to match the current global air-cooled BMC default credentials. These can be viewed with the following commands:

   ```bash
   ncn-m# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json |
                         jq -r '.data["vault-root"]' |  base64 -d)
   ncn-m# kubectl -n vault exec -it cray-vault-0 -c vault -- env \
      VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 \
      vault kv get secret/reds-creds/defaults
   ```

   Example output:

   ```text
   ==== Data ====
   Key     Value
   ---     -----
   Cray    map[password:foobar username:root] 
   ```

* If adding an NCN that was not previously in the system, follow the [Access and Update the Settings for Replacement NCNs](Access_and_Update_the_Settings_for_Replacement_NCNs.md) procedure.
* Ensure the NCN BMC is configured to use DHCP. (This does not apply to the BMC for `ncn-m001`, because it is statically configured for the site.)
* Ensure that the NCN is configured to boot over the PCIe NICs instead of the Onboard 1 Gig NICs using the [Switch PXE Boot from Onboard NIC to PCIe](../../install/switch_pxe_boot_from_onboard_nic_to_pcie.md) procedure.

* If adding an HPE NCN, ensure that IPMI is enabled.

   1. Check to see if IPMI is enabled:

      > `read -s` is used to read the password in order to prevent it from being echoed to the screen or saved in the shell history.
      > Note that the subsequent `curl` commands **will** do both of these things. If this is not desired, the call should be made in
      > another way.

      ```bash
      ncn# read -s IPMI_PASSWORD
      ncn# export IPMI_PASSWORD
      ncn# curl -k -u root:$IPMI_PASSWORD https://NCN_NODE-mgmt/redfish/v1/Managers/1/NetworkProtocol | jq .IPMI
      ```

      Expected output:

      ```json
      {
         "Port": 623,
         "ProtocolEnabled": true
      }
      ```

   2. If IPMI is disabled, then enable IPMI:

      ```bash
      ncn# curl -k -u root:$IPMI_PASSWORD -X PATCH \
         -H 'Content-Type: application/json' \
         -d '{"IPMI": {"Port": 623, "ProtocolEnabled": true}}' \
         https://${NODE}-mgmt/redfish/v1/Managers/1/NetworkProtocol | jq
      ```

      Expected output:

      ```json
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

   3. If IPMI was disabled, then restart the BMC:

      ```bash
      ncn# curl -k -u root:$IPMI_PASSWORD -X POST \
         -H 'Content-Type: application/json' \
         -d '{"ResetType": "GracefulRestart"}' \
         https://${NODE}-mgmt/redfish/v1/Managers/1/Actions/Manager.Reset | jq
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

1. [Add Switch Configuration](Add_Remove_Replace_NCNs/Add_Switch_Config.md)

1. [Add NCN data](Add_Remove_Replace_NCNs/Add_NCN_Data.md) for SLS, BSS and HSM

1. [Update Firmware](Add_Remove_Replace_NCNs/Update_Firmware.md) via FAS

1. [Boot NCN and Configure](Add_Remove_Replace_NCNs/Boot_NCN.md)

1. [Redeploy Services](Add_Remove_Replace_NCNs/Redeploy_Services.md)

1. [Validate NCN](Add_Remove_Replace_NCNs/Validate_NCN.md)

1. [Validate Health](Add_Remove_Replace_NCNs/Validate_Health.md)

<a name="remove-worker-storage-master"></a>

## Remove Worker, Storage, or Master NCNs

Use this procedure to remove a worker, storage, or master node (NCN).

<a name="remove-ncn-prerequisites"></a>

### Remove NCN Prerequisites

Open two sessions: one on the node that is to be removed and another on a different master or worker node.
For several of the commands in this section, variables must be set with the name of the node being removed and its component name (xname).
Set `NODE` to the hostname of the node being removed (for example `ncn-w001`, `ncn-s002`, etc).
Set `XNAME` to the xname of that node.

```bash
ncn# NODE=ncn-x00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

<a name="remove-ncn-procedure"></a>

### Remove NCN Procedure

The following is a high-level overview of the remove NCN workflow:

1. [Remove NCN from Role, Wipe the Disks, and Power Down](Add_Remove_Replace_NCNs/Remove_NCN_from_Role.md)

1. [Remove NCN data](Add_Remove_Replace_NCNs/Remove_NCN_Data.md) from SLS, BSS and HSM

1. [Remove Switch Configuration](Add_Remove_Replace_NCNs/Remove_Switch_Config.md)

1. [Redeploy Services](Add_Remove_Replace_NCNs/Redeploy_Services.md)

1. [Validate Health](Add_Remove_Replace_NCNs/Validate_Health.md)

**IMPORTANT:** Update the SHCD to remove the device. This is only needed if no NCN device will be added back to same location with the same cabling.

<a name="replace-worker-storage-master"></a>

## Replace or Move Worker, Storage, or Master NCNs

Replacing an NCN is defined as removing an NCN of a given type and adding a different NCN of the same type (but with different MAC addresses) back into the same cabinet slot.
Moving an NCN is defined as removing an NCN of a given type from one cabinet and adding it back into a different cabinet.

Use the [Remove Worker, Storage, or Master NCNs](#remove-worker-storage-master) procedure followed by the [Add Worker, Storage, or Master NCNs](#add-worker-storage-master) procedure to replace a worker, storage, or master node (NCN).
In general, scaling master nodes is not recommended because it can cause Etcd latency.

### Replace NCN Procedure

The following is a high-level overview of the replace NCN workflow:

1. [Remove Worker, Storage, or Master NCNs](#remove-worker-storage-master)

1. [Add Worker, Storage, or Master NCNs](#add-worker-storage-master)
