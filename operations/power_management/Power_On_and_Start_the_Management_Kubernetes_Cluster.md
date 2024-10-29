# Power On and Start the Management Kubernetes Cluster

Power on and start management services on the HPE Cray EX management Kubernetes cluster.

## Prerequisites

* All management rack PDUs are connected to facility power and facility power is on.
* An authentication token is required to access the API gateway and to use the `sat` command. For more information, see
  [Authenticate SAT Commands](../../operations/system_admin_toolkit/configuration/Authenticate_SAT_Commands.md).
* To avoid slow `sat` commands, ensure `/root/.bashrc` has proper handling of `kubectl` commands on all master and worker nodes. See [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md).

## Procedure

1. If necessary, power on the management cabinet CDU and chilled doors.

1. Set all management cabinet PDU circuit breakers to `ON` \(all cabinets that contain Kubernetes master nodes, worker nodes, or storage nodes\).

1. Power on the HPE Cray EX cabinet PDUs and standard rack cabinet PDUs.

    Be sure that management switches in all racks and CDU cabinets are powered on and healthy.

1. From a remote system, start the Lustre file system, if it was stopped.

1. (`remote#`) Activate the serial console window to `ncn-m001`.

    > `read -s` is used to prevent the password from being written to the screen or the shell history.

    ```bash
    USERNAME=root
    read -r -s -p "ncn-m001 BMC ${USERNAME} password: " IPMI_PASSWORD
    ```

    > In the example commands below, replace `NCN_M001_BMC_HOSTNAME` with the hostname of the BMC of `ncn-m001`.

    ```bash
    export IPMI_PASSWORD
    ipmitool -I lanplus -U $USERNAME -E -H NCN_M001_BMC_HOSTNAME sol activate
    ```

1. (`remote#`) In a separate window, power on the master node 1 \(`ncn-m001`\) chassis using IPMI tool.

    > `read -s` is used to prevent the password from being written to the screen or the shell history.

    ```bash
    USERNAME=root
    read -r -s -p "ncn-m001 BMC ${USERNAME} password: " IPMI_PASSWORD
    ```

    > In the example commands below, replace `NCN_M001_BMC_HOSTNAME` with the hostname of the BMC of `ncn-m001`.

    ```bash
    export IPMI_PASSWORD
    ipmitool -I lanplus -U $USERNAME -E -H NCN_M001_BMC_HOSTNAME chassis power on
    ```

    Wait for the login prompt.

    If `ncn-m001` boots into the PIT node, then perform the following procedure:

    1. Set boot order to boot from disk.

        See [NCN Boot Workflow](../../background/ncn_boot_workflow.md).

    1. (`pit#`) Shutdown the PIT node.

        ```bash
        shutdown -h now
        ```

    1. (`remote#`) Power cycle again to boot into `ncn-m001`.

         > In the example commands below, replace `NCN_M001_BMC_HOSTNAME` with the hostname of the BMC of `ncn-m001`.

        ```bash
        ipmitool -I lanplus -U "${USERNAME}" -E -H NCN_M001_BMC_HOSTNAME chassis power on
        ```

1. (`remote#`) Wait for `ncn-m001` to boot, then `ping` the node to check status.

    ```bash
    ping NCN_M001_HOSTNAME
    ```

1. (`remote#`) Log in to `ncn-m001` as `root`.

   ```bash
   ssh root@NCN_M001_HOSTNAME
   ```

   In case the node is not accessible directly, restart the network through console and try again.

   ```bash
   systemctl restart network
   ```

### Power on all other management NCNs

