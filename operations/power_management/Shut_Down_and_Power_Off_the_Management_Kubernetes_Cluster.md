# Shut Down and Power Off the Management Kubernetes Cluster

Shut down management services and power off the HPE Cray EX management Kubernetes cluster.

**Important:** When performing a complete system shutdown, do NOT start with this page. Refer to [System Power Off Procedures](System_Power_Off_Procedures.md) for the expected shutdown sequence.

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Check health of the management cluster](#check-health-of-the-management-cluster)
- [Shut down the Kubernetes management cluster](#shut-down-the-kubernetes-management-cluster)
- [Next step](#next-step)

## Overview

Understand the following concepts before powering off the management non-compute nodes \(NCNs\) for the Kubernetes cluster and storage:

- The etcd cluster provides storage for the state of the management Kubernetes cluster. The three node etcd cluster runs on the same nodes that are configured as Kubernetes master nodes. The
  management cluster state must be frozen when powering off the Kubernetes cluster. When one member is unavailable, the two other members continue to provide full access to the data. When two
  members are down, the remaining member will switch to only providing read-only access to the data.
- **Avoid unnecessary data movement with Ceph**: The Ceph cluster runs not only on the dedicated storage nodes, but also on the nodes configured as Kubernetes master nodes. Specifically, the `mon`
  processes. If one of the storage nodes goes down, then Ceph can rebalance the data onto the remaining nodes and object storage daemons \(OSDs\) to regain full protection.
- **Avoid spinning up replacement pods on worker nodes**: Kubernetes keeps all pods running on the management cluster. The `kubelet` process on each node retrieves information from the etcd
  cluster about which pods must be running. If a node becomes unavailable for more than five minutes, then Kubernetes creates replacement pods on other management nodes.
- **High-Speed Network \(HSN\)**: When the management cluster is shut down the HSN is also shut down.

The `sat bootsys` command automates the shutdown of Ceph and the Kubernetes management cluster and performs these tasks:

- Stops `etcd` and which freezes the state of the Kubernetes cluster on each management node.
- Stops **and disables** the `kubelet` on each management and worker node.
- Stops all containers on each management and worker node.
- Stops `containerd` on each management and worker node.
- Stops Ceph from rebalancing on the management node that is running a `mon` process.

## Prerequisites

- An authentication token is required to access the API gateway and to use the `sat` command. See the "SAT Authentication" section of the HPE Cray EX System Admin Toolkit (SAT) product stream
documentation (`S-8031`) for instructions on how to acquire a SAT authentication token.
- To avoid slow `sat` commands, ensure `/root/.bashrc` has proper handling of `kubectl` commands on all master and worker nodes. See [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md)

## Check health of the management cluster

1. To check the health and status of the management cluster before shutdown, see the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md).

1. Check the health and backup status of etcd clusters:

   1. Determine whether the etcd clusters are healthy.

      Review [Check the Health and Balance of etcd Clusters](../kubernetes/Check_the_Health_and_Balance_of_etcd_Clusters.md).

   1. Check the status of etcd cluster backups and make backups if missing.

      See [Backups for etcd-operator Clusters](../kubernetes/Backups_for_etcd-operator_Clusters.md).

1. (`ncn-m001#`) Check the status of NCN no wipe settings.

   Make sure that `metal.no-wipe=1`. If any management NCNs do not have that set, then review
   [Check and Set the `metal.no-wipe` Setting on NCNs](../node_management/Check_and_Set_the_metalno-wipe_Setting_on_NCNs.md) before proceeding.

   ```bash
   /opt/cray/platform-utils/ncnGetXnames.sh
   ```

   Example output:

   ```text
                +++++ Get NCN Xnames +++++
   === Can be executed on any worker or master ncn node. ===
   === Executing on ncn-m001, Thu Mar 18 20:58:04 UTC 2021 ===
   === NCN node xnames and metal.no-wipe status ===
   === metal.no-wipe=1, expected setting - the client ===
   === already has the right partitions and a bootable ROM. ===
   === Requires CLI to be initialized ===
   === NCN Master nodes: ncn-m001 ncn-m002 ncn-m003 ===
   === NCN Worker nodes: ncn-w001 ncn-w002 ncn-w003 ===
   === NCN Storage nodes: ncn-s001 ncn-s002 ncn-s003 ===
   Thu Mar 18 20:58:06 UTC 2021
   ncn-m001: x3000c0s1b0n0 - metal.no-wipe=1
   ncn-m002: x3000c0s2b0n0 - metal.no-wipe=1
   ncn-m003: x3000c0s3b0n0 - metal.no-wipe=1
   ncn-w001: x3000c0s4b0n0 - metal.no-wipe=1
   ncn-w002: x3000c0s5b0n0 - metal.no-wipe=1
   ncn-w003: x3000c0s6b0n0 - metal.no-wipe=1
   ncn-s001: x3000c0s7b0n0 - metal.no-wipe=1
   ncn-s002: x3000c0s8b0n0 - metal.no-wipe=1
   ncn-s003: x3000c0s9b0n0 - metal.no-wipe=1
   ```

## Shut down the Kubernetes management cluster

1. (`ncn-m001#`) Set variables as comma-separated lists for the three types of management NCNs.

   ```bash
   MASTERS="ncn-m002,ncn-m003"; echo MASTERS=$MASTERS
   STORAGE=$(ceph orch host ls | grep ncn-s | awk '{print $1}' | xargs | sed 's/ /,/g'); echo STORAGE=$STORAGE
   WORKERS=$(kubectl get nodes | grep ncn-w | awk '{print $1}' | sort -u | xargs | sed 's/ /,/g'); echo WORKERS=$WORKERS
   ```

1. (`ncn-m001#`) Install tools that will help to find processes preventing filesystem unmounting.

   The `psmisc` rpm includes these tools: `fuser`, `killall`, `peekfd`, `prtstat`, `pslog`, `pstree`.

   ```bash
   pdsh -w ncn-m001,$MASTERS,$WORKERS 'zypper -n install psmisc'
   ```

1. If the worker nodes have been supporting the containerized User Access Instance (UAI) pods, then the DVS mounted
   Cray Programming Environment (CPE) and Analytics filesystems should be unmounted.

   1. (`ncn-m001#`) Unmount the CPE content on the worker nodes.

      ```bash
      pdsh -w $WORKERS bash /etc/cray-pe.d/pe_cleanup.sh | dshbak -c
      ```

   1. Unmount Analytics contents on the worker nodes.

      1. (`ncn-m001#`) Checkout analytics-config-management from VCS.

        > If the `git clone` command fails to find the `analytics-config-management` repository in VCS, then Analytics
        > is not installed and the rest of these steps can be ignored.

         ```bash
         export git_pwd=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
         export git_url="api-gw-service-nmn.local/vcs/cray/analytics-config-management.git"
         git clone https://crayvcs:"${git_pwd}"@${git_url} >/dev/null 2>&1
         ```

      1. (`ncn-m001#`) Copy the `forcecleanup.sh` script to all worker nodes.

         ```bash
         (cd analytics-config-management; git checkout integration; cd ..)
         pdcp -w $WORKERS -p analytics-config-management/roles/analyticsdeploy/files/forcecleanup.sh /tmp/forcecleanup.sh
         ```

      1. (`ncn-m001#`) Run the `forcecleanup.sh` script on all worker nodes.

         > Sometimes it takes a few runs of the `forcecleanup.sh` script to unmount the Analytics contents.

         ```bash
         pdsh -w $WORKERS sh /tmp/forcecleanup.sh| dshbak -c
         ```

      1. (`ncn-m001#`) Check that the Analytics content has been unmounted on all worker nodes.

         If this command returns output, then run the `forcecleanup.sh` command again.

         ```bash
         pdsh -w $WORKERS 'mount -t dvs | grep -i analytics'
         ```

      1. (`ncn-m001#`) Confirm that the `dvs` kernel module has a zero reference count on all worker nodes.
         If this is not the case, then investigate why the unmounts did not complete correctly.

         ```bash
         pdsh -w $WORKERS 'lsmod | grep -P "^dvs "' | dshbak -c
         ```

1. (`ncn-m001#`) Shut down platform services.

   > NOTE: There are some interactive questions which need answers before the shutdown process can progress.

   ```bash
   sat bootsys shutdown --stage platform-services
   ```

   Example output:

   ```text
   Proceed with stopping platform services? [yes,no] yes
   Proceeding with stopping platform services.
   The following Non-compute Nodes (NCNs) will be included in this operation:
   managers:
   - ncn-m001
   - ncn-m002
   - ncn-m003
   storage:
   - ncn-s001
   - ncn-s002
   - ncn-s003
   workers:
   - ncn-w001
   - ncn-w002
   - ncn-w003

   Are the above NCN groupings correct? [yes,no] yes

   Executing step: Create etcd snapshot on all Kubernetes manager NCNs.
   Executing step: Stop etcd on all Kubernetes manager NCNs.
   Executing step: Stop and disable kubelet on all Kubernetes NCNs.
   Executing step: Stop containers running under containerd on all Kubernetes NCNs.
   WARNING: One or more "crictl stop" commands timed out on ncn-w003
   WARNING: One or more "crictl stop" commands timed out on ncn-w002
   ERROR: Failed to stop 1 container(s) on ncn-w003. Execute "crictl ps -q" on the host to view running containers.
   ERROR: Failed to stop 2 container(s) on ncn-w002. Execute "crictl ps -q" on the host to view running containers.
   WARNING: One or more "crictl stop" commands timed out on ncn-w001
   ERROR: Failed to stop 4 container(s) on ncn-w001. Execute "crictl ps -q" on the host to view running containers.
   WARNING: Non-fatal error in step "Stop containers running under containerd on all Kubernetes NCNs." of platform services stop: Failed to stop containers on the following NCN(s): ncn-w001, ncn-w002, ncn-w003
   Continue with platform services stop? [yes,no] no
   Aborting.
   ```

   In the preceding example, the commands to stop containers timed out on all the worker nodes and reported `WARNING` and `ERROR` messages.
   A summary of the issue displays and prompts the user to continue or stop. Respond `no` to stop the shutdown. Then review the containers running on the nodes.

   ```bash
   for ncn in $(echo $WORKERS | sed 's/,/ /g'); do echo "${ncn}"; ssh "${ncn}" "crictl ps"; echo; done
   ```

   Example output:

   ```text
   ncn-w001
   CONTAINER         IMAGE             CREATED           STATE         NAME              ATTEMPT         POD ID
   032d69162ad24     302d9780da639     54 minutes ago    Running       cray-dhcp-kea     0               e4d1c01818a5a
   7ab8021279164     2ad3f16035f1f     3 hours ago       Running       log-forwarding    0               a5e89a366f5a3

   ncn-w002
   CONTAINER         IMAGE             CREATED           STATE         NAME              ATTEMPT         POD ID
   1ca9d9fb81829     de444b360808f     4 hours ago       Running       cray-uas-mgr      0               902287a6d0393

   ncn-w003
   CONTAINER         IMAGE             CREATED           STATE         NAME              ATTEMPT         POD ID
   ```

   Run the `sat` command again and enter `yes` at the prompt about the `etcd` snapshot not being created:

   ```bash
   sat bootsys shutdown --stage platform-services
   ```

   Example output:

   ```text
   The following Non-compute Nodes (NCNs) will be included in this operation:
   managers:
   - ncn-m001
   - ncn-m002
   - ncn-m003
   storage:
   - ncn-s001
   - ncn-s002
   - ncn-s003
   workers:
   - ncn-w001
   - ncn-w002
   - ncn-w003

   Are the above NCN groupings correct? [yes,no] yes

   Executing step: Create etcd snapshot on all Kubernetes manager NCNs.
   WARNING: Failed to create etcd snapshot on ncn-m001: The etcd service is not active on ncn-m001 so a snapshot cannot be created.
   WARNING: Failed to create etcd snapshot on ncn-m002: The etcd service is not active on ncn-m002 so a snapshot cannot be created.
   WARNING: Failed to create etcd snapshot on ncn-m003: The etcd service is not active on ncn-m003 so a snapshot cannot be created.
   WARNING: Non-fatal error in step "Create etcd snapshot on all Kubernetes manager NCNs." of platform services stop: Failed to create etcd snapshot on hosts: ncn-m001, ncn-m002, ncn-m003
   Continue with platform services stop? [yes,no] yes
   Continuing.
   Executing step: Stop etcd on all Kubernetes manager NCNs.
   Executing step: Stop and disable kubelet on all Kubernetes NCNs.
   Executing step: Stop containers running under containerd on all Kubernetes NCNs.
   Executing step: Stop containerd on all Kubernetes NCNs.
   Executing step: Check health of Ceph cluster and freeze state.
   ```

   If the process continues to report errors due to `Failed to stop containers`, then iterate on the above step. Each iteration should reduce the number of containers running. If necessary,
   containers can be manually stopped using `crictl stop CONTAINER`. If containers are stopped manually, then re-run the above procedure to complete any final steps in the process.

1. (`ncn-m001#`) Unload DVS and `Lnet` kernel modules from worker nodes.

   > This step helps to avoid error messages in the console log while Linux is shutting down similar to "DVS: task XXX exiting on a signal"

   ```bash
   pdsh -w $WORKERS 'lsmod | egrep "^dvs\s+"; rm -rf /run/dvs; \
      echo quiesce / > /sys/fs/dvs/quiesce; modprobe -r dvs; sleep 5; \
      modprobe -r dvsipc dvsipc_lnet dvsproc; lsmod | egrep "^lnet\s"; \
      lsmod | egrep "^lustre\s"; systemctl stop lnet; lsmod | egrep "^lnet\s"'
   ```

1. (`ncn-m001#`) Adjust boot order for management NCNs so the next boot will use disk.
   This ensures that when the node is powered up again it will boot from disk rather than attempting
   to PXE boot before the services to support that are available.

   ```bash
   pdsh -w ncn-m001,$MASTERS,$STORAGE,$WORKERS 'efibootmgr -n $(efibootmgr | grep "CRAY UEFI OS 0"| cut -c 5-8)' | dshbak -c
   ```

1. (`ncn-m001#`) Unmount `ceph` and `fuse.s3fs` filesystems from master and worker nodes.

   ```bash
   pdsh -w ncn-m001,$MASTERS,$WORKERS 'mount -t ceph|egrep -v kubelet; umount /etc/cray/upgrade/csm' | dshbak -c
   pdsh -w ncn-m001,$MASTERS 'mount -t fuse.s3fs |egrep -v kubelet; umount /var/opt/cray/sdu/collection-mount; umount  /var/opt/cray/config-data' | dshbak -c
   pdsh -w $WORKERS 'mount -t fuse.s3fs ; fusermount -u /var/lib/cps-local/boot-images;  umount  /var/lib/cps-local/boot-images; pkill s3fs' | dshbak -c 
   ```

1. (`ncn-m001#`) Shut down and power off all management NCNs except `ncn-m001`.

    This command requires input for the IPMI username and password for the management nodes.

    **Important:** The default timeout for the `sat bootsys shutdown --stage ncn-power` command is 300 seconds. If it is known that
    the nodes take longer than this amount of time for a graceful shutdown, then a different value
    can be set using `--ncn-shutdown-timeout NCN_SHUTDOWN_TIMEOUT` with a value other than 300
    for `NCN_SHUTDOWN_TIMEOUT`. Once this timeout has been exceeded, the node will be forcefully
    powered down.

   1. Shutdown management NCNs.

      > NOTE: There are some interactive questions which need answers before the shutdown process can progress.

      ```bash
      sat bootsys shutdown --stage ncn-power --ncn-shutdown-timeout 1200
      ```

      Example output:

      ```text
      Proceed with shutdown of other management NCNs? [yes,no] yes
      Proceeding with shutdown of other management NCNs.
      IPMI username: root
      IPMI password:
      The following Non-compute Nodes (NCNs) will be included in this operation:
      managers:
      - ncn-m002
      - ncn-m003
      storage:
      - ncn-s001
      - ncn-s002
      - ncn-s003
      workers:
      - ncn-w001
      - ncn-w002
      - ncn-w003

      The following Non-compute Nodes (NCNs) will be excluded from this operation:
      managers:
      - ncn-m001
      storage: []
      workers: []

      Are the above NCN groupings and exclusions correct? [yes,no] yes
      ```

   1. (`ncn-m001#`) Monitor the consoles for each NCN.

      Use `tail` to monitor the log files in `/var/log/cray/console_logs` for each NCN.

      Alternately attach to the screen session \(screen sessions real time, but not saved\):

      ```bash
      screen -ls
      ```

      Example output:

      ```text
      There are screens on:
      26745.SAT-console-ncn-m003-mgmt (Detached)
      26706.SAT-console-ncn-m002-mgmt (Detached)
      26666.SAT-console-ncn-s003-mgmt (Detached)
      26627.SAT-console-ncn-s002-mgmt (Detached)
      26589.SAT-console-ncn-s001-mgmt (Detached)
      26552.SAT-console-ncn-w003-mgmt (Detached)
      26514.SAT-console-ncn-w002-mgmt (Detached)
      26444.SAT-console-ncn-w001-mgmt (Detached)
      ```

      ```bash
      screen -x 26745.SAT-console-ncn-w003-mgmt
      ```

      > NOTE: There may be many messages like this in the console logs for worker nodes and master nodes.
      > There are no special actions to address these errors.
      >
      > Example console log output:
      >
      > ```bash
      > [76266.056108][T2394731] libceph: connect (1)100.96.129.14:6789 error -101
      > ```

   1. (`ncn-m001#`) Check the power off status of management NCNs.

       > NOTE: `read -s` is used to read the password in order to prevent it from being
       > echoed to the screen or preserved in the shell history.

       ```bash
       USERNAME=root
       read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
       ```

       ```bash
       export IPMI_PASSWORD
       for ncn in $(echo "$MASTERS,$STORAGE,$WORKERS" | sed 's/,/ /g'); do
           echo -n "${ncn}: "
           ipmitool -U "${USERNAME}" -H "${ncn}-mgmt" -E -I lanplus chassis power status
       done
       ```

1. (`external#`) From a remote system, activate the serial console for `ncn-m001`.

    ```bash
    USERNAME=root
    read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
    ```

    ```bash
    export IPMI_PASSWORD
    ipmitool -I lanplus -U "${USERNAME}" -E -H NCN-M001_BMC_HOSTNAME sol activate
    ```

1. (`ncn-m001#`) From the serial console of `ncn-m001`, shut down Linux.

    ```bash
    shutdown -h now
    ```

1. Wait until the console indicates that the node has shut down.

1. (`external#`) From a remote system that has access to the management plane, power off `ncn-m001`.

    ```bash
    ipmitool -I lanplus -U "${USERNAME}" -E -H NCN-M001_BMC_HOSTNAME chassis power status
    ipmitool -I lanplus -U "${USERNAME}" -E -H NCN-M001_BMC_HOSTNAME chassis power off
    ipmitool -I lanplus -U "${USERNAME}" -E -H NCN-M001_BMC_HOSTNAME chassis power status
    ```

1. (Optional) Power down Modular coolant distribution unit (MDCU) in a liquid-cooled HPE Cray EX20000 cabinet.

    **CAUTION:** The modular coolant distribution unit \(MDCU\) in a liquid-cooled HPE Cray EX2000 cabinet (also referred to as a Hill or TDS cabinet) typically receives power from its management
    cabinet PDUs. If the system includes an EX2000 cabinet, then **do not power off** the management cabinet PDUs. Powering off the MDCU will cause an emergency power off \(EPO\) of the cabinet and
    may result in data loss or equipment damage.

    1. (Optional) If a liquid-cooled EX2000 cabinet is not receiving MCDU power from this management cabinet, then power off the PDU circuit breakers or disconnect the PDUs from facility power and
   follow lock out/tag out procedures for the site.

## Next step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
