# Updating BMC Firmware and BIOS for `ncn-m001`

Retrieve the model name and firmware image required to update an HPE or Gigabyte `ncn-m001` node.

> **NOTE:** 
> * On HPE nodes, the BMC Firmware is iLO 5 and BIOS is System ROM.
> * The commands in the procedure must be run on `ncn-m001`.

## Prerequisites

The following information is needed:

* IP Address of `ncn-m001` BMC
* IP Address of `ncn-m001`
* Root password for `ncn-m001` BMC

## Find the Model Name

Use one of the following commands to find the model name for the node type in use.

### HPE Nodes

  ```bash
  ncn-m001# curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/1 | jq .Model
  ```

### Gigabyte Nodes

  ```bash
  ncn-m001# curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/Self | jq .Model
  ```

## Get the Firmware Images

1. View a list of images stored in FAS that are ready to be flashed:
    
    In the following example, `ModelName` is the name from the previous command.

    ```bash
    ncn-m001# cray fas images list --format json | jq '.[] | .[] | select(.models | index("ModelName"))'
    ```

    Locate the image in the returned output that is required to `ncn-m001` firmware and/or BIOS.

    Look for the returned `s3URL`. For example:

    `"s3URL": "s3:/fw-update/4e5f569a603311eb96b582a8e219a16d/image.RBU"`

1. Get the firmware images using the `s3URL` path from the previous step.

    ```bash
    ncn-m001# cray artifacts get fw-update 4e5f569a603311eb96b582a8e219a16d/image.RBU image.RBU
    ```

    `4e5f569a603311eb96b582a8e219a16d/image.RBU` is the path in the `s3URL`.
    `image.RBU` is the name of the file to save the image on local disk.

## Flash the Firmware

### Gigabyte `ncn-m001`

1. Start a webserver from the directory containing the downloaded image:

    ```bash
    ncn-m001# python3 -m http.server 8770
    ```

    1. Update BMC:

       * `passwd` = Root password of BMC
       * `ipaddressOfBMC` = IP address of BMC
       * `ipaddressOfM001` = IP address of `ncn-m001` node
       * `filename` = Filename of the downloaded image

       ```bash
       ncn-m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BMC"}'
       ```

    2. Update BIOS:

       * `passwd` = Root password of BMC
       * `ipaddressOfBMC` = IP address of BMC
       * `ipaddressOfM001` = IP address of `ncn-m001` node
       * `filename` = Filename of the downloaded image

       ```bash
       ncn-m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BIOS"}'
       ```

       > After updating BIOS, `ncn-m001` will need to be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot `ncn-m001`.

### HPE `ncn-m001`

The web interface will be used to update iLO 5 (BMC) firmware and/or System ROM (BIOS) on the HPE `ncn-m001` node.

1. Copy the iLO 5 firmware and/or System ROM file(s) to a local computer from `ncn-m001` using `scp` or other secure copy tools.

    ```bash
    linux# scp root@ipaddressOfM001Node:pathToFile/filename .
    ```

1. Open a web browser window and type in the name or IP address of the iLO device for `ncn-m001`.

1. Log in with `root` and the root password for the iLO device.

    1. Click on `"Firmware & OS Software"` on the left menu.
    1. Click on `"Update Firmware"` on the right menu.
    1. Check `"Local File"`.
    1. Click `"Choose File"` and select the iLO firmware file or System ROM file.
    1. Click `"Confirm TPM override"`.
    1. Click `"Flash"`.

    > After updating System ROM (BIOS), `ncn-m001` will need to be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot `ncn-m001`.
