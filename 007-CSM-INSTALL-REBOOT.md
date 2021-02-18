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
	* [Token Expiration](#token-expiration)
* [LiveCD Pre-Reboot Workarounds](#livecd-pre-reboot-workarounds)
* [Hand-Off](#hand-off)
    * [Start Hand-Off](#start-hand-off)
* [Accessing USB Partitions After Reboot](#accessing-usb-partitions-after-reboot)
   * [Accessing CSI from a USB or RemoteISO](#accessing-csi-from-a-usb-or-remoteiso)
* [Enable NCN Disk Wiping Safeguard](#enable-ncn-disk-wiping-safeguard)


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

<a name="token-expiration"></a>
### Token Expiration

Tokens for joining the cluster expire after `2hours`, if the cluster has been running for longer than that time then 
workarounds are going to be needed.

Check the [LiveCD Pre-Reboot Workarounds](#livecd-pre-reboot-workarounds).


<a name="livecd-pre-reboot-workarounds"></a>
## LiveCD Pre-Reboot Workarounds



Check for workarounds in the `/var/www/ephemeral/${CSM_RELEASE}/fix/livecd-pre-reboot` directory. If there are any 
workarounds in that directory, run those when the workaround instructs. Timing is critical to ensure properly loaded 
data so run them only when indicated. Instructions are in the `README` files.

```
# Example
pit# ls /var/www/ephemeral/${CSM_RELEASE}/fix/livecd-pre-reboot
casminst-435
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
   2021/02/02 14:05:15 Retrieving S3 credentails ( sls-s3-credentials ) for SLS
   2021/02/02 14:05:15 Uploading SLS file: /var/www/ephemeral/prep/surtur/sls_input_file.json
   2021/02/02 14:05:15 Successfully uploaded SLS Input File.
   ```
2. Get a token to use for authenticated communication with the gateway.
   > **`NOTE`** `api-gw-service-nmn.local` is legacy, and will be replaced with api-gw-service.nmn.
   ```text
   pit# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
      -d client_id=admin-client \
      -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
      https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```
3. Upload the same `data.json` file we used to BSS, our Kubernetes cloud-init DataSource. __If you have made any changes__ 
   to this file as a result of any customizations or workarounds use the path to that file instead. This step will 
   prompt for the root password of the NCNs.
   ```bash
   pit# csi handoff bss-metadata --data-file /var/www/ephemeral/configs/data.json
   ```
4. Upload NCN artifacts, filling `CSM_RELEASE` with the actual release tarball.
   ```bash
   pit# export CSM_RELEASE=csm-0.7.29
   pit# export artdir=/var/www/ephemeral/${CSM_RELEASE}/images
   pit# csi handoff ncn-images \
        --k8s-kernel-path $artdir/kubernetes/*.kernel \
        --k8s-initrd-path $artdir/kubernetes/initrd.img*.xz \
        --k8s-squashfs-path $artdir/kubernetes/kubernetes*.squashfs \
        --ceph-kernel-path $artdir/storage-ceph/*.kernel \
        --ceph-initrd-path $artdir/storage-ceph/initrd.img*.xz \
        --ceph-squashfs-path $artdir/storage-ceph/storage-ceph*.squashfs
   ```
5. Set efibootmgr for booting next from Port-1 of Riser-1
   ```bash
   pit# efibootmgr | grep -i ipv4
   Boot0005* UEFI IPv4: Network 00 at Riser 02 Slot 01
   Boot0007* UEFI IPv4: Network 01 at Riser 02 Slot 01
   Boot000A* UEFI IPv4: Intel Network 00 at Baseboard
   Boot000C* UEFI IPv4: Intel Network 01 at Baseboard
   ```
   Looking at the above output, `Network 00 at Riser 02 Slot 01` is reasonably our Port-1 of Riser-1.

   ```bash
   pit# efibootmgr | grep -i ipv4
   Boot0013* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (HTTP(S) IPv4)
   Boot0014* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
   Boot0017* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (HTTP(S) IPv4)
   Boot0018* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
   ```
   In the above example, look for the non-OCP device that has "PXE IPv4" rather than "HTTP(S) IPv4".

   This value varies, take a moment to study the `efibootmgr` output before running this next command.
   ```bash
   pit# efibootmgr -n 0005 2>&1 | grep -i BootNext
   BootNext: 0005
   ```
6. **`SKIP THIS STEP IF USING USB LIVECD`** The remote LiveCD will lose all changes and local data once it is rebooted. 
   It is advised to backup the prep directory for the LiveCD off of the CRAY before rebooting. This will facilitate 
   setting the LiveCD up again in the event of a bad reboot. Follow the procedure in 
   [VirtuaL ISO Boot - Backing up the OverlayFS](062-LIVECD-VIRTUAL-ISO-BOOT.md#backing-up-the-overlay-cow-fs).
   After completing that, return here and proceed to the next step.
7. Optionally setup conman or serial console if not already on one from any laptop
8. Collect the CAN IPs for logging into other NCNs while this happens. This is useful for interacting
   and debugging the kubernetes cluster while the LiveCD is `offline`.
   ```bash
   pit# ssh ncn-m002
   ncn-m002# ip a show vlan007 | grep inet
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
9. Reboot the LiveCD.
   ```bash
   pit# reboot
   ```
10. Observe the serial console
   > **`NOTE`** This requires `ipmitool` to be present on another machine.
   ```bash
   external# export username
   external# export IPMI_PASSWORD
   external# ipmitool -I lanplus -U $username -E -H bigbird-ncn-m001-mgmt sol activate
   ```
11. The node should boot, acquire its hostname (i.e. ncn-m001).

   > **`NOTE`**: If m001 booted without a hostname or it didn't run all the cloud-init scripts the following commands need to be ran **(but only in that circumstance)**.
   > Make directory to copy network config files to.
   > ```
   > mkdir /mnt/cow
   > ```
   > Mount the USB to that directory.
   > ```
   > mount -L cow /mnt/cow
   > ```
   > Copy the network config files.
   > ```
   > cp -pv /mnt/cow/rw/etc/sysconfig/network/ifroute* /etc/sysconfig/network/
   > cp -pv /mnt/cow/rw/etc/sysconfig/network/ifcfg-lan0 /etc/sysconfig/network/
   > ```
   >
   > Run the dhcp to static script
   > ```
   > /srv/cray/scripts/metal/set-dhcp-to-static.sh
   > ```
   > After this you should have network connectivity.
   > Then you will run.
   > ```
   > cloud-init clean
   > cloud-init init
   > cloud-init modules -m init
   > cloud-init modules -m config
   > cloud-init modules -m final
   > ```
   > This should pull all the required cloud-init data for the NCN to join the cluster.

12. Run `kubectl get nodes` to see the full Kubernetes cluster.
    > **`NOTE`** If the new node fails to join the cluster after running other cloud-init items please refer to the 
    > `handoff`
   ```bash
   ncn-m001# kubectl get nodes
   NAME       STATUS   ROLES    AGE     VERSION
   ncn-m001   Ready    master   7s      v1.18.6
   ncn-m002   Ready    master   4h40m   v1.18.6
   ncn-m003   Ready    master   4h38m   v1.18.6
   ncn-w001   Ready    <none>   4h39m   v1.18.6
   ncn-w002   Ready    <none>   4h39m   v1.18.6
   ncn-w003   Ready    <none>   4h39m   v1.18.6
   ```

13. Restore and verify the site link. It will be necessary to restore the `ifcfg-lan0` file, and both the `ifroute-lan0` and `ifroute-vlan002` file from either 
    manual backup take in step 6 or re-mount the USB and copy it from the prep directory to `/etc/sysconfig/network/`.

   > The following command assumes that the PITDATA partition of the USB stick has been remounted at /mnt/pitdata
   ```
   ncn-m001# cp /mnt/pitdata/prep/surtur/pit-files/ifcfg-lan0 /etc/sysconfig/network/
   ncn-m001# cp /mnt/pitdata/prep/surtur/pit-files/ifroute-lan0 /etc/sysconfig/network/
   ncn-m001# cp /mnt/pitdata/prep/surtur/pit-files/ifroute-vlan002 /etc/sysconfig/network/
   ncn-m001# wicked ifup lan0
   ``` 

14. Run `ip a` to show our IPs, verify the site link. 
    ```bash
    ncn-m001# ip a show lan0
    ```
15. Run `ip a` to show our VLANs, verify they all have IPs
    ```bash
    ncn-m001# ip a show vlan002
    ncn-m001# ip a show vlan004
    ncn-m001# ip a show vlan007
    ```
16. Verify we do not have a metal bootstrap IP, this should be blank
    ```bash
    ncn-m001# ip a show bond0
    ```
17. Enable the wipe-safeguard to prevent destructive behavior from occurring during reboot. 
      1. Follow the procedure defined in [Accessing CSI from a USB or RemoteISO](#accessing-csi-from-a-usb-or-remoteiso)
      2. Activate the safe-guard with the final procedure [Enable NCN Disk Wiping Safeguard](#enable-ncn-disk-wiping-safeguard)
      > **`NOTE`** This safeguard needs to be _removed_ to faciliate bare-metal deployments of new nodes. The linked [Enable NCN Disk Wiping Safeguard](#enable-ncn-disk-wiping-safeguard) procedure can be used to disable the safeguard.
   At this time, the cluster is done. If the administrator used a USB stick, it may be ejected at this time or [re-accessed](#accessing-usb-partitions-after-reboot).
18. Apply Mountain, Hill and River cabinet routing to m001 as described in [Add Compute Cabinet Routes](109-COMPUTE-CABINET-ROUTES-FOR-NCN.md).
19. Now check for workarounds in the `fix/after-livecd-reboot` directory within the CSM tar. Each has its own instructions in their respective `README` files.
```
# Example
# The following command assumes that the data partition of the USB stick has been remounted at /mnt/pitdata
ncn-m001# mount -L PITDATA /mnt/pitdata
ncn-m001# export CSM_RELEASE=csm-x.y.z
ncn-m001# ls /mnt/pitdata/${CSM_RELEASE}/fix/after-livecd-reboot
CASMINST-980
```

The administrator can continue onto [CSM Validation](008-CSM-VALIDATION.md) to conclude the CSM product deployment.

<a name="accessing-usb-partitions-after-reboot"></a>
## Accessing USB Partitions After Reboot

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

<a name="accessing-csi-from-a-usb-or-remoteiso"></a>
#### Accessing CSI from a USB or RemoteISO

CSI is not installed on the NCNs, however it is compiled against the same base architecture and OS. Therefore, it can
be accessed by any LiveCD ISO file if not the one used for the original installation.


1. Set the CSM Release
   ```bash
   ncn-m001# CSM_RELEASE=0.8.6
   ```
2. Make directories.
   ```bash
   ncn-m001# mkdir /mnt/livecd /mnt/rootfs /mnt/sqfs /mnt/pitdata
   ```
3. Mount the rootfs (prompts omitted to facilitate copy-paste)
   ```bash
   mount -L PITDATA /mnt/pitdata
   mount /mnt/pitdata/csm-${CSM_RELEASE}/cray-pre-install-toolkit-*.iso /mnt/livecd/
   mount /mnt/livecd/LiveOS/squashfs.img /mnt/squashfs/
   mount /mnt/squashfs/LiveOS/rootfs.img /mnt/rootfs/
   ```
4. Invoke CSI usage to validate it runs and is ready for use:
   ```bash
   ncn-m001# /mnt/rootfs/usr/bin/csi --help
   ```

5. Unmount the partitions after use, or copy the binary off to `tmp/`:
   ```bash
   ncn-m001# cp -pv /mnt/rootfs/usr/bin/csi /tmp/csi
   ncn-m001# umount /mnt/rootfs /mnt/squashfs /mnt/livecd /mnt/pitdata
   ```

<a name="enable-ncn-disk-wiping-safeguard"></a>
## Enable NCN Disk Wiping Safeguard

> For more information about the safeguard, see `/usr/share/doc/metal-dracut/mdsquash/README.md` on any NCN. (`view $(rpm -qi --fileprovide dracut-metal-mdsquash | grep -i readme)`).

After all the NCNs have been installed, it is imperative to disable the automated wiping of disks so subsequent boots 
do not destroy any data unintentionally. First follow the procedure [above](#accessing-usb-partitions-after-reboot)
to re-mount the assets and then get a new token:

```text
pit# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
  -d client_id=admin-client \
  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Followed by a call to CSI to update BSS:

```bash
/tmp/csi handoff bss-update-param --set metal.no-wipe=1
```

> **`NOTE`** `/tmp/csi` will delete itself on the next reboot since /tmp/ is mounted as tmpfs and does not persist **no matter what**.
