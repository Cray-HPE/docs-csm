## Manually Wipe Boot Configuration on Nodes to be Reinstalled

This procedure removes the SLES boot partitions and clears the master boot record \(MBR\) of all six disks of the first worker node and any other NCNs in the system that are running a base OS and are booted. This forces the other NCNs to PXE boot from the first worker node when they are rebooted to reinstall software. It is not necessary to wipe the boot configuration on any compute nodes that are booted, because they are already configured to PXE boot.

This procedure is necessary for preparing any NCNs that need to have software reinstalled.

### Prerequisites

-   The first worker node and possibly the other non-compute nodes \(NCNs\) are running a base operating system and are booted.
-   The booted nodes need to be reinstalled.

### Procedure

1.  Log in as `root` to the first worker node \(`ncn-w001`\).

2.  Delete the boot config on the first worker node.

    ```bash
    ncn-w001# rm -rf /boot/efi/EFI/sles/
    ```

3.  Clear MBR on all six disks of the first worker node.

    ```bash
    ncn-w001# rm -rf /boot/efi/EFI/sles/
    ncn-w001# wipefs --all --force /dev/sda
    ncn-w001# wipefs --all --force /dev/sdb
    ncn-w001# wipefs --all --force /dev/sdc
    ncn-w001# wipefs --all --force /dev/sdd
    ncn-w001# wipefs --all --force /dev/sde
    ncn-w001# wipefs --all --force /dev/sdf
    ```

4.  Log in as `root` to a different NCN \(not the first worker node\) that is booted.

    Use one of the following methods to log in to that NCN from the first worker node:

    -   SSH:

        ```bash
        ncn-w001# ssh root@IP_ADDRESS
        ```

    -   SOL:

        ```bash
        ncn-w001# export USERNAME=root
        ncn-w001# export IPMI_PASSWORD=changeme
        ncn-w001# ipmitool -U $USERNAME -E -I lanplus -H BMC_IP_ADDRESS sol activate
        ```

        **SOL Trouble?**

        -   **Java exception**: If a Java exception occurs when trying to connect via SOL, see [Change Java Security Settings](Change_Java_Security_Settings.md).
        -   **Unable to access BMC**: If unable to access the node's BMC, and ConMan is being used, ConMan may be blocking that access. See [Troubleshoot ConMan Blocking Access to a Node BMC](../conman/Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md).

    -   Physical KVM:

        Press **Prnt Scrn** to bring up the main menu, then use the arrow keys to move to the desired NCN \(ports 02–04\) and press **Enter**. The login screen for that NCN will appear. \(For photos and details, see [Use the Physical KVM](Use_the_Physical_KVM.md).\)

    -   Virtual KVM:

        Log in to the BMC web console and launch the iKVM Viewer. \(For details, see [Launch a Virtual KVM on Intel Servers](Launch_a_Virtual_KVM_on_Intel_Servers.md).\)

5.  When logged in to the NCN \(`ncn-w002` in the example\), wipe it using the following commands.

    ```bash
    ncn-w002# rm -rf /boot/efi/EFI/sles/
    ncn-w002# wipefs --all --force /dev/sda
    ncn-w002# wipefs --all --force /dev/sdb
    ncn-w002# wipefs --all --force /dev/sdc
    ncn-w002# wipefs --all --force /dev/sdd
    ncn-w002# wipefs --all --force /dev/sde
    ncn-w002# wipefs --all --force /dev/sdf
    ```

    If ipmitool was used to log in to the NCN, press the `~.` key combination to exit from ipmitool when done.

    Repeat the previous step and this step for each NCN that is booted.



