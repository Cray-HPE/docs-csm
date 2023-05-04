# Update Compute Node Mellanox HSN NIC Firmware

This procedure updates liquid-cooled or standard rack compute node NIC mezzanine cards \(NMC\) firmware for Slingshot 10 Mellanox ConnectX-5 NICs. The deployed RPM on compute nodes contains the scripts and firmware images
required to perform the firmware and configuration updates.

**Attention:** The NIC firmware update is performed while the node is running the compute image \(in-band\). Use the CX-5 NIC firmware that is deployed with the compute node RPMs and not from some other repository.

See [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) for information about automated firmware updates using Redfish.

## Time Required

2-5 minutes for a firmware update and 1-3 minutes for a configuration update.

## Procedure

1. SSH to the node as root.

1. (`nid#`) Load the module.

    ```bash
    module load cray-shasta-mlnx-firmware
    module show cray-shasta-mlnx-firmware
    ```

    Example output:

    ```text
    -------------------------------------------------------------------
    /opt/cray/modulefiles/cray-shasta-mlnx-firmware/1.0.5:
    module-whatis   "This module adds cray-shasta-mlnx-firmware v1.0.5 to the environment"
    prepend-path    PATH /opt/cray/cray-shasta-mlnx-firmware/1.0.5/sbin
    -------------------------------------------------------------------
    ```

1. (`nid#`) List the contents of the firmware directories.

    ```bash
    ls /opt/cray/cray-shasta-mlnx-firmware/1.0.5/share/firmware/*
    ```

    Example output:

    ```text
    apply_mlnx_configs  generate_mlnx_configs  update_mlnx_firmware
    ```

    ```bash
    ls /opt/cray/cray-shasta-mlnx-firmware/1.0.5/share/firmware/
    ```

    Example output:

    ```text
    CRAY000000001/ MT_0000000011/ images/
    ```

    ```bash
    ls /opt/cray/cray-shasta-mlnx-firmware/1.0.5/share/firmware/
    ```

    Example output:

    ```text
    CRAY000000001/ MT_0000000011/ images/
    ```

    ```bash
    ls /opt/cray/cray-shasta-mlnx-firmware/1.0.5/share/firmware/*
    ```

    Example output:

    ```text
    /opt/cray/cray-shasta-mlnx-firmware/1.0.5/share/firmware/CRAY000000001:
    config.xml  fw-ConnectX5-rel-16_26_4012-Cray_Timms_mezz_100G_1P-UEFI-14.19.17-FlexBoot-3.5.805.bin

    /opt/cray/cray-shasta-mlnx-firmware/1.0.5/share/firmware/MT_0000000011:
    config.xml  fw-ConnectX5-rel-16_26_4012-MCX515A-CCA_Ax-UEFI-14.19.17-FlexBoot-3.5.805.bin

    /opt/cray/cray-shasta-mlnx-firmware/1.0.5/share/firmware/images:
    CRAY000000001.bin  MT_0000000011.bin
    ```

1. (`nid#`) Update the firmware on the node.

    ```bash
    update_mlnx_firmware
    ```

1. (`nid#`) Apply the configuration settings.

    ```bash
    apply_mlnx_configs
    ```

1. (`nid#`) Determine the prepend pathname.

    ```bash
    module show cray-shasta-mlnx-firmware
    ```

    Example output:

    ```text
    -------------------------------------------------------------------
    /opt/cray/modulefiles/cray-shasta-mlnx-firmware/1.0.5:
    module-whatis   "This module adds cray-shasta-mlnx-firmware v1.0.5 to the environment"
    prepend-path    PATH /opt/cray/cray-shasta-mlnx-firmware/1.0.5/sbin
    -------------------------------------------------------------------
    ```

1. (`ncn-m001#`) Log in to `ncn-m001` and use `pdsh` to update the firmware.

    ```bash
    pdsh -w NODE_LIST /opt/cray/cray-shasta-mlnx-firmware/1.0.5/sbin/update_mlnx_firmware
    ```

1. (`ncn-m001#`) Apply the configuration settings.

    ```bash
    pdsh -w NODE_LIST /opt/cray/cray-shasta-mlnx-firmware/1.0.5/sbin/apply_mlnx_configs
    ```

1. (`ncn-m001#`) Use the Boot Orchestration Service \(BOS\) to reboot all the affected nodes.

    ```bash
    cray bos v1 session create --template-uuid SESSION_TEMPLATE --operation reboot
    ```
