# CSM Install Reboot - Final NCN Install

This page describes rebooting and deploying the non-compute node that is currently hosting the LiveCD.

* [Required Services](#required-services)
* [Notice of Danger](#danger)
* [Hand-Off](#hand-off)
    * [Start Hand-Off](#start-hand-off)
* [Reboot](#reboot)
* [Accessing USB Partitions After Reboot](#accessing-usb-partitions-after-reboot)

<a name="required-services"></a>
## Required Services

These services must be healthy in Kubernetes before the reboot of the LiveCD can take place.

Required Platform Services:
- cray-bss
- cray-dhcp-kea
- cray-dns-unbound
- cray-ipxe
- cray-sls
- cray-s3
- cray-tftp

> ## Danger!
> <a name="danger"></a>
> 
> An administrator is **strongly encouraged** to be mindful of pitfalls during this segment of the CSM install.
> The steps below do contain warnings themselves, but overall there are risks:
> 
> - SSH will cease to work when the LiveCD reboots; the serial console will need to be leveraged
> 
> - Rebooting a remoteISO will dump all running changes on the `pit` node; USBs are accessible after the install
> 
> - The NCN **will never wipe a USB stick** during installation
> 
> - Learning the CAN IPs of the other NCNs will be a benefit if troubleshooting is required 
> 
> This procedure entails deactivating the LiveCD, meaning the LiveCD and all of its resources will be
> **unavailable**.

<a name="hand-off"></a>
## Hand-Off

The steps in this guide will ultimately walk an administrator through loading hand-off data and rebooting the node.
This will assist with remote-console setup, for observing the reboot.

At the end of these steps, the LiveCD will be no longer active. The node it was using will join
the Kubernetes cluster as the final of 3 masters forming a quorum.

<a name="start-hand-off"></a>
### Start Hand-Off

1. Start a new typescript (quit )
   (Run this on the `pit` node as root, the prompts are removed for easier copy-paste; this step is only useful as a whole)
   - Exit the current typescript if one has arrived here from the prior pages:
      ```bash
      pit# exit
      pit# popd
      ```
   - Start the new script
      ```bash
      mkdir -pv /var/www/ephemeral/prep/admin
      pushd /var/www/ephemeral/prep/admin
      script -af csm-livecd-reboot.$(date +%Y-%m-%d).txt
      export PS1='\u@\H \D{%Y-%m-%d} \t \w # ' 
      ```

1. Check for workarounds in the `/opt/cray/csm/workarounds/livecd-pre-reboot` directory. If there are any
workarounds in that directory, run those when the workaround instructs. Timing is critical to ensure properly loaded
data so run them only when indicated. Instructions are in the `README` files.
    
    ```bash
    # Example
    pit# ls /opt/cray/csm/workarounds/livecd-pre-reboot
    ```
    
    If there is a workaround here, the output looks similar to the following:
    ```
    CASMINST-435
    ```
    
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

1. <a name="ncn-boot-artifacts-hand-off"></a>Upload NCN boot artifacts into S3.
    
    1. Set variables
    
        **IMPORTANT**: The variables you set depend on whether or not you followed the steps in 
        [108-NCN-NTP.md#setting-a-local-timezone](108-NCN-NTP.md#setting-a-local-timezone).  The
        two paths forward are listed below:
        
        * If you customized the timezones, set the following variables:
            
            ```bash
            pit# export artdir=/var/www/ephemeral/data
            pit# export k8sdir=$artdir/k8s
            pit# export cephdir=$artdir/ceph
            ```
            
        * If you did **not** customize the timezones, set the following variables (this is the default path):
            
            ```bash
            pit# export CSM_RELEASE=csm-x.y.z
            pit# export artdir=/var/www/ephemeral/${CSM_RELEASE}/images
            pit# export k8sdir=$artdir/kubernetes
            pit# export cephdir=$artdir/storage-ceph
            ```
    
    2. After setting the variables above per your situation, run:
        
        ```bash
        pit# csi handoff ncn-images \
        --k8s-kernel-path $k8sdir/*.kernel \
        --k8s-initrd-path $k8sdir/initrd.img*.xz \
        --k8s-squashfs-path $k8sdir/*.squashfs \
        --ceph-kernel-path $cephdir/*.kernel \
        --ceph-initrd-path $cephdir/initrd.img*.xz \
        --ceph-squashfs-path $cephdir/*.squashfs
        ```
       
        Running this command will output a block that looks like this at the end:
        ```text
        You should run the following commands so the versions you just uploaded can be used in other steps:
        export KUBERNETES_VERSION=x.y.z
        export CEPH_VERSION=x.y.z
        ```
        Be sure to perform this action so subsequent steps are successful.

1. Upload the same `data.json` file we used to BSS, our Kubernetes cloud-init DataSource. __If you have made any changes__
   to this file as a result of any customizations or workarounds, use the path to that file instead. This step will
   prompt for the root password of the NCNs.
    
    ```bash
    pit# csi handoff bss-metadata --data-file /var/www/ephemeral/configs/data.json
    ```
    
1. Ensure the DNS server value is set correctly. If for any reason you have changed the IP address of the DNS server,
   use that value instead.
    
    ```bash
    pit# csi handoff bss-update-cloud-init --set meta-data.dns-server=10.92.100.225 --limit Global
    ```
        
1. Upload the bootstrap information; note this denotes information that should always be kept together in order to fresh-install the system again.

    > **`NOTE`** This is important for installations using the RemoteISO (not USB stick). For USBs, this is recommended as to remove 
    > the need for safekeeping the USB.
   
    - **Option 1**: Copy to ncn-m002
        
        1. Login; setup passwordless SSH _to_ the pit node by copying ONLY the public key from `ncn-m002` to the `pit` (**do not setup passwordless SSH _from_ the PIT** or the key will have to be securely tracked or expunged if using a USB installation).
        
            ```bash
            pit# CSM_RELEASE=$(basename $(ls -d /var/www/ephemeral/csm*/ | head -n 1))
            
            # this will prompt for a password:
            pit# ssh ncn-m002 cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
            ```
        
        1. Login to ncn-m002, then into pit.nmn; accept the host signatures to allow the upcoming nested rsync to work:
            
            ```bash
            pit# ssh ncn-m002 ssh pit.nmn
            ```

        1. Run this to create the backup; in one swoop, login to m002 and pull the files off the pit. _This runs `rsync` with specific parameters; `partial`, `non-verbose`, and `progress`._
            
            > NOTE: this needs to be optimized to copy only the change/delta within the `csm/` folder, as well as the tar. Right now this 
            > fetches 100% of the `csm/` folder without any compression.

            ```bash
            pit# ssh ncn-m002 CSM_RELEASE=$(basename $(ls -d /var/www/ephemeral/csm*/ | head -n 1)) \
            'mkdir -pv /metal/bootstrap
            rsync -rltD -P --delete pit.nmn:/var/www/ephemeral/prep /metal/bootstrap/
            rsync -rltD -P --delete pit.nmn:/var/www/ephemeral/${CSM_RELEASE} /metal/bootstrap/'
            ```
        
        1. Handoff prep and CSM backups are done; the administrator or CI/CD agent can move onto the next step.

    - **Option 2**: Create an S3 bucket
        
        > **`STUB`** This is not done (CASMINST-1850); this is preferred, it could be done anytime after an installation as well.

        ```bash
        # placeholder;
        ```
    
1. List ipv4 boot options using `efibootmgr`:
    
    ```bash
    pit# efibootmgr | grep -Ei "ip(v4|4)"
    ```
    
1. Set the boot order for **masters** from one of the following guides:
    
    > `**NOTE**` If your boot order from `efibootmgr` looks like one of [these examples](101-NCN-BOOTING.md#examples) then you can proceed to the next step.
    
    - [Gigabyte Technology](101-NCN-BOOTING.md#gigabyte-technology)
    - [Hewlett Packard Enterprise](101-NCN-BOOTING.md#hewlett-packard-enterprise)
    - [Intel Corporation](101-NCN-BOOTING.md#intel-corporation)
    
1. Tell the node to PXE boot on the next boot ... use `efibootmgr` to set next boot device to the first PXE boot option. This step assumes the boot order was set up by the immediate, previous step.

    ```bash
    pit# efibootmgr -n $(efibootmgr | grep -Ei "ip(v4|4)" | awk '{print $1}' | head -n 1 | tr -d Boot*) | grep -i bootnext
    BootNext: 0014
    ```

1. Collect a backdoor login ... fetch the CAN IP for ncn-m002 for a backdoor during the reboot of ncn-m001.

    1. Get the IP
        ```bash
        pit# ssh ncn-m002 'ip a show vlan007 | grep inet'
        ```
        
        _Expected output (values may differ)_:
        ```
        inet 10.102.11.13/24 brd 10.102.11.255 scope global vlan007
        inet6 fe80::1602:ecff:fed9:7820/64 scope link
        ```
    
    1. Login from another external machine to verify SSH is up and running for this session.
        ```bash
        external# ssh root@10.102.11.13
        ncn-m002#
        ```

    > Keep this terminal active as it will enable `kubectl` commands during the bring-up of the new NCN.
    If the reboot successfully deploys the LiveCD, this terminal can be exited.
    
    > **POINT OF NO RETURN** The next step will wipe the underlying nodes disks clean, it will ignore USB sticks. RemoteISOs are at risk here, even though a backup has been
    > performed of the pit node we can't simply boot back to the same state.
    > This is the last step before rebooting the node.

1. **`IN-PLACE WAR`** This is a WAR until the auto-wipe feature ceases preventing the creation of the 3rd disk (CASMINST-169. This step is safe to do even after auto-wipe is fixed.
   
    > **`WARNING : USER ERROR`** Do not assume to wipe the first three disks (e.g. `sda, sdb, and sdc`), they float and are not pinned to any physical disk layout. **Choosing the wrong ones may result in wiping the USB stick**, the USB stick can only be wiped by operators at this point in the install. The USB sticks are never wiped by the CSM installer.

    1. Select disks to wipe; SATA/NVME/SAS
        > TODO: provide `md_disks` from a callable
        ```bash
        pit# md_disks="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print "/dev/" $2}')"
        ```

    1. Sanity check; print disks into typscript or console
        ```bash
        pit# echo $md_disks
        ```

        Expected output looks similar to the following:
        ```
        /dev/sda /dev/sdb /dev/sdc
        ```

    1. Wipe. **This is irreversible.**
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

        If there was any wiping done, output should appear similar to the snippet above. If this is re-ran, there may be no output or an ignorable error.
    
1. Quit the typescript session with the `exit` command and copy the file (`booted-csm-lived.<date>.txt`) to a location on another server for reference later.
    
    ```bash
    pit# exit
    ```

<a name="reboot"></a>
## Reboot

1. Reboot the LiveCD.
    
    ```bash
    pit# reboot
    ```
    
1. The node should boot, acquire its hostname (i.e. ncn-m001), and run cloud-init.
    
    > **`NOTE`**: If the nodes has pxe boot issues, such as getting pxe errors or not pulling the ipxe.efi binary, see [PXE boot troubleshooting](420-MGMT-NET-PXE-TSHOOT.md)
    
    > **`NOTE`**: If ncn-m001 booted without a hostname or it didn't run all the cloud-init scripts, the following commands need to be run **(but only in that circumstance)**.
    
    1. Make directory to copy network config files to.
        ```bash
        ncn-m001# mkdir /mnt/cow
        ```
    1. Mount the USB to that directory.
        ```bash
        ncn-m001# mount -L cow /mnt/cow
        ```
    1. Copy the network config files.
        ```bash
        ncn-m001# cp -pv /mnt/cow/rw/etc/sysconfig/network/ifroute* /etc/sysconfig/network/
        ncn-m001# cp -pv /mnt/cow/rw/etc/sysconfig/network/ifcfg-lan0 /etc/sysconfig/network/
        ```
    1. Run the `set-dhcp-to-static.sh` script
        ```bash
        ncn-m001# /srv/cray/scripts/metal/set-dhcp-to-static.sh
        ```
        Network connectivity should be restored afterwards; the bond is up.
    1. Run the following commands:
        ```bash
        ncn-m001# cloud-init clean
        ncn-m001# cloud-init init
        ncn-m001# cloud-init modules -m init
        ncn-m001# cloud-init modules -m config
        ncn-m001# cloud-init modules -m final
        ```
    
1. Once cloud-init has completed successfully, login and start a typescript (the IP used here is the one we noted for ncn-m002 in an earlier step).
    
    ```bash
    external# ssh root@10.102.11.13
      ncn-m002# pushd /metal/bootstrap/prep/admin
      ncn-m002# script -af csm-verify.$(date +%Y-%m-%d).txt
      ncn-m002# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
      ncn-m002# ssh ncn-m001
      ```
    
1. If the pre-NCN deployment password change method was **not** used, then the root password on ncn-m001 needs to be changed now.
   Run `passwd` on ncn-m001 and complete the prompts.
    
    ```bash
    ncn-m001# passwd
    ```
    
1. Run `kubectl get nodes` to see the full Kubernetes cluster.
    
    > **`NOTE`** If the new node fails to join the cluster after running other cloud-init items please refer to the `handoff`
    
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

1. Restore and verify the site link. It will be necessary to restore the `ifcfg-lan0` file, and both the
   `ifroute-lan0` and `ifroute-vlan002` file from either manual backup take in step 6 or re-mount the USB and copy it
   from the prep directory to `/etc/sysconfig/network/`.
   
    ```bash
    ncn-m001# SYSTEM_NAME=eniac
    ncn-m001# rsync ncn-m002:/metal/bootstrap/prep/${SYSTEM_NAME}/pit-files/ifcfg-lan0 /etc/sysconfig/network/
    ncn-m001# wicked ifreload lan0
    ncn-m001# wicked ifstatus lan0
    lan0            up
       link:     #32, state up, mtu 1500
       type:     bridge, hwaddr 90:e2:ba:0f:11:c2
       config:   compat:suse:/etc/sysconfig/network/ifcfg-lan0
       leases:   ipv4 static granted
       addr:     ipv4 172.30.53.88/20 [static]
    ```
    
1. Run `ip a` to show our IPs, verify the site link.
    
    ```bash
    ncn-m001# ip a show lan0
    ```
    
1. Run `ip a` to show our VLANs, verify they all have IPs.
    
    ```bash
    ncn-m001# ip a show vlan002
    ncn-m001# ip a show vlan004
    ncn-m001# ip a show vlan007
    ```
    
1. Verify we **do not** have a metal bootstrap IP.
    ```bash
    ncn-m001# rm /etc/zypp/repos.d/* && zypper ms --remote --disable
    ```
    
1. Install the latest documentation and workaround packages. This will require external access. 

    - **Recommended** fetch from Google (if external access is not an option due to the physical site restrictions then look at the next bullet point instead).

        ```bash
        ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm-install/docs-csm-install-latest.noarch.rpm
        ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
        ```

    - **Fallback** option for installations in **`AIRGAP/OFFLINE`**.
    
        ```bash
        ncn-m001# zypper --plus-repo /metal/bootstrap/${CSM_RELEASE}/rpm/cray/csm/ -n --no-gpg-checks in docs-csm-install csm-install-workarounds
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
    
1. Now exit the typescript and relocate the backup over to ncn-m001, thus removing the need to track ncn-m002 as yet-another bootstrapping agent. This is required to facilitate re-installations, since it pulls the preperation data back over to the documented area (ncn-m001).

    ```bash
    ncn-m001# exit
    ncn-m002# exit
    # typescript exited
    ncn-m002# rsync -rltDv -P /metal/bootstrap ncn-m001:/metal/
    ncn-m002# rm -rf /metal/bootstrap
    ncn-m002# exit
    ```
    
    > The next steps require `csi` from the installation media. `csi` will not be provided on an NCN otherwise since it is used for CRAY installation & bootstrap. The CSI binary is compiled against the NCN base, simply fetching it from the bootable media will suffice.
    
1. SSH back into ncn-m001, or restart a local console and resume the typescript
    
    ```bash
    ncn-m001# script -af /metal/bootstrap/prep/admin/csm-verify.$(date +%Y-%m-%d).txt
    ```
    
1. Obtain access to CSI

    ```bash
    ncn-m001# export CSM_RELEASE=csm-x.y.z
    ncn-m001# mkdir -pv /mnt/livecd /mnt/rootfs /mnt/sqfs
    ncn-m001# mount /metal/bootstrap/csm*/cray-pre-install-toolkit-*.iso /mnt/livecd/
    ncn-m001# mount /mnt/livecd/LiveOS/squashfs.img /mnt/sqfs/
    ncn-m001# mount /mnt/sqfs/LiveOS/rootfs.img /mnt/rootfs/
    ncn-m001# cp -pv /mnt/rootfs/usr/bin/csi /tmp/csi
    ncn-m001# /tmp/csi version
    ncn-m001# umount -vl /mnt/sqfs /mnt/rootfs /mnt/livecd
    ```
    
1. Authenticate with the cluster
    
    ```bash
    ncn# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
    -d client_id=admin-client \
    -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```
    
1.  **`IN-PLACE WAR`** Set the wipe safeguard to allow safe net-reboots. **This will set the safeguard on all NCNs**. This is fixed by MTL
    
    ```bash
    ncn# /tmp/csi handoff bss-update-param --set metal.no-wipe=1
    ```
    
> **`CSI NOTE`** `/tmp/csi` will delete itself on the next reboot. The /tmp directory is `tmpfs` and runs in memory, it normally will not persist on restarts.

The administrator can continue onto these next items to conclude the CSM product deployment Next up:

1. [CSM Validation](008-CSM-VALIDATION.md)
1. [NCN/Management Node Locking](009-NCN-LOCKING.md)
1. [Firmware updates with FAS](010-FIRMWARE-UPDATE-WITH-FAS.md)

Once through those, the administrator should install additional products following the procedures in the HPE Cray EX System Installation and Configuration Guide S-8000.

<a name="accessing-usb-partitions-after-reboot"></a>
## Accessing USB Partitions After Reboot

> **`USB ONLY`** If the installation above was done from a [Remote ISO](003-CSM-LIVECD.md)

After deploying the LiveCD's NCN, the LiveCD USB itself is unharmed and available to an administrator.

Mount and view the USB stick:
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

When removing the USB stick, please unmount it first to avoid corruption. This corruption risk is low, but varies if large data use was done to or on the USB.
```bash
ncn-m001# umount /mnt/cow /mnt/pitdata
```
