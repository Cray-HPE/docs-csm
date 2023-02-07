# Updating BMC Firmware and BIOS for NCNs without FAS

> **`NOTE`**
>
> - On HPE nodes, the BMC firmware is iLO 5 and BIOS is System ROM.
> - The commands in the procedure must be run on `ncn-m001`.
> - This procedure should only be used if FAS is not available, such as during initial CSM install.
> - In order to update the firmware or BIOS for `ncn-m001` itself, see [Updating BMC Firmware and BIOS for `ncn-m001`](Updating_Firmware_m001.md).

- [Prerequisites](#prerequisites)
- [Obtain the required firmware](#obtain-the-required-firmware)
- [Flash the firmware](#flash-the-firmware)
  - [Gigabyte NCNs](#gigabyte-ncns)
  - [HPE NCNs](#hpe-ncns)
    - [Using the `ilorest` command](#using-the-ilorest-command)
    - [Using the iLO GUI](#using-the-ilo-gui)

## Prerequisites

The following information is needed:

- IP address of each NCN BMC
- IP address of `ncn-m001`
- `root` user password for each NCN BMC

## Obtain the required firmware

The firmware or BIOS can be obtained from the `HFP` tarball if it has been installed, or from the HPE Support Center (HPESC).

**The correct version of firmware / BIOS must be selected.**

Move the firmware to be updated into an accessible directory.

## Flash the firmware

### Gigabyte NCNs

This procedure can be followed on any Linux system with network connectivity to the NCN BMCs.

1. Start a webserver from the directory containing the downloaded firmware / BIOS image:

    ```bash
    python3 -m http.server 8770
    ```

1. Update BMC firmware.

    - `passwd` = `root` user password of BMC
    - `ipaddressOfBMC` = IP address of NCN BMC
    - `ipaddressOfM001` = IP address of `ncn-m001`
    - `filename` = Filename of the downloaded image

    ```bash
    curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -H 'Content-Type: application/json' \
                  -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BMC"}'
    ```

1. Update BIOS.

    - `passwd` = `root` user password of BMC
    - `ipaddressOfBMC` = IP address of BMC
    - `ipaddressOfM001` = IP address of `ncn-m001`
    - `filename` = Filename of the downloaded image

    ```bash
    curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -H 'Content-Type: application/json' \
                  -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BIOS"}'
    ```

    > After updating its BIOS, an NCN must be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.

1. Repeat the previous two steps for all NCNs to be updated.

1. Stop the webserver started in the first step.

### HPE NCNs

#### Using the `ilorest` command

If the command `ilorest` is available, then follow the procedure in this section to update the NCNs.
Otherwise, see [Using the iLO GUI](#using-the-ilo-gui).

1. Use the `ilorest` command to flash the firmware for each NCN that requires an update:

    - `passwd` = `root` user password of BMC
    - `ipaddressOfBMC` = IP address of BMC
    - `ipaddressOfM001` = IP address of `ncn-m001`
    - `filename.fwpkg` = Filename of the downloaded image

    ```bash
    ilorest flashfwpkg filename.fwpkg --url ipaddressOfBMC -u root -p passwd
    ```

    > After updating its System ROM (BIOS), an NCN must be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure to reboot NCNs.

#### Using the iLO GUI

The web interface will be used to update iLO 5 (BMC) firmware and/or System ROM (BIOS) on the HPE NCNs.

1. Copy the iLO 5 firmware and/or System ROM files to a local computer from `ncn-m001` using `scp` or other secure copy tools.

    ```bash
    scp root@ipaddressOfM001Node:pathToFile/filename .
    ```

On a machine external to the cluster (for example, a laptop), do the following steps for each NCN to be updated:

1. Create an SSH tunnel.

    > - `-L` creates the tunnel
    > - `-N` prevents a shell and stubs the connection

    ```bash
    ssh -L 6443:ipaddressOfNCNBMC:443 -N ipaddressofM001
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