1. (`ncn-m001#`) Power on and boot other management NCNs.

    This command requires input for the IPMI username and password for the management nodes.

    **Important:** The default timeout for booting each group of NCNs is 300 seconds, which is reasonable for smaller systems.
    To avoid needing to re-run the command in the event of a timeout, increase the timeout using the `--ncn-boot-timeout` option.
    See `sat bootsys boot --help` for additional information and options.

   ```bash
   sat bootsys boot --stage ncn-power --ncn-boot-timeout 900
   ```

   Example output when the command is successful:

   ```text
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
   INFO: Starting console logging on ncn-s003,ncn-s001,ncn-w002,ncn-m003,ncn-m002,ncn-s002,ncn-w001,ncn-w003.
   INFO: Powering on NCNs and waiting up to 900 seconds for them to be reachable via SSH: ncn-s001, ncn-s002, ncn-s003
   INFO: Sending IPMI power on command to host ncn-s002
   INFO: Sending IPMI power on command to host ncn-s001
   INFO: Sending IPMI power on command to host ncn-s003
   INFO: Powered on NCNs: ncn-s001, ncn-s002, ncn-s003
   INFO: Unfreezing Ceph
   INFO: Running command: ceph osd unset noout
   INFO: Command output: noout is unset
   INFO: Running command: ceph osd unset norecover
   INFO: Command output: norecover is unset
   INFO: Running command: ceph osd unset nobackfill
   INFO: Command output: nobackfill is unset
   INFO: Waiting up to 60 seconds for Ceph to become healthy after unfreeze
   INFO: Checking Ceph health
   ...
   INFO: Ceph unfreeze completed successfully on storage NCNs.
   INFO: Checking whether ceph filesystem is mounted on /etc/cray/upgrade/csm.
   INFO: Mounting ceph filesystem on /etc/cray/upgrade/csm.
   INFO: Successfully mounted ceph filesystem on /etc/cray/upgrade/csm.
   INFO: Checking whether fuse.s3fs filesystem is mounted on /var/opt/cray/sdu/collection-mount.
   INFO: Mounting fuse.s3fs filesystem on /var/opt/cray/sdu/collection-mount.
   INFO: Successfully mounted fuse.s3fs filesystem on /var/opt/cray/sdu/collection-mount.
   INFO: Checking whether fuse.s3fs filesystem is mounted on /var/opt/cray/config-data.
   INFO: Mounting fuse.s3fs filesystem on /var/opt/cray/config-data.
   INFO: Successfully mounted fuse.s3fs filesystem on /var/opt/cray/config-data.
   INFO: Successfully restarted 'cray-sdu-rda' service on ncn-m001
   INFO: Powering on NCNs and waiting up to 900 seconds for them to be reachable via SSH: ncn-m002, ncn-m003,ncn-w001, ncn-w002, ncn-w003
   INFO: Sending IPMI power on command to host ncn-w001
   INFO: Sending IPMI power on command to host ncn-m002
   INFO: Sending IPMI power on command to host ncn-w003
   INFO: Sending IPMI power on command to host ncn-w002
   INFO: Sending IPMI power on command to host ncn-m003
   INFO: Powered on NCNs: ncn-m002, ncn-m003, ncn-w001, ncn-w002, ncn-w003
   INFO: Stopping console logging on ncn-s001,ncn-w001,ncn-m002,ncn-w003,ncn-s003,ncn-s002,ncn-w002,ncn-m003.
   INFO: Succeeded with boot of other management NCNs.
   ```

   The above command may fail either while waiting for a group of management NCNs to boot and become
   reachable or while waiting for Ceph to become healthy. See the following sub-steps for how to
   proceed in either of those cases.

   1. If any of the nodes time out during boot, an error message like the following will be logged:

      ```text
      ERROR: Waiting for condition "Hosts accessible via SSH" timed out after 300 seconds
      ERROR: Unable to reach the following NCNs via SSH after powering them on: ncn-s001, ncn-s002, ncn-s003. Troubleshoot the issue and then try again.
      ```

      If this error occurs, troubleshoot the issue and then repeat the `sat bootsys` command again.

   1. If Ceph does not become healthy within the expected time, the `sat bootsys` command will
      prompt whether to proceed further or exit to allow further troubleshooting of Ceph health
      issues. If the prompt is answered with 'yes', the command will continue to boot the other
      management nodes.

      Example output:

      ```text
      INFO: Checking Ceph health
      ERROR: Waiting for condition "Ceph cluster in healthy state" timed out after 60 seconds
      ERROR: Failed to unfreeze Ceph on storage NCNs: Ceph is not healthy. Please correct Ceph health and try again.
      Ceph is not healthy. Do you want to continue anyway? [yes,no] yes
      INFO: Continuing despite Ceph not being healthy as per user's input, make sure to verify it later.
      INFO: Checking whether ceph filesystem is mounted on /etc/cray/upgrade/csm.
      ```

      If the prompt is answered with 'no', the command will exit and allow the administrator to
      troubleshoot the Ceph health issues. Note that a Ceph status of `HEALTH_WARN` may resolve on
      its own if given time to recover. For further Ceph health troubleshooting procedures, see
      [Manage Ceph Services](../utility_storage/Manage_Ceph_Services.md). After troubleshooting the
      Ceph health issues, repeat the `sat bootsys` command.

