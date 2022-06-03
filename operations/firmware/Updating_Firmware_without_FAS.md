# Updating BMC Firmware and BIOS for NCNs without FAS

**NOTE: This procedure should only be used if FAS is not available such as during installation time.**

> **NOTE:**
> * On HPE nodes, the BMC Firmware is iLO 5 and BIOS is System ROM.
> * The commands in the procedure must be run on `ncn-m001`.

## Prerequisites

The following information is needed:

* IP Address of each NCN BMC
* IP Address of `ncn-m001`
* Root password for each NCN BMC

## Obtain the Required Firmware

The firmware or BIOS can be obtained from the `HFP` tarball if it has been installed, or from HPE Morpheus Server (https://morph.ams.hpecorp.net/app/)

**You must select the correct version of firmware / BIOS.**

Move the firmware to be updated into a directory you have access to.

## Flash the Firmware

### Gigabyte NCNs

1. Start a webserver from the directory containing the downloaded firmware / BIOS image:

    ```bash
    ncn-m001# python3 -m http.server 8770
    ```

    1. Update BMC:

       * `passwd` = Root password of BMC
       * `ipaddressOfBMC` = IP address of NCN BMC
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

       > After updating BIOS, NCNs will need to be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.

### HPE NCNs

## Using the `ilorest` command

If the command `ilorest` is available, use the following command for each NCN to be updated.
If that command is not available, follow the procedure Using the iLO GUI.

1. Do the following for each NCN needing update:

    ```bash
    ncn-m001# ilorest flashfwpkg filename.fwpkg --url ipaddressOfNCN -u root -p passwd
    ```

    > After updating System ROM (BIOS), NCN will need to be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.

## Using the iLO GUI

The web interface will be used to update iLO 5 (BMC) firmware and/or System ROM (BIOS) on the HPE NCNs.

1. Copy the iLO 5 firmware and/or System ROM file(s) to a local computer from `ncn-m001` using `scp` or other secure copy tools.

    ```bash
    linux# scp root@ipaddressOfM001Node:pathToFile/filename .
    ```

Do the following steps for each NCN needing update:

1. From your own machine, create a SSH tunnel (`-L` creates the tunnel, and `-N` prevents a shell and stubs the connect).
    ```bash
    linux# ssh -L 6443:ipaddressOfNCN:443 -N ipaddressofM001
    ```

1. Open a web browser window and type `https://127.0.0.1:6443`

1. Log in with `root` and the root password for the iLO device.

    1. Click on `"Firmware & OS Software"` on the left menu.
    1. Click on `"Update Firmware"` on the right menu.
    1. Check `"Local File"`.
    1. Click `"Choose File"` and select the iLO firmware file or System ROM file.
    1. Click `"Confirm TPM override"`.
    1. Click `"Flash"`.

    > After updating System ROM (BIOS), NCN will need to be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.
