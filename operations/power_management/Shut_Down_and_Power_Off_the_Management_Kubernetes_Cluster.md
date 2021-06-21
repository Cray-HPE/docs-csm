
## Shut Down and Power Off the Management Kubernetes Cluster

Shut down management services and power off the HPE Cray EX management Kubernetes cluster.

Be aware of the following concepts before powering off the management non-compute nodes \(NCNs\) for the Kubernetes cluster and storage:

-   The etcd cluster provides storage for the state of the management Kubernetes cluster. The three node etcd cluster runs on the same nodes that are configured as Kubernetes Master nodes. The management cluster state must be frozen when powering off the Kubernetes cluster. When one member is unavailable, the two other members continue to provide full access to the data. When two members are down, the remaining member will switch to only providing read-only access to the data.
-   **Avoid Unnecessary Data Movement with Ceph** - The Ceph cluster runs not only on the dedicated storage nodes, but also on the nodes configured as Kubernetes Master nodes. Specifically, the `mon` processes. If one of the storage nodes goes down, Ceph can rebalance the data onto the remaining nodes and object storage daemons \(OSDs\) to regain full protection.
-   **Avoid Spinning up Replacement Pods on Worker Nodes** - Kubernetes keeps all pods running on the management cluster. The `kubelet` process on each node retrieves information from the etcd cluster about what pods must be running. If a node becomes unavailable for more than five minutes, Kubernetes creates replacement pods on other management nodes.
-   **High-Speed Network \(HSN\)** - When the management cluster is shut down the HSN is also shut down.

The `sat bootsys` command automates the shutdown of Ceph and the Kubernetes management cluster and performs these tasks:

-   Stops etcd and which freezes the state of the Kubernetes cluster on each management node.
-   Stops **and disables** the kubelet on each management and worker node.
-   Stops all containers on each management and worker node.
-   Stop `containerd` on each management and worker node.
-   Stops ceph from rebalancing on the management node that is running a `mon` process.

### Prerequisites

An authentication token is required to access the API gateway and to use the `sat` command. See the [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md) and "SAT Authentication" in the SAT repository for more information.

### Procedure


**CHECK HEALTH OF THE MANAGEMENT CLUSTER**

1.  To check the health and status of the management cluster before shutdown, see the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md).

