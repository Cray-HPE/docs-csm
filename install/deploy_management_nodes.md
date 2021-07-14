# Deploy Management Nodes

The following procedure deploys Linux and Kubernetes software to the management NCNs.
Deployment of the nodes starts with booting the storage nodes followed by the master nodes
and worker nodes together.
After the operating system boots on each node, there are some configuration actions which
take place. Watching the console or the console log for certain nodes can help to understand
what happens and when. When the process completes for all nodes, the Ceph storage is
initialized and the Kubernetes cluster is created and ready for a workload. The PIT node
will join Kubernetes after it is rebooted later in
[Redeploy PIT Node](index.md#redeploy_pit_node).

<a name="timing-of-deployments"></a>
### Timing of Deployments

The timing of each set of boots varies based on hardware. Nodes from some manufacturers will
POST faster than others or vary based on BIOS setting. After powering a set of nodes on,
an administrator can expect a healthy boot session to take about 60 minutes depending on
the number of storage and worker nodes.

### Topics:

   1. [Prepare for Management Node Deployment](prepare_for_management_node_deployment)
      1. [Configure Bootstrap Registry to Proxy an Upstream Registry](#configure-bootstrap-registry-to-proxy-an-upstream-registry)
      1. [Tokens and IPMI Password](#tokens-and-ipmi-password)
      1. [Apply NCN Pre-Boot Workarounds](#apply-ncn-pre-boot-workarounds)
      1. [Ensure Time Is Accurate Before Deploying NCNs](#ensure-time-is-accurate-before-deploying-ncns)
   1. [Update Management Node Firmware](#update_management_node_firmware)
   1. [Deploy Management Nodes](#deploy_management_nodes)
      1. [Deploy Workflow](#deploy-workflow)
      1. [Deploy](#deploy)
      1. [Check for Unused Drives on Utility Storage Nodes](#check-for-unused-drives-on-utility-storage-nodes)
      1. [Apply NCN Post-Boot Workarounds](#apply-ncn-post-boot-workarounds)
   1. [Configure after Management Node Deployment](#configure_after_management_node_deployment)
      1. [LiveCD Cluster Authentication](#livecd-cluster-authentication)
      1. [BGP Routing](#bgp-routing)
      1. [Configure and Trim UEFI Entries](#configure-and-trim-uefi-entries)
      1. [Install Tests and Test Server on NCNs](#install-tests)
   1. [Validate Management Node Deployment](#validate_management_node_deployment)
      1. [Validation](#validation)
      1. [Optional Validation](#optional-validation)
   1. [Next Topic](#next-topic)

## Details

<a name="prepare_for_management_node_deployment"></a>
### 1. Prepare for Management Node Deployment

Preparation of the environment must be done before attempting to deploy the management nodes.

<a name="configure-bootstrap-registry-to-proxy-an-upstream-registry"></a>
#### 1.1 Configure Bootstrap Registry to Proxy an Upstream Registry

> **`INTERNAL USE`** -- This procedure to configure a bootstrap registry to proxy to an upstream registry is only relevant for HPE Cray internal systems.

> **`SKIP IF AIRGAP/OFFLINE`** - Do **NOT** reconfigure the bootstrap registry to proxy an upstream registry if performing an _airgap/offline_ install.

By default, the bootstrap registry is a `type: hosted` Nexus repository to
support _airgap/offline_ installs, which requires container images to be
imported prior to platform installation. However, it may be reconfigured to
proxy container images from an upstream registry in order to support _online_
installs as follows:

1. Stop Nexus:

    ```bash
    pit# systemctl stop nexus
    ```

1. Remove `nexus` container:

    ```bash
    pit# podman container exists nexus && podman container rm nexus
    ```

1. Remove `nexus-data` volume:

    ```bash
    pit# podman volume rm nexus-data
    ```

1. Add the corresponding URL to the `ExecStartPost` script in
    `/usr/lib/systemd/system/nexus.service`.

    > **`INTERNAL USE`** Cray internal systems may want to proxy to https://dtr.dev.cray.com as follows:
    >
    > ```bash
    > pit# URL=https://dtr.dev.cray.com
    > pit# sed -e "s,^\(ExecStartPost=/usr/sbin/nexus-setup.sh\).*$,\1 $URL," -i /usr/lib/systemd/system/nexus.service
    > ```

1. Restart Nexus

    ```bash
    pit# systemctl daemon-reload
    pit# systemctl start nexus
    ```

<a name="tokens-and-ipmi-password"></a>
#### 1.2 Tokens and IPMI Password

1. Define shell environment variables that will simplify later commands to deploy management nodes.

    **Notice** that one of them is the `IPMI_PASSWORD`. Replace `changeme` with the real root password for BMCs.

   ```bash
   pit# export mtoken='ncn-m(?!001)\w+-mgmt'
   pit# export stoken='ncn-s\w+-mgmt'
   pit# export wtoken='ncn-w\w+-mgmt'
   pit# export USERNAME=root
   pit# export IPMI_PASSWORD=changeme
   ```

   Throughout the guide, simple one-liners can be used to query status of expected nodes. If the shell or environment is terminated, these environment variables should be re-exported.

   Examples:

   Check power status of all NCNs.

   ```bash
   pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power status
   ```

   Power off all NCNs.

   ```bash
   pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
   ```

<a name="apply-ncn-pre-boot-workarounds"></a>
#### 1.3 Apply NCN Pre-Boot Workarounds

_There will be post-boot workarounds as well._

1. Check for workarounds in the `/opt/cray/csm/workarounds/before-ncn-boot` directory. If there are any workarounds in that directory, run those now. Each has its own instructions in their respective `README.md` files.

   If there is a workaround here, the output will look similar to the following.

   ```bash
   pit# ls /opt/cray/csm/workarounds/before-ncn-boot
   CASMINST-980
   ```

<a name="ensure-time-is-accurate-before-deploying-ncns"></a>
#### 1.4 Ensure Time Is Accurate Before Deploying NCNs

**NOTE**: If you wish to use a timezone other than UTC, instead of step 1 below, follow
[this procedure for setting a local timezone](../operations/configure_ntp_on_ncns.md#set-a-local-timezone), then
proceed to step 2.

1. Ensure that the PIT node has the current and correct time.

   The time can be inaccurate if the system has been powered off for a long time, or, for example, the CMOS was cleared on a Gigabyte node. See [Clear Gigabyte CMOS](clear_gigabyte_cmos.md).

   > This step should not be skipped

   Check the time on the PIT node to see whether it matches the current time:

   ```
   pit# date "+%Y-%m-%d %H:%M:%S.%6N%z"
   ```

   If the time is inaccurate, set the time manually.

   ```
   pit# timedatectl set-time "2019-11-15 00:00:00"
   ```

   Run the NTP script:

   ```
   pit# /root/bin/configure-ntp.sh
   ```

   This ensures that the PIT is configured with an accurate date/time, which will be properly propagated to the NCNs during boot.

1. Ensure the current time is set in BIOS for all management NCNs.

   > If each NCN is booted to the BIOS menu, you can check and set the current UTC time.


   ```bash
   pit# export USERNAME=root
   pit# export IPMI_PASSWORD=changeme
   ```

   Repeat the following process for each NCN.

   1. Start an IPMI console session to the NCN.

      ```bash
      pit# bmc=ncn-w001-mgmt  # Change this to be each node in turn.
      pit# conman -j $bmc
      ```

   1. Using another terminal to watch the console, boot the node to BIOS.

      ```bash
      pit# bmc=ncn-w001-mgmt  # Change this to be each node in turn.
      pit# ipmitool -I lanplus -U $USERNAME -E -H $bmc chassis bootdev bios
      pit# ipmitool -I lanplus -U $USERNAME -E -H $bmc chassis power off
      pit# sleep 10
      pit# ipmitool -I lanplus -U $USERNAME -E -H $bmc chassis power on
      ```

      > For HPE NCNs the above process will boot the nodes to their BIOS, but the menu is unavailable through conman as the node is booted into a graphical BIOS menu.
      >
      > To access the serial version of the BIOS setup. Perform the ipmitool steps above to boot the node. Then in conman press `ESC+9` key combination to when you
      > see the following messages in the console, this will open you to a menu that can be used to enter the BIOS via conman.
      >
      > ```
      > For access via BIOS Serial Console:
      > Press 'ESC+9' for System Utilities
      > Press 'ESC+0' for Intelligent Provisioning
      > Press 'ESC+!' for One-Time Boot Menu
      > Press 'ESC+@' for Network Boot
      > ```
      >
      > For HPE NCNs the date configuration menu can be found at the following path: `System Configuration -> BIOS/Platform Configuration (RBSU) -> Date and Time`
      >
      > Alternatively for HPE NCNs you can login to the BMC's web interface and access the HTML5 console for the node to interact with the graphical BIOS.
      > From the administrators own machine create a SSH tunnel (-L creates the tunnel, and -N prevents a shell and stubs the connection):
      >
      > ```bash
      > linux# bmc=ncn-w001-mgmt # Change this to be each node in turn.
      > linux# ssh -L 9443:$bmc:443 -N root@eniac-ncn-m001
      > ```
      > Opening a web browser to `https://localhost:9443` will give access to the BMC's web interface.

   1. When the node boots, you will be able to use the conman session to see the BIOS menu to check and set the time to current UTC time. The process varies depending on the vendor of the NCN.

   Repeat the above process for each NCN.

<a name="update_management_node_firmware"></a>
### 2. Update Management Node Firmware

The management nodes are expected to have certain minimum firmware installed for BMC, node BIOS, and PCIe card
firmware. Where possible, the firmware should be updated prior to install. Some firmware can be updated
during or after the installation, but it is better to meet the minimum NCN firmware requirement before starting.

1. Check these BIOS settings on management nodes.

   For setting each one, please refer to the vendor manuals for the system's inventory.

   > **`NOTE`** The table below declares desired settings; unlisted settings should remain at vendor-default. This table may be expanded as new settings are adjusted.

   | Common Name | Common Value | Memo | Menu Location
   | --- | --- | --- | --- |
   | Intel® Hyper-Threading (e.g. HT) | `Enabled` | Enables two-threads per physical core. | Within the Processor or the PCH Menu.
   | Intel® Virtualization Technology (e.g. VT-x, VT) and AMD Virtualization Technology (e.g. AMD-V)| `Enabled` | Enables Virtual Machine extensions. | Within the Processor or the PCH Menu.
   | PXE Retry Count | 1 or 2 (default: 1) | Attempts done on a single boot-menu option (note: 2 should be set for systems with unsolved network congestion). | Within the Networking Menu, and then under Network Boot.

   > **`NOTE`** **PCIe** options can be found in [PCIe : Setting Expected Values](switch_pxe_boot_from_onboard_nic_to_pcie.md#setting-expected-values).

1. Check for minimum NCN firmware versions and update them as needed,
   The firmware on the management nodes should be checked for compliance with the minimum version required
   and updated, if necessary, at this point.

   See [Update NCN Firmware](update_ncn_firmware.md).

   > **`WARNING:`** Gigabyte NCNs running BIOS version C20 can become unusable
   > when Shasta 1.5 is installed. This is a result of a bug in the Gigabyte
   > firmware. This bug has not been observed in BIOS version C17.
   >
   > A key symptom of this bug is that the NCN will not PXE boot and will instead
   > fall through to the boot menu, despite being configure to PXE boot. This
   > behavior will persist until the failing node's CMOS is cleared.

   * See [Clear Gigabyte CMOS](clear_gigabyte_cmos.md).

<a name="deploy_management_nodes"></a>
### 3. Deploy Management Nodes

Deployment of the nodes starts with booting the storage nodes first, then the master nodes and worker nodes together.
After the operating system boots on each node there are some configuration actions which take place. Watching the
console or the console log for certain nodes can help to understand what happens and when. When the process is complete
for all nodes, the Ceph storage will have been initialized and the Kubernetes cluster will be created ready for a workload.


<a name="deploy-workflow"></a>
##### 3.1 Deploy Workflow
The configuration workflow described here is intended to help understand the expected path for booting and configuring. See the actual steps below for the commands to deploy these management NCNs.

1. Start watching the consoles for ncn-s001 and at least one other storage node
1. Boot all storage nodes at the same time
    - The first storage node ncn-s001 will boot and then starts a loop as ceph-ansible configuration waits for all other storage nodes to boot
    - The other storage nodes boot and become passive. They will be fully configured when ceph-ansible runs to completion on ncn-s001
1. Once ncn-s001 notices that all other storage nodes have booted, ceph-ansible will begin Ceph configuration. This takes several minutes.
1. Once ceph-ansible has finished on ncn-s001, then ncn-s001 waits for ncn-m002 to create /etc/kubernetes/admin.conf.
1. Start watching the consoles for ncn-m002, ncn-m003 and at least one worker node
1. Boot master nodes (ncn-m002 and ncn-m003) and all worker nodes at the same time
    - The worker nodes will boot and wait for ncn-m002 to create the `/etc/cray/kubernetes/join-command-control-plane` so they can join Kubernetes
    - The third master node ncn-m003 boots and waits for ncn-m002 to create the `/etc/cray/kubernetes/join-command-control-plane` so it can join Kubernetes
    - The second master node ncn-m002 boots, runs the kubernetes-cloudinit.sh which will create /etc/kubernetes/admin.conf and /etc/cray/kubernetes/join-command-control-plan, then waits for the storage node to create etcd-backup-s3-credentials
1. Once ncn-s001 notices that ncn-m002 has created /etc/kubernetes/admin.conf, then ncn-s001 waits for any worker node to become available.
1. Once each worker node notices that ncn-m002 has created /etc/cray/kubernetes/join-command-control-plan, then it will join the Kubernetes cluster.  
    - Now ncn-s001 should notice this from any one of the worker nodes and move forward with creation of config maps and running the post-ceph playbooks (s3, OSD pools, quotas, etc.)
1. Once ncn-s001 creates etcd-backup-s3-credentials during the benji-backups role which is one of the last roles after Ceph has been set up, then ncn-m001 notices this and moves forward


<a name="deploy"></a>
##### 3.2 Deploy

1. Change the default root password and SSH keys
   > If you want to avoid using the default install root password and SSH keys for the NCNs, follow the
   > NCN image customization steps in [Change NCN Image Root Password and SSH Keys](../operations/change_ncn_image_root_password_and_ssh_keys.md)

   This step is **strongly encouraged** for external/site deployments.

1. Create boot directories for any NCN in DNS:
    > This will create folders for each host in `/var/www`, allowing each host to have their own unique set of artifacts; kernel, initrd, SquashFS, and `script.ipxe` bootscript.

    ```bash
    pit# /root/bin/set-sqfs-links.sh
    ```

1. Customize boot scripts for any out-of-baseline NCNs
    - **kubernetes-worker nodes** with more than 2 small disks need to make adjustments to [prevent bare-metal etcd creation](../background/ncn_mounts_and_file_systems.md#worker-nodes-with-etcd)
    - A brief overview of what is expected is here, in [disk plan of record / baseline](../background/ncn_mounts_and_file_systems.md#plan-of-record--baseline)

1. Set each node to always UEFI Network Boot, and ensure they are powered off

    ```bash
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=efiboot,persistent
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

    > Note: some BMCs will "flake" and ignore the bootorder setting by `ipmitool`. As a fallback, cloud-init will
    > correct the bootorder after NCNs complete their first boot. The first boot may need manual effort to set the boot order over the conman console. The NCN boot order is further explained in [NCN Boot Workflow](../background/ncn_boot_workflow.md).

1. Validate that the LiveCD is ready for installing NCNs
    Observe the output of the checks and note any failures, then remediate them.

    ```bash
    pit# csi pit validate --livecd-preflight
    ```

    > Note: If you are **not** on an internal HPE Cray system or if you are on an offline/airgapped system, then you can ignore any errors about not being able resolve arti.dev.cray.com

1. Print the consoles available to you:

    ```bash
    pit# conman -q
    ```

    Expected output looks similar to the following:

    ```
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

    > **`IMPORTANT`** This is the administrators _last chance_ to run [NCN pre-boot workarounds](#apply-ncn-pre-boot-workarounds).

    > **`NOTE`**: All consoles are located at `/var/log/conman/console*`

1. Boot the **Storage Nodes**

    **`Note`**: You can boot all the storage nodes at the same time, but we have had better success boot all storage nodes except ncn-s001.  then boot that node approximately 1 minute after the other nodes.

    1. Boot all storage nodes except ncn-s001:
    
        ```bash
        pit# grep -oP $stoken /etc/dnsmasq.d/statics.conf | grep -v "ncn-s001-" | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
        ```
    
    1. Wait 1 minute.
    
    1. Boot ncn-s001:
    
        ```bash
        pit# ipmitool -I lanplus -U $USERNAME -E -H ncn-s001-mgmt power on
        ```

1. Wait. Observe the installation through ncn-s001-mgmt's console:

    Print the console name
    ```bash
    pit# conman -q | grep s001
    ```

    Expected output looks similar to the following:
    ```
    ncn-s001-mgmt
    ```

    Then join the console:

    ```bash
    pit# conman -j ncn-s001-mgmt
    ```

    From there an administrator can witness console-output for the cloud-init scripts.

    **`NOTE`**: Watch the storage node consoles carefully for error messages. If any are seen, consult [Ceph-CSI Troubleshooting](ceph_csi_troubleshooting.md)

    **`NOTE`**: If the nodes have PXE boot issues (e.g. getting PXE errors, not pulling the ipxe.efi binary) see [PXE boot troubleshooting](pxe_boot_troubleshooting.md)

    **`NOTE`**: If other issues arise, such as cloud-init (e.g. NCNs come up to Linux with no hostname) see the CSM workarounds for fixes around mutual symptoms. If there is a workaround here, the output will look similar to the following.

      > ```bash
      > pit# ls /opt/cray/csm/workarounds/after-ncn-boot
      > ```
      > CASMINST-1093
      > ```

1. Wait for storage nodes before booting Kubernetes master nodes and worker nodes.

   **`NOTE`**: Once all storage nodes are up and the message "...sleeping 5 seconds until /etc/kubernetes/admin.conf" appears on the ncn-s001 console, it is safe to proceed with booting the **Kubernetes master nodes and worker nodes**

    ```bash
    pit# grep -oP "($mtoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
    ```

1.  Stop watching the console from ncn-s001.

    Type the ampersand character and then the period character to exit from the conman session on ncn-s001.
    ```
    &.
    pit#
    ```

1.  Wait. Observe the installation through ncn-m002-mgmt's console:

    Print the console name
    ```bash
    pit# conman -q | grep m002
    ```

    Expected output looks similar to the following:

    ```
    ncn-m002-mgmt
    ```

    Then join the console:

    ```bash
    pit# conman -j ncn-m002-mgmt
    ```

    **`NOTE`**: If the nodes have PXE boot issues (e.g. getting PXE errors, not pulling the ipxe.efi binary) see [PXE boot troubleshooting](pxe_boot_troubleshooting.md)

    **`NOTE`**: If one of the master nodes seems hung waiting for the storage nodes to create a secret, check the storage node consoles for error messages. If any are found, consult [CEPH CSI Troubleshooting](ceph_csi_troubleshooting.md)

    **`NOTE`**: If other issues arise, such as cloud-init (e.g. NCNs come up to Linux with no hostname) see the CSM workarounds for fixes around mutual symptoms. If there is a workaround here, the output will look similar to the following.

    > ```bash
    > pit# ls /opt/cray/csm/workarounds/after-ncn-boot
    > CASMINST-1093
    > ```

1. Refer to [timing of deployments](#timing-of-deployments). It should not take more than 60 minutes for the `kubectl get nodes` command to return output indicating that all the master nodes and worker nodes aside from the PIT node booted from the LiveCD are `Ready`:

    ```bash
    pit# ssh ncn-m002
    ncn-m002# kubectl get nodes -o wide
    ```

    Expected output looks similar to the following:

    ```
    NAME       STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                  KERNEL-VERSION         CONTAINER-RUNTIME
    ncn-m002   Ready    master   14m     v1.18.6   10.252.1.5    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
    ncn-m003   Ready    master   13m     v1.18.6   10.252.1.6    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
    ncn-w001   Ready    <none>   6m30s   v1.18.6   10.252.1.7    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
    ncn-w002   Ready    <none>   6m16s   v1.18.6   10.252.1.8    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
    ncn-w003   Ready    <none>   5m58s   v1.18.6   10.252.1.12   <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
    ```

1.  Stop watching the console from ncn-m002.

    Type the ampersand character and then the period character to exit from the conman session on ncn-m002.
    ```
    &.
    pit#
    ```

<a name="check-for-unused-drives-on-utility-storage-nodes"></a>
#### 3.3 Check for Unused Drives on Utility Storage Nodes

> **`IMPORTANT:`** Do the following if NCNs use Gigabyte hardware.

1. Log into **each** ncn-s node and check for unused drives

    ```bash
    ncn-s# cephadm shell -- ceph-volume inventory
    ```

    The field "available" would be true if Ceph sees the drive as empty and can
    be used, e.g.:

    ```
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

1. Add unused drives

    ```bash
    ncn-s# cephadm shell -- ceph-volume lvm create --data /dev/sd<drive to add>  --bluestore
    ```

More information can be found at [cephadm reference page](../upgrade/1.0/resource_material/common/cephadm-reference.md)

<a name="apply-ncn-post-boot-workarounds"></a>
#### 3.4 Apply NCN Post-Boot Workarounds

Check for workarounds in the `/opt/cray/csm/workarounds/after-ncn-boot` directory. If there are any workarounds in that directory, run those now. Instructions are in the `README` files.

If there is a workaround here, the output looks similar to the following:
```
pit# ls /opt/cray/csm/workarounds/after-ncn-boot
CASMINST-12345
```

<a name="configure_after_management_node_deployment"></a>
### 4. Configure after Management Node Deployment

After the management nodes have been deployed, configuration can be applied to the booted nodes.


<a name="livecd-cluster-authentication"></a>
#### 4.1 LiveCD Cluster Authentication

The LiveCD needs to authenticate with the cluster to facilitate the rest of the CSM installation.

1. Copy the Kubernetes config to the LiveCD to be able to use `kubectl` as cluster administrator.

   > This will always be whatever node is the `first-master-hostname` in your `/var/www/ephemeral/configs/data.json | jq` file. If you are provisioning your HPE Cray EX system from `ncn-m001` then you can expect to fetch these from `ncn-m002`.

   ```bash
   pit# mkdir -v ~/.kube
   pit# scp ncn-m002.nmn:/etc/kubernetes/admin.conf ~/.kube/config
   ```


<a name="bgp-routing"></a>
#### 4.2 BGP Routing

After the NCNs are booted, the BGP peers will need to be checked and updated if the neighbor IPs are incorrect on the switches. See the doc to [Check and Update BGP Neighbors](../operations/update_bgp_neighbors.md).

1. Make sure you clear the BGP sessions here.
   - Aruba:`clear bgp *`
   - Mellanox: `clear ip bgp all`

1. **`NOTE`**: At this point the peering sessions with the BGP neighbors should be in IDLE, CONNECT, or ACTIVE state and not ESTABLISHED state. This is because the MetalLB speaker pods have not been deployed yet. If the switch is an Aruba, you will have one peering session ESTABLISHED with the other switch. You should check that all of the neighbor IP addresses are correct.

1. If needed, the following helper scripts are available for the various switch types:

   ```bash
   pit# ls -1 /usr/bin/*peer*py
   ```

   Expected output looks similar to the following:

   ```
   /usr/bin/aruba_set_bgp_peers.py
   /usr/bin/mellanox_set_bgp_peers.py
   ```


<a name="configure-and-trim-uefi-entries"></a>
#### 4.3 Configure and Trim UEFI Entries

> **`IMPORTANT`** *The Boot-Order is set by cloud-init, however the current setting is still iterating. This manual step is required until further notice.*

1. Do the following two steps outlined in [Set Boot Order](../background/ncn_boot_workflow.md#set-boot-order)

   1. [Setting Order](../background/ncn_boot_workflow.md#setting-order)
   1. [Trimming Boot Order](../background/ncn_boot_workflow.md#trimming_boot_order)

<a name="install-tests"></a>
#### 4.4 Install Tests and Test Server on NCNs

    ```bash
    pit:/var/www/ephemeral# $CSM_RELEASE/lib/install-goss-tests.sh
    ```

<a name="validate_management_node_deployment"></a>
### 5. Validate Management Node Deployment

Do all of the validation steps. The optional validation steps are manual steps which could be skipped.

<a name="validation"></a>
#### 5.1 Validation

The following commands will run a series of remote tests on the other nodes to validate they are healthy and configured correctly.

Observe the output of the checks and note any failures, then remediate them.

1. Check Ceph

   ```bash
   pit# csi pit validate --ceph
   ```

   **`Note`**: Throughout the output there are multiple lines of test totals; be sure to check all of them and not just the final one.

   **`Note`**: Please refer to the **Utility Storage** section of the Admin guide to help resolve any failed tests.

1. Check Kubernetes

   ```bash
   pit# csi pit validate --k8s
   ```

   > **`WARNING`** if test failures for "/dev/sdc" are observed they should be discarded for a manual test:
   >
   > ```bash
   > # master nodes:
   > ncn# blkid -L ETCDLVM
   > # worker nodes:
   > ncn# blkid -L CONLIB
   > ncn# blkid -L CONRUN
   > ncn# blkid -L K8SLET
   > ```
   >
   > The test should be looking for the ephemeral disk, that disk is sometimes `/dev/sdc`. The name of the disk is a more accurate test, and is not prone to the random path change.

   > Note: If your shell terminal is not echoing your input after running this, type "reset" and press enter to recover.

1. Ensure that weave has not split-brained

   Run the following command on each member of the Kubernetes cluster (master nodes and worker nodes) to ensure that weave is operating as a single cluster:

   ```bash
   ncn# weave --local status connections  | grep failed
   ```
   If you see messages like **'IP allocation was seeded by different peers'** then weave looks to have split-brained. At this point it is necessary to wipe the ncns and start the PXE boot again:

   1. Wipe the ncns using the 'Basic Wipe' section of [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md).
   1. Return to the 'Boot the **Storage Nodes**' step of [Deploy Management Nodes](#deploy_management_nodes) section above.


<a name="optional-validation"></a>
#### 5.2 Optional Validation

   These tests are for sanity checking. These exist as software reaches maturity, or as tests are worked
   and added into the installation repertoire.

   All validation should be taken care of by the CSI validate commands. The following checks can be
   done for sanity-checking:

   **Important common issues should be checked by tests, new pains in these areas should entail requests for
   new tests.**

   1. Verify all nodes have joined the cluster
   1. Verify etcd is running outside Kubernetes on master nodes
   1. Verify that all the pods in the kube-system namespace are running
   1. Verify that the ceph-csi requirements are in place (see [Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md)

# Important Checkpoint

> Before you move on, this is the last point where you will be able to rebuild nodes without having to rebuild the PIT node. So take time to double check either the cluster or the validation test results**

<a name="next-topic"></a>
# Next Topic

   After completing the deployment of the management nodes, the next step is to install the CSM services.

   See [Install CSM Services](index.md#install_csm_services)
