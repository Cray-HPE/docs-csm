# Deploy Final NCN

The following procedure contains information for rebooting and deploying the management node that is currently
hosting the LiveCD. At the end of this procedure, the LiveCD will no longer be active. The node it was using will
join the Kubernetes cluster as the final of three master nodes, forming a quorum.

**IMPORTANT:** While the node is rebooting, it will only be available through Serial-Over-LAN (SOL) and local terminals. This
procedure entails deactivating the LiveCD, meaning the LiveCD and all of its resources will be unavailable.

1. [Required services](#1-required-services)
1. [Notice of danger](#2-notice-of-danger)
1. [Hand-off](#3-handoff)
   1. [Handoff Data](#31-handoff-data)
   1. [Backup](#32-backup)
   1. [Prepare for Rebooting](#33-prepare-for-rebooting)
1. [Enable NCN disk wiping safeguard](#5-enable-ncn-disk-wiping-safeguard)
1. [Remove the default NTP pool](#6-remove-the-default-ntp-pool)
1. [Configure DNS and NTP on each BMC](#7-configure-dns-and-ntp-on-each-bmc)
1. [Next topic](#8-next-topic)

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

## 3. Handoff

The steps in this section load hand-off data before a later procedure reboots the LiveCD node.

### 3.1 Handoff Data

1. (`pit#`) Start a new typescript.

    1. Exit the current typescript, if one is active.

        ```bash
        exit
        ```

    1. Start a new typescript on the PIT node.

        ```bash
        mkdir -pv "${PITDATA}"/prep/admin &&
             pushd "${PITDATA}"/prep/admin &&
             script -af "csm-livecd-reboot.$(date +%Y-%m-%d).txt"
        export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
        ```

1. (`pit#`) Upload SLS file.

    > **`NOTE`** The environment variable `SYSTEM_NAME` must be set.

    ```bash
    csi upload-sls-file --sls-file "${PITDATA}/prep/${SYSTEM_NAME}/sls_input_file.json"
    ```

    Expected output looks similar to the following:

    ```text
    2021/02/02 14:05:15 Retrieving S3 credentials ( sls-s3-credentials ) for SLS
    2021/02/02 14:05:15 Uploading SLS file: /var/www/ephemeral/prep/eniac/sls_input_file.json
    2021/02/02 14:05:15 Successfully uploaded SLS Input File.
    ```

1. (`pit#`) Get a token to use for authenticated communication with the gateway.

    > **`NOTE`** `api-gw-service-nmn.local` is legacy, and will be replaced with `api-gw-service.nmn`.

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
                    -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`pit#`) Upload NCN boot artifacts into S3.

    ```bash
    k8sdir="$(dirname $(readlink -f /var/www/ncn-m002/filesystem.squashfs))" &&
    cephdir="$(dirname $(readlink -f /var/www/ncn-s001/filesystem.squashfs))" &&
    csi handoff ncn-images \
        --k8s-kernel-path "${k8sdir}"/*.kernel \
        --k8s-initrd-path "${k8sdir}"/initrd.img*.xz \
        --k8s-squashfs-path "${k8sdir}"/secure-*.squashfs \
        --ceph-kernel-path "${cephdir}"/*.kernel \
        --ceph-initrd-path "${cephdir}"/initrd.img*.xz \
        --ceph-squashfs-path "${cephdir}"/secure-*.squashfs
    ```

1. (`pit#`) Upload the `data.json` file to BSS, the `cloud-init` data source.

    > **`NOTE`** This step will prompt for the root password of the NCNs.

    ```bash
    csi handoff bss-metadata --data-file "${PITDATA}/configs/data.json" || echo "ERROR: csi handoff bss-metadata failed"
    ```

1. (`pit#`) Patch the metadata for the Ceph nodes to have the correct run commands.

    ```bash
    python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
    ```

1. (`pit#`) Ensure that the DNS server value is correctly set to point toward Unbound at `10.92.100.225` (NMN) and `10.94.100.225` (HMN).

    ```bash
    csi handoff bss-update-cloud-init --set meta-data.dns-server="10.92.100.225 10.94.100.225" --limit Global
    ```

### 3.2 Backup

1. (`pit#`) Preserve logs and configuration files if desired.

    The PIT RemoteISO is running in memory, thus all files contained are ephemeral. It is recommended to retain some of the log files and
    configuration files, because they may be useful if issues are encountered during the remainder of the install.

    The following commands create a `tar` archive of these files, storing it in a directory that will be backed up in the next step.

    ```bash
    mkdir -pv "${PITDATA}"/prep/logs &&
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
         xargs tar -C / -czvf "${PITDATA}/prep/logs/pit-backup-$(date +%Y-%m-%d_%H-%M-%S).tgz"
    ```

1. (`pit#`) Backup the bootstrap information from `ncn-m001`.

    > **`NOTE`** This preserves information that should always be kept together in order to fresh-install the system again.

    1. Log in and set up passwordless SSH **to** the PIT node.

        Copying **only** the public keys from `ncn-m002` and `ncn-m003` to the PIT node. **Do not** set up
        passwordless SSH **from** the PIT node or the key will have to be securely tracked or expunged if using a USB installation).

        > The `ssh` commands below may prompt for the NCN root password.

        ```bash
        ssh ncn-m002 cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys &&
             ssh ncn-m003 cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys &&
             chmod 600 /root/.ssh/authorized_keys
        ```

    1. Back up files from the PIT to `ncn-m002`.

        ```bash
        ssh ncn-m002 \
            "mkdir -pv /metal/bootstrap
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:'${PITDATA}'/prep /metal/bootstrap/
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:'${CSM_PATH}'/cray-pre-install-toolkit*.iso /metal/bootstrap/"
        ```

    1. Back up files from the PIT to `ncn-m003`.

        ```bash
        ssh ncn-m003 \
            "mkdir -pv /metal/bootstrap
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:'${PITDATA}'/prep /metal/bootstrap/
            rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:'${CSM_PATH}'/cray-pre-install-toolkit*.iso /metal/bootstrap/"
        ```

### 3.3 Prepare for Rebooting

1. (`pit#`) Set the PIT node to PXE boot.

    ```bash
    efibootmgr | grep -Ei "ip(v4|4)"
    ```

1. (`pit#`) Set and trim the boot order on the PIT node.

    This only needs to be done for the PIT node, not for any of the other NCNs. See
    [Setting boot order](../background/ncn_boot_workflow.md#setting-boot-order) and
    [Trimming boot order](../background/ncn_boot_workflow.md#trimming-boot-order).

1. (`pit#`) Tell the PIT node to PXE boot on the next boot.

    ```bash
    efibootmgr -n $(efibootmgr | grep -Ei "ip(v4|4)" | awk '{print $1}' | head -n 1 | tr -d Boot*) | grep -i bootnext
    ```

1. (`pit#`) Collect a backdoor login. Fetch the CMN IP address for `ncn-m002` for a backdoor during the reboot of `ncn-m001`.

    1. (`pit#`) Get the IP address.

        ```bash
        ssh ncn-m002 ip -4 a show bond0.cmn0 | grep inet | awk '{print $2}' | cut -d / -f1
        ```

        Expected output will look similar to the following (exact values may differ):

        ```text
        10.102.11.13
        ```

    1. (`external#`) Log in from another external machine to verify SSH is up and running for this session.

        ```bash
        ssh root@10.102.11.13
        ```

        > Keep this terminal active as it will enable `kubectl` commands during the bring-up of the new NCN.
        > If the reboot successfully deploys the LiveCD, then this terminal can be exited.
        >
        > **POINT OF NO RETURN** The next step will wipe the underlying nodes disks clean. It will ignore USB devices.
        > RemoteISOs are at risk here; even though a backup has been performed of the PIT node, it is not possible to
        > boot back to the same state. This is the last step before rebooting the node.

1. (`pit#`) Quit the typescript session and copy the typescript file off of `ncn-m001`.

    1. Stop the typescript session:

        ```bash
        exit
        ```

    1. Back up the completed typescript file by re-running the `rsync` commands in the [Backup Bootstrap Information](#32-backup) section.

1. (`external#`) Setup ConMan or serial console, if not already on, from any laptop or other system with network connectivity to the cluster.

    ```bash
    script -a boot.livecd.$(date +%Y-%m-%d).txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    SYSTEM_NAME=eniac
    ```

    ```bash
    USERNAME=root
    read -r -s -p "ncn-m001 BMC ${USERNAME} password: " IPMI_PASSWORD
    ```

    ```bash
    export IPMI_PASSWORD
    ipmitool -I lanplus -U "${USERNAME}" -E -H "${SYSTEM_NAME}-ncn-m001-mgmt" chassis power status
    ipmitool -I lanplus -U "${USERNAME}" -E -H "${SYSTEM_NAME}-ncn-m001-mgmt" sol activate
    ```

## 4. Reboot

1. (`pit#`) Reboot the LiveCD.

    ```bash
    reboot
    ```

1. (`pit#`) Wait for the node to boot, acquire its hostname (`ncn-m001`), and run `cloud-init`.

    > **`NOTE`** If the node has PXE boot issues, such as getting PXE errors or not pulling the `ipxe.efi` binary, see [PXE boot troubleshooting](troubleshooting_pxe_boot.md).

1. (`external#`) Once `cloud-init` has completed successfully, log in and start a typescript (the IP address used here is the one noted for `ncn-m002` in an earlier step).

    ```bash
    ssh root@10.102.11.13

    pushd /metal/bootstrap/prep/admin
    script -af "csm-verify.$(date +%Y-%m-%d).txt"
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ssh ncn-m001
    ```

1. (`ncn-m001#`) Run `kubectl get nodes` to see the full Kubernetes cluster.

    ```bash
    kubectl get nodes
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

1. (`ncn-m001#`) Restore and verify the site link.

    Restore networking files from the manual backup taken during the
    [Backup](#32-backup) step.

    ```bash
    SYSTEM_NAME=eniac
    rsync "ncn-m002:/metal/bootstrap/prep/${SYSTEM_NAME}/pit-files/ifcfg-lan0" /etc/sysconfig/network/ && \
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

1. (`ncn-m001#`) Verify that the site link (`lan0`) and the VLANs have IP addresses.

    > Examine the output to ensure that each interface has been assigned an IPv4 address.

    ```bash
    for INT in lan0 bond0.nmn0 bond0.hmn0 bond0.can0 bond0.cmn0 ; do
        ip a show "${INT}" || echo "ERROR: Command failed: ip a show ${INT}"
    done
    ```

1. (`ncn-m001#`) Verify that the default route is via the CMN.

    ```bash
    ip r show default
    ```

1. (`ncn-m001#`) Verify that there **is not** a metal bootstrap IP address.

    ```bash
    ip a show bond0
    ```

1. (`ncn-m001#`) Download and install/upgrade the documentation RPM.

    If this machine does not have direct internet access, then this RPM will need to be
    externally downloaded and then copied to this machine.

    See [Check for Latest Documentation](../update_product_stream/README.md#check-for-latest-documentation).

1. (`ncn-m001#`) Exit the typescript and move the backup to `ncn-m001`.

    This is required to facilitate reinstallations, because it pulls the preparation data back over to the documented area (`ncn-m001`).

    ```console
    exit
    exit
    # typescript exited
    rsync -rltDv -P /metal/bootstrap ncn-m001:/metal/ && rm -rfv /metal/bootstrap
    exit
    ```

## 5. Enable NCN disk wiping safeguard

The next steps require `csi` from the installation media. `csi` will not be provided on an NCN otherwise because
it is used for Cray installation and bootstrap.

1. SSH back into `ncn-m001` or restart a local console.

1. (`ncn-m001#`) Resume the typescript.

    ```bash
    script -af "/metal/bootstrap/prep/admin/csm-verify.$(date +%Y-%m-%d).txt"
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

1. (`ncn-m001#`) Obtain access to CSI.

    ```bash
    mkdir -pv /mnt/livecd /mnt/rootfs /mnt/sqfs && \
        mount -v /metal/bootstrap/cray-pre-install-toolkit-*.iso /mnt/livecd/ && \
        mount -v /mnt/livecd/LiveOS/squashfs.img /mnt/sqfs/ && \
        mount -v /mnt/sqfs/LiveOS/rootfs.img /mnt/rootfs/ && \
        cp -pv /mnt/rootfs/usr/bin/csi /tmp/csi && \
        /tmp/csi version && \
        umount -vl /mnt/sqfs /mnt/rootfs /mnt/livecd
    ```

    > **`NOTE`** `/tmp/csi` will delete itself on the next reboot. The `/tmp` directory is `tmpfs` and runs in memory;
    > it will not persist on restarts.

1. (`ncn-m001#`) Authenticate with the cluster.

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
                    -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-m001#`) Set the wipe safeguard to allow safe reboots on all NCNs.

    ```bash
    /tmp/csi handoff bss-update-param --set metal.no-wipe=1
    ```

## 6. Remove the default NTP pool

(`ncn-m001#`) Run the following command to remove the default pool, in order to prevent contention issues with NTP.

```bash
sed -i "s/^! pool pool\.ntp\.org.*//" /etc/chrony.conf
```

## 7. Configure DNS and NTP on each BMC

 > **`NOTE`** Only follow this section if the NCNs are HPE hardware. If the system uses
 > Gigabyte or Intel hardware, then skip this section.

Configure DNS and NTP on the BMC for each management node **except `ncn-m001`**.
However, the commands in this section are all run **on** `ncn-m001`.

1. (`ncn-m001#`) Validate that the system is HPE hardware.

    ```bash
    ipmitool mc info | grep "Hewlett Packard Enterprise" || echo "Not HPE hardware -- SKIP these steps"
    ```

1. (`ncn-m001#`) Set environment variables.

    Set the `IPMI_PASSWORD` and `USERNAME` variables to the BMC credentials for the NCNs.

    > **`NOTE`** Using `read -s` for this prevents the credentials from being echoed to the screen or saved in the shell history.

    ```bash
    USERNAME=root
    read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
    ```

    ```bash
    export IPMI_PASSWORD USERNAME
    ```

1. (`ncn-m001#`) Set `BMCS` variable to list of the BMCs for all master, worker, and storage nodes,
   except `ncn-m001-mgmt`:

    ```bash
    readarray BMCS < <(grep mgmt /etc/hosts | awk '{print $NF}' | grep -v m001 | sort -u | tr '\n' ' ')
    for BMC in "${BMCS[@]}"; do echo ${BMC}; done
    ```

    Expected output looks similar to the following:

    ```text
    ncn-m002-mgmt ncn-m003-mgmt ncn-s001-mgmt ncn-s002-mgmt ncn-s003-mgmt ncn-w001-mgmt ncn-w002-mgmt ncn-w003-mgmt
    ```

1. (`ncn-m001#`) Get the DNS server IP address for the NMN.

    ```bash
    NMN_DNS=$(kubectl get services -n services -o wide | grep cray-dns-unbound-udp-nmn | awk '{ print $4 }'); echo ${NMN_DNS}
    ```

    Example output:

    ```text
    10.92.100.225
    ```

1. (`ncn-m001#`) Get the DNS server IP address for the HMN.

    ```bash
    HMN_DNS=$(kubectl get services -n services -o wide | grep cray-dns-unbound-udp-hmn | awk '{ print $4 }'); echo ${HMN_DNS}
    ```

    Example output:

    ```text
    10.94.100.225
    ```

1. (`ncn-m001#`) Run the following to loop through all of the BMCs (except `ncn-m001-mgmt`) and apply the desired settings.

    ```bash
    for BMC in "${BMCS[@]}"; do
        echo "${BMC}: Disabling DHCP and configure NTP on the BMC using data from unbound service"
        /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H "${BMC}" -S -n
        echo
        echo "${BMC}: Configuring DNS on the BMC using data from unbound"
        /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H "${BMC}" -D "${NMN_DNS},${HMN_DNS}" -d
        echo
        echo "${BMC}: Showing settings"
        /opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H "${BMC}" -s
        echo
    done ; echo "Configuration completed on all NCN BMCs"
    ```

## 8. Next topic

After completing this procedure, the next step is to [Configure Administrative Access](README.md#5-configure-administrative-access).
