## HPE PDU Admin Procedures

The following procedures are used to manage the HPE Power Distribution Unit (PDU):

* [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)
* [HPE PDU Initial Set-up](#hpe-pdu-initial-set-up)
* [Update HPE PDU Firmware](#update-hpe-pdu-firmware)
* [Change HPE PDU User Passwords](#change-hpe-pdu-user-passwords)
* [Discover HPE PDU after upgrading CSM](#discover-hpe-pdu-after-upgrading-csm)

**Because of the polling method used to process sensor data from the HPE PDU, telemetry data may take up to 6 minutes to refresh; this includes outlet status reported by HSM.**


### Connect to HPE PDU Web Interface
The following is needed before running this procedure:
* IP address or Domain Name of ncn-m001
* Xname of the HPE PDU
* Root password for ncn-m001
* Admin password for HPE PDU _(default: 12345678)_

1. Use the `ssh` command from your local machine:
    ```bash
    > ssh -L 8443:{PDU_xname}:443 -N root@{ncn-m001_ip}
    ```
    Where `{PDU_xname}` is the xname of the PDU and `{ncn-m001_ip}` is the ip address of ncn-m001.\
    You will need to enter the root password for ncn-m001.

2. Connect to: [`https://localhost:8443`](https://localhost:8443) using a web browser.

3. Log in with the `admin` username.  Enter the admin password.  If you have not changed the admin password, there will be a prompt to change the password.

### HPE PDU Initial Set-up
Use this procedure to do the following:
* Ensure redfish is enabled
* Add the default user
* Enable Outlet Control

1. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`.

#### Ensure Redfish is Enabled
1. Using the **"Settings"** Icon (gear in computer monitor in top right corner) navigate to **"Network Settings"**.
2. Verify there is a check next to "RESTapi Access", if not, click the **"Edit"** Icon (pencil) and enable.

#### Add Default User
1. Using the **"admin"** menu (top right corner) navigate to **"User Accounts"**.
2. Click on the **"Add User"** button.
3. Use the form to add the _username_ and _password_ for the default River user.  Assign the role _"Administrator"_ to that user.

#### Enable Outlet Control
1. Using the **"Home"** icon (House in top right corner) navigate to **"Control & Manage"**
2. Verify **"Outlet Control Enable"** switch on the top of the page is selected (green)

#### Update HPE PDU Firmware
##### Check Firmware Version
1. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`
2. Check which version of firmware is installed by selecting the **"Home"** icon (House in the top right corner) navigate to **"Identification"**
3. The _"Version"_ will be displayed.  If the version is not _"2.0.0.L"_ update firmware.

##### Update Firmware
1. Download version **2.0.0.L** firmware from: [https://support.hpe.com/connect/s/search?language=en_US#q=P9S23A&t=All&sort=%40hpescuniversaldate%20descending&numberOfResults=25&f:@contenttype=[Drivers%20and%20Software]](https://support.hpe.com/connect/s/search?language=en_US#q=P9S23A&t=All&sort=%40hpescuniversaldate%20descending&numberOfResults=25&f:@contenttype=[Drivers%20and%20Software])
This will download an ".exe" file which is a self extracting zip file.
2. If using a windows system, run the .exe file to extract the files, or use an unzip program on the file.  One of the files extracted will be named **"HPE.FW"**, that is the firmware file you will need for uploading.
3. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`.
4. Using the **"Settings"** Icon (gear in computer monitor in top right corner) navigate to **"System Management"**
5. Click the **"Update Firmware"** button.
6. Click **"Choose File"** and select the **"HPE.FW"** file downloaded.
7. Click **"Upload"** button.

The firmware will be updated and the PDU management processor will restart.

#### Change HPE PDU User Passwords
1. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`.
2. Using the **"admin"** menu (top right corner) and navigate to **"User Accounts"**.
3. Click on the **"Edit"** icon (pencil) next to the user.
4. Enter new password and make any other changes for that user account and click the **"Save"** button.

#### Discover HPE PDU after Upgrading CSM
**This procedure is only needed when upgrading CSM, not performing a fresh install.  This procedure should be run after CSM has been fully upgraded including the discovery job.**
1.  In CSM 1.0 and before the hms-discovery job and Redfish Translation Service (RTS) treated all PDUs as if were made by ServerTech, and after the upgrade to CSM 1.2 RTS will still think the HPE PDUs in the system are ServerTech PDUs. These erroneous HPE PDU entries for RTS need to get removed from Vault.  
    ```bash
    ncn-m001# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    ncn-m001# alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```
    1.  For each HPE PDU Identified in the command above remove it from Vault:
        ```bash
        ncn-m001# PDU=x3000m0
        ncn-m001# vault kv delete secret/pdu-creds/$PDU
        ```
    2.  Restart the Redfish Translation Service (RTS):
        ```bash
        ncn-m001# kubectl -n services rollout restart deployment cray-hms-rts
        ncn-m001# kubectl -n services rollout status deployment cray-hms-rts
        ```
2. Find the list of PDU MAC address.  The `ID` field in each element is the normalized MAC address of each PDU:
    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces list --type CabinetPDUController
    ```
3. Use the `"ID"` from the command above to delete each HPE PDU MAC address from HSM:
    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces delete {ID}
    ```
4. On the next `hms-discovery` job run, it should locate the PDU and discover it correctly as a HPE PDU.
5. After waiting 5 minutes, verify the enthernet interfaces that were pervious delete are now present:
    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces list --type CabinetPDUController
    ```
6. Verify the redfish endpoints for the PDUs exist and are DiscoverOK:
    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints list --type CabinetPDUController
    ```