1. (`ncn-m001#`) Monitor the consoles for each NCN while nodes are booting:

    Use `tail` to monitor the log files in `/var/log/cray/console_logs` for each NCN. For example,
    to watch the console log for `ncn-s001`, use the following `tail` command:

    ```text
    tail -f /var/log/cray/console_logs/console-ncn-s001-mgmt.log
    ```

    Alternatively, attach to the screen session in which the `ipmitool sol activate` command is running. This allows for input to be provided on the console if needed.

    List the screen sessions:

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

    Attach to a screen session as follows:

    ```bash
    screen -x 26589.SAT-console-ncn-s001-mgmt
    ```

    Detach from the screen session using `Ctrl + A` followed by `D`. This will leave the screen
    session running in detached mode. The `sat bootsys` command will automatically exit screen
    sessions when nodes have finished booting.

1. (`ncn-m001#`) Confirm all NCNs have booted.

    ```bash
     pdsh -w $(grep "nmn ncn-" /etc/hosts | awk '{print $3}' | xargs | sed 's/ /,/g') uptime
    ```

### Verify Access to External File Systems

If the worker nodes host User Access Instance (UAI) pods or normally mount the external Lustre or Spectrum Scale (GPFS) file systems,
then verify that the external file system is ready to be mounted by the worker nodes.

Some systems are configured with lazy mounts that do not have this requirement for the worker nodes.

### Start Kubernetes and other services

1. (`ncn-m001#`) Start the Kubernetes cluster.

    ```bash
    sat bootsys boot --stage platform-services
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
    INFO: Executing step: Ensure containerd is running and enabled on all Kubernetes NCNs.
    INFO: Executing step: Ensure etcd is running and enabled on all Kubernetes manager NCNs.
    INFO: Executing step: Start and enable kubelet on all Kubernetes NCNs.
    INFO: Waiting up to 300 seconds for the Kubernetes API to become available
    INFO: The Kubernetes API is currently unreachable.
    INFO: Kubernetes API is available
    ```

    If any errors occur, after troubleshooting and fixing the issue, be sure to run the `sat bootsys
    boot --stage platform-services` command again until it succeeds as shown above. This will ensure
    that all necessary steps are executed.

