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

- An authentication token is required to access the API gateway and to use the `sat` command. For more information, see
  [Authenticate SAT Commands](../../operations/system_admin_toolkit/configuration/Authenticate_SAT_Commands.md).
- To avoid slow `sat` commands, ensure `/root/.bashrc` has proper handling of `kubectl` commands on all master and worker nodes. See [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md)

## Check health of the management cluster

1. To check the health and status of the management cluster before shutdown, see the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md).

1. Check the health and backup status of etcd clusters:

   1. Determine whether the etcd clusters are healthy.

      Review [Check the Health of etcd Clusters](../kubernetes/Check_the_Health_of_etcd_Clusters.md).

   1. Check the status of etcd cluster backups and make backups if missing.

      See [Backups for Etcd Clusters Running in Kubernetes](../kubernetes/Backups_for_Etcd_Clusters_Running_in_Kubernetes.md).

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
   Cray Programming Environment (CPE) filesystems should be unmounted.

   1. (`ncn-m001#`) Unmount the CPE content on the worker nodes.

      ```bash
      pdsh -w $WORKERS bash /etc/cray-pe.d/pe_cleanup.sh | dshbak -c
      ```

1. (`ncn-m001#`) Shut down platform services.

   > NOTE: There are some interactive questions which need answers before the shutdown process can progress.

   ```bash
   sat bootsys shutdown --stage platform-services
   ```

   The following example output shows warnings that may occur while stopping containers on
   Kubernetes nodes. When these warnings occur, the `sat bootsys` command will continue attempting
   to stop containers until all containers are stopped.

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
   All containers stopped on ncn-m001.
   All containers stopped on ncn-m003.
   All containers stopped on ncn-w003.
   All containers stopped on ncn-w002.
   WARNING: Some containers are still running after stop attempt on ncn-m002: ['f8a4d0ffe74588fcd4a6ab644cac62cc271df7681cea74173f28d66b5391873a']
   Retrying container stop procedure on ncn-m002
   WARNING: Some containers are still running after stop attempt on ncn-w001: ['21570acf6af066532bf80b2ece10c6808506f9672a03d24fd4f7e5a7775512bf', '5aebf6f06341327bbec581543e9812a20faac977fe45d870dffabf4d6f81a6c8', 'd1970d162b2f2e8f460fdba554f4aa5193c7450aa1dd0230272e18d3f6360177']
   Retrying container stop procedure on ncn-w001
   All containers stopped on ncn-m002.
   WARNING: Some containers are still running after stop attempt on ncn-w001: ['5aebf6f06341327bbec581543e9812a20faac977fe45d870dffabf4d6f81a6c8']
   Retrying container stop procedure on ncn-w001
   All containers stopped on ncn-w001.
   Executing step: Stop containerd on all Kubernetes NCNs.
   ```

1. (`ncn-m001#`) Unload DVS and `Lnet` kernel modules from worker nodes.

   > This step helps to avoid error messages in the console log while Linux is shutting down similar to "DVS: task XXX exiting on a signal"

   ```bash
   pdsh -w $WORKERS 'lsmod | egrep "^dvs\s+"; rm -rf /run/dvs; \
      echo quiesce / > /sys/fs/dvs/quiesce; modprobe -r dvs; sleep 5; \
      modprobe -r dvsipc dvsipc_lnet dvsproc; lsmod | egrep "^lnet\s"; \
      lsmod | egrep "^lustre\s"; systemctl stop lnet; lsmod | egrep "^lnet\s"'
   ```

