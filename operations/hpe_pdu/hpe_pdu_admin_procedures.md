# HPE PDU Admin Procedures

The following procedures are used to manage the HPE Power Distribution Unit (PDU):

 * [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)
 * [HPE PDU Initial Set-up](#hpe-pdu-initial-set-up)
 * [Update HPE PDU Firmware](#update-hpe-pdu-firmware)
 * [Change HPE PDU User Passwords](#change-hpe-pdu-user-passwords)
 * [Discover HPE PDU after Upgrading CSM](#discover-hpe-pdu-after-upgrading-csm)

> **IMPORTANT:** Because of the polling method used to process sensor data from the HPE PDU, telemetry data may take up to six minutes to refresh; this includes the outlet status reported by the Hardware State Manager (HSM).

## Connect to HPE PDU Web Interface

Connect and log in to the HPE PDU web interface.
Access to the HPE PDU web interface is required for the other administrative procedures in this section.

### Prerequisites

The following is needed before running this procedure:

* IP address or Domain Name of `ncn-m001`
* Component name (xname) of the HPE PDU
* Root password for `ncn-m001`
* Admin password for HPE PDU _(default: 12345678)_

### Procedure

1. Use the `ssh` command from a local PC/MAC/Linux machine:

   ```bash
   > ssh -L 8443:{PDU_xname}:443 -N root@{ncn-m001_ip}
   ```

   In this example, `{PDU_xname}` is the component name (xname) of the PDU and `{ncn-m001_ip}` is the IP address of `ncn-m001`.

   Enter the root password for `ncn-m001` when prompted.

2. Connect to [`https://localhost:8443`](https://localhost:8443) using a web browser.

3. Log in with the `admin` username. Enter the admin password. If the admin password has not been changed, there will be a prompt to change the password.

## HPE PDU Initial Set-up

Set up an HPE PDU for administrative use by completing the following tasks:

* Ensure Redfish is enabled
* Add the default user
* Enable Outlet Control

### Procedure

1. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`.

#### Ensure Redfish is Enabled

1. Use the **"Settings"** icon (gear in computer monitor in top right corner) to navigate to **"Network Settings"**.
1. Verify there is a check next to "RESTapi Access", if not, click the **"Edit"** icon (pencil) and enable.

#### Add Default User

1. Use the **"admin"** menu (top right corner) to navigate to **"User Accounts"**.
1. Click on the **"Add User"** button.
1. Use the form to add the _username_ and _password_ for the default River user. Assign the role _"Administrator"_ to that user.

#### Enable Outlet Control

1. Using the **"Home"** icon (House in top right corner) navigate to **"Control & Manage"**.
1. Verify **"Outlet Control Enable"** switch on the top of the page is selected (green).

## Update HPE PDU Firmware

Verify that the firmware version for the HPE PDU is **2.0.0.L**. If it is not, a firmware update is required.

### Procedure

#### Check Firmware Version

1. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`.
1. Check which version of firmware is installed by selecting the **"Home"** icon (House in the top right corner) and navigating to **"Identification"**.
1. The _"Version"_ will be displayed. If the version is not the _"2.0.0.L"_, update firmware.

#### Update Firmware

1. Download version **2.0.0.L** firmware from: [https://support.hpe.com/connect/s/search?language=en_US#q=P9S23A&t=All&sort=%40hpescuniversaldate%20descending&numberOfResults=25&f:@contenttype=[Drivers%20and%20Software]](https://support.hpe.com/connect/s/search?language=en_US#q=P9S23A&t=All&sort=%40hpescuniversaldate%20descending&numberOfResults=25&f:@contenttype=[Drivers%20and%20Software])
This will download an .exe file, which is a self extracting zip file.
1. If using a Windows system, run the .exe file to extract the files, or use an unzip program on the file. One of the files extracted will be named **"HPE.FW"**, that is the firmware file needed for uploading.
2. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`.
3. Use the **"Settings"** icon (gear in computer monitor in top right corner) to navigate to **"System Management"**.
4. Click the **"Update Firmware"** button.
5. Click **"Choose File"** and select the **"HPE.FW"** file downloaded.
6. Click **"Upload"** button.

The firmware will be updated and the PDU management processor will restart.

## Change HPE PDU User Passwords

Change the password of any existing user account using the HPE PDU web interface.

### Procedure

1. Connect to the HPE PDU Web Interface (See [Connect to HPE PDU Web Interface](#connect-to-hpe-pdu-web-interface)) and log in as `admin`.
1. Use the **"admin"** menu (top right corner) to navigate to **"User Accounts"**.
1. Click on the **"Edit"** icon (pencil) next to the user.
1. Enter new password and make any other changes for that user account and click the **"Save"** button.

## Discover HPE PDU after Upgrading CSM

Use the following procedure to ensure the `hms-discovery` job and Redfish Translation Service (RTS) correctly discover HPE PDUs when upgrading from CSM 1.0 or earlier releases to CSM 1.2.

> **IMPORTANT:** This procedure is only needed when upgrading CSM, not performing a fresh install. This procedure should be run after CSM has been fully upgraded including the discovery job.

### Procedure

1.  In CSM 1.0 and earlier releases, the `hms-discovery` job and RTS treated all PDUs as if were made by ServerTech. After the upgrade to CSM 1.2, RTS will still think the HPE PDUs in the system are ServerTech PDUs. Remove these erroneous HPE PDU entries for RTS from Vault.

    1. Get Vault password and create Vault alias.

        ```bash
        ncn# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
        ncn# alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
        ```

    1.  Identify HPE PDUs known by RTS:

        ```bash
        ncn# vault kv list secret/pdu-creds
        ```

        Example output:

        ```json
        [
          "global/",
          "x3000m0",
          "x3000m1"
        ]
        ```

    1.  Remove each HPE PDU identified in the previous sub-step from Vault:

        ```bash
        ncn# PDU=x3000m0
        ncn# vault kv delete secret/pdu-creds/$PDU
        ```

    1.  Restart the Redfish Translation Service (RTS):

        ```bash
        ncn# kubectl -n services rollout restart deployment cray-hms-rts
        ncn# kubectl -n services rollout status deployment cray-hms-rts
        ```

1. Find the list of PDU MAC address. The `ID` field in each element is the normalized MAC address of each PDU:

   ```bash
   ncn# cray hsm inventory ethernetInterfaces list --type CabinetPDUController
   ```

1. Use the returned `ID` from the previous step to delete each HPE PDU MAC address from HSM:

   ```bash
   ncn# cray hsm inventory ethernetInterfaces delete {ID}
   ```

   On the next `hms-discovery` job run, it should relocate the deleted PDUs and discover it correctly as an HPE PDU.

1. After waiting five minutes, verify the Ethernet interfaces that were previously deleted are now present:

   ```bash
   ncn# cray hsm inventory ethernetInterfaces list --type CabinetPDUController
   ```

1. Verify the Redfish endpoints for the PDUs exist and are `DiscoverOK`:

   ```bash
   ncn# cray hsm inventory redfishEndpoints list --type CabinetPDUController
   ```

