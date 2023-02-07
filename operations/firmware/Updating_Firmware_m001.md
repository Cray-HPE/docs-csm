# Updating BMC Firmware and BIOS for `ncn-m001`

Retrieve the model name and firmware image required to update an HPE or Gigabyte `ncn-m001` node.

> **`NOTE`**
>
> - On HPE nodes, the BMC firmware is iLO 5 and BIOS is System ROM.
> - The commands in the procedure must be run on `ncn-m001`.

- [Prerequisites](#prerequisites)
- [Find the model name](#find-the-model-name)
- [Get the firmware images](#get-the-firmware-images)
- [Flash the firmware](#flash-the-firmware)
  - [Flash Gigabyte `ncn-m001`](#flash-gigabyte-ncn-m001)
  - [Flash HPE `ncn-m001`](#flash-hpe-ncn-m001)

## Prerequisites

> **WARNING:** This procedure should not be performed during a CSM install while `ncn-m001` is booted as the PIT node using a remote ISO image.
> Doing so may reset the remote ISO mount, requiring a reboot to recover.

The following information is needed:

- IP address of `ncn-m001` BMC
- IP address of `ncn-m001`
- Root password for `ncn-m001` BMC

## Find the model name

Use one of the following commands to find the model name for the node type in use.

- [Find HPE model name](#find-hpe-model-name)
- [Find Gigabyte model name](#find-gigabyte-model-name)

- (`ncn-m001#`) Find HPE model name.

    ```bash
    curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/1 | jq .Model
    ```

- (`ncn-m001#`) Find Gigabyte model name.

    ```bash
    curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/Self | jq .Model
    ```

## Get the firmware images

1. (`ncn-m001#`) View a list of images stored in FAS that are ready to be flashed.

    In the following example, `ModelName` is the name found in the previous section.

    ```bash
    cray fas images list --format json | jq '.[] | .[] | select(.models | index("ModelName"))'
    ```

    Locate the images in the returned output for the `ncn-m001` firmware and/or BIOS.

    Look for the returned `s3URL`. For example:

    ```text
    "s3URL": "s3:/fw-update/4e5f569a603311eb96b582a8e219a16d/image.RBU"
    ```

1. (`ncn-m001#`) Get the firmware images using the `s3URL` path from the previous step.

    In the following example command, `4e5f569a603311eb96b582a8e219a16d/image.RBU` is the path in the `s3URL`,
    and the image will be saved to the file `image.RBU` in the current directory.

    ```bash
    cray artifacts get fw-update 4e5f569a603311eb96b582a8e219a16d/image.RBU image.RBU
    ```

## Flash the firmware

- [Flash Gigabyte `ncn-m001`](#flash-gigabyte-ncn-m001)
- [Flash HPE `ncn-m001`](#flash-hpe-ncn-m001)

### Flash Gigabyte `ncn-m001`

1. (`ncn-m001#`) Start a webserver from the directory containing the downloaded image:

    ```bash
    python3 -m http.server 8770
    ```

1. (`ncn-m001#`) Update BMC.

    Be sure to substitute the correct values for the following strings in the example command:

    - `passwd` = Root password of `ncn-m001` BMC
    - `ipaddressOfBMC` = IP address of `ncn-m001` BMC
    - `ipaddressOfM001` = IP address of `ncn-m001` node
    - `filename` = Filename of the downloaded image

    ```bash
    curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -H 'Content-Type: application/json' \
        -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BMC"}'
    ```

1. (`ncn-m001#`) Update BIOS.

    Be sure to substitute the correct values for the following strings in the example command:

    - `passwd` = Root password of `ncn-m001` BMC
    - `ipaddressOfBMC` = IP address of `ncn-m001` BMC
    - `ipaddressOfM001` = IP address of `ncn-m001` node
    - `filename` = Filename of the downloaded image

    ```bash
    curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -H 'Content-Type: application/json' \
        -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BIOS"}'
    ```

    > After updating BIOS, `ncn-m001` will need to be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot `ncn-m001`.

### Flash HPE `ncn-m001`

The web interface will be used to update iLO 5 (BMC) firmware and/or System ROM (BIOS) on the HPE `ncn-m001` node.

1. (`linux#`) Copy the iLO 5 firmware and/or System ROM files to a local computer from `ncn-m001` using `scp` or other secure copy tools.

    ```bash
    scp root@ipaddressOfM001Node:pathToFile/filename .
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