1. (`ncn-m001#`) Check the space available on the Ceph cluster.

    ```bash
    ceph df
    ```

    Example output:

    ```text
    RAW STORAGE:
        CLASS     SIZE       AVAIL      USED        RAW USED     %RAW USED
        ssd       63 TiB     60 TiB     2.8 TiB      2.8 TiB          4.45
        TOTAL     63 TiB     60 TiB     2.8 TiB      2.8 TiB          4.45

    POOLS:
        POOL                           ID     STORED      OBJECTS     USED        %USED     MAX AVAIL
        cephfs_data                     1      40 MiB         382     124 MiB         0        18 TiB
        cephfs_metadata                 2     262 MiB         117     787 MiB         0        18 TiB
        .rgw.root                       3     3.5 KiB           8     384 KiB         0        18 TiB
        default.rgw.buckets.data        4      71 GiB      27.07k     212 GiB      0.38        18 TiB
        default.rgw.control             5         0 B           8         0 B         0        18 TiB
        default.rgw.buckets.index       6     7.7 MiB          13     7.7 MiB         0        18 TiB
        default.rgw.meta                7      21 KiB         111     4.2 MiB         0        18 TiB
        default.rgw.log                 8         0 B         207         0 B         0        18 TiB
        kube                            9      67 GiB      26.57k     197 GiB      0.35        18 TiB
        smf                            10     806 GiB     271.69k     2.4 TiB      4.12        18 TiB
        default.rgw.buckets.non-ec     11         0 B           0         0 B         0        18 TiB
    ```

1. If `%USED` for any pool approaches 80% used, then resolve the space issue.

    To resolve the space issue, see [Troubleshoot Ceph OSDs Reporting Full](../utility_storage/Troubleshoot_Ceph_OSDs_Reporting_Full.md).

1. (`ncn-m001#`) Check that `spire` pods have started.

    Monitor the status of the `spire-jwks` pods to ensure they restart and enter the `Running` state.

    ```bash
    kubectl get pods -n spire -o wide | grep spire-jwks
    ```

    Example output:

    ```text
    spire-jwks-6b97457548-gc7td    2/3  CrashLoopBackOff   9    23h   10.44.0.117  ncn-w002 <none>   <none>
    spire-jwks-6b97457548-jd7bd    2/3  CrashLoopBackOff   9    23h   10.36.0.123  ncn-w003 <none>   <none>
    spire-jwks-6b97457548-lvqmf    2/3  CrashLoopBackOff   9    23h   10.39.0.79   ncn-w001 <none>   <none>
    ```

   1. (`ncn-m001#`) If the `spire-jwks` pods indicate `CrashLoopBackOff`, then restart the Spire deployment.

       ```bash
       kubectl rollout restart -n spire deployment spire-jwks
       ```

   1. (`ncn-m001#`) Rejoin Spire on the worker and master NCNs, to avoid issues with Spire tokens.

       ```bash
       kubectl rollout restart -n spire daemonset request-ncn-join-token
       kubectl rollout status -n spire daemonset request-ncn-join-token
       ```

   1. (`ncn-m001#`) Rejoin Spire on the storage NCNs, to avoid issues with Spire tokens.

       ```bash
       /opt/cray/platform-utils/spire/fix-spire-on-storage.sh
       ```

1. (`ncn-m001#`) Monitor the status of the management cluster and which pods are restarting (as indicated by either a `Running` or `Completed` state).

    ```bash
    kubectl get pods -A -o wide | grep -v -e Running -e Completed
    ```

    The pods and containers are normally restored in approximately 10 minutes.

    Because no containers are running, all pods first transition to an `Error` state. The error state indicates that their containers were stopped. The `kubelet` on each node
    restarts the containers for each pod. The `RESTARTS` column of the `kubectl get pods -A` command increments as each pod progresses through the restart sequence.

    If there are pods in the `MatchNodeSelector` state, delete these pods. Then verify that the pods restart and are in the `Running` state.

1. (`ncn-m001#`) Check the status of the `slurmctld` and `slurmdbd` pods to determine if they are starting:

    ```bash
    kubectl describe pod -n user -lapp=slurmctld
    kubectl describe pod -n user -lapp=slurmdbd
    ```

    An error similar to the following may be seen:

    ```text
    Events:
      Type     Reason                  Age                    From               Message
      ----     ------                  ----                   ----               -------
      Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod
    sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
    "314ca4285d0706ec3d76a9e953e412d4b0712da4d0cb8138162b53d807d07491": Multus: Err in tearing down failed
    plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
      Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod
    sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
    ```

    If the preceding error is displayed, then remove all files in the following directories on all worker nodes:

    * `/var/lib/cni/networks/macvlan-slurmctld-nmn-conf`
    * `/var/lib/cni/networks/macvlan-slurmdbd-nmn-conf`