2.  To check the status of Border Gateway Protocol \(BGP\), refer to [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

3.  Check the health and backup etcd clusters:

    1.  Determine what etcd clusters must be backed up and if they are healthy. See [Check the Health and Balance of etcd Clusters](../kubernetes/Check_the_Health_and_Balance_of_etcd_Clusters.md).

    2.  Backup etcd clusters. See [Backups for etcd-operator Clusters](../kubernetes/Backups_for_etcd-operator_Clusters.md).

4. Check the status of NCN no wipe settings. Make sure `metal.no-wipe=1`. If a management NCN is set to `metal.no-wipe==wipe`, see [Check and Set the metal.no-wipe Setting on NCNs](../node_management/Check_and_Set_the_metalno-wipe_Setting_on_NCNs.md) before proceeding.

   ```bash
   ncn-m001# /opt/cray/platform-utils/getXnames.sh
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
   root@ncn-m001 2021-03-18 20:58:21 ~ #
   ```



**SHUT DOWN THE KUBERNETES MANAGEMENT CLUSTER**

7.  Shutdown platform services.

    ```bash
    ncn-m001# sat bootsys shutdown --stage platform-services
    Identified the following Non-compute Node (NCN) groups as follows.
    managers: ['ncn-m001', 'ncn-m002', 'ncn-m003']
    workers: ['ncn-w001', 'ncn-w002', 'ncn-w003']
    kubernetes: ['ncn-m001', 'ncn-m002', 'ncn-m003', 'ncn-w001', 'ncn-w002', 'ncn-w003']
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
    WARNING: Non-fatal error in step "Stop containers running under containerd on all Kubernetes NCNs." of platform services stop: Failed to stop containers on the following NCN
    (s): ncn-w001, ncn-w002, ncn-w003
    Continue with platform services stop? [yes,no] no
    Aborting.
    ```

    In the above example, the commands to stop containers timed out on all the worker nodes and reported `WARNING` and `ERROR` messages. A summary of the issue displays and the user to continue or stop. Respond `no` stop the shutdown. Then view the containers running on the nodes and stop them manually if necessary.

    ```bash
    ncn-m001# for ncn in ncn-w00{1,2,3}; do echo "$ncn"; ssh $ncn "crictl ps"; echo; done
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
    ncn-m001# sat bootsys shutdown --stage platform-services
    Identified the following Non-compute Node (NCN) groups as follows.
    managers: ['ncn-m001', 'ncn-m002', 'ncn-m003']
    workers: ['ncn-w001', 'ncn-w002', 'ncn-w003']
    kubernetes: ['ncn-m001', 'ncn-m002', 'ncn-m003', 'ncn-w001', 'ncn-w002', 'ncn-w003']
    Are the above NCN groupings correct? [yes,no] yes
    Executing step: Create etcd snapshot on all Kubernetes manager NCNs.
    WARNING: Failed to create etcd snapshot on ncn-m001: The etcd service is not active on ncn-m001 so a snapshot cannot be created.
    WARNING: Failed to create etcd snapshot on ncn-m002: The etcd service is not active on ncn-m002 so a snapshot cannot be created.
    WARNING: Failed to create etcd snapshot on ncn-m003: The etcd service is not active on ncn-m003 so a snapshot cannot be created.
    WARNING: Non-fatal error in step "Create etcd snapshot on all Kubernetes manager NCNs." of platform services stop: Failed to create etcd snapshot on hosts: ncn-m001, ncn-m00
    2, ncn-m003
    Continue with platform services stop? [yes,no] yes
    Continuing.
    Executing step: Stop etcd on all Kubernetes manager NCNs.
    Executing step: Stop and disable kubelet on all Kubernetes NCNs.
    Executing step: Stop containers running under containerd on all Kubernetes NCNs.
    Executing step: Stop containerd on all Kubernetes NCNs.
    Executing step: Check health of Ceph cluster and freeze state.
    ```

8.  Shut down and power off all management NCNs except ncn-m001.

    ```bash
    ncn-m001# sat bootsys shutdown --stage ncn-power
    ```

9.  Use `tail` to monitor the log files in /var/log/cray/console\_logs for each NCN.

    Alternately attach to the screen session \(screen sessions real time, but not saved\):

    ```bash
    ncn-m001# screen -ls
    There are screens on:
    26745.SAT-console-ncn-m003-mgmt (Detached)
    26706.SAT-console-ncn-m002-mgmt (Detached)
    26666.SAT-console-ncn-s003-mgmt (Detached)
    26627.SAT-console-ncn-s002-mgmt (Detached)
    26589.SAT-console-ncn-s001-mgmt (Detached)
    26552.SAT-console-ncn-w003-mgmt (Detached)
    26514.SAT-console-ncn-w002-mgmt (Detached)
    26444.SAT-console-ncn-w001-mgmt (Detached)
    
    ncn-m001# screen -x 26745.SAT-console-ncn-m003-mgmt
    ```

10. Use `ipmitool` to check the power off status of management nodes.

    ```bash
    ncn-m001# for h in ncn-w001 ncn-w002 ncn-w003 ncn-s001 ncn-s002 ncn-s003 ncn-m002 ncn-m003; \
     do echo -n "$h: "; ipmitool -U root -H ${h}-mgmt -P PASSWORD -I lanplus chassis power status; done
    ```

11. From a remote system, activate the serial console for ncn-m001.

    ```bash
    remote$ ipmitool -I lanplus -U root -P PASSWORD -H NCN-M001_BMC_HOSTNAME sol activate
    
    ncn-m001 login: root
    Password:
    ```
    
12. From the serial console, shut down Linux.

    ```bash
    ncn-m001# shutdown -h now
    ```

13. Wait until the console indicates that the node has shutdown.

14. From a remote system that has access to the management plane, use IPMItool to power off ncn-w001.

    ```bash
    remote$ ipmitool -I lanplus -U root -P initial0 -H NCN-M001_BMC_HOSTNAME chassis power status
    remote$ ipmitool -I lanplus -U root -P initial0 -H NCN-M001_BMC_HOSTNAME chassis power off
    remote$ ipmitool -I lanplus -U root -P initial0 -H NCN-M001_BMC_HOSTNAME chassis power status
    ```

    **CAUTION:** The modular coolant distribution unit \(MDCU\) in a liquid-cooled TDS cabinet typically receives power from its management cabinet PDUs. If the system includes a liquid-cooled TDS cabinet, **do not power off** the management cabinet PDUs, Powering off the MDCU will cause an emergency power off \(EPO\) of the TDS cabinet and may result in data loss or equipment damage.

15. Power off the PDU circuit breakers in the management cabinet.




