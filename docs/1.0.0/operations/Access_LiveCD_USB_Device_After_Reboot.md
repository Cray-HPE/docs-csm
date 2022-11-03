# Accessing LiveCD USB Device After Reboot

This is a procedure that only applies to the LiveCD USB device after the PIT node has been rebooted.

> **`USB ONLY`** If the installation above was done from a [Remote ISO](../install/bootstrap_livecd_remote_iso.md).

After deploying the LiveCD's NCN, the LiveCD USB itself is unharmed and available to an administrator.

## Procedure

1. Mount and view the USB device.

    ```bash
    ncn-m001# mkdir -pv /mnt/{cow,pitdata}
    ncn-m001# mount -vL cow /mnt/cow
    ncn-m001# mount -vL PITDATA /mnt/pitdata
    ncn-m001# ls -ld /mnt/cow/rw/*
    ```

    Example output:

    ```
    drwxr-xr-x  2 root root 4096 Jan 28 15:47 /mnt/cow/rw/boot
    drwxr-xr-x  8 root root 4096 Jan 29 07:25 /mnt/cow/rw/etc
    drwxr-xr-x  3 root root 4096 Feb  5 04:02 /mnt/cow/rw/mnt
    drwxr-xr-x  3 root root 4096 Jan 28 15:49 /mnt/cow/rw/opt
    drwx------ 10 root root 4096 Feb  5 03:59 /mnt/cow/rw/root
    drwxrwxrwt 13 root root 4096 Feb  5 04:03 /mnt/cow/rw/tmp
    drwxr-xr-x  7 root root 4096 Jan 28 15:40 /mnt/cow/rw/usr
    drwxr-xr-x  7 root root 4096 Jan 28 15:47 /mnt/cow/rw/var
    ```

1. Look at the contents of `/mnt/pitdata`.

    ```bash
    ncn-m001# ls -ld /mnt/pitdata/*
    ```

    Example output:

    ```
    drwxr-xr-x  2 root root        4096 Feb  3 04:32 /mnt/pitdata/configs
    drwxr-xr-x 14 root root        4096 Feb  3 07:26 /mnt/pitdata/csm-0.7.29
    -rw-r--r--  1 root root 22159328586 Feb  2 22:18 /mnt/pitdata/csm-0.7.29.tar.gz
    drwxr-xr-x  4 root root        4096 Feb  3 04:25 /mnt/pitdata/data
    drwx------  2 root root       16384 Jan 28 15:41 /mnt/pitdata/lost+found
    drwxr-xr-x  5 root root        4096 Feb  3 04:20 /mnt/pitdata/prep
    drwxr-xr-x  2 root root        4096 Jan 28 16:07 /mnt/pitdata/static
    ```

1. Unmount the USB device to avoid corruption.

   The corruption risk is low, but varies if large data use was done to or on the USB.

    ```bash
    ncn-m001# umount -v /mnt/cow /mnt/pitdata
    ```

1. Remove the USB device after it has been unmounted.