1. (`ncn-m001#`) Check if any pods are in `CrashLoopBackOff` state because of errors connecting to Vault.

    If so, restart the Vault operator, then the Vault pods, and finally the pod which is in `CrashLoopBackOff`. For example:

    1. Find the pods that are in `CrashLoopBackOff` state.

        ```bash
        kubectl get pods -A | grep CrashLoopBackOff
        ```

        Example output:

        ```text
        services     cray-console-node-1        2/3     CrashLoopBackOff   206        6d21h
        ```

    1. View the logs for the pods in `CrashLoopBackOff`.

        ```bash
        kubectl -n services logs cray-console-node-1 cray-console-node | grep "connection failure" | grep vault
        ```

        Example output:

        ```text
        2021/08/26 16:39:28 Error: &api.ResponseError{HTTPMethod:"PUT", URL:"http://cray-vault.vault:8200/v1/auth/kubernetes/login", StatusCode:503, RawError:true, Errors:[]string{"upstream connect error or disconnect/reset before headers. reset reason: connection failure"}}
        panic: Error: &api.ResponseError{HTTPMethod:"PUT", URL:"http://cray-vault.vault:8200/v1/auth/kubernetes/login", StatusCode:503, RawError:true, Errors:[]string{"upstream connect error or disconnect/reset before headers. reset reason: connection failure"}}
        ```

    1. Restart the `vault-operator`.

        ```bash
        kubectl delete pods -n vault -l app.kubernetes.io/name=vault-operator
        ```

    1. Wait for the `cray-vault` pods to restart with `5/5` ready and `Running`.

        ```bash
        kubectl get pods -n vault -l app.kubernetes.io/name=vault-operator
        ```

        Example output:

        ```text
        NAME                                  READY   STATUS    RESTARTS   AGE
        cray-vault-operator-69b4b6887-dfn2f   2/2     Running   2          1m
        ```

    1. Restart the pods.

        In this example, `cray-console-node-1` is the only pod.

        ```bash
        kubectl delete pod cray-console-node-1 -n services
        ```

    1. Wait for the pods to restart with `3/3` ready and `Running`.

        In this example, `cray-console-node-1` is the only pod.

        ```bash
        kubectl get pods -n services | grep cray-console-node-1
        ```

        Example output:

        ```text
        cray-console-node-1      3/3     Running            0          2m
        ```

1. (`ncn-m001#`) Determine whether the `cfs-state-reporter` service is failing to start on each manager/master and worker NCN while trying to contact CFS.

    **Note:** The `systemctl` command run on each node may have `exit code 3` reported. This does not indicate a problem with `cfs-state-reporter` on that node.

    ```bash
    pdsh -w $(kubectl get nodes | grep -v NAME | awk '{print $1}' | xargs | sed 's/ /,/g') systemctl status cfs-state-reporter | grep "Active: activating"
    ```

    Example output:

    ```text
    pdsh@ncn-m001: ncn-m002: ssh exited with exit code 3
    pdsh@ncn-m001: ncn-m003: ssh exited with exit code 3
    pdsh@ncn-m001: ncn-w001: ssh exited with exit code 3
    pdsh@ncn-m001: ncn-w002: ssh exited with exit code 3
    pdsh@ncn-m001: ncn-w004: ssh exited with exit code 3
    pdsh@ncn-m001: ncn-w003: ssh exited with exit code 3
    pdsh@ncn-m001: ncn-m001: ssh exited with exit code 3
    ncn-w001:    Active: activating (start) since Thu 2021-03-18 22:29:15 UTC; 21h ago
    ```

    1. (`ncn#`) On each NCN where `cfs-state-reporter` is stuck in `activating` as shown in the preceding error messages, restart the `cfs-state-reporter` service.

        Do this by logging in to each affected NCN and running the following command:

        ```bash
        systemctl restart cfs-state-reporter
        ```

    1. (`ncn-m001#`) Check the status again.

        ```bash
        pdsh -w $(kubectl get nodes | grep -v NAME | awk '{print $1}' | xargs | sed 's/ /,/g') systemctl status cfs-state-reporter | grep "Active: activating"
        ```

