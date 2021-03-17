# CSM Install Reboot - Final NCN Install

This page describes rebooting and deploying the non-compute node that is currently hosting the LiveCD.


* [Required Services](#required-services)
* [Notice of Danger](#notice-of-danger)
* [LiveCD Pre-Reboot Workarounds](#livecd-pre-reboot-workarounds)
* [Hand-Off](#hand-off)
    * [Start Hand-Off](#start-hand-off)
* [Accessing USB Partitions After Reboot](#accessing-usb-partitions-after-reboot)
   * [Accessing CSI from a USB or RemoteISO](#accessing-csi-from-a-usb-or-remoteiso)
* [Enable NCN Disk Wiping Safeguard](#enable-ncn-disk-wiping-safeguard)


<a name="required-services"></a>
## Required Services

These services must be healthy in Kubernetes before the reboot of the LiveCD can take place.

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


<a name="livecd-pre-reboot-workarounds"></a>
## LiveCD Pre-Reboot Workarounds


Check for workarounds in the `/opt/cray/csm/workarounds/livecd-pre-reboot` directory. If there are any
workarounds in that directory, run those when the workaround instructs. Timing is critical to ensure properly loaded
data so run them only when indicated. Instructions are in the `README` files.

```
# Example
pit# ls /opt/cray/csm/workarounds/livecd-pre-reboot
```

If there is a workaround here, the output looks similar to the following:
```
CASMINST-435
```

<a name="hand-off"></a>
## Hand-Off

The steps in this guide will ultimately walk an administrator through loading hand-off data and rebooting the node.
This will assist with remote-console setup, for observing the reboot.

At the end of these steps, the LiveCD will be no longer active. The node it was using will join
the Kubernetes cluster as the final of 3 masters forming a quorum.

<a name="start-hand-off"></a>
### Start Hand-Off

**It is very important to run the livecd-pre-reboot workarounds**. Ensure that the [](#pre-reboot-workarounds) have
all been run by the administrator before starting this stage.

1. Upload SLS file.
   > Note the system name environment variable `SYSTEM_NAME` must be set

   ```bash
   pit# csi upload-sls-file --sls-file /var/www/ephemeral/prep/${SYSTEM_NAME}/sls_input_file.json
   ```

   Expected output looks similar to the following:
   ```
   2021/02/02 14:05:15 Retrieving S3 credentails ( sls-s3-credentials ) for SLS
   2021/02/02 14:05:15 Uploading SLS file: /var/www/ephemeral/prep/eniac/sls_input_file.json
   2021/02/02 14:05:15 Successfully uploaded SLS Input File.
   ```
1. Get a token to use for authenticated communication with the gateway.
   > **`NOTE`** `api-gw-service-nmn.local` is legacy, and will be replaced with api-gw-service.nmn.
   ```bash
   pit# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
      -d client_id=admin-client \
      -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
      https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```
1. Upload the same `data.json` file we used to BSS, our Kubernetes cloud-init DataSource. __If you have made any changes__
   to this file as a result of any customizations or workarounds use the path to that file instead. This step will
   prompt for the root password of the NCNs.
   ```bash
   pit# csi handoff bss-metadata --data-file /var/www/ephemeral/configs/data.json
   ```
1. Upload NCN artifacts, filling `CSM_RELEASE` with the actual release tarball.
   ```bash
   pit# export CSM_RELEASE=csm-x.y.z
   pit# export artdir=/var/www/ephemeral/${CSM_RELEASE}/images
   pit# csi handoff ncn-images \
      --k8s-kernel-path $artdir/kubernetes/*.kernel \
      --k8s-initrd-path $artdir/kubernetes/initrd.img*.xz \
      --k8s-squashfs-path $artdir/kubernetes/kubernetes*.squashfs \
      --ceph-kernel-path $artdir/storage-ceph/*.kernel \
      --ceph-initrd-path $artdir/storage-ceph/initrd.img*.xz \
      --ceph-squashfs-path $artdir/storage-ceph/storage-ceph*.squashfs
   ```
1. List ipv4 boot options using `efibootmgr`:
   ```bash
   pit# efibootmgr | grep -Ei "ip(v4|4)"
   ```
1. Identify Port-1 of Riser-1 in `efibootmgr` output and set `PXEPORT` variable.
   * Example 1

      Possible output of `efibootmgr` command in the previous step:
      ```
      Boot0005* UEFI IPv4: Network 00 at Riser 02 Slot 01
      Boot0007* UEFI IPv4: Network 01 at Riser 02 Slot 01
      Boot000A* UEFI IPv4: Intel Network 00 at Baseboard
      Boot000C* UEFI IPv4: Intel Network 01 at Baseboard
      ```
      Looking at the above output, `Network 00 at Riser 02 Slot 01` is reasonably our Port-1 of Riser-1, which would
      be `Boot0005` in this case. Set `PXEPORT` to the numeric suffix of that name.
      ```bash
      pit# export PXEPORT=0005
      ```
   * Example 2

      Possible output of `efibootmgr` command in the previous step:
      ```
      Boot0013* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (HTTP(S) IPv4)
      Boot0014* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
      Boot0017* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (HTTP(S) IPv4)
      Boot0018* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
      ```
      In the above output, look for the non-OCP device that has "PXE IPv4" rather than "HTTP(S) IPv4", which would be
      `Boot0018` in this case. Set `PXEPORT` to the numeric suffix of that name.
      ```bash
      pit# export PXEPORT=0018
      ```

   * Example 3

      The output below if what a Gigabyte machine may look like.

      ```
      Boot000B* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:C7:12:F2
      Boot000C* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:C7:12:F3
      Boot000D* UEFI: PXE IP6 Mellanox Network Adapter - B8:59:9F:C7:12:F2
      Boot000E* UEFI: PXE IP6 Mellanox Network Adapter - B8:59:9F:C7:12:F3
      ```

      This value varies, take a moment to study the `efibootmgr` output before proceeding.

1. Use `efibootmgr` to set next boot device to port selected in the previous step.
   ```bash
   pit# efibootmgr -n $PXEPORT 2>&1 | grep -i BootNext
   ```

   If `PXEPORT` was set to 0005, the expected output looks similar to the following:
   ```
   BootNext: 0005
   ```
1. **`SKIP THIS STEP IF USING USB LIVECD`** The remote LiveCD will lose all changes and local data once it is rebooted.
   It is advised to backup the prep directory for the LiveCD off of the CRAY before rebooting. This will facilitate
   setting the LiveCD up again in the event of a bad reboot. Follow the procedure in
   [Virtual ISO Boot - Backing up the OverlayFS](062-LIVECD-VIRTUAL-ISO-BOOT.md#backing-up-the-overlay-cow-fs).
   After completing that, return here and proceed to the next step.
1. Optionally setup conman or serial console if not already on one from any laptop
   ```bash
   external# script -a boot.livecd.$(date +%Y-%m-%d).txt
   external# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   external# SYSTEM_NAME=eniac
   external# username=root
   external# IPMI_PASSWORD=changeme
   external# ipmitool -I lanplus -U $username -E -H ${SYSTEM_NAME}-ncn-m001-mgmt chassis power status
   external# ipmitool -I lanplus -U $username -E -H ${SYSTEM_NAME}-ncn-m001-mgmt sol activate
   ```
1. Collect the CAN IPs for logging into other NCNs while this happens. This is useful for interacting
   and debugging the Kubernetes cluster while the LiveCD is `offline`.
   ```bash
   pit# ssh ncn-m002
   ncn-m002# ip a show vlan007 | grep inet
   ```

   Expected output looks similar to the following:
   ```
   inet 10.102.11.13/24 brd 10.102.11.255 scope global vlan007
   inet6 fe80::1602:ecff:fed9:7820/64 scope link
   ```
   Now login from another machine to verify that IP is usable
   ```bash
   external# ssh root@10.102.11.13
   ncn-m002#
   ```
   Keep this terminal active as it will enable `kubectl` commands during the bring-up of the new NCN.
   If the reboot successfully deploys the LiveCD, this terminal can be exited.

1. Wipe the node beneath the LiveCD, erasing the RAIDs labels will trigger a fresh partition table to deploy.
   > **`WARNING`** Do not assume to wipe the first three disks (e.g. `sda, sdb, and sdc`), these could be any letter. Choosing the wrong ones may result in wiping the USB stick.
   1. Select disks to wipe; SATA/NVME/SAS
      ```bash
      pit# md_disks="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print "/dev/" $2}')"
      ```

   2. Sanity check; print disks into typscript or console
      ```bash
      pit# echo $md_disks
      ```

      Expected output looks similar to the following:
      ```
      /dev/sda /dev/sdb /dev/sdc
      ```

   3. Wipe. **This is irreversible.**
      ```bash
      pit# wipefs --all --force $md_disks
      ```

      If any disks had labels present, output looks similar to the following:
      ```
      /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
      /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
      /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
      /dev/sdb: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
      /dev/sdb: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
      /dev/sdc: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
      /dev/sdc: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
      /dev/sdc: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
      ```

      The thing to verify is that there are no error messages in the output.
1. Reboot the LiveCD.
   ```bash
   pit# reboot
   ```
1. The node should boot, acquire its hostname (i.e. ncn-m001).
   > **`NOTE`**: If the nodes has pxe boot issues, such as getting pxe errors or not pulling the ipxe.efi binary, see [PXE boot troubleshooting](420-MGMT-NET-PXE-TSHOOT.md)

   > **`NOTE`**: If ncn-m001 booted without a hostname or it didn't run all the cloud-init scripts the following commands need to be ran **(but only in that circumstance)**.
   > In the commands below the prompt is shown as ncn-m001 purely to indicate that the commands should be run on that node.
   >
   > 1. Make directory to copy network config files to.
   >    ```bash
   >    ncn-m001# mkdir /mnt/cow
   >    ```
   > 2. Mount the USB to that directory.
   >    ```bash
   >    ncn-m001# mount -L cow /mnt/cow
   >    ```
   > 3. Copy the network config files.
   >    ```bash
   >    ncn-m001# cp -pv /mnt/cow/rw/etc/sysconfig/network/ifroute* /etc/sysconfig/network/
   >    ncn-m001# cp -pv /mnt/cow/rw/etc/sysconfig/network/ifcfg-lan0 /etc/sysconfig/network/
   >    ```
   > 4. Run the `set-dhcp-to-static.sh` script
   >    ```bash
   >    ncn-m001# /srv/cray/scripts/metal/set-dhcp-to-static.sh
   >    ```
   >    Network connectivity should be restored afterwards; the bond is up.
   > 5. Run the following commands:
   >    ```bash
   >    ncn-m001# cloud-init clean
   >    ncn-m001# cloud-init init
   >    ncn-m001# cloud-init modules -m init
   >    ncn-m001# cloud-init modules -m config
   >    ncn-m001# cloud-init modules -m final
   >    ```
   >    This should pull all the required cloud-init data for the NCN to join the cluster.
1. Login and start a typescript (the IP used here is the same from step 9).

   ```bash
   external# ssh root@10.102.11.13
   ncn-m002# ssh ncn-m001
   ncn-m001# script -a verify.csm.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```
1. Optionally change the root password on ncn-m001 to match the other management NCNs.

   > This step is optional and is only needed when the other management NCNs passwords were customized during the [CSM Metal Install](005-CSM-METAL-INSTALL.md) procedure. If the management NCNs still have the default password this step can be skipped.

   ```bash
   ncn-m001# passwd
   ```
1. Run `kubectl get nodes` to see the full Kubernetes cluster.
    > **`NOTE`** If the new node fails to join the cluster after running other cloud-init items please refer to the
    > `handoff`
   ```bash
   ncn-m001# kubectl get nodes
   ```

   Expected output looks similar to the following:
   ```
   NAME       STATUS   ROLES    AGE     VERSION
   ncn-m001   Ready    master   7s      v1.18.6
   ncn-m002   Ready    master   4h40m   v1.18.6
   ncn-m003   Ready    master   4h38m   v1.18.6
   ncn-w001   Ready    <none>   4h39m   v1.18.6
   ncn-w002   Ready    <none>   4h39m   v1.18.6
   ncn-w003   Ready    <none>   4h39m   v1.18.6
   ```
1. Follow the procedure defined in [Accessing CSI from a USB or RemoteISO](#accessing-csi-from-a-usb-or-remoteiso).
1. Restore and verify the site link. It will be necessary to restore the `ifcfg-lan0` file, and both the
    `ifroute-lan0` and `ifroute-vlan002` file from either manual backup take in step 6 or re-mount the USB and copy it
    from the prep directory to `/etc/sysconfig/network/`.
   ```bash
   ncn-m001# export SYSTEM_NAME=eniac
   ncn-m001# cp /mnt/pitdata/prep/${SYSTEM_NAME}/pit-files/ifcfg-lan0 /etc/sysconfig/network/
   ncn-m001# cp /mnt/pitdata/prep/${SYSTEM_NAME}/pit-files/ifroute-lan0 /etc/sysconfig/network/
   ncn-m001# cp /mnt/pitdata/prep/${SYSTEM_NAME}/pit-files/ifroute-vlan002 /etc/sysconfig/network/
   ncn-m001# wicked ifreload lan0
   ```
1. Run `ip a` to show our IPs, verify the site link.
    ```bash
    ncn-m001# ip a show lan0
    ```
1. Run `ip a` to show our VLANs, verify they all have IPs
    ```bash
    ncn-m001# ip a show vlan002
    ncn-m001# ip a show vlan004
    ncn-m001# ip a show vlan007
    ```
1. Verify we do not have a metal bootstrap IP, this should be blank
    ```bash
    ncn-m001# ip a show bond0
    ```
1. [Enable NCN Disk Wiping Safeguard](#enable-ncn-disk-wiping-safeguard) to prevent destructive behavior from occurring during reboot.
      > **`NOTE`** This safeguard needs to be _removed_ to facilitate bare-metal deployments of new nodes. The linked [Enable NCN Disk Wiping Safeguard](#enable-ncn-disk-wiping-safeguard) procedure can be used to disable the safeguard by setting the value back to `0`.
1. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have direct internet 
   access these RPMs will need to be externally downloaded and then copied to be installed.
   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```
1. Now check for workarounds in the `/opt/cray/csm/workarounds/livecd-post-reboot` directory. If there are any workarounds in that directory, run those now. Each has its own instructions in their respective `README.md` files.

    **Note:** The following command assumes that the data partition of the USB stick has been remounted at /mnt/pitdata
    ```bash
    # Example
    ncn-m001# ls /opt/cray/csm/workarounds/livecd-post-reboot
    ```

    If there are workarounds here, the output looks similar to the following:
    ```
    CASMINST-1309  CASMINST-1570
    ```

At this time, the NCN cluster is fully established. The administrator may now eject any mounted USB stick:
   ```bash
   ncn-m001# umount /mnt/rootfs /mnt/sqfs /mnt/livecd /mnt/pitdata
   ```

The administrator can continue onto [CSM Validation](008-CSM-VALIDATION.md) to conclude the CSM product deployment.

There are some operational steps to be taken in [NCN/Management Node Locking](009-NCN-LOCKING.md) and then [Firmware updates with FAS](010-FIRMWARE-UPDATE-WITH-FAS.md)

Then the administrator should install additional products following the procedures in the HPE Cray EX System Installation and Configuration Guide S-8000.

<a name="accessing-usb-partitions-after-reboot"></a>
## Accessing USB Partitions After Reboot

After deploying the LiveCD's NCN, the LiveCD USB itself is unharmed and available to an administrator.

1. Mount and view the USB stick:
   ```bash
   ncn-m001# mkdir -pv /mnt/{cow,pitdata}
   ncn-m001# mount -L cow /mnt/cow
   ncn-m001# mount -L PITDATA /mnt/pitdata
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

   Look at the contents of `/mnt/pitdata`:
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

1. Be kind, unmount the USB before ejecting it:
    ```bash
    ncn-m001# umount /mnt/cow /mnt/pitdata
    ```

<a name="accessing-csi-from-a-usb-or-remoteiso"></a>
#### Accessing CSI from a USB or RemoteISO

CSI is not installed on the NCNs, however it is compiled against the same base architecture and OS. Therefore, it can
be accessed by any LiveCD ISO file if not the one used for the original installation.


1. Set the CSM Release
   ```bash
   ncn# export CSM_RELEASE=csm-x.y.z
   ```
2. Make directories.
   ```bash
   ncn# mkdir -pv /mnt/livecd /mnt/rootfs /mnt/sqfs /mnt/pitdata
   ```
3. Mount the rootfs.
   ```bash
   ncn# mount -L PITDATA /mnt/pitdata
   ncn# mount /mnt/pitdata/${CSM_RELEASE}/cray-pre-install-toolkit-*.iso /mnt/livecd/
   ncn# mount /mnt/livecd/LiveOS/squashfs.img /mnt/sqfs/
   ncn# mount /mnt/sqfs/LiveOS/rootfs.img /mnt/rootfs/
   ```
4. Invoke CSI usage to validate it runs and is ready for use:
   ```bash
   ncn# /mnt/rootfs/usr/bin/csi --help
   ```

5. Copy the CSI binary and CSM workaround documentation off to `tmp/`
   ```bash
   ncn# cp -pv /mnt/rootfs/usr/bin/csi /tmp/csi
   ```

<a name="enable-ncn-disk-wiping-safeguard"></a>
## Enable NCN Disk Wiping Safeguard

> For more information about the safeguard, see `/usr/share/doc/metal-dracut/mdsquash/README.md` on any NCN. (`view $(rpm -qi --fileprovide dracut-metal-mdsquash | grep -i readme)`).

After all the NCNs have been installed, it is imperative to disable the automated wiping of disks so subsequent boots
do not destroy any data unintentionally. First follow the procedure [above](#accessing-usb-partitions-after-reboot)
to re-mount the assets and then get a new token:

```bash
pit# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
  -d client_id=admin-client \
  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Followed by a call to CSI to update BSS:

```bash
pit# /tmp/csi handoff bss-update-param --set metal.no-wipe=1
```

> **`NOTE`** `/tmp/csi` will delete itself on the next reboot since /tmp/ is mounted as tmpfs and does not persist **no matter what**.