1. (`ncn-m001#`) Shut down and power off all management NCNs except `ncn-m001`.

    This command requires input for the IPMI username and password for the management nodes.

    **Important:** The default timeout for the `sat bootsys shutdown --stage ncn-power` command is
    300 seconds. If it is known that the nodes take longer than this amount of time for a graceful
    shutdown, then a different value can be set using `--ncn-shutdown-timeout NCN_SHUTDOWN_TIMEOUT`
    with a value other than 300 for `NCN_SHUTDOWN_TIMEOUT`. Once this timeout has been exceeded, the
    command will prompt whether the node should be forcefully powered off.

   1. Shutdown management NCNs.

      > NOTE: There are some interactive questions which need answers before the shutdown process can progress.

      ```bash
      sat bootsys shutdown --stage ncn-power --ncn-shutdown-timeout 1200
      ```

      Example output when the command is successful:

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
      INFO: Successfully set next boot device to disk (Boot0014) for ncn-w001
      INFO: Successfully set next boot device to disk (Boot0012) for ncn-w002
      INFO: Successfully set next boot device to disk (Boot0014) for ncn-w003
      INFO: Starting console logging on ncn-w001,ncn-w002,ncn-w003.
      INFO: Shutting down worker NCNs: ncn-w001, ncn-w002, ncn-w003
      INFO: Executing command on host "ncn-w001": `shutdown -h now`
      INFO: Executing command on host "ncn-w002": `shutdown -h now`
      INFO: Executing command on host "ncn-w003": `shutdown -h now`
      INFO: Waiting up to 900 seconds for worker NCNs to shut down...
      INFO: Stopping console logging on ncn-w001,ncn-w002,ncn-w003,ncn-w004.
      INFO: Successfully set next boot device to disk (Boot0000) for ncn-m001
      INFO: Successfully set next boot device to disk (Boot0014) for ncn-m002
      INFO: Successfully set next boot device to disk (Boot000F) for ncn-m003
      INFO: Starting console logging on ncn-m002,ncn-m003.
      INFO: Shutting down manager NCNs: ncn-m002, ncn-m003
      INFO: Executing command on host "ncn-m002": `shutdown -h now`
      INFO: Executing command on host "ncn-m003": `shutdown -h now`
      INFO: Waiting up to 900 seconds for manager NCNs to shut down...
      INFO: Stopping console logging on ncn-m002,ncn-m003.
      INFO: Finding mounted RBD devices on ncn-m001
      INFO: Found no mounted RBD devices on ncn-m001
      INFO: Finding mounted Ceph or s3fs filesystems on ncn-m001
      INFO: Found 3 mounted Ceph or s3fs filesystems on ncn-m001
      INFO: Checking whether mounts are in use on ncn-m001
      INFO: Checking whether mount point /var/opt/cray/config-data is in use on ncn-m001
      INFO: Mount point /var/opt/cray/config-data is not in use on ncn-m001
      INFO: Checking whether mount point /etc/cray/upgrade/csm is in use on ncn-m001
      INFO: Mount point /etc/cray/upgrade/csm is not in use on ncn-m001
      INFO: Checking whether mount point /var/opt/cray/sdu/collection-mount is in use on ncn-m001
      INFO: Mount point /var/opt/cray/sdu/collection-mount is not in use on ncn-m001
      INFO: All mount points are not in use and ready to be unmounted
      INFO: Disabling cron job that ensures Ceph and s3fs filesystems are mounted on ncn-m001
      INFO: Successfully disabled cron job on ncn-m001
      INFO: Unmounting 3 filesystems on ncn-m001
      INFO: Unmounting /var/opt/cray/config-data on ncn-m001
      INFO: Successfully unmounted /var/opt/cray/config-data on ncn-m001
      INFO: Unmounting /etc/cray/upgrade/csm on ncn-m001
      INFO: Successfully unmounted /etc/cray/upgrade/csm on ncn-m001
      INFO: Unmounting /var/opt/cray/sdu/collection-mount on ncn-m001
      INFO: Successfully unmounted /var/opt/cray/sdu/collection-mount on ncn-m001
      INFO: Successfully unmounted 3 filesystems on ncn-m001
      INFO: Unmapping all RBD devices on ncn-m001
      INFO: Successfully unmapped all RBD devices on ncn-m001
      INFO: Successfully set next boot device to disk (Boot000F) for ncn-s001
      INFO: Successfully set next boot device to disk (Boot000F) for ncn-s002
      INFO: Successfully set next boot device to disk (Boot000F) for ncn-s003
      INFO: Freezing Ceph and shutting down storage NCNs: ncn-s001, ncn-s002, ncn-s003
      INFO: Checking Ceph health
      INFO: Freezing Ceph
      INFO: Running command: ceph osd set noout
      INFO: Command output: noout is set
      INFO: Running command: ceph osd set norecover
      INFO: Command output: norecover is set
      INFO: Running command: ceph osd set nobackfill
      INFO: Command output: nobackfill is set
      INFO: Ceph freeze completed successfully on storage NCNs.
      INFO: Starting console logging on ncn-s001,ncn-s002,ncn-s003.
      INFO: Executing command on host "ncn-s001": `shutdown -h now`
      INFO: Executing command on host "ncn-s002": `shutdown -h now`
      INFO: Executing command on host "ncn-s003": `shutdown -h now`
      INFO: Waiting up to 900 seconds for storage NCNs to shut down...
      INFO: Shutdown and power off of storage NCNs: ncn-s001, ncn-s002, ncn-s003
      INFO: Stopping console logging on ncn-s001,ncn-s002,ncn-s003.
      INFO: Shutdown and power off of all management NCNs complete.
      INFO: Succeeded with shutdown of other management NCNs.
      ```

      Manual intervention may be required in the above command if a timeout occurs while waiting for
      nodes to gracefully power down or if mount points provided by Ceph are in use. See the
      following sub-steps for how to proceed in either of those cases.

      1. If any nodes fail to reach a powered off state, log messages and a prompt like the
         following will be displayed:

         ```text
         ERROR: Waiting for condition "IPMI power off" timed out after 900 seconds
         WARNING: The following nodes did not complete a graceful shutdown within the timeout: ncn-w003
         Do you want to forcibly power off the nodes that timedout? [yes,no]
         ```

         Enter 'yes' at the prompt if you wish to perform a hard power off of these nodes. See the
         next main step of the procedure for instructions on viewing console logs to see why the
         node is still shutting down. The following messages will be logged if the prompt is
         answered with 'yes':

         ```text
         INFO: Proceeding with hard power off.
         INFO: Sending IPMI power off command to host ncn-w004
         ```

      1. If any filesystems provided by Ceph are in use, the command will log a message like the
         following:

         ```text
         INFO: Mount point /etc/cray/upgrade/csm is in use by the following processes on ncn-m001:
         INFO: COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF     NODE NAME
         INFO: bash    560967 root  cwd    DIR 252,16     4096 63569921 /etc/cray/upgrade/csm
         Some filesystems to be unmounted remain in use. Please address this before continuing.
         Proceed with unmount of filesystems? [yes,no]
         ```

         The output of the `lsof` command is logged to help identify processes using the
         filesystem(s). Stop all usages of the identified filesystems, and then enter 'yes' to
         proceed with the next step of shutting down management NCNs. If 'no' is entered at the
         prompt, run the `sat bootsys` command again when the filesystems are no longer in use.

   1. (`ncn-m001#`) Monitor the consoles for each NCN.

      Use `tail` to monitor the log files in `/var/log/cray/console_logs` for each NCN. For example,
      to watch the console log for `ncn-w003`, use the following `tail` command:

      ```text
      tail -f /var/log/cray/console_logs/console-ncn-w003-mgmt.log
      ```

      Alternatively, attach to the screen session in which the `ipmitool sol activate` command is running. This allows for input to be provided on the console if needed.

      List the screen sessions:

      ```bash
      screen -ls
      ```

      Example output:

      ```text
      There are screens on:
      26552.SAT-console-ncn-w003-mgmt (Detached)
      26514.SAT-console-ncn-w002-mgmt (Detached)
      26444.SAT-console-ncn-w001-mgmt (Detached)
      ```

      Attach to a screen session as follows:

      ```bash
      screen -x 26552.SAT-console-ncn-w003-mgmt
      ```

      Detach from the screen session using `Ctrl + A` followed by `D`. This will leave the screen
      session running in detached mode. The `sat bootsys` command will automatically exit screen
      sessions when nodes have finished shutting down.

   1. Proceed with the next step to shut down `ncn-m001` only when the `sat bootsys shutdown --stage ncn-power`
      command has succeeded with the final messages:

      ```text
      INFO: Shutdown and power off of all management NCNs complete.
      INFO: Succeeded with shutdown of other management NCNs.
      ```

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
