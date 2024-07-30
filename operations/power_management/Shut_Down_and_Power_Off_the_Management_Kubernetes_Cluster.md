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

1. Check the health and backup etcd clusters:

   1. Determine which etcd clusters must be backed up and if they are healthy.

      Review [Check the Health of etcd Clusters](../kubernetes/Check_the_Health_of_etcd_Clusters.md).

   1. Backup etcd clusters.

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

1. (`ncn-m001#`) Shut down platform services.

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

1. (`ncn-m001#`) Shut down and power off all management NCNs except `ncn-m001`.

    This command requires input for the IPMI username and password for the management nodes.

    **Important:** The default timeout for the `sat bootsys shutdown --stage ncn-power` command is 300 seconds. If it is known that
    the nodes take longer than this amount of time for a graceful shutdown, then a different value
    can be set using `--ncn-shutdown-timeout NCN_SHUTDOWN_TIMEOUT` with a value other than 300
    for `NCN_SHUTDOWN_TIMEOUT`. Once this timeout has been exceeded, the node will be forcefully
    powered down.

   1. Shutdown management NCNs.

      ```bash
      sat bootsys shutdown --stage ncn-power --ncn-shutdown-timeout 900
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