### Verify BGP peering sessions

1. Check the status of the Border Gateway Protocol \(BGP\).

    See [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

### Check etcd status and health

1. Check the status and health of `etcd` clusters.

    See [Check the Health of etcd Clusters](../kubernetes/Check_the_Health_of_etcd_Clusters.md).

### Check `cronjobs`

The `sat bootsys boot --stage platform-services` command checks that all cronjobs
run on time according to their specified cron schedule. If a cronjob is not being scheduled on time,
it will be deleted and re-created to force it to be scheduled again. It is recommended to check that
all cronjobs are being scheduled on time after running `sat bootsys boot --stage platform-services`.

1. (`ncn-m001#`) Display all the Kubernetes `cronjobs`.

    ```bash
    kubectl get cronjobs.batch -A
    ```

    Example output:

    ```text
    NAMESPACE     NAME                              SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    kube-system   kube-etcdbackup                   */10 * * * *   False     0        2d1h            29d
    operators     kube-etcd-defrag                  0 0 * * *      False     0        18h             29d
    operators     kube-etcd-defrag-cray-hbtd-etcd   0 */4 * * *    False     0        178m            29d
    operators     kube-etcd-periodic-backup-cron    0 * * * *      False     0        58m             29d
    services      cray-dns-unbound-manager          */3 * * * *    False     0        63s             18h
    services      hms-discovery                     */3 * * * *    True      1        63s             18h
    services      hms-postgresql-pruner             */5 * * * *    False     0        3m3s            18h
    services      sonar-sync                        */1 * * * *    False     0        63s             18h
    sma           sma-pgdb-cron                     10 4 * * *     False     0        14h             27d
    ```

    **Attention:** It is normal for the `hms-discovery` service to be suspended at this point if liquid-cooled cabinets have not been powered on. The `hms-discovery` service is
    un-suspended during the liquid-cooled cabinet power on procedure. Do not recreate the `hms-discovery` `cronjob` at this point.

1. Check for `cronjobs` that have a `LAST SCHEDULE` time that is older than the `SCHEDULE` time. These `cronjobs` must be restarted.

1. (`ncn-m001#`) Check any `cronjobs` in question for errors.

    ```bash
    kubectl describe cronjobs.batch -n kube-system kube-etcdbackup | egrep -A 15 Events
    ```

    Example output:

    ```text
    Events:
      Type     Reason            Age                      From                Message
      ----     ------            ----                     ----                -------
      Warning  FailedNeedsStart  4m15s (x15156 over 42h)  cronjob-controller  Cannot determine if job needs to be \
                                                                              started: too many missed start time (> 100). \
                                                                              Set or decrease .spec.startingDeadlineSeconds \
                                                                              or check clock skew
    ```

1. (`ncn-m001#`) For any `cronjobs` producing errors, get the YAML representation of the `cronjob` and edit the YAML file:

    ```bash
    cd ~/k8s
    CRON_JOB_NAME=name-of-k8s-cron-job
    kubectl get cronjobs.batch -n NAMESPACE "${CRON_JOB_NAME}" -o yaml > "${CRON_JOB_NAME}-cronjob.yaml"
    vi "${CRON_JOB_NAME}-cronjob.yaml"
    ```

    1. Delete all lines that contain `uid:`.

    1. Delete the entire `status:` section, including the `status` key.

    1. Save the file and quit the editor.

1. (`ncn-m001#`) Delete the `cronjob`.

    ```bash
    kubectl delete -f "${CRON_JOB_NAME}-cronjob.yaml"
    ```

1. (`ncn-m001#`) Apply the `cronjob`.

    ```bash
    kubectl apply -f "${CRON_JOB_NAME}-cronjob.yaml"
    ```

1. (`ncn-m001#`) Verify that the `cronjob` has been scheduled.

    ```bash
    kubectl get cronjobs -n backups benji-k8s-backup-backups-namespace
    ```

    Example output:

    ```text
    NAME                                 SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    kube-etcdbackup                      */10 * * * *  False     0        92s             29
    ```

### Check the HSM inventory status of NCNs

1. (`ncn-m001#`) Use the `sat` command to check for management NCNs in an `Off` state.

    ```bash
    sat status --filter role=management --filter enabled=true --filter=state=off \
        --fields xname,aliases,state,flag,role,subrole
    ```

    Example output:

    ```text
    +----------------+----------+-------+------+------------+---------+
    | xname          | Aliases  | State | Flag | Role       | SubRole |
    +----------------+----------+-------+------+------------+---------+
    | x3000c0s13b0n0 | ncn-w004 | Off   | OK   | Management | Worker  |
    | x3000c0s25b0n0 | ncn-w005 | Off   | OK   | Management | Worker  |
    +----------------+----------+-------+------+------------+---------+
    ```

    **Attention:** When the NCNs are brought back online after a power outage or planned shutdown, `sat status` may report them as being `Off`.

1. (`ncn-m001#`) Run a manual discovery of any NCNs in the `Off` state.

    ```bash
    cray hsm inventory discover create --xnames x3000c0s12b0,x3000c0s20b0 --format toml
    ```

    Example output:

    ```toml
    [[results]]
    URI = "/hsm/v2/Inventory/DiscoveryStatus/0"
    ```

1. (`ncn-m001#`) Check for NCN status.

    ```bash
    sat status --filter role=management --filter enabled=true --fields xname,aliases,state,flag,role,subrole
    ```

    Example output:

    ```text
    +----------------+----------+-----------+------+------------+---------+
    | xname          | Aliases  | State     | Flag | Role       | SubRole |
    +----------------+----------+-----------+------+------------+---------+
    | x3000c0s1b0n0  | ncn-m001 | Populated | OK   | Management | Master  |
    | x3000c0s3b0n0  | ncn-m002 | Ready     | OK   | Management | Master  |
    | x3000c0s5b0n0  | ncn-m003 | Ready     | OK   | Management | Master  |
    | x3000c0s7b0n0  | ncn-w001 | Ready     | OK   | Management | Worker  |
    | x3000c0s9b0n0  | ncn-w002 | Ready     | OK   | Management | Worker  |
    | x3000c0s11b0n0 | ncn-w003 | Ready     | OK   | Management | Worker  |
    | x3000c0s13b0n0 | ncn-w004 | Ready     | OK   | Management | Worker  |
    | x3000c0s17b0n0 | ncn-s001 | Ready     | OK   | Management | Storage |
    | x3000c0s19b0n0 | ncn-s002 | Ready     | OK   | Management | Storage |
    | x3000c0s21b0n0 | ncn-s003 | Ready     | OK   | Management | Storage |
    | x3000c0s25b0n0 | ncn-w005 | Ready     | OK   | Management | Worker  |
    +----------------+----------+-----------+------+------------+---------+
    ```

### Validate CSM Health

1. To check the health and status of the management cluster after a power cycle, refer to the sections 1-4 in [Validate CSM Health](../validate_csm_health.md).

## Next step

Return to [System Power On Procedures](System_Power_On_Procedures.md) and continue with next step.
