# Deploy Final NCN

The following procedure contains information for rebooting and deploying the management node that is currently
hosting the LiveCD. At the end of this procedure, the LiveCD will no longer be active. The node it was using will
join the Kubernetes cluster as the final of three master nodes, forming a quorum.

**IMPORTANT:** While the node is rebooting, it will only be available through Serial-Over-LAN (SOL) and local terminals. This
procedure entails deactivating the LiveCD, meaning the LiveCD and all of its resources will be unavailable.

1. [Required services](#1-required-services)
1. [Notice of danger](#2-notice-of-danger)
1. [Hand-off](#3-hand-off)
1. [Reboot](#4-reboot)
1. [Enable NCN disk wiping safeguard](#5-enable-ncn-disk-wiping-safeguard)
1. [Clean up `chrony` configurations](#6-clean-up-chrony-configurations)
1. [<s>Configure DNS and NTP on each BMC](#7-configure-dns-and-ntp-on-each-bmc)</s>
1. [Next topic](#8-next-topic)

<a name="required-services"></a>

## 1. Required services

These services must be healthy before the reboot of the LiveCD can take place. If the health checks performed earlier in the install
completed successfully \([Validate CSM Health](../operations/validate_csm_health.md)\), then the following platform services will be healthy
and ready for reboot of the LiveCD:

* Utility Storage (Ceph)
* `cray-bss`
* `cray-dhcp-kea`
* `cray-dns-unbound`
* `cray-ipxe`
* `cray-sls`
* `cray-tftp`

check all services listed above. Example - 
```bash
pit# kubectl get pods -A|grep cray-bss
services            cray-bss-7f9f89fd98-jtghx                                         2/2     Running     0          22h
services            cray-bss-7f9f89fd98-nsbhm                                         2/2     Running     0          22h
services            cray-bss-7f9f89fd98-sf7xp                                         2/2     Running     0          22h
services            cray-bss-etcd-2266jchlzq                                          1/1     Running     0          22h
services            cray-bss-etcd-dnxnn8hpwb                                          1/1     Running     0          22h
services            cray-bss-etcd-vvtkvkhhmv                                          1/1     Running     0          22h
services            cray-bss-wait-for-etcd-1-fm7cn                                    0/1     Completed   0          22h

```

<a name="notice-of-danger"></a>

## 2. Notice of danger

> An administrator is **strongly encouraged** to be mindful of pitfalls during this segment of the CSM install.
> The steps below do contain warnings themselves, but overall there are risks:
>
> * SSH will cease to work when the LiveCD reboots; the serial console will need to be used.
> * Rebooting a remote ISO will dump all running changes on the PIT node; USB devices are accessible after the install.
> * The NCN **will never wipe a USB device** during installation.
> * Prior to shutting down the PIT node, learning the CMN IP addresses of the other NCNs will be helpful if
>   troubleshooting is required.
>
> This procedure entails deactivating the LiveCD, meaning the LiveCD and all of its resources will be **unavailable**.

<a name="hand-off"></a>

## 3. Hand-off

The steps in this section load hand-off data before a later procedure reboots the LiveCD node.

<a name="start-hand-off"></a>

1. Start a new typescript.

    1. Exit the current typescript, if one is active.

        ```bash
        pit# exit
        ```

    1. Start a new typescript on the PIT node.

        ```bash
        pit# mkdir -pv /var/www/ephemeral/prep/admin &&
             pushd /var/www/ephemeral/prep/admin &&
             script -af csm-livecd-reboot.$(date +%Y-%m-%d).txt
        pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
        ```

1. Upload SLS file.

    > **NOTE:** The environment variable `SYSTEM_NAME` must be set.

    ```bash
    pit# csi upload-sls-file --sls-file /var/www/ephemeral/prep/${SYSTEM_NAME}/sls_input_file.json
    ```

    Expected output looks similar to the following:

    ```text
    2021/02/02 14:05:15 Retrieving S3 credentials ( sls-s3-credentials ) for SLS
    2021/02/02 14:05:15 Uploading SLS file: /var/www/ephemeral/prep/eniac/sls_input_file.json
    2021/02/02 14:05:15 Successfully uploaded SLS Input File.
    ```

1. Get a token to use for authenticated communication with the gateway.

    > **NOTE:** `api-gw-service-nmn.local` is legacy, and will be replaced with `api-gw-service.nmn`.

    ```bash
    pit# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. Validate that `CSM_RELEASE` and `CSM_PATH` variables are set.

    These variables were set and added to `/etc/environment` during the earlier [Bootstrap PIT Node](index.md#bootstrap_pit_node) step of the install.
    `CSM_PATH` should be the fully-qualified path to the expanded CSM release tarball on the PIT node.

    ```bash
    pit# echo "CSM_RELEASE=${CSM_RELEASE} CSM_PATH=${CSM_PATH}"
    ```
    Expected Output - 
    ```bash
    CSM_RELEASE=csm-1.2.0 CSM_PATH=/var/www/ephemeral/csm-1.2.0
    ```


1. <a name="ncn-boot-artifacts-hand-off"></a>Upload NCN boot artifacts into S3.

    1. Run the following command.

        ```bash
        pit# artdir=/var/www/ephemeral/data && 
             k8sdir=$artdir/k8s &&
             cephdir=$artdir/ceph &&
             csi handoff ncn-images \
                --k8s-kernel-path $k8sdir/*.kernel \
                --k8s-initrd-path $k8sdir/initrd.img*.xz \
                --k8s-squashfs-path $k8sdir/secure-*.squashfs \
                --ceph-kernel-path $cephdir/*.kernel \
                --ceph-initrd-path $cephdir/initrd.img*.xz \
                --ceph-squashfs-path $cephdir/secure-*.squashfs
        ```
        Expected Output - 
        ```text
        Uploading NCN images into S3.
        Successfully created ncn-images bucket.
        Uploading file /var/www/ephemeral/data/k8s/5.3.18-150300.59.43-default-0.2.89.kernel to S3 at s3://ncn-images/k8s/0.2.89/kernel...
        Successfully uploaded K8s kernel.
        Uploading file /var/www/ephemeral/data/k8s/initrd.img-0.2.89.xz to S3 at s3://ncn-images/k8s/0.2.89/initrd...
        Successfully uploaded K8s initrd.
        Uploading file /var/www/ephemeral/data/k8s/secure-kubernetes-0.2.89.squashfs to S3 at s3://ncn-images/k8s/0.2.89/filesystem.squashfs...
        Successfully uploaded K8s squash FS.
        Uploading file /var/www/ephemeral/data/ceph/5.3.18-150300.59.43-default-0.2.89.kernel to S3 at s3://ncn-images/ceph/0.2.89/kernel...
        Successfully uploaded CEPH kernel.
        Uploading file /var/www/ephemeral/data/ceph/initrd.img-0.2.89.xz to S3 at s3://ncn-images/ceph/0.2.89/initrd...
        Successfully uploaded CEPH initrd.
        Uploading file /var/www/ephemeral/data/ceph/secure-storage-ceph-0.2.89.squashfs to S3 at s3://ncn-images/ceph/0.2.89/filesystem.squashfs...
        Successfully uploaded CEPH squash FS
        Image versions uploaded:
        Kubernetes:     0.2.89
        CEPH:           0.2.89
        ```

        The end of the command output contains a block similar to this:

        ```text
        Run the following commands so that the versions of the images that were just uploaded can be used in other steps:
        export KUBERNETES_VERSION=x.y.z
        export CEPH_VERSION=x.y.z
        ```

    1. Run the `export` commands listed at the end of the output from the previous step.

1. <a name="csi-handoff-bss-metadata"></a>Upload the `data.json` file to BSS, our `cloud-init` data source.

    **If any changes have been made** to this file (for example, as a result of any customizations or workarounds), then use the path to the
    modified file instead.

    > This step will prompt for the root password of the NCNs.

    ```bash
    pit# csi handoff bss-metadata --data-file /var/www/ephemeral/configs/data.json || echo "ERROR: csi handoff bss-metadata failed"
    ```
    Expected Output - 
    ```text
    2022/09/08 05:05:02 Getting management NCNs from SLS...
    2022/09/08 05:05:02 Done getting management NCNs from SLS.
    2022/09/08 05:05:02 Building BSS metadata for NCNs...
    Enter root password for NCNs:
    2022/09/08 05:05:09 Connecting to ncn-s002...
    2022/09/08 05:05:09 Creating session to 10.252.1.8:22...
    2022/09/08 05:05:09 Creating session to 10.252.1.8:22...
    2022/09/08 05:05:09 Creating session to 10.252.1.8:22...
    2022/09/08 05:05:09 Creating session to 10.252.1.8:22...
    2022/09/08 05:05:09 Successfully POST EthernetInterfaces entry for x3000c0s15b0n0:
    {
            "ID": "b8599f1dd7f2",
            "Description": "Bond0 - bond0.nmn0",
            "MACAddress": "b8599f1dd7f2",
            "IPAddress": "10.252.1.8",
            "LastUpdate": "",
            "ComponentID": "x3000c0s15b0n0",
            "Type": "Node"
    }
    2022/09/08 05:05:19 Successfully PATCH EthernetInterfaces entry for x3000c0s7b0n0:
    {
            "ID": "98039bb42763",
            "Description": "Ethernet Interface Lan3",
            "MACAddress": "98:03:9b:b4:27:63",
            "IPAddress": "",
            "LastUpdate": "2022-09-07T06:29:57.092069Z",
            "ComponentID": "x3000c0s7b0n0",
            "Type": "Node"
    }
    <snip>
    2022/09/08 05:05:19 Done building BSS metadata for NCNs.
    2022/09/08 05:05:19 Transferring global cloud-init metadata to BSS...
    2022/09/08 05:05:19 Successfully PUT BSS entry for Global
    2022/09/08 05:05:19 Done transferring global cloud-init metadata to BSS.

    ```

1. Patch the metadata for the Ceph nodes to have the correct run commands.

    ```bash
    pit# python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
    ```
    Expected Output - 
    ```text
    BSS entry for x3000c0s13b0n0/ncn-s001 patched.
    BSS entry for x3000c0s15b0n0/ncn-s002 patched.
    BSS entry for x3000c0s17b0n0/ncn-s003 patched.
    ```

1. Ensure that the DNS server value is correctly set to point toward Unbound at `10.92.100.225` (NMN) and `10.94.100.225` (HMN).

    ```bash
    pit# csi handoff bss-update-cloud-init --set meta-data.dns-server="10.92.100.225 10.94.100.225" --limit Global
    ```
    Expected Output - 
    ```text
    2022/09/08 05:07:52 Getting management NCNs from SLS...
    2022/09/08 05:07:52 Done getting management NCNs from SLS.
    2022/09/08 05:07:52 Updating NCN cloud-init parameters...
    2022/09/08 05:07:52 Successfully PUT BSS entry for Global
    2022/09/08 05:07:52 Done updating NCN cloud-init parameters.

    ```
1. Preserve logs and configuration files if desired (optional).

    After the PIT node is redeployed, **all files on its local drives will be lost**. It is recommended to retain some of the log files and
    configuration files, because they may be useful if issues are encountered during the remainder of the install.

    The following commands create a `tar` archive of these files, storing it in a directory that will be backed up in the next step.

    ```bash
    pit# mkdir -pv /var/www/ephemeral/prep/logs &&
         ls -d \
                    /etc/dnsmasq.d \
                    /etc/os-release \
                    /etc/sysconfig/network \
                    /opt/cray/tests/cmsdev.log \
                    /opt/cray/tests/install/logs \
                    /opt/cray/tests/logs \
                    /root/.canu \
                    /root/.config/cray/logs \
                    /root/csm*.{log,txt} \
                    /tmp/*.log \
                    /usr/share/doc/csm/install/scripts/csm_services/yapl.log \
                    /var/log/conman \
                    /var/log/zypper.log 2>/dev/null |
         sed 's_^/__' |
         xargs tar -C / -czvf /var/www/ephemeral/prep/logs/pit-backup-$(date +%Y-%m-%d_%H-%M-%S).tgz
    ```

1. <a name="backup-bootstrap-information"></a>Backup the bootstrap information from `ncn-m001`.

    > **NOTE:** This preserves information that should always be kept together in order to fresh-install the system again.

    1. Log in and set up passwordless SSH **to** the PIT node.

        Copying **only** the public keys from `ncn-m002` and `ncn-m003` to the PIT node. **Do not** set up
        passwordless SSH **from** the PIT node or the key will have to be securely tracked or expunged if using a USB installation).

        > The `ssh` commands below may prompt for the NCN root password.

        ```bash
        pit# ssh ncn-m002 cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys &&
             ssh ncn-m003 cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys &&
             chmod 600 /root/.ssh/authorized_keys
        ```

    1. Back up files from the PIT to `ncn-m002`.

        ```bash
        pit# ssh ncn-m002 \
            "mkdir -pv /metal/bootstrap
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:/var/www/ephemeral/prep /metal/bootstrap/
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:${CSM_PATH}/cray-pre-install-toolkit*.iso /metal/bootstrap/"
        ```

    1. Back up files from the PIT to `ncn-m003`.

        ```bash
        pit# ssh ncn-m003 \
            "mkdir -pv /metal/bootstrap
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:/var/www/ephemeral/prep /metal/bootstrap/
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:${CSM_PATH}/cray-pre-install-toolkit*.iso /metal/bootstrap/"
        ```

1. Set the PIT node to PXE boot.

    1. List IPv4 boot options using `efibootmgr`.

        ```bash
        pit# efibootmgr | grep -Ei "ip(v4|4)"
        ```
        Expected Output  - 
        ```text
        Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4E
        Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4F
        Boot000D* UEFI: HTTP IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4E
        Boot000E* UEFI: HTTP IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4F
        Boot000F* UEFI: HTTP IP4 Intel(R) I350 Gigabit Network Connection
        Boot0010* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
        Boot0011* UEFI: HTTP IP4 Intel(R) I350 Gigabit Network Connection
        Boot0012* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
        ```

    1. Set and trim the boot order on the PIT node.

        This only needs to be done for the PIT node, not for any of the other NCNs. See
        [Setting boot order](../background/ncn_boot_workflow.md#setting-order) and
        [Trimming boot order](../background/ncn_boot_workflow.md#trimming_boot_order).

    1. Tell the PIT node to PXE boot on the next boot.

        Use `efibootmgr` to set the next boot device to the first PXE boot option. This step assumes the boot order was set up in the previous step.

        ```bash
        pit# efibootmgr -n $(efibootmgr | grep -Ei "ip(v4|4)" | awk '{print $1}' | head -n 1 | tr -d Boot*) | grep -i bootnext
        BootNext: 0014
        ```
        BootNext: 0007

1. <a name="collect-can-ip-ncn-m002"></a>Collect a backdoor login. Fetch the CMN IP address for `ncn-m002` for a backdoor during the reboot of `ncn-m001`.

    1. Get the IP address.

        ```bash
        pit# ssh ncn-m002 'ip a show bond0.cmn0 | grep inet'
        ```

        Expected output will look similar to the following (exact values may differ):

        ```text
        inet 10.102.11.13/24 brd 10.102.11.255 scope global bond0.cmn0
        inet6 fe80::1602:ecff:fed9:7820/64 scope link
        ```

    1. Log in from another external machine to verify SSH is up and running for this session.

        ```bash
        external# ssh root@10.102.11.13
        ncn-m002#
        ```

        > Keep this terminal active as it will enable `kubectl` commands during the bring-up of the new NCN.
        > If the reboot successfully deploys the LiveCD, then this terminal can be exited.
        >
        > **POINT OF NO RETURN:** The next step will wipe the underlying nodes disks clean. It will ignore USB devices.
        > RemoteISOs are at risk here; even though a backup has been performed of the PIT node, it is not possible to
        > boot back to the same state. This is the last step before rebooting the node.

1. Wipe the disks on the PIT node.

    > **WARNING:** Risk of **USER ERROR**! Do not assume to wipe the first three disks (for example, `sda`, `sdb`, and `sdc`);
    > they are not pinned to any physical disk layout. **Choosing the wrong ones may result in wiping the USB device**. USB devices can
    > only be wiped by operators at this point in the install. USB devices are never wiped by the CSM installer.

    1. Select disks to wipe (SATA/NVME/SAS).

        ```bash
        pit# md_disks="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print "/dev/" $2}')"
        ```

    1. Run a sanity check by printing disks into typescript or console.

        ```bash
        pit# echo $md_disks
        ```

        Expected output looks similar to the following:

        ```text
        /dev/sda /dev/sdb /dev/sdc
        ```

    1. Wipe. **This is irreversible.**

        ```bash
        pit# wipefs --all --force $md_disks
        ```

        If any disks had labels present, output looks similar to the following:

        ```text
        /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
        /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
        /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
        /dev/sdb: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
        /dev/sdb: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
        /dev/sdc: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
        /dev/sdc: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
        /dev/sdc: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
        ```

        If there was any wiping done, output should appear similar to the output above. If this is re-run, there may be no output or an ignorable error.

1. Quit the typescript session and copy the typescript file off of `ncn-m001`.

    1. Stop the typescript session:

        ```bash
        pit# exit
        ```

    1. Back up the completed typescript file by re-running the `rsync` commands in the [Backup Bootstrap Information](#backup-bootstrap-information) section.

1. (Optional) Setup ConMan or serial console, if not already on, from any laptop or other system with network connectivity to the cluster.

    ```bash
    external# script -a boot.livecd.$(date +%Y-%m-%d).txt
    external# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    external# SYSTEM_NAME=eniac
    external# USERNAME=root
    external# export IPMI_PASSWORD=changeme
    external# ipmitool -I lanplus -U $USERNAME -E -H ${SYSTEM_NAME}-ncn-m001-mgmt chassis power status
    external# ipmitool -I lanplus -U $USERNAME -E -H ${SYSTEM_NAME}-ncn-m001-mgmt sol activate
    ```

<a name="reboot"></a>

## 4. Reboot

1. Reboot the LiveCD.

    ```bash
    pit# reboot
    ```

1. Wait for the node to boot, acquire its hostname (`ncn-m001`), and run `cloud-init`.

    If all of that happens successfully, then **skip the rest of this step and proceed to the next step**. Otherwise, use the following information to remediate the problems.

    > **NOTES:**
    >
    > * If the node has PXE boot issues, such as getting PXE errors or not pulling the `ipxe.efi` binary, see [PXE boot troubleshooting](pxe_boot_troubleshooting.md).
    > * If `ncn-m001` did not run all the `cloud-init` scripts, then the following commands need to be run **(but only in that circumstance)**.

    ```bash
    ncn-m001# cloud-init clean ; cloud-init init ; cloud-init modules -m init ; \
              cloud-init modules -m config ; cloud-init modules -m final
    ```

1. Once `cloud-init` has completed successfully ( var/log/messages) -
    ```bash 
    2022-09-08T05:54:15.934854+00:00 ncn cloud-init[11265]: Cloud-init v. 21.4-1 running 'modules:final' at Thu, 08 Sep 2022 05:49:58 +0000. Up 100.60 seconds.
    2022-09-08T05:54:15.934954+00:00 ncn cloud-init[11265]: The system is finally up, after 356.90 seconds cloud-init has come to completion.
    ```


    log in and start a typescript (the IP address used here is the one noted for `ncn-m002` in an earlier step).

    ```bash
    external# ssh root@10.102.11.13

    ncn-m002# pushd /metal/bootstrap/prep/admin
    ncn-m002# script -af csm-verify.$(date +%Y-%m-%d).txt
    ncn-m002# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ncn-m002# ssh ncn-m001
    ```

1. Run `kubectl get nodes` to see the full Kubernetes cluster.

    ```bash
    ncn-m001# kubectl get nodes
    ```

    Expected output looks similar to the following:

    ```text
    NAME       STATUS   ROLES                  AGE   VERSION
    ncn-m001   Ready    control-plane,master   27s   v1.20.13
    ncn-m002   Ready    control-plane,master   4h    v1.20.13
    ncn-m003   Ready    control-plane,master   4h    v1.20.13
    ncn-w001   Ready    <none>                 4h    v1.20.13
    ncn-w002   Ready    <none>                 4h    v1.20.13
    ncn-w003   Ready    <none>                 4h    v1.20.13
    ```

1. Restore and verify the site link.

    Restore networking files from the manual backup taken during the
    [Backup the bootstrap information](#backup-bootstrap-information) step.

    ```bash
    ncn-m001# SYSTEM_NAME=eniac
    ncn-m001# rsync ncn-m002:/metal/bootstrap/prep/${SYSTEM_NAME}/pit-files/ifcfg-lan0 /etc/sysconfig/network/ && \
              wicked ifreload lan0 && \
              wicked ifstatus lan0
    ```
    Expected Output - 
    ```text
     em1             enslaved
     lan0            up
     lan0            up
      link:     #27, state up, mtu 1500
      type:     bridge, hwaddr b4:2e:99:3b:70:6a
      config:   compat:suse:/etc/sysconfig/network/ifcfg-lan0
      leases:   ipv4 static granted
      addr:     ipv4 172.30.52.177/20 [static]

    ```

    <s>Expected output looks similar to:

    ```text
    lan0            up
       link:     #32, state up, mtu 1500
       type:     bridge, hwaddr 90:e2:ba:0f:11:c2
       config:   compat:suse:/etc/sysconfig/network/ifcfg-lan0
       leases:   ipv4 static granted
       addr:     ipv4 172.30.53.88/20 [static]
    ```
    </s>

1. Verify that the site link (`lan0`) and the VLANs have IP addresses.

    > Examine the output to ensure that each interface has been assigned an IPv4 address.

    ```bash
    ncn-m001# for INT in lan0 bond0.nmn0 bond0.hmn0 bond0.can0 bond0.cmn0 ; do
                ip a show $INT || echo "ERROR: Command failed: ip a show $INT"
              done
    ```
    Expected Output - 
    ```
    lan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b4:2e:99:3b:70:6a brd ff:ff:ff:ff:ff:ff
    inet 172.30.52.177/20 brd 172.30.63.255 scope global lan0
       valid_lft forever preferred_lft forever
    inet6 fe80::b62e:99ff:fe3b:706a/64 scope link
       valid_lft forever preferred_lft forever
    <snip>
    8: bond0.cmn0@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc noqueue state UP group default qlen 1000
    link/ether b8:59:9f:1d:d8:4e brd ff:ff:ff:ff:ff:ff
    inet 10.102.5.19/25 brd 10.102.5.127 scope global bond0.cmn0
       valid_lft forever preferred_lft forever
    inet6 fe80::ba59:9fff:fe1d:d84e/64 scope link
       valid_lft forever preferred_lft forever

    ```

1. Verify that the default route is via the CMN.

    ```bash
    ncn-m001# ip r show default
    ```
    Expected Output - 
    ```
    default via 10.102.5.1 dev bond0.cmn0
    ```

1. Verify that there **is not** a metal bootstrap IP address.

    ```bash
    ncn-m001# ip a show bond0
    ```

1. Verify `zypper` repositories are empty and all remote SUSE repositories are disabled.

    > If the `rm` command fails because the files do not exist, this is not an error and should be ignored.

    ```bash
    ncn-m001# rm -v /etc/zypp/repos.d/* && zypper ms --remote --disable
    ```

1. Download and install/upgrade the documentation RPM.

    See [Check for Latest Documentation](../update_product_stream/index.md#documentation)

1. Exit the typescript and move the backup to `ncn-m001`.

    This is required to facilitate reinstallations, because it pulls the preparation data back over to the documented area (`ncn-m001`).

    ```console
    ncn-m001# exit
    ncn-m002# exit
    # typescript exited
    ncn-m002# rsync -rltDv -P /metal/bootstrap ncn-m001:/metal/ && rm -rfv /metal/bootstrap
    ncn-m002# exit
    ```

1. SSH back into `ncn-m001` or restart a local console.

1. Resume the typescript.

    ```bash
    ncn-m001# script -af /metal/bootstrap/prep/admin/csm-verify.$(date +%Y-%m-%d).txt
    ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

1. Apply the `kdump` workaround.

    `kdump` assists in taking a dump of the NCN if it encounters a kernel panic.
    `kdump` does not work properly in CSM 1.2. Until this workaround is applied, `kdump` may not produce a proper dump.
    Earlier in the install, this workaround was applied to all of the NCNs except for `ncn-m001`, because it was the PIT
    node. Running it now applies the fix to `ncn-m001` as well.

    ```bash
    ncn-m001# /usr/share/doc/csm/scripts/workarounds/kdump/run.sh
    ```

    Example output:

    ```text
    Uploading hotfix files to ncn-m001:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-m002:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-m003:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-s001:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-s002:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-s003:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-s004:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-w001:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-w002:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-w003:/srv/cray/scripts/common/ ... Done
    Uploading hotfix files to ncn-w004:/srv/cray/scripts/common/ ... Done
    Running updated create-kdump-artifacts.sh script on [11] NCNs ... Done
    The following NCNs contain the kdump patch:
    ncn-m001
    ncn-m002
    ncn-m003
    ncn-s001
    ncn-s002
    ncn-s003
    ncn-s004
    ncn-w001
    ncn-w002
    ncn-w003
    ncn-w004
    This workaround has completed.
    ```

<a name="enable-ncn-disk-wiping-safeguard"></a>

## 5. Enable NCN disk wiping safeguard

The next steps require `csi` from the installation media. `csi` will not be provided on an NCN otherwise because
it is used for Cray installation and bootstrap.

1. Obtain access to CSI.

    ```bash
    ncn-m001# mkdir -pv /mnt/livecd /mnt/rootfs /mnt/sqfs && \
              mount -v /metal/bootstrap/cray-pre-install-toolkit-*.iso /mnt/livecd/ && \
              mount -v /mnt/livecd/LiveOS/squashfs.img /mnt/sqfs/ && \
              mount -v /mnt/sqfs/LiveOS/rootfs.img /mnt/rootfs/ && \
              cp -pv /mnt/rootfs/usr/bin/csi /tmp/csi && \
              /tmp/csi version && \
              umount -vl /mnt/sqfs /mnt/rootfs /mnt/livecd
    ```

    > **NOTE** `/tmp/csi` will delete itself on the next reboot. The `/tmp` directory is `tmpfs` and runs in memory;
    > it will not persist on restarts.

1. Authenticate with the cluster.

    ```bash
    ncn-m001# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                -d client_id=admin-client \
                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. Set the wipe safeguard to allow safe reboots on all NCNs.

    ```bash
    ncn-m001# /tmp/csi handoff bss-update-param --set metal.no-wipe=1
    ```

<a name="remove-the-default-ntp-pool"></a>

## 6. Clean up `chrony` configurations

This step requires the exported `TOKEN` variable from the previous section: [Enable NCN disk wiping safeguard](#enable-ncn-disk-wiping-safeguard).
If still using the same shell session, there is no need to export it again.

```bash
ncn-m001# /srv/cray/scripts/common/chrony/csm_ntp.py
```

Successful output can appear as:

```text
...
BSS query failed. Checking local cache...
Chrony configuration created
Problematic config found: /etc/chrony.d/cray.conf.dist
Problematic config found: /etc/chrony.d/pool.conf
Restarted chronyd
...
```

or

```text
...
Chrony configuration created
Restarted chronyd
...
```

<a name="configure-dns-and-ntp-on-each-bmc"></a>

## 7. <s>Configure DNS and NTP on each BMC

 > **NOTE:** Only follow this section if the NCNs are HPE hardware. If the system uses
 > Gigabyte or Intel hardware, skip this section.

Configure DNS and NTP on the BMC for each management node **except `ncn-m001`**.
However, the commands in this section are all run **on** `ncn-m001`.

1. Validate that the system is HPE hardware.

    ```bash
    ncn-m001# ipmitool mc info | grep "Hewlett Packard Enterprise" || echo "Not HPE hardware -- SKIP these steps"
    ```

1. Set environment variables.

    Set the `IPMI_PASSWORD` and `USERNAME` variables to the BMC credentials for the NCNs.

    > Using `read -s` for this prevents the credentials from being echoed to the screen or saved in the shell history.

    ```bash
    ncn-m001# read -s IPMI_PASSWORD
    ncn-m001# read -s USERNAME
    ncn-m001# export IPMI_PASSWORD USERNAME
    ```

1. Set `BMCS` variable to list of the BMCs for all master, worker, and storage nodes,
   except `ncn-m001-mgmt`:

    ```bash
    ncn-m001# BMCS=$(grep -Eo "[[:space:]]ncn-[msw][0-9][0-9][0-9]-mgmt([.]|[[:space:]]|$)" /etc/hosts |
                        sed 's/^.*\(ncn-[msw][0-9][0-9][0-9]-mgmt\).*$/\1/' |
                        sort -u |
                        grep -v "^ncn-m001-mgmt$") ; echo $BMCS
    ```

    Expected output looks similar to the following:

    ```text
    ncn-m002-mgmt ncn-m003-mgmt ncn-s001-mgmt ncn-s002-mgmt ncn-s003-mgmt ncn-w001-mgmt ncn-w002-mgmt ncn-w003-mgmt
    ```

1. Get the DNS server IP address for the NMN.

    ```bash
    ncn-m001# NMN_DNS=$(kubectl get services -n services -o wide | grep cray-dns-unbound-udp-nmn | awk '{ print $4 }'); echo $NMN_DNS
    ```

    Example output:

    ```text
    10.92.100.225
    ```

1. Get the DNS server IP address for the HMN.

    ```bash
    ncn-m001# HMN_DNS=$(kubectl get services -n services -o wide | grep cray-dns-unbound-udp-hmn | awk '{ print $4 }'); echo $HMN_DNS
    ```

    Example output:

    ```text
    10.94.100.225
    ```

1. Run the following to loop through all of the BMCs (except `ncn-m001-mgmt`) and apply the desired settings.

    ```bash
    ncn-m001# for BMC in $BMCS ; do
                echo "$BMC: Disabling DHCP and configure NTP on the BMC using data from unbound service"
                /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H $BMC -S -n
                echo
                echo "$BMC: Configuring DNS on the BMC using data from unbound"
                /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H $BMC -D $NMN_DNS,$HMN_DNS -d
                echo
                echo "$BMC: Showing settings"
                /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H $BMC -s
                echo
              done ; echo "Configuration completed on all NCN BMCs"
    ```
    </s>

<a name="next-topic"></a>

## 8. Next topic

After completing this procedure, proceed to [Configure Administrative Access](index.md#configure_administrative_access).
