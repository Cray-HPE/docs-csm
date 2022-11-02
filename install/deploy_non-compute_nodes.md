# Deploy Management Nodes

The following procedure deploys Linux and Kubernetes software to the management NCNs.
Deployment of the nodes starts with booting the storage nodes, followed by the master nodes
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

1. [Prepare for management node deployment](#1-prepare-for-management-node-deployment)
    1. [Tokens and IPMI password](#11-tokens-and-ipmi-password)
    1. [BIOS baseline](#12-bios-baseline)
1. [Deploy management nodes](#2-deploy-management-nodes)
    1. [Deploy storage NCNs](#21-deploy-storage-ncns)
    1. [Deploy Kubernetes NCNs](#22-deploy-kubernetes-ncns)
    1. [Check LVM on Kubernetes NCNs](#23-check-lvm-on-kubernetes-ncns)
1. [Cleanup](#3-cleanup)
1. [Validate deployment](#4-validate-deployment)
1. [Next topic](#next-topic)

## 1. Prepare for management node deployment

Preparation of the environment must be done before attempting to deploy the management nodes.

### 1.1 Tokens and IPMI password

1. (`pit#`) Define shell environment variables that will simplify later commands to deploy management nodes.

   1. Set `USERNAME` and `IPMI_PASSWORD` to the credentials for the NCN BMCs.

      > `read -s` is used to prevent the password from being written to the screen or the shell history.

      ```bash
      USERNAME=root
      read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
      ```

   1. Set the remaining helper variables.

      > These values do not need to be altered from what is shown.

      ```bash
      export IPMI_PASSWORD ; mtoken='ncn-m(?!001)\w+-mgmt' ; stoken='ncn-s\w+-mgmt' ; wtoken='ncn-w\w+-mgmt'
      ```

### 1.2. BIOS baseline

1. (`pit#`) If the NCNs are HPE hardware, then ensure that DCMI/IPMI is enabled.

    This will enable `ipmitool` usage with the BMCs.

    ```bash
    /root/bin/bios-baseline.sh
    ```

1. (`pit#`) Check power status of all NCNs.

    ```bash
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power status
    ```

1. (`pit#`) Power off all NCNs.

    ```bash
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power off
    ```

1. (`pit#`) Clear CMOS; ensure default settings are applied to all NCNs.

   > **NOTE:** Gigabyte Servers and Intel Servers should SKIP THIS STEP.

   Resetting the CMOS will:

   - Disable Hyper-Threading® on Intel CPUs; there is no way to enable it remotely through CSM at this time.
   - Disable VT-x, AMD-V, SVM, VT-d, and AMD IOMMU for Virtualization, on both AMD and Intel CPUs; there is no way to enable at this time.

    ```bash
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} chassis bootdev none options=clear-cmos
    ```

1. (`pit#`) Boot NCNs to BIOS to allow the CMOS to reinitialize.

    ```bash
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} chassis bootdev bios options=efiboot
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power on
    ```

1. (`pit#`) Run `bios-baseline.sh`.

    > **NOTE:** For HPE servers, this should still be done, even though it was already run earlier in the procedure.

    ```bash
    /root/bin/bios-baseline.sh
    ```

1. (`pit#`) Power off the nodes.

    ```bash
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u |
          xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power off
    ```

## 2. Deploy management nodes

Deployment of the nodes starts with booting the storage nodes first. Then, the master nodes and worker nodes should be booted together.
After the operating system boots on each node, there are some configuration actions which take place. Watching the
console or the console log for certain nodes can help to understand what happens and when. When the process is complete
for all nodes, the Ceph storage will have been initialized and the Kubernetes cluster will be created ready for a workload.

1. (`pit#`) Customize boot scripts for any out-of-baseline NCNs if needed (see below).

    - See the [Plan of Record](../background/ncn_plan_of_record.md) and compare against the server's hardware.
    - If modifications are needed for the PCIe hardware, then see [Customize PCIe Hardware](../operations/node_management/Customize_PCIe_Hardware.md).
    - If modifications for disk usage are necessary, then see [Customize Disk Hardware](../operations/node_management/Customize_Disk_Hardware.md).
    - If any customizations were done, backup the new boot scripts for reinstallation in `/var/www/ncn-*/script.ipxe` (e.g. `tar -czvf $SYSTEM_NAME-boot-scripts.tar.gz /var/www/ncn-*/script.ipxe`).

1. (`pit#`) Set each node to always UEFI network boot, and ensure that they are powered off.

    ```bash
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} chassis bootdev pxe options=persistent
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} chassis bootdev pxe options=efiboot
    grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power off
    ```

    > **NOTE:** The NCN boot order is further explained in [NCN Boot Workflow](../background/ncn_boot_workflow.md).

### 2.1 Deploy storage NCNs

1. (`pit#`) Boot the **storage NCNs**.

    ```bash
    grep -oP "${stoken}" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power on 
    ```

1. (`pit#`) Observe the installation through the console of `ncn-s001-mgmt`.

    ```bash
    conman -j ncn-s001-mgmt
    ```

    From there, an administrator can witness console output for the `cloud-init` scripts.

    > **NOTES:**
    >
    > - Watch the storage node consoles carefully for error messages. If any are seen, consult [Ceph-CSI Troubleshooting](troubleshooting_ceph_csi.md).
    > - If the nodes have PXE boot issues (for example, getting PXE errors, or not pulling the `ipxe.efi` binary), then see [PXE boot troubleshooting](troubleshooting_pxe_boot.md).

1. (`pit#`) Wait for storage nodes to output the following before booting Kubernetes master nodes and worker nodes.

    ```text
    ...sleeping 5 seconds until /etc/kubernetes/admin.conf 
    ```

### 2.2 Deploy Kubernetes NCNs

1. (`pit#`) Boot the **Kubernetes NCNs**.

    ```bash
    grep -oP "(${mtoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power on
    ```

1. (`pit#`) Start watching the first Kubernetes master's console.

    Either stop watching `ncn-s001-mgmt` before doing this, or do it in a different window.

    > **NOTE:** To exit a conman console, press `&` followed by a `.` (e.g. keystroke `&.`)

    1. Determine the first Kubernetes master.

        ```bash
        FM=$(cat "${PITDATA}"/configs/data.json | jq -r '."Global"."meta-data"."first-master-hostname"')
        echo ${FM}
        ```

    1. Open its console.

        ```bash
        conman -j "${FM}-mgmt"
        ```

    > **NOTES:**
    >
    > - If the nodes have PXE boot issues (e.g. getting PXE errors, not pulling the `ipxe.efi` binary), then see [Troubleshooting PXE Boot](troubleshooting_pxe_boot.md).
    > - If one of the master nodes seems hung waiting for the storage nodes to create a secret, then check the storage node consoles for error messages.
    >   If any are found, then consult [CEPH CSI Troubleshooting](troubleshooting_ceph_csi.md).

1. (`pit#`) Wait for the deployment to finish.

    1. Wait for the first Kubernetes master to complete `cloud-init`.

        The following text should appear in the console of the first Kubernetes master:

        ```text
        The system is finally up, after 995.71 seconds cloud-init has come to completion.
        ```

        > **NOTES:**
        >
        > - The duration reported will vary.
        > - All NCNs should report the above text when they have completed their Ceph or Kubernetes installation.

    1. Validate that all master and worker NCNs (except for `ncn-m001`) show up in the cluster.

        > Enter the `root` password for the first Kubernetes master node, if prompted.

        ```bash
        ssh "${FM}" kubectl get nodes -o wide
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

1. (`pit#`) Stop watching the consoles.

    Exit the first master's console; also exit the console for `ncn-s001`, if it was left open.

    > **NOTE:** To exit a conman console, press `&` followed by a `.` (e.g. keystroke `&.`)

1. (`pit#`) Copy the Kubernetes configuration file from the first master node to the LiveCD.

   This will allow `kubectl` to work from the PIT node.

   ```bash
   mkdir -v ~/.kube
   scp "${FM}.nmn:/etc/kubernetes/admin.conf" ~/.kube/config
   ```

1. (`pit#`) Ensure that the working directory is the `prep` directory.

   ```bash
   cd "${PITDATA}/prep"
   ```

1. (`pit#`) Check cabling.

    See [SHCD check cabling guide](../operations/network/management_network/validate_cabling.md).

### 2.3 Check LVM on Kubernetes NCNs

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

1. (`pit#`) Power cycle the node

    ```bash
    ipmitool -I lanplus -U "${USERNAME}" -E -H <node-in-question> power reset    
    ```

If the check fails after doing the rebuild, contact support.

## 3. Cleanup

1. (`pit#`) Install tests and test server on NCNs.

    ```bash
    "${CSM_PATH}"/lib/install-goss-tests.sh
    ```

1. (`pit#`) Remove the default NTP pool.

    This removes the default pool, which can cause contention issues with NTP.

    ```bash
    pdsh -b -S -w "$(grep -oP 'ncn-\w\d+' /etc/dnsmasq.d/statics.conf | grep -v m001 | sort -u |  tr -t '\n' ',')" \
            'sed -i "s/^! pool pool\.ntp\.org.*//" /etc/chrony.conf' && echo SUCCESS
    ```

    Successful output is:

    ```text
    SUCCESS
    ```

## 4. Validate deployment

1. (`pit#`) Check the storage nodes.

    ```bash
    csi pit validate --ceph
    ```

    For assistance resolving failed tests, see the following pages:

    - [Ceph CSI Troubleshooting](troubleshooting_ceph_csi.md)
    - [Troubleshooting Unused Drives on Storage Nodes](troubleshooting_unused_drives_on_storage_nodes.md)
    - [Utility Storage](../operations/utility_storage/Utility_Storage.md)

1. (`pit#`) Check the master and worker nodes.

   ```bash
   csi pit validate --k8s
   ```

## Next topic

After completing the deployment of the management nodes, the next step is to install the CSM services.

See [Install CSM Services](README.md#2-install-csm-services).
