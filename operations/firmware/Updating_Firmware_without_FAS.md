# Updating BMC Firmware and BIOS for NCNs without FAS

**NOTE: This procedure should only be used if FAS is not available, such as during initial CSM install.**

> **NOTE:**
> On HPE nodes, the BMC Firmware is iLO 5 and BIOS is System ROM.
> The commands in the procedure must be run on `ncn-m001`.

## Prerequisites

The following information is needed:

* IP address of each NCN BMC
* IP address of `ncn-m001`
* `root` user password for each NCN BMC

## Obtain the required firmware

The firmware or BIOS can be obtained from the `HFP` tarball if it has been installed, or from the HPE Morpheus Server.

**The correct version of firmware / BIOS must be selected.**

Move the firmware to be updated into an accessible directory.

## Flash the firmware

### Gigabyte NCNs

1. Start a webserver from the directory containing the downloaded firmware / BIOS image:

    ```bash
    ncn-m001# python3 -m http.server 8770
    ```

1. Update BMC firmware.

    * `passwd` = `root` user password of BMC
    * `ipaddressOfBMC` = IP address of NCN BMC
    * `ipaddressOfM001` = IP address of `ncn-m001`
    * `filename` = Filename of the downloaded image

    ```bash
    ncn-m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate \
                  -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BMC"}'
    ```

1. Update BIOS.

    * `passwd` = `root` user password of BMC
    * `ipaddressOfBMC` = IP address of BMC
    * `ipaddressOfM001` = IP address of `ncn-m001`
    * `filename` = Filename of the downloaded image

    ```bash
    ncn-m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate \
                  -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BIOS"}'
    ```

    > After updating its BIOS, an NCN must be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.

1. Repeat the previous two steps for all NCNs to be updated.

1. Stop the webserver started in the first step.

### HPE NCNs

## Using the `ilorest` command

If the command `ilorest` is available, then follow the procedure in this section to update the NCNs.
Otherwise, see [Using the iLO GUI](#using-the-ilo-gui).

1. Do the following for each NCN to be updated:

    * `passwd` = `root` user password of BMC
    * `ipaddressOfBMC` = IP address of BMC
    * `ipaddressOfM001` = IP address of `ncn-m001`
    * `filename.fwpkg` = Filename of the downloaded image

    ```bash
    ncn-m001# ilorest flashfwpkg filename.fwpkg --url ipaddressOfBMC -u root -p passwd
    ```

    > After updating its System ROM (BIOS), an NCN must be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.

<a name="using-the-ilo-gui"></a>

## Using the iLO GUI

The web interface will be used to update iLO 5 (BMC) firmware and/or System ROM (BIOS) on the HPE NCNs.

1. Copy the iLO 5 firmware and/or System ROM files to a local computer from `ncn-m001` using `scp` or other secure copy tools.

    ```bash
    linux# scp root@ipaddressOfM001Node:pathToFile/filename .
    ```

Do the following steps for each NCN to be updated:

1. From your own machine, create an SSH tunnel.

    > * `-L` creates the tunnel
    > * `-N` prevents a shell and stubs the connection

    ```bash
    linux# ssh -L 6443:ipaddressOfNCNBMC:443 -N ipaddressofM001
    ```

1. Open the following URL in a web browser: `https://127.0.0.1:6443`

1. Log in with `root` and the `root` user password for the iLO device.

    1. Click on `Firmware & OS Software` on the left menu.
    1. Click on `Update Firmware` on the right menu.
    1. Check `Local File`.
    1. Click `Choose File` and select the iLO firmware file or System ROM file.
    1. Click `Confirm TPM override`.
    1. Click `Flash`.

    > After updating its System ROM (BIOS), an NCN must be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.
