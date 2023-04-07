# Validate Boot Loader

Perform the following steps **on `ncn-m001`**.

1. (`ncn-m001#`) Run the script to ensure the local `BOOTRAID` has a valid kernel, `initrd`, and `grub.cfg`.

    ```bash
    pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') '
    /opt/cray/tests/install/ncn/scripts/check_bootloader.sh
    '
    ```
    If the script fails because of 'Host key verification' failures, then follow the documentation to [Apply root SSH keys to NCNs](../../security_and_authentication/SSH_Keys.md#procedure-apply-root-ssh-keys-to-ncns-standalone).

## Next Step

If this is a storage node rebuild, proceed to the next step to [Re-add Storage Node to Ceph](Re-add_Storage_Node_to_Ceph.md). Otherwise, return to the main [Rebuild NCNs](Rebuild_NCNs.md) page.
