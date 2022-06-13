# Deploy Management Nodes

The following procedure deploys Linux and Kubernetes software to the management NCNs.
Deployment of the nodes starts with booting the storage nodes followed by the master nodes
and worker nodes together.

After the operating system boots on each node, there are some configuration actions which
take place. Watching the console or the console log for certain nodes can help to understand
what happens and when. When the process completes for all nodes, the Ceph storage is
initialized and the Kubernetes cluster is created and ready for a workload. The PIT node
will join Kubernetes after it is rebooted later in
[Deploy Final NCN](README.md#4-deploy-final-ncn).

## Timing of deployments

The timing of each set of boots varies based on hardware. Nodes from some manufacturers will
POST faster than others or vary based on BIOS setting. After powering on a set of nodes,
an administrator can expect a healthy boot session to take about 60 minutes depending on
the number of storage and worker nodes.

## Topics

1. [Prepare for Management Node Deployment](#1-prepare-for-management-node-deployment)
    1. [Tokens and IPMI Password](#tokens-and-ipmi-password)
1. [BIOS Baseline](#2-bios-baseline)
1. [Deploy Management Nodes](#3-deploy-management-nodes)
    1. [Deploy Storage NCNs](#31-deploy-storage-ncns)
    1. [Deploy Kubernetes NCNs](#32-deploy-kubernetes-ncns)
    1. [Check LVM on Kubernetes NCNs](#33-check-lvm-on-kubernetes-ncns)
1. [Cleanup](#4-cleanup)
    1. [Install tests and test server on NCNs](#41-install-tests-and-test-server-on-ncns)
    1. [Remove the default NTP pool](#42-remove-the-default-ntp-pool)
1. [Validate management node deployment](#5-validate-deployment)
1. [Next topic](#next-topic)

## 1. Prepare for management node deployment

Preparation of the environment must be done before attempting to deploy the management nodes.

### Tokens and IPMI password

1. (`pit#`) Define shell environment variables that will simplify later commands to deploy management nodes.

   1. Set `IPMI_PASSWORD` to the root password for the NCN BMCs.

      > `read -s` is used to prevent the password from being written to the screen or the shell history.

      ```bash
      read -s IPMI_PASSWORD
      export IPMI_PASSWORD
      ```

   1. Set the remaining helper variables.

      > These values do not need to be altered from what is shown.

      ```bash
      mtoken='ncn-m(?!001)\w+-mgmt' ; stoken='ncn-s\w+-mgmt' ; wtoken='ncn-w\w+-mgmt' ; export USERNAME=$(whoami)
      ```

## 2. BIOS Baseline

> **`NOTE`** Regarding bare-metal HPE servers
> 
> Run `bios-baseline.sh` twice, run it immediately to ensure that DCMI/IPMI is enabled (enabling `ipmitool` usage with the the BMC).
>
> ```bash
> /root/bin/bios-baseline.sh
> ```
> 
> Then start at step 1 below.

1. (`pit#`) Check power status of all NCNs.

    ```bash
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power status
    ```

1. (`pit#`) Power off all NCNs.

    ```bash
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

1. (`pit#`) Clear CMOS; ensure default settings are applied to all NCNs.

   > **`NOTE`** Gigabyte Servers and Intel Servers should SKIP THIS STEP. Resetting the CMOS will:
   > - Disable Hyper-Threading® on Intel CPUs, there is no way to enable it remotely through CSM at this time.
   > - Disable VT-x, AMD-V, SVM, VT-d or AMD IOMMU for Virtualization, on both Gigabyte and Intel CPUs, there is no way to enable at this time.
   > Continue onto the next step to at least prepare the nodes for `bios-baseline.sh`. 

    ```bash
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev none options=clear-cmos
    ```

1. (`pit#`) Boot NCNs to BIOS to allow the CMOS to reinitialize.

    ```bash
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev bios options=efiboot
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
    ```

1. (`pit#`) Run bios-baseline.sh

   > **`NOTE`** HPE servers in bare-metal will need to invoke this again at this time.

    ```bash
    /root/bin/bios-baseline.sh
    ```

1. (`pit#`) Power off the nodes

    ```bash
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

## 3. Deploy management nodes

Deployment of the nodes starts with booting the storage nodes first. Then, the master nodes and worker nodes should be booted together.
After the operating system boots on each node, there are some configuration actions which take place. Watching the
console or the console log for certain nodes can help to understand what happens and when. When the process is complete
for all nodes, the Ceph storage will have been initialized and the Kubernetes cluster will be created ready for a workload.

1. (`pit#`) Set the default root password and SSH keys and optionally change the timezone.

   > **`NOTE`** The management nodes images do not contain a default password or default SSH keys.
   > If this step is skipped and the nodes are booted they will be inaccessible via console or SSH.
   > Until MTL-1288 is resolved, the nodes would have to be booted with the secure images built from this step, wiped, and then redeployed.

   It is **required** to set the default root password and SSH keys in the images used to boot the management nodes.
   Follow the NCN image customization steps in [Change NCN Image Root Password and SSH Keys on PIT Node](../operations/security_and_authentication/Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md)

1. (`pit#`) Create boot directories for any NCN in DNS.

    > **`NOTE`** This script also sets the BMCs to DHCP. This script only sets up boot directories 
    > for nodes that appear in `/var/lib/misc/dnsmasq.leases`. Since nodes may take a few seconds
    > to DHCP after switching from their old, static IPs, it is advised to run this twice when 
    > reinstalling a system.

    ```bash
    /root/bin/set-sqfs-links.sh
    ```

1. (`pit#`) Customize boot scripts for any out-of-baseline NCNs

    - See the [Plan of Record](../background/ncn_plan_of_record.md) and compare against your server's racked hardware.
    - If modifications are needed for the PCIe hardware, see [Customize PCIe Hardware](../operations/node_management/Customize_PCIe_Hardware.md).
    - If modifications for disk usage are necessary, see [Customize Disk Hardware](../operations/node_management/Customize_Disk_Hardware.md).
    - If any customizations were done, backup the new boot scripts for reinstallation in `/var/www/ncn-*/script.ipxe` (e.g. `tar -czvf $SYSTEM_NAME-boot-scripts.tar.gz /var/www/ncn-*/script.ipxe`).

1. (`pit#`) Set each node to always UEFI Network Boot, and ensure they are powered off

    ```bash
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=efiboot,persistent
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

    > **`NOTE`** The NCN boot order is further explained in [NCN Boot Workflow](../background/ncn_boot_workflow.md).

### 3.1 Deploy Storage NCNs

1. (`pit#`) Boot the **Storage NCNs**

    ```bash
    grep -oP $stoken /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on; \
    ```

1. (`pit#`) Observe the installation through the console of `ncn-s001-mgmt`.

    ```bash
    conman -j ncn-s001-mgmt
    ```

    From there an administrator can witness console output for the `cloud-init` scripts.

    > **`NOTE`** Watch the storage node consoles carefully for error messages. If any are seen, consult [Ceph-CSI Troubleshooting](troubleshooting_ceph_csi.md).

    > **`NOTE`** If the nodes have PXE boot issues (for example, getting PXE errors, or not pulling the `ipxe.efi` binary), see [PXE boot troubleshooting](troubleshooting_pxe_boot.md).

1. (`pit#`) Wait for storage nodes to output the following before booting Kubernetes master nodes and worker nodes.

    ```text
    ...sleeping 5 seconds until /etc/kubernetes/admin.conf 
    ```

### 3.2 Deploy Kubernetes NCNs

1. (`pit#`) Boot the **Kuberenetes NCNs**

    ```bash
    grep -oP "($mtoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
    ```

1. (`pit#`) Either stop watching `ncn-s001-mgmt` or open a new window, start watching the the first kubernetes master's console.

    ```bash
    FM=$(cat /var/www/ephemeral/configs/data.json | jq -r '."Global"."meta-data"."first-master-hostname"')
    echo $FM
    conman -j ${FM}-mgmt
    ```

    > **`NOTE`** If the nodes have PXE boot issues (e.g. getting PXE errors, not pulling the ipxe.efi binary) see [PXE boot troubleshooting](troubleshooting_pxe_boot.md)

    > **`NOTE`** If one of the master nodes seems hung waiting for the storage nodes to create a secret, check the storage node consoles for error messages.
    If any are found, consult [CEPH CSI Troubleshooting](troubleshooting_ceph_csi.md)

1. (`pit#`) Wait for the deployment to finish, the following text should appear in the console:

    > **`NOTE`** The duration reported will vary.

    ```text
    The system is finally up, after 995.71 seconds cloud-init has come to completion.
    ```

    > **`NOTE`** All NCNs should report the above text when they've completed their ceph or kubernetes installation.

    ```bash
    ssh ncn-m002 kubectl get nodes -o wide
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

1. (`pit#`) Stop watching the consoles (exit the first master's console and ncn-s001's if it was left open).

    > **`NOTE`** To exit a conman console, press `&` followed by a `.` (e.g. keystroke `&.`)

    ```text
    &.
    pit#
    ```

1. (`pit#`) Copy the Kubernetes configuration file from that node to the LiveCD to be able to use `kubectl` as cluster administrator.

   Run the following commands on the PIT node:

   ```bash
   mkdir -v ~/.kube
   scp ${FM}.nmn:/etc/kubernetes/admin.conf ~/.kube/config
   ```

1. (`pit#`) Ensure the present working directory is the preperation directory.

   ```bash
   cd "${PITDATA}/prep"
   ```
   
1. (`pit#`) Check cabling by following the [SHCD check cabling guide](../operations/network/management_network/validate_cabling.md).

### 3.3 Check LVM on Kubernetes NCNs

Run the following command on the PIT node to validate that the expected LVM labels are present on disks on the master and worker nodes.

```bash
/usr/share/doc/csm/install/scripts/check_lvm.sh
```

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

If the check fails, stop and:

1. (`pit#`) Wipe the node(s) in question with [](./re-installation.md#wipe-disks-on-booted-nodes)
   
1. (`pit#`) Power cycle the node

    ```bash
    ipmitool -I lanplus -U $USERNAME -E -H <node-in-question> power reset    
    ```

If the check fails after doing the rebuild, contact CASM Triage for support.

## 4. Cleanup

### 4.1 Install tests and test server on NCNs

Run the following commands on the PIT node.

```bash
pushd /var/www/ephemeral && ${CSM_RELEASE}/lib/install-goss-tests.sh && popd
```

### 4.2 Remove the default NTP pool

Run the following command on the PIT node to remove the default pool, which can cause contention issues with NTP.

```bash
pdsh -b -S -w "$(grep -oP 'ncn-\w\d+' /etc/dnsmasq.d/statics.conf | grep -v m001 | sort -u |  tr -t '\n' ',')" \
        'sed -i "s/^! pool pool\.ntp\.org.*//" /etc/chrony.conf' && echo SUCCESS
```

Successful output is:

```text
SUCCESS
```

## 5. Validate Deployment

1. (`pit#`) Check the storage nodes.

   ```bash
   csi pit validate --ceph | tee csi-pit-validate-ceph.log
   ```

   Once that command has finished, the following will extract the test totals reported for each node:

   ```bash
   grep "Total Test" csi-pit-validate-ceph.log
   ```

   Example output for a system with three storage nodes:

   ```text
   Total Tests: 8, Total Passed: 8, Total Failed: 0, Total Execution Time: 74.3782 seconds
   Total Tests: 3, Total Passed: 3, Total Failed: 0, Total Execution Time: 0.6091 seconds
   Total Tests: 3, Total Passed: 3, Total Failed: 0, Total Execution Time: 0.6260 seconds
   ```

   If these total lines report any failed tests, then look through the full output of the test in `csi-pit-validate-ceph.log` to see which node had the failed test and what the details are for that test.

   > **`NOTE`** See [Utility Storage](../operations/utility_storage/Utility_Storage.md) and [Ceph CSI Troubleshooting](troubleshooting_ceph_csi.md) in order to help resolve any
   failed tests.

1. (`pit#`) Check the master and worker nodes.

   > **`NOTE`** Throughout the output of the `csi pit validate` command are test totals for each node where the tests run. **Be sure to check
   all of them and not just the final one.** A `grep` command is provided to help with this.

   ```bash
   csi pit validate --k8s | tee csi-pit-validate-k8s.log
   ```

   Once that command has finished, the following will extract the test totals reported for each node:

   ```bash
   grep "Total Test" csi-pit-validate-k8s.log
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

1. (`pit#`) Ensure that `weave` has not become split-brained.

   To ensure that `weave` is operating as a single cluster, run the following command on the PIT node to check each member of the Kubernetes cluster:

   ```bash
   pdsh -b -S -w "$(grep -oP 'ncn-[mw][0-9]{3}' /etc/dnsmasq.d/statics.conf | grep -v '^ncn-m001$' | sort -u |  tr -t '\n' ',')" \
           'weave --local status connections | grep -i failed || true'
   ```

### 5.2 Optional Validation

   1. Verify that all the pods in the `kube-system` namespace are `Running` or `Completed`.

      Run the following command on any Kubernetes master or worker node, or the PIT node:

      ```bash
      kubectl get pods -o wide -n kube-system | grep -Ev '(Running|Completed)'
      ```

      If any pods are listed by this command, it means they are not in the `Running` or `Completed` state. That needs to be investigated before proceeding.

   1. Verify that the ceph-csi requirements are in place.

      See [Ceph CSI Troubleshooting](troubleshooting_ceph_csi.md) for details.

## Next topic

After completing the deployment of the management nodes, the next step is to install the CSM services.

See [Install CSM Services](README.md#2-install-csm-services)
