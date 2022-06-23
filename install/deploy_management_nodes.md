# Deploy Management Nodes

The following procedure deploys Linux and Kubernetes software to the management NCNs.
Deployment of the nodes starts with booting the storage nodes followed by the master nodes
and worker nodes together.

After the operating system boots on each node, there are some configuration actions which
take place. Watching the console or the console log for certain nodes can help to understand
what happens and when. When the process completes for all nodes, the Ceph storage is
initialized and the Kubernetes cluster is created and ready for a workload. The PIT node
will join Kubernetes after it is rebooted later in
[Deploy Final NCN](index.md#deploy_final_ncn).

## Timing of deployments

The timing of each set of boots varies based on hardware. Nodes from some manufacturers will
POST faster than others or vary based on BIOS setting. After powering on a set of nodes,
an administrator can expect a healthy boot session to take about 60 minutes depending on
the number of storage and worker nodes.

## Topics

   1. [Prepare for management node deployment](#1-prepare-for-management-node-deployment)
      1. [Tokens and IPMI password](#11-tokens-and-ipmi-password)
      2. [Ensure time is accurate before Deploying NCNs](#12-ensure-time-is-accurate-before-deploying-ncns)
   2. [Update management node firmware](#2-update-management-node-firmware)
   3. [Deploy management nodes](#3-deploy-management-nodes)
      1. [Deploy workflow](#31-deploy-workflow)
      2. [Deploy](#32-deploy)
      3. [Check LVM on Kubernetes NCNs](#33-check-lvm-on-kubernetes-ncns)
      4. [Check for unused drives on utility storage nodes](#34-check-for-unused-drives-on-utility-storage-nodes)
   4. [Configure after management node deployment](#4-configure-after-management-node-deployment)
      1. [LiveCD cluster authentication](#41-livecd-cluster-authentication)
      2. [Install tests and test server on NCNs](#42-install-tests-and-test-server-on-ncns)
      3. [Clean up `chrony` configurations](#43-clean-up-chrony-configurations)
   5. [Validate management node deployment](#5-validate-management-node-deployment)
   6. [Important checkpoint](#important-checkpoint)
   7. [Next topic](#next-topic)

<a name="prepare_for_management_node_deployment"></a>

## 1. Prepare for management node deployment

Preparation of the environment must be done before attempting to deploy the management nodes.

<a name="tokens-and-ipmi-password"></a>

### 1.1 Tokens and IPMI password

1. Define shell environment variables that will simplify later commands to deploy management nodes.

   1. Set `IPMI_PASSWORD` to the root password for the NCN BMCs.

      > `read -s` is used to prevent the password from being written to the screen or the shell history.

      ```bash
      pit# read -s IPMI_PASSWORD
      pit# export IPMI_PASSWORD
      ```

   1. Set the remaining helper variables.

      > These values do not need to be altered from what is shown.

      ```bash
      pit# mtoken='ncn-m(?!001)\w+-mgmt' ; stoken='ncn-s\w+-mgmt' ; wtoken='ncn-w\w+-mgmt' ; export USERNAME=root
      ```

   Throughout the guide, simple one-liners can be used to query status of expected nodes. If the shell or environment is terminated, these
   environment variables should be re-exported.

   Examples:

   * Check power status of all NCNs.

      ```bash
      pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
              xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power status
      ```

   * Power off all NCNs.

      ```bash
      pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
              xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
      ```

<a name="ensure-time-is-accurate-before-deploying-ncns"></a>

### 1.2 Ensure time is accurate before deploying NCNs

**NOTE:** Optionally, in order to use a timezone other than UTC, instead of step 1 below, follow
[this procedure for setting a local timezone](../operations/node_management/Configure_NTP_on_NCNs.md#set-a-local-timezone). Then
proceed to step 2.

1. Ensure that the PIT node has the correct current time.

   The time can be inaccurate if the system has been powered off for a long time, or, for example, the CMOS was cleared on a Gigabyte node. See [Clear Gigabyte CMOS](clear_gigabyte_cmos.md).

   > **This step should not be skipped.**

   Check the time on the PIT node to see whether it matches the current time:

   ```bash
   pit# date "+%Y-%m-%d %H:%M:%S.%6N%z"
   ```

   If the time is inaccurate, set the time manually.

   ```bash
   pit# timedatectl set-time "2019-11-15 00:00:00"
   ```

   Run the NTP script:

   ```bash
   pit# /root/bin/configure-ntp.sh
   ```

   This ensures that the PIT is configured with an accurate date/time, which will be propagated to the NCNs during boot.

   If the error `Failed to set time: NTP unit is active` is observed, then stop `chrony` first.

   ```bash
   pit# systemctl stop chronyd
   ```

   Then run the commands above to complete the process.

1. Ensure that the current time is set in BIOS for all management NCNs.

   Each NCN is booted to the BIOS menu, the date and time are checked, and set to the current UTC time if needed.

   > **NOTE:** Some steps in this procedure depend on `USERNAME` and `IPMI_PASSWORD` being set. This is done in
[Tokens and IPMI Password](#tokens-and-ipmi-password).

   Repeat the following process for each NCN.

   1. Set the `bmc` variable to the name of the BMC of the NCN being checked.

      **Important:** Be sure to change the below example to the appropriate NCN.

      ```console
      pit# bmc=ncn-w001-mgmt
      ```

   1. Start an IPMI console session to the NCN.

      ```console
      pit# conman -j $bmc
      ```

   1. Using another terminal to watch the console, boot the node to BIOS.

      ```console
      pit# ipmitool -I lanplus -U $USERNAME -E -H $bmc chassis bootdev bios &&
           ipmitool -I lanplus -U $USERNAME -E -H $bmc chassis power off && sleep 10 &&
           ipmitool -I lanplus -U $USERNAME -E -H $bmc chassis power on
      ```

      > For HPE NCNs, the above process will boot the nodes to their BIOS; however, the BIOS menu is unavailable through conman because
      > the node is booted into a graphical BIOS menu.
      >
      > In order to access the serial version of the BIOS menu, perform the `ipmitool` steps above to boot the node.
      > Then, in conman, press `ESC+9` key combination when
      > the following messages are shown on the console. That key combination will open a menu that can be used to enter
      > the BIOS using conman.
      >
      > ```text
      > For access via BIOS Serial Console:
      > Press 'ESC+9' for System Utilities
      > Press 'ESC+0' for Intelligent Provisioning
      > Press 'ESC+!' for One-Time Boot Menu
      > Press 'ESC+@' for Network Boot
      > ```
      >
      > For HPE NCNs, the date configuration menu is at the following path: `System Configuration -> BIOS/Platform Configuration (RBSU) -> Date and Time`.
      >
      > Alternatively, for HPE NCNs, log in to the BMC's web interface and access the HTML5 console for the node, in order to interact with the graphical BIOS.
      > From the administrator's own machine, create an SSH tunnel (`-L` creates the tunnel; `-N` prevents a shell and stubs the connection):
      >
      > ```bash
      > linux# bmc=ncn-w001-mgmt # Change this to be the appropriate node
      > linux# ssh -L 9443:$bmc:443 -N root@eniac-ncn-m001
      > ```
      >
      > Opening a web browser to `https://localhost:9443` will give access to the BMC's web interface.

   1. When the node boots, the conman session can be used to see the BIOS menu, in order to check and set the time to current UTC time.
      The process varies depending on the vendor of the NCN.

   1. After the correct time has been verified, power off the NCN.

      ```bash
      pit# ipmitool -I lanplus -U $USERNAME -E -H $bmc chassis power off
      ```

   Repeat the above process for each NCN.

<a name="update_management_node_firmware"></a>

## 2. Update management node firmware

> All firmware can be found in the HFP package provided with the Shasta release.

The management nodes are expected to have certain minimum firmware installed for BMC, node BIOS, and PCIe cards.
Where possible, the firmware should be updated prior to install. It is good to meet the minimum NCN
firmware requirement before starting.

   >**Note:** When the PIT node is booted from the LiveCD, it is not possible to use the Firmware Action Service (FAS) to update the
   the firmware because that service has not yet been installed. However, at this point, it would be possible to use
   the HPE Cray EX HPC Firmware Pack (HFP) product on the PIT node to learn about the firmware versions available in HFP.

   If the firmware is not updated at this point in the installation workflow, then it can be done with FAS after CSM and HFP have
   both been installed and configured. However, at that point a rolling reboot procedure for the management nodes will be needed,
   after the firmware has been updated.

   See the [`HPE Cray EX System Software Getting Started Guide (S-8000) 22.06`](http://www.hpe.com/support/ex-gsg-042120221040)
   on the HPE Customer Support Center for information about the _HPE Cray EX HPC Firmware Pack_ (HFP) product.

   In the HFP documentation there is information about the recommended firmware packages to be installed.
   See "Product Details" in the HPE Cray EX HPC Firmware Pack Installation Guide.

   Some of the component types have manual procedures to check firmware versions and update firmware.
   See `Upgrading Firmware Without FAS` in the `HPE Cray EX HPC Firmware Pack Installation Guide`.
   It will be possible to extract the files from the product tarball, but the `install.sh` script from that product
   will be unable to load the firmware versions into the Firmware Action Services (FAS) because the management nodes
   are not booted and running Kubernetes and FAS cannot be used until Kubernetes is running.

   If booted into the PIT node, the firmware can be found with HFP package provided with the Shasta release.

1. (optional) Check these BIOS settings on management nodes [NCN BIOS](../background/ncn_bios.md).

    > This is **optional**, the BIOS settings (or lack thereof) do not prevent deployment. The NCN installation will work with the CMOS' default
    > BIOS. There may be settings that facilitate the speed of deployment, but they may be tuned at a later time.
    >
    > **NOTE:** The BIOS tuning will be automated, further reducing this step.

1. The firmware on the management nodes should be checked for compliance with the minimum required version
   and updated, if necessary, at this point.

   > **WARNING:** Gigabyte NCNs running BIOS version C20 can become unusable
   > when Shasta 1.5 is installed. This is a result of a bug in the Gigabyte
   > firmware. This bug has not been observed in BIOS version C17.
   >
   > A key symptom of this bug is that the NCN will not PXE boot and will instead
   > fall through to the boot menu, despite being configure to PXE boot. This
   > behavior will persist until the failing node's CMOS is cleared.

   * See [Clear Gigabyte CMOS](clear_gigabyte_cmos.md).

<a name="deploy_management_nodes"></a>

## 3. Deploy management nodes

Deployment of the nodes starts with booting the storage nodes first. Then, the master nodes and worker nodes should be booted together.
After the operating system boots on each node, there are some configuration actions which take place. Watching the
console or the console log for certain nodes can help to understand what happens and when. When the process is complete
for all nodes, the Ceph storage will have been initialized and the Kubernetes cluster will be created ready for a workload.

<a name="deploy-workflow"></a>

### 3.1 Deploy workflow

The configuration workflow described here is intended to help understand the expected path for booting and configuring. The actual steps to
be performed are in the [Deploy](#deploy) section.

1. Start watching the consoles for `ncn-s001` and at least one other storage node
1. Boot all storage nodes at the same time
    * The first storage node (`ncn-s001`) will boot; it then starts a loop as `ceph-ansible` configuration waits for all other storage nodes to boot.
    * The other storage nodes boot and become passive. They will be fully configured when `ceph-ansible` runs to completion on `ncn-s001`.
1. Once `ncn-s001` notices that all other storage nodes have booted, `ceph-ansible` will begin Ceph configuration. This takes several minutes.
1. Once `ceph-ansible` has finished on `ncn-s001`, then `ncn-s001` waits for `ncn-m002` to create `/etc/kubernetes/admin.conf`.
1. Start watching the consoles for `ncn-m002`, `ncn-m003`, and at least one worker node.
1. Boot master nodes (`ncn-m002` and `ncn-m003`) and all worker nodes at the same time.
    * The worker nodes will boot and wait for `ncn-m002` to create the `/etc/cray/kubernetes/join-command-control-plane` file so that they can join Kubernetes.
    * The third master node (`ncn-m003`) boots and waits for `ncn-m002` to create the `/etc/cray/kubernetes/join-command-control-plane` file so that it can join Kubernetes
    * The second master node (`ncn-m002`) boots and runs `kubernetes-cloudinit.sh`, which will create `/etc/kubernetes/admin.conf` and
      `/etc/cray/kubernetes/join-command-control-plan`. It then waits for the storage node to `create etcd-backup-s3-credentials`.
1. Once `ncn-s001` notices that `ncn-m002` has created `/etc/kubernetes/admin.conf`, then `ncn-s001` waits for any worker node to become available.
1. As each worker node notices that `ncn-m002` has created `/etc/cray/kubernetes/join-command-control-plane`, they will join the Kubernetes cluster.
    * Once `ncn-s001` notices that a worker node has done this, it moves forward with the creation of ConfigMaps and running the post-Ceph playbooks
      (S3, OSD pools, quotas, and so on.)
1. Once `ncn-s001` creates `etcd-backup-s3-credentials` during the `ceph-rgw-users` role (one of the last roles after Ceph has been set up), then `ncn-m001`
   notices this and proceeds.

> **NOTE:** If several hours have elapsed between storage and master nodes booting, or if there were issues PXE booting master nodes, the `cloud-init` script on
> `ncn-s001` may not complete successfully. This can cause the `/var/log/cloud-init-output.log` on master node(s) to continue to output the following message:
>
> ```text
> [ 1328.351558] cloud-init[8472]: Waiting for storage node to create etcd-backup-s3-credentials secret...
> ```
>
> In this case, the following script is safe to be executed again on `ncn-s001`:
>
> ```ShellSession
> ncn-s001# /srv/cray/scripts/common/storage-ceph-cloudinit.sh
> ```
>
> After this script finishes, the secrets will be created and the `cloud-init` script on the master node(s) should complete.

<a name="deploy"></a>

### 3.2 Deploy

> **NOTE:** Some scripts in this section depend on `IPMI_PASSWORD` being set. This is done in
[Tokens and IPMI Password](#tokens-and-ipmi-password).

1. Set the default root password and SSH keys and optionally change the timezone.

   The management nodes images do not contain a default password or default SSH keys.

   It is **required** to set the default root password and SSH keys in the images used to boot the management nodes.
   Follow the NCN image customization steps in [Change NCN Image Root Password and SSH Keys on PIT Node](../operations/security_and_authentication/Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md)

1. Create boot directories for any NCN in DNS.

    This will create folders for each host in `/var/www`, allowing each host to have its own unique set of artifacts:
    kernel, `initrd`, SquashFS, and `script.ipxe` bootscript.

    ```bash
    pit# /root/bin/set-sqfs-links.sh
    ```

    > Every NCN except for `ncn-m001` should be included in the output from this script. If that is not the case,
    > then verify that all NCN BMCs are set to use DHCP. See
    > [Set node BMCs to DHCP](prepare_management_nodes.md#set_node_bmcs_to_dhcp). After that is done,
    > re-run the `set-sqfs-links.sh` script.

1. Customize boot scripts for any out-of-baseline NCNs
    * **Worker nodes** with more than two small disks need to make adjustments to [prevent bare-metal `etcd` creation](../background/ncn_mounts_and_file_systems.md#worker-nodes-with-etcd).
    * For a brief overview of what is expected, see [disk plan of record / baseline](../background/ncn_mounts_and_file_systems.md#plan-of-record--baseline).

1. Run the BIOS baseline script to apply configurations to BMCs.

    The script will apply helper configurations to facilitate more deterministic network booting on any NCN port.
    **This runs against any server vendor**, but some settings are not applied for certain vendors.

    > **NOTE:** This script will enable DCMI/IPMI on Hewlett-Packard Enterprise servers equipped with ILO. If `ipmitool` is not working at this time, it will after running this script.

    ```bash
    pit# /root/bin/bios-baseline.sh
    ```

1. <a name="set-uefi-and-power-off"></a>Set each node to always UEFI Network Boot, and ensure they are powered off

    ```bash
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=persistent
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=efiboot
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

    > **NOTE:** The NCN boot order is further explained in [NCN Boot Workflow](../background/ncn_boot_workflow.md).

1. Validate that the LiveCD is ready for installing NCNs.

   Observe the output of the checks and note any failures, then remediate them.

   1. Specify the `admin` user password for the management switches in the system.

      > `read -s` is used to prevent the password from being written to the screen or the shell history.

      ```bash
      pit# read -s SW_ADMIN_PASSWORD
      pit# export SW_ADMIN_PASSWORD
      ```

   1. Run the LiveCD preflight checks.

      ```bash
      pit# csi pit validate --livecd-preflight
      ```

      > Note: Ignore any errors about not being able resolve `arti.dev.cray.com`.

1. Print the available consoles.

    ```bash
    pit# conman -q
    ```

    Expected output looks similar to the following:

    ```text
    ncn-m001-mgmt
    ncn-m002-mgmt
    ncn-m003-mgmt
    ncn-s001-mgmt
    ncn-s002-mgmt
    ncn-s003-mgmt
    ncn-w001-mgmt
    ncn-w002-mgmt
    ncn-w003-mgmt
    ```

    > **NOTE:** All console logs are located at `/var/log/conman/console*`

1. <a name="boot-the-storage-nodes"></a>Boot the **Storage Nodes**

    Boot all the storage nodes. `ncn-s001` will start 1 minute after the other storage nodes.

    ```bash
    pit# grep -oP $stoken /etc/dnsmasq.d/statics.conf | grep -v "ncn-s001-" | sort -u |
            xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on; \
         sleep 60; ipmitool -I lanplus -U $USERNAME -E -H ncn-s001-mgmt power on
    ```

1. Observe the installation through the console of `ncn-s001-mgmt`.

    ```bash
    pit# conman -j ncn-s001-mgmt
    ```

    From there an administrator can witness console output for the `cloud-init` scripts.

    **NOTE:** Watch the storage node consoles carefully for error messages. If any are seen, consult [Ceph-CSI Troubleshooting](ceph_csi_troubleshooting.md).

    **NOTE:** If the nodes have PXE boot issues (for example, getting PXE errors, or not pulling the `ipxe.efi` binary), see [PXE boot troubleshooting](pxe_boot_troubleshooting.md).

1. Wait for storage nodes before booting Kubernetes master nodes and worker nodes.

   **NOTE:** Once all storage nodes are up and the message `...sleeping 5 seconds until /etc/kubernetes/admin.conf` appears on `ncn-s001`'s console, it is safe to proceed with booting the **Kubernetes master nodes and worker nodes**

    ```bash
    pit# grep -oP "($mtoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
    ```

1. Stop watching the console from `ncn-s001`.

    Type the ampersand character and then the period character to exit from the conman session on `ncn-s001`.

    ```text
    &.
    pit#
    ```

1. Wait. Observe the installation through `ncn-m002-mgmt`'s console:

    Print the console name:

    ```bash
    pit# conman -q | grep m002
    ```

    Expected output looks similar to the following:

    ```text
    ncn-m002-mgmt
    ```

    Then join the console:

    ```bash
    pit# conman -j ncn-m002-mgmt
    ```

    **NOTE:** If the nodes have PXE boot issues (e.g. getting PXE errors, not pulling the ipxe.efi binary) see [PXE boot troubleshooting](pxe_boot_troubleshooting.md)

    **NOTE:** If one of the master nodes seems hung waiting for the storage nodes to create a secret, check the storage node consoles for error messages.
    If any are found, consult [CEPH CSI Troubleshooting](ceph_csi_troubleshooting.md)

1. Wait for the deployment to finish.

    Refer to [timing of deployments](#timing-of-deployments). It should not take more than 60 minutes for the `kubectl get nodes` command to return output indicating
    that all the master nodes and worker nodes (excluding from the PIT node) booted from the LiveCD and are `Ready`.

    > When the following command prompts for a password, enter the root password for `ncn-m002`.

    ```bash
    pit# ssh ncn-m002 kubectl get nodes -o wide
    ```

    Expected output looks similar to the following:

    ```text
    NAME       STATUS   ROLES                  AGE   VERSION    INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                  KERNEL-VERSION         CONTAINER-RUNTIME
    ncn-m002   Ready    control-plane,master   2h    v1.20.13   10.252.1.5    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-m003   Ready    control-plane,master   2h    v1.20.13   10.252.1.6    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w001   Ready    <none>                 2h    v1.20.13   10.252.1.7    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w002   Ready    <none>                 2h    v1.20.13   10.252.1.8    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w003   Ready    <none>                 2h    v1.20.13   10.252.1.9    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ```

1. Enable passwordless SSH for the PIT node.

    1. Copy SSH files from `ncn-m002` to the PIT node.

        > When the following command prompts for a password, enter the root password for `ncn-m002`.

        ```ShellSession
        pit# rsync -av ncn-m002:.ssh/ /root/.ssh/
        ```

        Expected output looks similar to the following:

        ```text
        Password:
        receiving incremental file list
        ./
        authorized_keys
        id_rsa
        id_rsa.pub
        known_hosts

        sent 145 bytes  received 13,107 bytes  3,786.29 bytes/sec
        total size is 12,806  speedup is 0.97
        ```

    1. Make a list of all of the NCNs (including `ncn-m001`).

        ```ShellSession
        pit# NCNS=$(grep -oP "ncn-[msw][0-9]{3}" /etc/dnsmasq.d/statics.conf | sort -u | tr '\n' ',') ; echo "${NCNS}"
        ```

        Expected output looks similar to the following:

        ```text
        ncn-m001,ncn-m002,ncn-m003,ncn-s001,ncn-s002,ncn-s003,ncn-w001,ncn-w002,ncn-w003,
        ```

    1. Verify that passwordless SSH is now working from the PIT node to the other NCNs.

        The following command should not prompt for a password.

        ```ShellSession
        pit# PDSH_SSH_ARGS_APPEND='-o StrictHostKeyChecking=no' pdsh -Sw "${NCNS}" date && echo SUCCESS || echo ERROR
        ```

        Expected output looks similar to the following:

        ```text
        ncn-w001: Warning: Permanently added 'ncn-w001,10.252.1.7' (ECDSA) to the list of known hosts.
        ncn-w003: Warning: Permanently added 'ncn-w003,10.252.1.9' (ECDSA) to the list of known hosts.
        ncn-m003: Warning: Permanently added 'ncn-m003,10.252.1.6' (ECDSA) to the list of known hosts.
        ncn-s002: Warning: Permanently added 'ncn-s002,10.252.1.11' (ECDSA) to the list of known hosts.
        ncn-m001: Warning: Permanently added 'ncn-m001,10.252.1.4' (ECDSA) to the list of known hosts.
        ncn-w002: Warning: Permanently added 'ncn-w002,10.252.1.8' (ECDSA) to the list of known hosts.
        ncn-m002: Warning: Permanently added 'ncn-m002,10.252.1.5' (ECDSA) to the list of known hosts.
        ncn-s003: Warning: Permanently added 'ncn-s003,10.252.1.12' (ECDSA) to the list of known hosts.
        ncn-s001: Warning: Permanently added 'ncn-s001,10.252.1.10' (ECDSA) to the list of known hosts.
        ncn-s003: Thu 28 Apr 2022 02:43:21 PM UTC
        ncn-s001: Thu 28 Apr 2022 02:43:21 PM UTC
        ncn-s002: Thu 28 Apr 2022 02:43:21 PM UTC
        ncn-m001: Thu 28 Apr 2022 02:43:21 PM UTC
        ncn-m003: Thu 28 Apr 2022 02:43:21 PM UTC
        ncn-m002: Thu 28 Apr 2022 02:43:21 PM UTC
        ncn-w001: Thu 28 Apr 2022 02:43:22 PM UTC
        ncn-w002: Thu 28 Apr 2022 02:43:22 PM UTC
        ncn-w003: Thu 28 Apr 2022 02:43:22 PM UTC
        SUCCESS
        ```

1. Stop watching the console of `ncn-m002`.

    Type the ampersand character and then the period character to exit from the conman session on `ncn-m002`.

    ```text
    &.
    pit#
    ```

<a name="check-lvm-on-masters-and-workers"></a>

### 3.3 Check LVM on Kubernetes NCNs

#### 3.3.1 Run the check

Run the following command on the PIT node to validate that the expected LVM labels are present on disks on the master and worker nodes.

```bash
pit# /usr/share/doc/csm/install/scripts/check_lvm.sh
```

#### 3.3.2 Expected check output

Expected output looks similar to the following:

```text
When prompted, please enter the NCN password for ncn-m002
Warning: Permanently added 'ncn-m002,10.252.1.11' (ECDSA) to the list of known hosts.
Password:
Checking ncn-m002...
ncn-m002: OK
Checking ncn-m003...
Warning: Permanently added 'ncn-m003,10.252.1.10' (ECDSA) to the list of known hosts.
Warning: Permanently added 'ncn-m003,10.252.1.10' (ECDSA) to the list of known hosts.
ncn-m003: OK
Checking ncn-w001...
Warning: Permanently added 'ncn-w001,10.252.1.9' (ECDSA) to the list of known hosts.
Warning: Permanently added 'ncn-w001,10.252.1.9' (ECDSA) to the list of known hosts.
ncn-w001: OK
Checking ncn-w002...
Warning: Permanently added 'ncn-w002,10.252.1.8' (ECDSA) to the list of known hosts.
Warning: Permanently added 'ncn-w002,10.252.1.8' (ECDSA) to the list of known hosts.
ncn-w002: OK
Checking ncn-w003...
Warning: Permanently added 'ncn-w003,10.252.1.7' (ECDSA) to the list of known hosts.
Warning: Permanently added 'ncn-w003,10.252.1.7' (ECDSA) to the list of known hosts.
ncn-w003: OK
SUCCESS: LVM checks passed on all master and worker NCNs
```

If the check succeeds, skip the manual check procedure and recovery steps.

**If the check fails for any nodes, the problem must be resolved before continuing.** See [LVM Check Failure Recovery](#lvm-check-failure-recovery).

<a name="manual-lvm-check-procedure"></a>

#### 3.3.3 Manual LVM check procedure

If needed, the LVM checks can be performed manually on the master and worker nodes.

* Manual check on master nodes:

    ```bash
    ncn-m# blkid -L ETCDLVM
    /dev/sdc
    ```

* Manual check on worker nodes:

    ```bash
    ncn-w# blkid -L CONLIB
    /dev/sdb2
    ncn-w# blkid -L CONRUN
    /dev/sdb1
    ncn-w# blkid -L K8SLET
    /dev/sdb3
    ```

The manual checks are considered successful if all of the `blkid` commands report a disk device (such as `/dev/sdc` -- the particular device is unimportant).
If any of the `lsblk` commands return no output, then the check is a failure. **Any failures must be resolved before continuing.** See the following section
for details on how to do so.

<a name="lvm-check-failure-recovery"></a>

#### 3.3.4 LVM check failure recovery

If there are LVM check failures, then the problem must be resolved before continuing with the install.

* If **any master node** has the problem, then wipe and redeploy **all** of the NCNs before continuing the installation:
    1. Wipe each worker node using the 'Basic Wipe' section of [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe).
    1. Wipe each master node (**except** `ncn-m001` because it is the PIT node) using the 'Basic Wipe' section of [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe).
    1. Wipe each storage node using the 'Full Wipe' section of [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#full-wipe).
    1. Return to the [Set each node to always UEFI Network Boot, and ensure they are powered off](#set-uefi-and-power-off) step of the [Deploy Management Nodes](#deploy_management_nodes) section above.

* If **only worker nodes** have the problem, then wipe and redeploy the affected worker nodes before continuing the installation:
    1. Wipe each affected worker node using the 'Basic Wipe' section of [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe).
    1. Power off each affected worker node.
    1. Return to the [Boot the Master and Worker Nodes](#boot-master-and-worker-nodes) step of the [Deploy Management Nodes](#deploy_management_nodes) section above.
        * Note: The `ipmitool` command will give errors trying to power on the unaffected nodes, because they are already powered on -- this is expected and not a problem.

<a name="check-for-unused-drives-on-utility-storage-nodes"></a>

### 3.4 Check for unused drives on utility storage nodes

> **IMPORTANT:** Do the following if NCNs are Gigabyte hardware. It is suggested (but optional) for HPE NCNs.
>
> **IMPORTANT:** Estimate the expected number of OSDs using the following table and using this equation:
>
> `total_osds` = `(number of utility storage/Ceph nodes)` `*` `(OSD count from table below for the appropriate hardware)`

| Hardware Manufacturer | OSD Drive Count (not including OS drives)|
| :-------------------: | :---------------------------------------: |
| GigaByte              | 12 |
| HPE                   | 8  |

#### Option 1

  If there are OSDs on each node (`ceph osd tree` can show this), then all the nodes are in Ceph. That means the orchestrator can be used to look for the devices.

1. Get the number of OSDs in the cluster.

    ```bash
    ncn-s# ceph -f json-pretty osd stat |jq .num_osds
    24
    ```

   **IMPORTANT:** If the returned number of OSDs is equal to `total_osds` calculated, then skip the following steps. If not, then proceed with the below additional checks and remediation steps.

1. Compare the number of OSDs to the output (which should resemble the example below). The number of drives will depend on the server hardware.

    > **NOTE:** If the Ceph cluster is large and has a lot of nodes, a node may be specified after the below command to limit the results.

    ```bash
    ncn-s# ceph orch device ls
    Hostname  Path      Type  Serial              Size   Health   Ident  Fault  Available
    ncn-s001  /dev/sda  ssd   PHYF015500M71P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdb  ssd   PHYF016500TZ1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdc  ssd   PHYF016402EB1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdd  ssd   PHYF016504831P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sde  ssd   PHYF016500TV1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdf  ssd   PHYF016501131P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdi  ssd   PHYF016500YB1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s001  /dev/sdj  ssd   PHYF016500WN1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sda  ssd   PHYF0155006W1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdb  ssd   PHYF0155006Z1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdc  ssd   PHYF015500L61P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdd  ssd   PHYF015502631P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sde  ssd   PHYF0153000G1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdf  ssd   PHYF016401T41P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdi  ssd   PHYF016504C21P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s002  /dev/sdj  ssd   PHYF015500GQ1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sda  ssd   PHYF016402FP1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdb  ssd   PHYF016401TE1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdc  ssd   PHYF015500N51P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdd  ssd   PHYF0165010Z1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sde  ssd   PHYF016500YR1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdf  ssd   PHYF016500X01P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdi  ssd   PHYF0165011H1P9DGN  1920G  Unknown  N/A    N/A    No
    ncn-s003  /dev/sdj  ssd   PHYF016500TQ1P9DGN  1920G  Unknown  N/A    N/A    No
    ```

    If there are devices that show `Available` as `Yes` and they are not being automatically added, that device may need to be zapped.

    **IMPORTANT:** Prior to zapping any device, ensure that it is not being used.

1. Check to see if the number of devices is less than the number of listed drives in the output from step 1.

    ```bash
    ncn-s# ceph orch device ls|grep dev|wc -l
    24
    ```

    If the numbers are equal, but less than the `total_osds` calculated, then the `ceph-mgr` daemon may need to be failed in order to get a fresh inventory.

    ```bash
    ncn-s# ceph mgr fail $(ceph mgr dump | jq -r .active_name)
    ```

    Wait 5 minutes and then re-check `ceph orch device ls`. See if the drives are still showing as `Available`. If so, then proceed to the next step.

1. `ssh` to the host and look at `lsblk` output and check against the device from the above `ceph orch device ls`

    ```bash
    ncn-s# lsblk
    NAME                                                                                                 MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
    loop0                                                                                                   7:0    0   4.2G  1 loop  / run/    rootfsbase
    loop1                                                                                                  7:1    0    30G  0 loop
     └─live-overlay-pool                                                                                  254:8    0   300G  0 dm
    loop2                                                                                                  7:2    0   300G  0 loop
     └─live-overlay-pool                                                                                  254:8    0   300G  0 dm
    sda                                                                                                    8:0    0   1.8T  0 disk
     └─ceph--0a476f53--8b38--450d--8779--4e587402f8a8-osd--data--b620b7ef--184a--46d7--9a99--771239e7a323 254:7    0   1.8T  0 lvm
    ```

    * If it has an LVM volume like above, then it may be in use. In that case, do the option 2 check below to make sure that the drive can be wiped.

#### Option 2

1. Log into **each** `ncn-s` node and check for unused drives.

    ```bash
    ncn-s# cephadm shell -- ceph-volume inventory
    ```

    **IMPORTANT:** The `cephadm` command may output this warning `WARNING: The same type, major and minor should not be used for multiple devices.`. Ignore this warning.

    The field `available` would be `True` if Ceph sees the drive as empty and can
    be used. For example:

    ```text
    Device Path               Size         rotates available Model name
    /dev/sda                  447.13 GB    False   False     SAMSUNG MZ7LH480
    /dev/sdb                  447.13 GB    False   False     SAMSUNG MZ7LH480
    /dev/sdc                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdd                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sde                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdf                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdg                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    /dev/sdh                  3.49 TB      False   False     SAMSUNG MZ7LH3T8
    ```

    Alternatively, just dump the paths of available drives:

    ```bash
    ncn-s# cephadm shell -- ceph-volume inventory --format json-pretty | jq -r '.[]|select(.available==true)|.path'
    ```

##### Wipe and add drives

1. Wipe the drive **ONLY after confirming that the drive is not being used by the current Ceph cluster** using options 1, 2, or both.

    > The following example wipes drive `/dev/sdc` on `ncn-s002`. Replace these values with the appropriate ones for the situation.

    ```bash
    ncn-s# ceph orch device zap ncn-s002 /dev/sdc --force
    ```

1. Add unused drives.

    ```bash
    ncn-s# cephadm shell -- ceph-volume lvm create --data /dev/sd<drive to add> --bluestore
    ```

More information can be found at [the `cephadm` reference page](../operations/utility_storage/Cephadm_Reference_Material.md).

<a name="configure_after_management_node_deployment"></a>

## 4. Configure after management node deployment

After the management nodes have been deployed, configuration can be applied to the booted nodes.

<a name="livecd-cluster-authentication"></a>

### 4.1 LiveCD cluster authentication

The LiveCD needs to authenticate with the cluster to facilitate the rest of the CSM installation.

1. Determine which master node is the first master node.

   Most often the first master node will be `ncn-m002`.

   Run the following commands on the PIT node to extract the value of the `first-master-hostname` field from the `/var/www/ephemeral/configs/data.json` file:

   ```bash
   pit# FM=$(cat /var/www/ephemeral/configs/data.json | jq -r '."Global"."meta-data"."first-master-hostname"')
   pit# echo $FM
   ```

1. Copy the Kubernetes configuration file from that node to the LiveCD to be able to use `kubectl` as cluster administrator.

   Run the following commands on the PIT node:

   ```bash
   pit# mkdir -v ~/.kube
   pit# scp ${FM}.nmn:/etc/kubernetes/admin.conf ~/.kube/config
   ```

1. Validate that `kubectl` commands run successfully from the PIT node.

    ```bash
    pit# kubectl get nodes -o wide
    ```

    Expected output looks similar to the following:

    ```text
    NAME       STATUS   ROLES                  AGE   VERSION    INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                  KERNEL-VERSION         CONTAINER-RUNTIME
    ncn-m002   Ready    control-plane,master   2h    v1.20.13   10.252.1.5    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-m003   Ready    control-plane,master   2h    v1.20.13   10.252.1.6    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w001   Ready    <none>                 2h    v1.20.13   10.252.1.7    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w002   Ready    <none>                 2h    v1.20.13   10.252.1.8    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w003   Ready    <none>                 2h    v1.20.13   10.252.1.9    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ```

<a name="install-tests"></a>

### 4.2 Install tests and test server on NCNs

Run the following commands on the PIT node.

```bash
pit# pushd /var/www/ephemeral && ${CSM_RELEASE}/lib/install-goss-tests.sh && popd
```

<a name="clean-up-chrony-configurations"></a>

### 4.3 Clean up chrony configurations

Run the following command without editing the value of the `TOKEN` variable.

```ShellSession
pit# for i in $(grep -oP 'ncn-\w\d+' /etc/dnsmasq.d/statics.conf | sort -u | grep -v ncn-m001); do 
       ssh $i "TOKEN=token /srv/cray/scripts/common/chrony/csm_ntp.py"; done
```

Successful output can appear as:

If BSS is unreachable, local cache is checked and the configuration is still deployed:

```text
...
BSS query failed. Checking local cache...
Chrony configuration created
Problematic config found: /etc/chrony.d/cray.conf.dist
Problematic config found: /etc/chrony.d/pool.conf
Restarted chronyd
...
```

<a name="validate_management_node_deployment"></a>

## 5. Validate management node deployment

The following `csi pit validate` commands will run a series of remote tests on the other nodes to validate they are healthy and configured correctly.

Observe the output of the checks. If there are any failures, remediate them.

1. Check the storage nodes.

   ```bash
   pit# csi pit validate --ceph | tee csi-pit-validate-ceph.log
   ```

   Once that command has finished, the following will extract the test totals reported for each node:

   ```bash
   pit# grep "Total Test" csi-pit-validate-ceph.log
   ```

   Example output for a system with three storage nodes:

   ```text
   Total Tests: 8, Total Passed: 8, Total Failed: 0, Total Execution Time: 74.3782 seconds
   Total Tests: 3, Total Passed: 3, Total Failed: 0, Total Execution Time: 0.6091 seconds
   Total Tests: 3, Total Passed: 3, Total Failed: 0, Total Execution Time: 0.6260 seconds
   ```

   If these total lines report any failed tests, then look through the full output of the test in `csi-pit-validate-ceph.log` to see which node had the failed test and what the details are for that test.

   **Note:** See [Utility Storage](../operations/utility_storage/Utility_Storage.md) and [Ceph CSI Troubleshooting](ceph_csi_troubleshooting.md) in order to help resolve any
   failed tests.

1. Check the master and worker nodes.

   **Note:** Throughout the output of the `csi pit validate` command are test totals for each node where the tests run. **Be sure to check
   all of them and not just the final one.** A `grep` command is provided to help with this.

   ```bash
   pit# csi pit validate --k8s | tee csi-pit-validate-k8s.log
   ```

   Once that command has finished, the following will extract the test totals reported for each node:

   ```bash
   pit# grep "Total Test" csi-pit-validate-k8s.log
   ```

   Example output for a system with five master and worker nodes (excluding the PIT node):

   ```text
   Total Tests: 16, Total Passed: 16, Total Failed: 0, Total Execution Time: 0.3072 seconds
   Total Tests: 16, Total Passed: 16, Total Failed: 0, Total Execution Time: 0.2727 seconds
   Total Tests: 12, Total Passed: 12, Total Failed: 0, Total Execution Time: 0.2841 seconds
   Total Tests: 12, Total Passed: 12, Total Failed: 0, Total Execution Time: 0.3622 seconds
   Total Tests: 12, Total Passed: 12, Total Failed: 0, Total Execution Time: 0.2353 seconds
   ```

   If these total lines report any failed tests, then look through the full output of the test in `csi-pit-validate-k8s.log` to see which node had the failed test and what the details are for that test.

   > **WARNING:** Notes on specific failures:
   >
   > * If any of the `FS Label` tests fail (they have names like `Master Node ETCDLVM FS Label` or `Worker Node CONLIB FS Label`),
   > then run manual tests on the node which reported the failure. See [Manual LVM Check Procedure](#manual-lvm-check-procedure). If the manual tests fail,
   > then the problem must be resolved before continuing to the next step. See [LVM Check Failure Recovery](#lvm-check-failure-recovery).
   > * If the `Weave Health` test fails, run `weave --local status connections` on the node where the test failed. If messages similar to
   > `IP allocation was seeded by different peers` are seen, then `weave` appears to be split-brained. At this point, it is necessary to wipe
   > the NCNs and start the PXE boot again:
   >    1. Wipe the NCNs using the 'Basic Wipe' section of [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md).
   >    1. Return to the 'Boot the **Storage Nodes**' step of [Deploy Management Nodes](#deploy_management_nodes) section above.

1. Verify that all the pods in the `kube-system` namespace are `Running` or `Completed`.

   Run the following command on any Kubernetes master or worker node, or the PIT node:

   ```bash
   ncn-mw/pit# kubectl get pods -o wide -n kube-system | grep -Ev '(Running|Completed)'
   ```

   If any pods are listed by this command, it means they are not in the `Running` or `Completed` state. Do not proceed before investigating this.

<a name="important-checkpoint"></a>

## Important checkpoint

Before proceeding, be aware that this is the last point where the other NCNs can be rebuilt without also having to rebuild the PIT node. Therefore, take time to double check both the cluster and the validation test results

<a name="next-topic"></a>

## Next topic

After completing the deployment of the management nodes, the next step is to install the CSM services.

See [Install CSM Services](index.md#install_csm_services)
