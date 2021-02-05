# CSM Install Reboot - Final NCN Install

This page describes rebooting and deploying the non-compute node that is currently hosting the LiveCD.

**This is the final step 🏁 in the Cray System Management (CSM) installer**. The customer or administrator may 
choose to install additional products following the completion of the CSM installer.

> Additional products include, but are not limited to:
> - Compute Nodes
> - High-Speed Network
> - Program Environment (PE)
> - User Access Nodes
> - Work-Load Managers / SLURM

* [Required Services](#required-services) 
* [Notice of Danger](#notice-of-danger)
* [Start Hand-Off](#start-hand-off)
    * [Accessing USB Partitions After Reboot](#accessing-usb-partitions-after-reboot)


<a name="required-services"></a>
## Required Services

These services must be healthy in kubernetes before the reboot of the LiveCD can take place.

Required Platform Services:
- cray-dhcp-kea
- cray-dns-unbound
- cray-bss
- cray-sls
- cray-s3
- cray-ipxe
- cray-tftp

<a name="notice-of-danger"></a>
## Notice of Danger

While the node is rebooting, it will be available only through Serial-over-LAN and local terminals.

This procedure entails deactivating the LiveCD, meaning the LiveCD and all of its resources will be
**unavailable**.

<a name="start-hand-off"></a>
## Start Hand-Off

These steps will walk an administrator through loading hand-off data and rebooting the node. This will
assist with remote-console setup, for observing the reboot.

At the end of these steps, the LiveCD will be no longer active and the node it was using will join
the kubernetes cluster.

1. Upload sls file
   ```bash
   pit# csi upload-sls-file --sls-file /var/www/ephemeral/prep/config/surtur/sls_input_file.json
   2021/02/02 14:05:15 Retrieving S3 credentails ( sls-s3-credentials ) for SLS
   2021/02/02 14:05:15 Uploading SLS file: /var/www/ephemeral/prep/config/surtur/sls_input_file.json
   2021/02/02 14:05:15 Successfully uploaded SLS Input File.
   ```
2. Upload the same `data.json` file we used to our Kubernetes cloud-init DataSource, cray-bss:
   ```bash
   pit# csi handoff bss-metadata --data-file /var/www/ephemeral/configs/data.json
   ```
3. Upload NCN artifacts, filling `CSM_RELEASE` with the actual release tarball.
   ```bash
   pit# export CSM_RELEASE=csm-0.7.29
   pit# export artdir=/var/www/ephemeral/${CSM_RELEASE}/images/
   csi handoff ncn-images \
        --k8s-kernel-path $adir/kubernetes/*.kernel \
        --k8s-initrd-path $adir/kubernetes/initrd.img*.xz \
        --k8s-squashfs-path $adir/kubernetes/kubernetes*.squashfs \
        --ceph-kernel-path $adir/ceph/*.kernel \
        --ceph-initrd-path $adir/ceph/initrd.img*.xz \
        --ceph-squashfs-path $adir/ceph/ceph*.squashfs
   ```
4. Set efibootmgr for booting next from Port-1 of Riser-1
   ```bash
   pit# efibootmgr | grep -i ipv4
   Boot0005* UEFI IPv4: Network 00 at Riser 02 Slot 01
   Boot0007* UEFI IPv4: Network 01 at Riser 02 Slot 01
   Boot000A* UEFI IPv4: Intel Network 00 at Baseboard
   Boot000C* UEFI IPv4: Intel Network 01 at Baseboard
   ```
   Looking at the above output, `Network 00 at Riser 02 Slot 01` is reasonably our Port-1 of Riser-1.
   This value varies, take a moment to study the `efibootmgr` output before running this next command.
   ```bash
   pit# efibootmgr -n 0005 2>&1 | grep -i bootbext
   BootNext: 0005
   ```
5. **`SKIP THIS STEP IF USING USB LIVECD`** The remote LiveCD will loose all changes and local data once it is rebooted. It is advised
   to backup the prep directory for the LiveCD off of the CRAY before rebooting. This will faciliate setting the LiveCD up again in the event
   of a bad reboot. Follow the procedure in [VirtuaL ISO Boot - Backing up the OverlayFS](062-LIVECD-VIRTUAL-ISO-BOOT.md#backing-up-the-overlay-cow-fs). After completing that, return here and proceed to the next step.
6. Optionally setup conman or serial console if not already on one from any laptop
   - Collect the CAN IPs for logging into other NCNs while this happens. This is useful for interacting
      and debugging the kubernetes cluster while the LiveCD is `offline`.
      ```bash
      pit# ssh ncn-m002
      ncn-m002# ip a show vlan007 | grep inet
      inet 10.102.11.13/24 brd 10.102.11.255 scope global vlan007
      inet6 fe80::1602:ecff:fed9:7820/64 scope link
      ```
      Now login from another machine to verify that IP is usable
      ```bash
      macos# ssh root@10.102.11.13
      ncn-m002#
      ```
      Keep this terminal active as it will enable `kubectl` commands during the bring-up of the new NCN. If the reboot successfully deploys the LiveCD, this terminal can be exited.
7. Reboot the LiveCD.
   ```bash
   pit# reboot
   ```
8. Observe the serial console
   > **`NOTE`** This requires `ipmitool` to be present on another machine.
   ```bash
   macOS# export username
   macOS# export IPMI_PASSWORD
   macOS# ipmitool -I lanplus -U $username -E -H bigbird-ncn-m001-mgmt sol activate
   ```
9. The node should boot, acquire its hostname (i.e. ncn-m001)

10. Run `kubectl get nodes` to see the full kubernetes cluster
    > **`NOTE`** If the new node fails to join the cluster after running other cloud-init items please refer to the 
    > `handoff`
   ```bash
   ncn-m001:~ # kubectl get nodes
   NAME       STATUS   ROLES    AGE     VERSION
   ncn-m001   Ready    master   7s      v1.18.6
   ncn-m002   Ready    master   4h40m   v1.18.6
   ncn-m003   Ready    master   4h38m   v1.18.6
   ncn-w001   Ready    <none>   4h39m   v1.18.6
   ncn-w002   Ready    <none>   4h39m   v1.18.6
   ncn-w003   Ready    <none>   4h39m   v1.18.6
   ```

11. Run `ip a` to show our IPs, verify the site link
    ```bash
    ncn-m001# ip a show lan0
    ```
12. Run `ip a` to show our VLANs, verify they all have IPs
    ```bash
    ncn-m001# ip a show vlan002 vlan004 vlan007
    ```
13. Verify we do not have a metal bootstrap IP, this should be blank
    ```bash
    ncn-m001# ip a show bond0
    ```
At this time, the cluster is done. If the administrator used a USB stick, it may be ejected at this time or [re-accessed](#accessing-usb-partitions-after-reboot).

The administrator can continue onto [CSM Validation](008-CSM-VALIDATION.md) to conclude the CSM product deployment.

<a name="accessing-usb-partitions-after-reboot"></a>
### Accessing USB Partitions After Reboot

After deploying the LiveCD's NCN, the LiveCD USB itself is unharmed and available to an administrator.

1. Mount and view the USB stick:
   ```bash
   ncn-m001# mkdir -pv /mnt/{cow,pitdata}
   ncn-m001# mount -L cow /mnt/cow
   ncn-m001# mount -L PITDATA /mnt/pitdata
   ncn-m001# ls -ld /mnt/cow/rw/*
   drwxr-xr-x  2 root root 4096 Jan 28 15:47 /mnt/cow/rw/boot
   drwxr-xr-x  8 root root 4096 Jan 29 07:25 /mnt/cow/rw/etc
   drwxr-xr-x  3 root root 4096 Feb  5 04:02 /mnt/cow/rw/mnt
   drwxr-xr-x  3 root root 4096 Jan 28 15:49 /mnt/cow/rw/opt
   drwx------ 10 root root 4096 Feb  5 03:59 /mnt/cow/rw/root
   drwxrwxrwt 13 root root 4096 Feb  5 04:03 /mnt/cow/rw/tmp
   drwxr-xr-x  7 root root 4096 Jan 28 15:40 /mnt/cow/rw/usr
   drwxr-xr-x  7 root root 4096 Jan 28 15:47 /mnt/cow/rw/var
   ncn-m001# ls -ld /mnt/pitdata/*
   drwxr-xr-x  2 root root        4096 Feb  3 04:32 /mnt/pitdata/configs
   drwxr-xr-x 14 root root        4096 Feb  3 07:26 /mnt/pitdata/csm-0.7.29
   -rw-r--r--  1 root root 22159328586 Feb  2 22:18 /mnt/pitdata/csm-0.7.29.tar.gz
   drwxr-xr-x  4 root root        4096 Feb  3 04:25 /mnt/pitdata/data
   drwx------  2 root root       16384 Jan 28 15:41 /mnt/pitdata/lost+found
   drwxr-xr-x  5 root root        4096 Feb  3 04:20 /mnt/pitdata/prep
   drwxr-xr-x  2 root root        4096 Jan 28 16:07 /mnt/pitdata/static
   ```

2. Be kind, unmount the USB before ejecting it:
    ```bash
    ncn-m001# umount /mnt/cow /mnt/pitdata
    ```
