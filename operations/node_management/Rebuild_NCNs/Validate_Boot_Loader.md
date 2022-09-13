# Validate Boot Loader

Perform the following steps **on `ncn-m001`**.

1. Run the script to ensure the local `BOOTRAID` has a valid kernel, `initrd`, and `grub.cfg`.

    ```bash
    pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') '
    /opt/cray/tests/install/ncn/scripts/check_bootloader.sh
    '
    ```
