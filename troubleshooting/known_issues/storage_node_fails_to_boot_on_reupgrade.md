# Storage node fails to boot on re-upgrade

If storage nodes need to be upgraded to a new node image that has the same CSM version as the version currently running on storage nodes,
then the storage nodes will fail to boot during the upgrade.
This is not an expected upgrade scenario.
However, this can happen anytime storage node images need to be rebuilt and upgraded to after the storage nodes have already been upgraded.

This happens because the storage node is not wiped when it is upgraded.
When it is booting into a new image, it already has the SquashFS downloaded with the same CSM version so it does not download the new SquashFS.
This causes errors which causes the boot to fail. This has been fixed in CSM 1.6+.

> NOTE: To observe the error and to resolve it, it is necessary to log into the storage node using conman.
> For instructions, refer to [log into a node using Conman](../../operations/conman/Log_in_to_a_Node_Using_ConMan.md).

## Observed error

In the storage node console, the following error will be seen when booting.

```text
http://rgw-vip.nmn/boot-images/edd22fe2-65e9-47d9-bd0b-41393df1d899/kernel... ok
http://rgw-vip.nmn/boot-images/edd22fe2-65e9-47d9-bd0b-41393df1d899/initrd... ok
kernel : 14185152 bytes [EFI] [SELECTED] "initrd=initrd biosdevname=1 ifname=lan1:a4:bf:01:65:be:ba ip=lan1:auto6 ifname=lan0:a4:bf:01:65:be:b9 ip=lan0:auto6 ifname=mgmt0:b8:59:9f:4a:f6:24 ip=mgmt0:dhcp ifname=mgmt1:b8:59:9f:4a:f6:25 ip=mgmt1:auto6 psi=1 pcie_ports=na
tive transparent_hugepage=never console=tty0 console=ttyS0,115200 iommu=pt split_lock_detect=off metal.server=http://rgw-vip.nmn/boot-images/edd22fe2-65e9-47d9-bd0b-41393df1d899/rootfs?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=KBSDOTX2FE5CH9845P9B%2F20250203%2
Fdefault%2Fs3%2Faws4_request&X-Amz-Date=20250203T161421Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=064b7db31022c6b7e57798d5501dd89af353f2b6166523e1ddecf207cbcb3b47 metal.no-wipe=1 ds=nocloud-net;s=http://10.92.100.81:8888/ rootfallback=LABEL=BOOTRAI
D root=live:LABEL=SQFSRAID rd.live.ram=0 rd.writable.fsimg=0 rd.skipfsck rd.live.overlay=LABEL=ROOTRAID rd.live.overlay.overlayfs=1 rd.luks rd.luks.crypttab=0 rd.lvm.conf=0 rd.lvm=1 rd.auto=1 rd.md=1 rd.dm=0 rd.neednet=0 rd.peerdns=0 rd.md.waitclean=1 rd.multipath=0 r
d.md.conf=1 rd.bootif=0 hostname=ncn-s001 rd.net.timeout.carrier=120 rd.net.timeout.ifup=120 rd.net.timeout.iflink=120 rd.net.dhcp.retry=5 rd.net.timeout.ipv6auto=0 rd.net.timeout.ipv6dad=0 append nosplash quiet crashkernel=360M log_buf_len=1 rd.retry=10 rd.shell rd.l
ive.squashimg=rootfs rd.live.overlay.thin=0 rd.live.dir=1.6.1-rc.3 rd.live.overlay.reset=1 xname=x3000c0s13b0n0 nid=100008 bss_referral_token=7066efb4-29d1-4de6-82b2-b27083033d0e"
initrd : 108122788 bytes
[    0.163982][    T0] x86/cpu: VMX (outside TXT) disabled by BIOS
[    4.371945] dracut-cmdline[592]: Warning: Network interface 'lan1' does not exist
[    4.388148] dracut-cmdline[592]: Warning: Network interface 'lan0' does not exist
[    4.408078] dracut-cmdline[592]: Warning: Network interface 'mgmt0' does not exist
[    4.424109] dracut-cmdline[592]: Warning: Network interface 'mgmt1' does not exist
[    8.183400] dracut-initqueue[1827]: wicked: mgmt0: Request to acquire DHCPv4 lease with UUID 84eba067-0413-0600-2307-000001000000
[   10.704583] dracut-initqueue[1827]: wicked: mgmt0: Committed DHCPv4 lease with address 10.1.1.9 (lease time 3598, renew in 1798 sec, rebind in 3148 sec)
[   11.429325] dracut-initqueue[1941]: mdadm: No arrays found in config file
[   11.510205] dracut-initqueue[1900]: Warning: local storage device wipe [ safeguard: ENABLED  ]
[   11.528108] dracut-initqueue[1900]: Warning: local storage devices will not be wiped (https://github.com/Cray-HPE/dracut-metal-mdsquash/tree/68361ab704036e3086f44e005ecf75cbfeaec185#metalno-wipe)
[ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHETC.
[DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHETC.
[DEPEND] Dependency failed for /etc/ceph.
[DEPEND] Dependency failed for Local File Systems.
[DEPEND] Dependency failed for Early Kernel Boot Messages.
[ TIME ] Timed out waiting for device /dev/disk/by-label/CONTAIN.
[DEPEND] Dependency failed for /var/lib/containers.
[DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CONTAIN.
[ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHVAR.
[DEPEND] Dependency failed for /var/lib/ceph.
[DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHVAR.
You are in emergency mode. After logging in, type "journalctl -xb" to view
systGive root password for maintenance
(or press Control-D to continue): &.
<ConMan> Connection to console [x3000c0s13b0n0] closed.
```

## Resolution

1. (`node console`) Log into the storage node console of the node being upgraded and provide the root password for maintenance.

2. (`node console`) Run the `cleanup-live-images.sh` script from the console. This will remove the SquashFS directories and the `/run/initramfs/live` images.

    ```bash
    /srv/cray/scripts/metal/cleanup-live-images.sh -y -a -o
    ```

3. (`ncn-mw#`) Power cycle the storage node from a master or worker node.

    1. Set the BMC variable to the hostname of the BMC of the node being rebuilt.

        ```bash
        BMC="${NODE}-mgmt"; echo $BMC
        ```

    1. Set and export the `root` password of the BMC.

        > NOTE: `read -s` is used to prevent the password from echoing to the screen or
        > being saved in the shell history.

        ```bash
        read -r -s -p "${BMC} root password: " IPMI_PASSWORD
        ```

        ```bash
        export IPMI_PASSWORD
        ```

    1. Verify that the node is on.

        ```bash
        ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
        ```

    1. Power off the node.

        ```bash
        ipmitool -I lanplus -U root -E -H "${BMC}" chassis power off
        ```

    1. Verify that the node is off.

       Ensure the power is reporting as off. This may take 5-10 seconds for this to update.

        ```bash
        ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
        ```

    1. Power on the node.

        ```bash
        ipmitool -I lanplus -U root -E -H "${BMC}" chassis power on
        ```

    1. Verify that the node is on.

       Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

       ```bash
       ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
       ```

    1. Watch the nodes console. The node should successfully boot and run cloud-init.
