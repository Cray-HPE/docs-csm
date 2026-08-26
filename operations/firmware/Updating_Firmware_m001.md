# Updating BMC Firmware and BIOS for `ncn-m001`

Retrieve the model name and firmware image required to update an HPE or Gigabyte `ncn-m001` node.

> **NOTE**
>
> - On HPE nodes, the BMC firmware is iLO 5 or iLO 6 and BIOS is System ROM.
> - The commands in the procedure must be run on `ncn-m001`.

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Flash the firmware](#flash-the-firmware)
    - [Flash Gigabyte `ncn-m001`](#flash-gigabyte-ncn-m001)
    - [Flash HPE `ncn-m001` using web interface](#flash-hpe-ncn-m001-using-web-interface)
    - [Flash HPE `ncn-m001` using `ilorest`](#flash-hpe-ncn-m001-using-ilorest)

## Prerequisites

> **WARNING:** This procedure should not be performed during a CSM install while `ncn-m001` is booted as the PIT node using a remote ISO image.
> Doing so may reset the remote ISO mount, requiring a reboot to recover.

The following information is needed:

- IP address of `ncn-m001`
- Root password for `ncn-m001` BMC

## Setup

1. (`ncn-m001#`) Set variables for `USERNAME` and `BMC_PASSWORD`.

    ```bash
    USERNAME=root
    read -r -s -p "NCN BMC ${USERNAME} password: " BMC_PASSWORD
    ```

1. (`ncn-m001#`) Get the IP address of `ncn-m001's` BMC (on the external/campus network).

    ```bash
    BMC_ADDRESS=$(ipmitool lan print | grep "IP Address  " | cut -f2 -d: | sed 's/ //g')
    echo $BMC_ADDRESS
    ```

1. (`ncn-m001#`) Find the model name.

    - For HPE nodes:

        ```bash
        MODEL=$(curl -k -u ${USERNAME}:${BMC_PASSWORD} https://${BMC_ADDRESS}/redfish/v1/Systems/1 | jq -r .Model)
        echo $MODEL
        export BMC_PASSWORD USERNAME BMC_ADDRESS MODEL
        ```

    - For Gigabyte nodes:

        ```bash
        MODEL=$(curl -k -u ${USERNAME}:${BMC_PASSWORD} https://${BMC_ADDRESS}ipaddressOfBMC/redfish/v1/Systems/Self | jq -r .Model)
        echo $MODEL
        export BMC_PASSWORD USERNAME BMC_ADDRESS MODEL
        ```

1. (`ncn-m001#`) Get the firmware images.

    1. View a list of images stored in FAS that are ready to be flashed.

        ```bash
        cray fas images list --format json | jq '.[] | .[] | select(.models | index($ENV.MODEL))'
        ```

        Locate the images in the returned output for the `ncn-m001` firmware and/or BIOS.
        Make sure to select the correct firmware/BIOS version as several versions may be installed in FAS.

        - For HPE nodes:
            - iLO firmware will be `ilo5_xxx.bin` or `ilo6_xxx.bin`
            - BIOS wil be a `.signed.flash` file
        - For Gigabyte nodes:
            - BMC firmware will be `rom.ima_enc`
            - BIOS will be `image.RBU`

        Look for the returned `s3URL`. For example:

        ```text
        "s3URL": "s3:/fw-update/4e5f569a603311eb96b582a8e219a16d/image.RBU"
        ```

    1. Get the firmware images using the `s3URL` path from the previous step.

        In the following example command, `4e5f569a603311eb96b582a8e219a16d/image.RBU` is the path in the `s3URL`,
        and the image will be saved to the file `image.RBU` in the current directory.

        ```bash
        cray artifacts get fw-update 4e5f569a603311eb96b582a8e219a16d/image.RBU image.RBU
        ```

## Flash the firmware

- [Flash Gigabyte `ncn-m001`](#flash-gigabyte-ncn-m001)
- HPE nodes can be updated using two different methods
    - [Flash HPE `ncn-m001` using web interface](#flash-hpe-ncn-m001-using-web-interface)
    - [Flash HPE `ncn-m001` using `ilorest`](#flash-hpe-ncn-m001-using-ilorest)

### Flash Gigabyte `ncn-m001`

1. (`ncn-m001#`) Start a webserver from the directory containing the downloaded image:

    ```bash
    python3 -m http.server 8770
    ```

1. (`ncn-m001#`) Update BMC.

    Be sure to substitute the correct values for the following strings in the example command:

    - `ipaddressOfM001` = IP address of `ncn-m001` node
    - `filename` = Filename of the downloaded image

    ```bash
    curl -k -u ${USERNAME}:${BMC_PASSWORD} https://${BMC_ADDRESS}/redfish/v1/UpdateService/Actions/SimpleUpdate -H 'Content-Type: application/json' \
        -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BMC"}'
    ```

1. (`ncn-m001#`) Wait for the BMC to update and reboot.

    ```bash
    sleep 200
    ping ${BMC_ADDRESS}
    ```

1. (`ncn-m001#`) After the reboot completes, check that the firmware version is at the expected value.

    ```bash
    curl -k -u ${USERNAME}:${BMC_PASSWORD} https://${BMC_ADDRESS}/redfish/v1/UpdateService/FirmwareInventory/BMC
    ```

1. (`ncn-m001#`) Update BIOS.

    Be sure to substitute the correct values for the following strings in the example command.

    - `ipaddressOfM001` = IP address of `ncn-m001` node
    - `filename` = Filename of the downloaded image

    ```bash
    curl -k -u ${USERNAME}:${BMC_PASSWORD} https://${BMC_ADDRESS}/redfish/v1/UpdateService/Actions/SimpleUpdate -H 'Content-Type: application/json' \
        -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BIOS"}'
    ```

    Example output:

     ```json
     {"@odata.type":"#UpdateService.v1_5_0.UpdateService","Messages":[{"@odata.type":"#Message.v1_0_7.Message","Message":"A new task /redfish/v1/TaskService/Tasks/596 was created.","MessageArgs":["/redfish/v1/TaskService/Tasks/596"],"MessageId":"Task.1.0.New","Resolution":"None","Severity":"OK"},{"@odata.type":"#Message.v1_0_7.Message","Message":"Device is prepareing flash firmware for action SimpleUpdate.","MessageArgs":["SimpleUpdate"],"MessageId":"UpdateService.1.0.PrepareUpdate","Resolution":"None","Severity":"OK"}]}
     ```

1. Verify successful update.

     When updating the Gigabyte BIOS, the BIOS version number will not change until the node is rebooted.
     To verify a successful update, check the task that was created.

     1. In the JSON response from the previous step, find the text that resembles the following.

         ```text
         "A new task /redfish/v1/TaskService/Tasks/596 was created."
         ```

     1. (`ncn-m001#`) Using the task number (`596` in the above example), check the state of the task.

         ```bash
         curl -sk -u ${USERNAME}:${BMC_PASSWORD} https://${BMC_ADDRESS}/redfish/v1/TaskService/Tasks/596 | jq .TaskState
         ```

     The state should be `Running` until the BIOS update is finished.
     Once finished, the state will be `Completed`.
     If a state other than `Running` or `Completed` is shown, then check the task for other messages.

1. Reboot `ncn-m001`.

    After updating BIOS, `ncn-m001` must be rebooted.
    Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot `ncn-m001`.

### Flash HPE `ncn-m001` using web interface

The web interface will be used to update iLO 5 or iLO 6 (BMC) firmware and/or System ROM (BIOS) on the HPE `ncn-m001` node.

1. (`linux/win/mac#`) Copy the iLO 5 or iLO 6 firmware and/or System ROM files to a local computer from `ncn-m001` using `scp` or other secure copy tools.

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

1. Reboot `ncn-m001`.

    After updating System ROM (BIOS), `ncn-m001` must be rebooted.
    Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot `ncn-m001`.

### Flash HPE `ncn-m001` using `ilorest`

1. (`ncn-m001#`) Install `ilorest` RPM on `ncn-m001`.

    ```bash
    zypper install ilorest
    ```

1. {`ncn-m001#`) Check firmware versions before making changes on `ncn-m001`.

    ```bash
    ilorest serverinfo  |grep "Firmware:" -A3
    ```

    Example output:

    ```text
    Firmware:
    ------------------------------------------------
    iLO 5 : 3.02 Feb 22 2024
    System ROM : A43 v3.60 (01/21/2025)
    ```

1. {`ncn-m001#`) Update BIOS on `ncn-m001` using the downloaded System ROM file.

    ```bash
    ilorest uploadcomp --component=A43_3.70_03_21_2025.signed.flash --update_target
    sleep 90
    ```

1. {`ncn-m001#`) Update BMC on `ncn-m001` using the downloaded iLO file.

    ```bash
    ilorest uploadcomp --component=ilo5_311.bin --forceupload --update_target
    sleep 60
    ```

1. Reboot `ncn-m001`.

    1. (`linux/win/mac#`) Open a console to `ncn-m001` and log in as `root`.

        > - **IMPORTANT**: Do not open the console from `ncn-m001` itself, or in a terminal that connected through `ncn-m001`.
        > - Update the example command to specify the correct user, password, and BMC IP address.

        ```bash
        ipmitool -I lanplus -U <BMC_USERNAME> -P <BMC_PASSWORD> -H <BMC_ADDRESS> sol activate
        ```

        Example console:

        ```console
        ncn-m001 login: root
        Password:
        ```

    1. {`ncn-m001#`) Reboot `ncn-m001`.

        **IMPORTANT** Do not accidentally issue this command on another node!

        ```bash
        shutdown -r now
        ```

    1. Watch the console until `ncn-m001` reboots and is back up.

        The console can be closed at this point. It is no longer needed for this procedure.

1. {`ncn-m001#`) Check firmware versions.

    ```bash
    ilorest serverinfo  |grep "Firmware:" -A3
    ```

    Example output:

    ```text
    Firmware:
    ------------------------------------------------
    iLO 5 : 3.11 Feb 25 2025
    System ROM : A43 v3.70 (03/21/2025)
    ```
