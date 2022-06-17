# HPE PDU Admin Procedures

The following procedures are used to manage the HPE Power Distribution Unit (PDU):

* [Verify PDU vendor](#verify-pdu-vendor)
* [Connect to HPE PDU web interface](#connect-to-hpe-pdu-web-interface)
* [HPE PDU initial set-up](#hpe-pdu-initial-set-up)
* [Update HPE PDU firmware](#update-hpe-pdu-firmware)
* [Change HPE PDU user passwords](#change-hpe-pdu-user-passwords)
* [Update Vault credentials](#update-vault-credentials)
* [Discover HPE PDU after upgrading CSM](#discover-hpe-pdu-after-upgrading-csm)

> **IMPORTANT:** Because of the polling method used to process sensor data from the HPE PDU, telemetry data may take up to six minutes to refresh; this includes the outlet status reported by the Hardware State Manager (HSM).

## Verify PDU vendor

If the PDU is accessible over the network, the following can be used to determine the vendor of the PDU.

```bash
ncn-mw# PDU=x3000m0
ncn-mw# curl -k -s --compressed  https://$PDU -i | grep Server:
```

* Example ServerTech output:

  ```text
  Server: ServerTech-AWS/v8.0v
  ```

* Example HPE output:

  ```text
  Server: HPE/1.4.0
  ```

This document covers HPE PDU procedures.

## Connect to HPE PDU web interface

Connect and log in to the HPE PDU web interface.
Access to the HPE PDU web interface is required for the other administrative procedures in this section.

### Prerequisites

The following is needed before running this procedure:

* IP address or domain name of `ncn-m001`
* Component name (xname) of the HPE PDU
* `root` password for `ncn-m001`
* `admin` password for HPE PDU (default: `12345678`)

1. Create an SSH tunnel from a local PC/MAC/Linux machine:

   ```bash
   external# ssh -L 8443:{PDU_xname}:443 -N root@{ncn-m001_ip}
   ```

   In this example, `{PDU_xname}` is the component name (xname) of the PDU and `{ncn-m001_ip}` is the IP address of `ncn-m001`.

   Enter the `root` password for `ncn-m001` when prompted.

   This command will not complete. It should be left running until the SSH tunnel is no longer needed. At that point, it can be
   exited with control-C.

1. Connect to `https://localhost:8443` using a web browser.

   This must be done on the system where the SSH tunnel was created in the previous step.

1. Log in with the `admin` username.

   Enter the `admin` password. If the `admin` password has never been changed, then there will be a prompt to change it.

## HPE PDU initial set-up

Set up an HPE PDU for administrative use by completing the following tasks:

* [Ensure that Redfish is enabled](#ensure-that-redfish-is-enabled)
* [Add the default user](#add-the-default-user)
* [Enable outlet control](#enable-outlet-control)

1. Connect to the HPE PDU Web Interface and log in as `admin`.

   See [Connect to HPE PDU web interface](#connect-to-hpe-pdu-web-interface).

### Ensure that Redfish is enabled

1. Use the `Settings` icon (gear in computer monitor in top right corner) to navigate to `Network Settings`.
1. Verify that there is a check next to `RESTapi Access`.

   If there is not, then click the **Edit** icon (pencil) and enable.

### Add the default user

1. Use the `admin` menu (top right corner) to navigate to `User Accounts`.
1. Click on the `Add User` button.
1. Use the form to add the username and password for the default River user. Assign the role `Administrator` to that user.

### Enable outlet control

1. Using the `Home` icon (house in top right corner) navigate to `Control & Manage`.
1. Verify that the `Outlet Control Enable` switch on the top of the page is selected (green).

## Update HPE PDU firmware

Verify that the firmware version for the HPE PDU is `2.0.0.L`. If it is not, then a firmware update is required.

### Check firmware version

1. Connect to the HPE PDU Web Interface and log in as `admin`.

   See [Connect to HPE PDU web interface](#connect-to-hpe-pdu-web-interface).

1. Select the `Home` icon (house in the top right corner) and navigate to `Identification`.

   The version will be displayed. If the version is not `2.0.0.L`, then [Update firmware](#update-firmware).

### Update firmware

1. Download version `2.0.0.L` firmware from [HPE Support](https://support.hpe.com).

   This will download an `.exe` file, which is a self-extracting zip archive.

1. Extract the firmware files.

   If using a Windows system, run the `.exe` file to extract the files. Otherwise use an unzip program on the file.

   One of the files extracted will be named `HPE.FW`. That is the firmware file needed for uploading.

1. Connect to the HPE PDU Web Interface and log in as `admin`.

   See [Connect to HPE PDU web interface](#connect-to-hpe-pdu-web-interface).

1. Use the `Settings` icon (gear in computer monitor in top right corner) to navigate to `System Management`.

1. Click the `Update Firmware` button.

1. Click `Choose File` and select the `HPE.FW` file that was downloaded.

1. Click `Upload` button.

   The firmware will be updated and the PDU management processor will restart.

## Change HPE PDU user passwords

Change the password of any existing user account using the HPE PDU web interface.

1. Connect to the HPE PDU Web Interface and log in as `admin`.

   See [Connect to HPE PDU web interface](#connect-to-hpe-pdu-web-interface).

1. Use the `admin` menu (top right corner) to navigate to `User Accounts`.

1. Click on the `Edit` icon (pencil) next to the user.

1. Enter the new password and make any other desired changes for that user account.

1. Click the `Save` button.

## Discover HPE PDU after upgrading CSM

Use the following procedure to ensure that the `hms-discovery` job and Redfish Translation Service (RTS) correctly discover HPE PDUs when upgrading to CSM 1.2 from an earlier release.

> **IMPORTANT:** This procedure is only needed when **upgrading** CSM, not performing a fresh install. Run this procedure after CSM has been fully upgraded, including the discovery job.

1. In CSM 1.0 and earlier releases, the `hms-discovery` job and RTS treated all PDUs as if were made by ServerTech.

   After the upgrade to CSM 1.2, RTS will still think that the HPE PDUs in the system are ServerTech PDUs.
   Remove these erroneous HPE PDU entries for RTS from Vault.

   1. Get Vault password and create Vault alias.

      ```bash
      ncn-mw# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
      ncn-mw# alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
      ```

   1. Identify HPE PDUs known by RTS.

      ```bash
      ncn-mw# vault kv list secret/pdu-creds
      ```

      Example output:

      ```json
      [
        "global/",
        "x3000m0",
        "x3000m1"
      ]
      ```

   1. Remove each identified HPE PDU from Vault.

      Repeat the following command for each HPE PDU identified in the output of the previous sub-step.

      ```bash
      ncn-mw# PDU=x3000m0
      ncn-mw# vault kv delete secret/pdu-creds/$PDU
      ```

   1. (`ncn-mw#`) Restart the Redfish Translation Service (RTS).

      ```bash
      ncn-mw# kubectl -n services rollout restart deployment cray-hms-rts
      ncn-mw# kubectl -n services rollout status deployment cray-hms-rts
      ```

1. Find the list of PDU MAC addresses.

   The `ID` field in each element is the normalized MAC address of each PDU:

   ```bash
   ncn-mw# cray hsm inventory ethernetInterfaces list --type CabinetPDUController
   ```

1. Use the returned `ID` from the previous step to delete each HPE PDU MAC address from HSM.

   ```bash
   ncn-mw# cray hsm inventory ethernetInterfaces delete {ID}
   ```

   On the next `hms-discovery` job run, it should relocate the deleted PDUs and discover them correctly as HPE PDUs.

1. After waiting five minutes, verify that the Ethernet interfaces that were previously deleted are now present:

   ```bash
   ncn-mw# sleep 300
   ncn-mw# cray hsm inventory ethernetInterfaces list --type CabinetPDUController
   ```

1. Verify that the Redfish endpoints for the PDUs exist and are `DiscoverOK`.

   ```bash
   ncn-mw# cray hsm inventory redfishEndpoints list --type CabinetPDUController
   ```
