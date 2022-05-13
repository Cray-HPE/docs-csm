# Redeploy PIT Node

The following procedure contains information for rebooting and deploying the management node that is currently
hosting the LiveCD. At the end of this procedure, the LiveCD will no longer be active. The node it was using will
join the Kubernetes cluster as the final of three master nodes, forming a quorum.

**IMPORTANT:** While the node is rebooting, it will only be available through Serial-Over-LAN (SOL) and local terminals. This
procedure entails deactivating the LiveCD, meaning the LiveCD and all of its resources will be unavailable.

1. [Required services](#required-services)
2. [Notice of danger](#notice-of-danger)
3. [Hand-off](#hand-off)
4. [Reboot](#reboot)
5. [Enable NCN disk wiping safeguard](#enable-ncn-disk-wiping-safeguard)
6. [Fix NTP on `ncn-m001`](#fix-ntp-config-on-ncn-m001)
7. [Remove the default NTP pool](#remove-the-default-ntp-pool)
8. [Configure DNS and NTP on each BMC](#configure-dns-and-ntp-on-each-bmc)
9. [Validate `BOOTRAID` artifacts](#validate-bootraid-artifacts)
10. [Next topic](#next-topic)

<a name="required-services"></a>

## 1. Required services

These services must be healthy before the reboot of the LiveCD can take place. If the health checks performed earlier in the install
completed successfully \([Validate CSM Health](../operations/validate_csm_health.md)\), the following platform services will be healthy
and ready for reboot of the LiveCD:

* Utility Storage (Ceph)
* `cray-bss`
* `cray-dhcp-kea`
* `cray-dns-unbound`
* `cray-ipxe`
* `cray-sls`
* `cray-tftp`

<a name="notice-of-danger"></a>

## 2. Notice of danger

> An administrator is **strongly encouraged** to be mindful of pitfalls during this segment of the CSM install.
> The steps below do contain warnings themselves, but overall there are risks:
>
> * SSH will cease to work when the LiveCD reboots; the serial console will need to be used.
>
> * Rebooting a remote ISO will dump all running changes on the PIT node; USB devices are accessible after the install.
>
> * The NCN **will never wipe a USB device** during installation.
>
> * Prior to shutting down the PIT node, learning the CAN IP addresses of the other NCNs will be helpful if
>   troubleshooting is required.
>
> This procedure entails deactivating the LiveCD, meaning the LiveCD and all of its resources will be
> **unavailable**.

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

1. Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `livecd-pre-reboot` breakpoint.

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

1. <a name="ncn-boot-artifacts-hand-off"></a>Upload NCN boot artifacts into S3.

    1. Set variables.

        **IMPORTANT**: The variables set depend on whether or not the default NCN images are customized. The most
        common procedures that involve customizing the images are
        [Configuring NCN Images to Use Local Timezone](../operations/node_management/Configure_NTP_on_NCNs.md#configure_ncn_images_to_use_local_timezone) and
        [Changing NCN Image Root Password and SSH Keys on PIT Node](../operations/security_and_authentication/Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md).
        The two paths forward are listed below:

        * If the NCN images were customized, set the following variables:

            ```bash
            pit# artdir=/var/www/ephemeral/data
            pit# k8sdir=$artdir/k8s
            pit# cephdir=$artdir/ceph
            ```

        * If the NCN images were **not** customized, set the following variables:

            ```bash
            pit# CSM_RELEASE=csm-x.y.z
            pit# artdir=/var/www/ephemeral/${CSM_RELEASE}/images
            pit# k8sdir=$artdir/kubernetes
            pit# cephdir=$artdir/storage-ceph
            ```

    1. After setting the variables in the previous step, run the following command.

        ```bash
        pit# csi handoff ncn-images \
                --k8s-kernel-path $k8sdir/*.kernel \
                --k8s-initrd-path $k8sdir/initrd.img*.xz \
                --k8s-squashfs-path $k8sdir/*.squashfs \
                --ceph-kernel-path $cephdir/*.kernel \
                --ceph-initrd-path $cephdir/initrd.img*.xz \
                --ceph-squashfs-path $cephdir/*.squashfs
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

1. Patch the metadata for the Ceph nodes to have the correct run commands.

    ```bash
    pit# python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
    ```

1. Ensure that the DNS server value is correctly set to point toward Unbound at `10.92.100.225`.

    ```bash
    pit# csi handoff bss-update-cloud-init --set meta-data.dns-server=10.92.100.225 --limit Global
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
                    /var/log/conman \
                    /var/log/zypper.log 2>/dev/null |
         sed 's_^/__' |
         xargs tar -C / -czvf /var/www/ephemeral/prep/logs/pit-backup-$(date +%Y-%m-%d_%H-%M-%S).tgz
    ```

1. Upload the bootstrap information.

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
        pit# CSM_RELEASE=$(basename $(ls -d /var/www/ephemeral/csm*/ | head -n 1))
        pit# CSM_PATH=/var/www/ephemeral/${CSM_RELEASE}
        pit# echo "${CSM_PATH}"
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

1. List IPv4 boot options using `efibootmgr`.

    ```bash
    pit# efibootmgr | grep -Ei "ip(v4|4)"
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

1. <a name="collect-can-ip-ncn-m002"></a>Collect a backdoor login. Fetch the CAN IP address for `ncn-m002` for a backdoor during the reboot of `ncn-m001`.

    1. Get the IP address.

        ```bash
        pit# ssh ncn-m002 'ip a show vlan007 | grep inet'
        ```

        _Expected output will look similar to the following (exact values may differ)_:

        ```text
        inet 10.102.11.13/24 brd 10.102.11.255 scope global vlan007
        inet6 fe80::1602:ecff:fed9:7820/64 scope link
        ```

    1. Log in from another external machine to verify SSH is up and running for this session.

        ```bash
        external# ssh root@10.102.11.13
        ncn-m002#
        ```

        > Keep this terminal active as it will enable `kubectl` commands during the bring-up of the new NCN.
        > If the reboot successfully deploys the LiveCD, this terminal can be exited.
        >
        > **POINT OF NO RETURN:** The next step will wipe the underlying nodes disks clean, it will ignore USB devices.
        > RemoteISOs are at risk here; even though a backup has been performed of the PIT node, it is not possible to
        > boot back to the same state. This is the last step before rebooting the node.

1. Wipe the disks on the PIT node.

    > **WARNING:** Risk of **USER ERROR**! Do not assume to wipe the first three disks (e.g. `sda`, `sdb`, and `sdc`); they are not
    > pinned to any physical disk layout. **Choosing the wrong ones may result in wiping the USB device**. USB devices can
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

1. Wait for the node to boot, acquire its hostname (i.e. `ncn-m001`), and run `cloud-init`.

    If all of that happens successfully, **skip the rest of this step and proceed to the next step**. Otherwise, use the following information to remediate the problems.

    > **NOTE:** If the node has PXE boot issues, such as getting PXE errors or not pulling the `ipxe.efi` binary, see [PXE boot troubleshooting](pxe_boot_troubleshooting.md).
    >
    > **NOTE:** If `ncn-m001` did not run all the `cloud-init` scripts, the following commands need to be run **(but only in that circumstance)**.

    ```bash
    ncn-m001# cloud-init clean ; cloud-init init ; cloud-init modules -m init ; \
              cloud-init modules -m config ; cloud-init modules -m final
    ```

1. Once `cloud-init` has completed successfully, log in and start a typescript (the IP address used here is the one noted for `ncn-m002` in an earlier step).

    ```bash
    external# ssh root@10.102.11.13

    ncn-m002# pushd /metal/bootstrap/prep/admin
    ncn-m002# script -af csm-verify.$(date +%Y-%m-%d).txt
    ncn-m002# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ncn-m002# ssh ncn-m001
    ```

1. Change the root password on `ncn-m001` if the pre-NCN deployment password change method was **not** used.

   Run `passwd` on `ncn-m001` and complete the prompts.

    ```bash
    ncn-m001# passwd
    ```

1. Run `kubectl get nodes` to see the full Kubernetes cluster.

    > **NOTE:** If the new node fails to join the cluster after running other `cloud-init` items, then refer to the `handoff`.

    ```bash
    ncn-m001# kubectl get nodes
    ```

    Expected output looks similar to the following:

    ```text
    NAME       STATUS   ROLES    AGE     VERSION
    ncn-m001   Ready    master   7s      v1.18.6
    ncn-m002   Ready    master   4h40m   v1.18.6
    ncn-m003   Ready    master   4h38m   v1.18.6
    ncn-w001   Ready    <none>   4h39m   v1.18.6
    ncn-w002   Ready    <none>   4h39m   v1.18.6
    ncn-w003   Ready    <none>   4h39m   v1.18.6
    ```

1. Restore and verify the site link.

    It will be necessary to restore the `ifcfg-lan0` file from either manual backup taken during the prior "Hand-Off" step or
    re-mount the USB and copy it from the prep directory to `/etc/sysconfig/network/`.

    ```bash
    ncn-m001# SYSTEM_NAME=eniac
    ncn-m001# rsync ncn-m002:/metal/bootstrap/prep/${SYSTEM_NAME}/pit-files/ifcfg-lan0 /etc/sysconfig/network/ && \
              wicked ifreload lan0 && \
              wicked ifstatus lan0
    ```

    Expected output looks similar to:

    ```text
    lan0            up
       link:     #32, state up, mtu 1500
       type:     bridge, hwaddr 90:e2:ba:0f:11:c2
       config:   compat:suse:/etc/sysconfig/network/ifcfg-lan0
       leases:   ipv4 static granted
       addr:     ipv4 172.30.53.88/20 [static]
    ```

1. Verify that the site link (`lan0`) and the VLANs have IP addresses.

    > Examine the output to ensure that each interface has been assigned an IPv4 address.

    ```bash
    ncn-m001# for INT in lan0 vlan002 vlan004 vlan007 ; do
                ip a show $INT || echo "ERROR: Command failed: ip a show $INT"
              done
    ```

1. Run `ip r` to show that the default route is via the CAN/`vlan007`.

    ```bash
    ncn-m001# ip r show default
    ```

1. Verify that there **is not** a metal bootstrap IP address.

    ```bash
     ncn-m001# ip a show bond0
     ```

1. Verify zypper repositories are empty and all remote SUSE repositories are disabled.

    ```bash
    ncn-m001# rm -v /etc/zypp/repos.d/* && zypper ms --remote --disable
    ```

1. Download and install/upgrade the documentation RPM.

    If this machine does not have direct internet access, then this RPM will need to be
    externally downloaded and then copied to this machine.

    **Important:** To ensure that the latest workarounds and documentation updates are available, see [Check for Latest Workarounds and Documentation Updates](../update_product_stream/index.md#workarounds)

1. Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `livecd-post-reboot` breakpoint.

1. Exit the typescript and move the backup to `ncn-m001`.

    This is required to facilitate reinstallations, because it pulls the preparation data back over to the documented area (`ncn-m001`).

    ```console
    ncn-m001# exit
    ncn-m002# exit
    # typescript exited
    ncn-m002# rsync -rltDv -P /metal/bootstrap ncn-m001:/metal/ && rm -rfv /metal/bootstrap
    ncn-m002# exit
    ```

<a name="enable-ncn-disk-wiping-safeguard"></a>

## 5. Enable NCN disk wiping safeguard

The next steps require `csi` from the installation media. `csi` will not be provided on an NCN otherwise because
it is used for Cray installation and bootstrap.

1. SSH back into `ncn-m001` or restart a local console; resume the typescript.

    ```bash
    ncn-m001# script -af /metal/bootstrap/prep/admin/csm-verify.$(date +%Y-%m-%d).txt
    ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

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

## 6. Remove the default NTP pool

Run the following command on `ncn-m001` to remove the default pool, which can cause contention issues with NTP.

```bash
ncn-m001# sed -i "s/^! pool pool\.ntp\.org.*//" /etc/chrony.conf
```

<a name="configure-dns-and-ntp-on-each-bmc"></a>

## 7. Configure DNS and NTP on each BMC

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
                        grep -v "^ncn-m001-mgmt$")
    ncn-m001# echo $BMCS
    ```

1. Run the following to loop through all of the BMCs (except `ncn-m001-mgmt`) and apply the desired settings.

    ```bash
    ncn-m001# for BMC in $BMCS ; do
                echo "$BMC: Disabling DHCP and configure NTP on the BMC using data from cloud-init"
                /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H $BMC -S -n
                echo
                echo "$BMC: Configuring DNS on the BMC using data from cloud-init"
                /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H $BMC -d
                echo
                echo "$BMC: Showing settings"
                /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H $BMC -s
                echo
                echo "Press enter to proceed to next BMC, or control-C to abort"
                echo
                read
            done ; echo "Configuration completed on all NCN BMCs"
    ```

<a name="validate-bootraid-artifacts"></a>

## 8. Validate `BOOTRAID` artifacts

Perform the following steps **on `ncn-m001`**.

1. Initialize the Cray CLI on `ncn-m001`. See [Configure the Cray Command Line Interface](../operations/configure_cray_cli.md) for details on how to do this.

1. Ensure that `ssh` works from `ncn-m001` to itself.

    The following command must work before proceeding to the next step.

    ```bash
    ncn-m001# ssh ncn-m001 date
    ```

1. Run the script to ensure the local `BOOTRAID` has a valid kernel and initrd.

    This script will perform the check on all NCNs, including `ncn-m001`.

    ```bash
    ncn-m001# /opt/cray/tests/install/ncn/scripts/validate-bootraid-artifacts.sh
    ```

1. If the above fails with messages about `Host key verification failed`, clear them from the `known_hosts` file:

    This script will perform the clear on all NCNs, including `ncn-m001`.

    ```console
    ncn-m001# for ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u); do ssh-keygen -R $ncn;done
    ```

<a name="next-topic"></a>

## 8. Next topic

After completing this procedure, the next step is to [Configure Administrative Access](index.md#configure_administrative_access).
