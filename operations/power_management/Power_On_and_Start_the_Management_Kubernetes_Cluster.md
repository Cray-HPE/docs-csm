# Power On and Start the Management Kubernetes Cluster

Power on and start management services on the HPE Cray EX management Kubernetes cluster.

## Prerequisites

* All management rack PDUs are connected to facility power and facility power is ON.
* An authentication token is required to access the API gateway and to use the `sat` command. See the [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md) and "SAT Authentication" in the System Admin Tookit product stream documentation.

## Procedure

First run `sat bootsys boot --stage ncn-power` to power on and boot the management NCNs. Then the run `sat bootsys boot --stage platform-services` to start platform services on the system.

1. If necessary, power on the management cabinet CDU and chilled doors.

2. Set all management cabinet PDU circuit breakers to ON \(all cabinets that contain Kubernetes master nodes, worker nodes, or storage nodes\).

3. Power on the HPE Cray EX cabinets and standard rack cabinet PDUs.

    See [Power On Compute and IO Cabinets](Power_On_Compute_and_IO_Cabinets.md).

    Be sure that management switches in all racks and CDU cabinets are powered on and healthy.

4. From a remote system, start the Lustre file system, if it was stopped.

5. Activate the serial console window to ncn-m001.

    ```bash
    remote$ export USERNAME=root
    remote$ export IPMI_PASSWORD=changeme
    remote$ ipmitool -I lanplus -U $USERNAME -E -H NCN_M001_BMC_HOSTNAME sol activate
    ```

6. In a separate window, power on the master node 1 \(ncn-m001\) chassis using IPMI tool.

    ```bash
    remote$ ipmitool -I lanplus -U $USERNAME -E -H NCN_M001_BMC_HOSTNAME chassis power on
    ```

    Wait for the login prompt.

    If the m001 node boots into the PIT (ncn-m001-pit), [Set Boot Order](../../background/ncn_boot_workflow.md) to boot from disk, shutdown the PIT node and power cycle again to boot to into ncn-m001.

    ```bash
    ncn-m001-pit:~ # shutdown -h now
    
    remote$ ipmitool -I lanplus -U $USERNAME -E -H NCN_M001_BMC_HOSTNAME chassis power on
    ```

7. Wait for the ncn-m001 node to boot, then ping the node to check status.

    ```bash
    remote$ ping NCN_M001_HOSTNAME
    ```

8. Log in to ncn-m001 as root.

   ```bash
   remote$ ssh root@NCN_M001_HOSTNAME
   ```

### POWER ON ALL OTHER MANAGEMENT NCNs

1. Power on and boot other management NCNs.

   ```bash
   ncn-m001# sat bootsys boot --stage ncn-power
   ``` 

   Example output:

   ```
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

   Powering on NCNs and waiting up to 300 seconds for them to be reachable via SSH: ncn-m002, ncn-m003
   Waiting for condition "Hosts accessible via SSH" timed out after 300 seconds
   ERROR: Unable to reach the following NCNs via SSH after powering them on: ncn-m003, ncn-s002.. Troubleshoot the issue and then try again.
   ```

   In the preceding example, the SSH command to the NCN nodes timed out and reported `ERROR` messages. Iterate on the above step until you see `Succeeded with boot of other management NCNs.` Each iteration should get further in the process.

1. Use `tail` to monitor the log files in `/var/log/cray/console_logs` for each NCN.

    Alternately attach to the screen session \(screen sessions real time, but not saved\):

    ```bash
    ncn-m001# screen -ls
    ```

    Example output:

    ```
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

    ```
    ncn-m001# screen -x 26745.SAT-console-ncn-m003-mgmt
    ```

### VERIFY ACCESS TO LUSTRE FILE SYSTEM

1. Verify that the Lustre file system is available from the management cluster.

    **START KUBERNETES \(k8s\)**

1. Use `sat bootsys` to start the k8s cluster. Note that the default timeout
    for Ceph to become healthy is 600 seconds, which is excessive. To work
    around this issue, set the timeout to a more reasonable value like 60
    seconds using the `--ceph-timeout` option as shown below.

    ```bash
    ncn-m001# sat bootsys boot --stage platform-services --ceph-timeout 60
    ```

    Example output:

    ```
    The following Non-compute Nodes (NCNs) will be included in this operation:
    managers:
    - ncn-m001
    storage:
    - ncn-s001
    - ncn-s002
    - ncn-s003
    workers:
    - ncn-w001
    - ncn-w002
    - ncn-w003
    
    Are the above NCN groupings correct? [yes,no] yes
    ```

1. The previous step may fail with a message like the following:

    ```bash
    Executing step: Start inactive Ceph services, unfreeze Ceph cluster and wait for Ceph health.
    Waiting up to 60 seconds for Ceph to become healthy after unfreeze
    Waiting for condition "Ceph cluster in healthy state" timed out after 60 seconds
    ERROR: Fatal error in step "Start inactive Ceph services, unfreeze Ceph cluster and wait for Ceph health." of platform services start: Ceph is not healthy. Please correct Ceph health and try again.
    ```

    If a failure like the above occurs, see the info-level log messages for
    details about the Ceph health check failure. Depending on the configured log
    level for `sat`, the log messages may appear in stderr or only in the log
    file. For example:

    ```bash
    ncn-m001# grep "fatal Ceph health warnings" /var/log/cray/sat/sat.log | tail -n 1
    ```

    Example output:

    ```
    2021-08-04 17:28:21,945 - INFO - sat.cli.bootsys.ceph - Ceph is not healthy: The following fatal Ceph health warnings were found: POOL_NO_REDUNDANCY
    ```

    The particular Ceph health warning may vary. In this example, it is POOL\_NO\_REDUNDANCY. See
    [Manage Ceph Services](../utility_storage/Manage_Ceph_Services.md) for Ceph troubleshooting
    steps, which may include restarting Ceph services as described below for convenience.

    Verify that the Ceph services started.

    * If the ceph services did not start, then please see [Manage Ceph Services](../utility_storage/Manage_Ceph_Services.md)for instruction on starting ceph services.

    Once Ceph is healthy, repeat the previous step to finish starting the Kubernetes cluster.

1. Check the space available on the Ceph cluster.

    ```bash
    ncn-m001# ceph df
    ```

    Example output:

    ```
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

1. If `%USED` for any pool approaches 80% used, resolve the space issue.

    To resolve the space issue, see [Troubleshoot Ceph OSDs Reporting Full](../utility_storage/Troubleshoot_Ceph_OSDs_Reporting_Full.md).

1. Monitor the status of the management cluster and which pods are restarting as indicated by either a `Running` or `Completed` state.

    ```bash
    ncn-m001# kubectl get pods -A -o wide | grep -v -e Running -e Completed
    ```

    The pods and containers are normally restored in approximately 10 minutes.

    Because no containers are running, all pods first transition to an `Error` state. The error state indicates that their containers were stopped. The kubelet on each node restarts the containers for each pod. The `RESTARTS` column of the kubectl get pods -A command increments as each pod progresses through the restart sequence.

    If there are pods in the `MatchNodeSelector` state, delete these pods. Then verify that the pods restart and are in the `Running` state.

1. Check the status of the `slurmctld` and `slurmdbd` pods to determine if they are starting:

    ```bash
    ncn-m001# kubectl describe pod -n user -lapp=slurmctld
    ```

    ```bash
    ncn-m001# kubectl describe pod -n user -lapp=slurmdbd
    ```

    ```bash
    Events:
      Type     Reason                  Age                    From               Message
      ----     ------                  ----                   ----               -------
      Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod
    sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
    "314ca4285d0706ec3d76a9e953e412d4b0712da4d0cb8138162b53d807d07491": Multus: Err in tearing down failed
    plugins: Multus: error in invoke Delegate add - "macvlan": failed to allocate for range 0: no IP addresses available in range set: 10.252.2.4-10.252.2.4
      Warning  FailedCreatePodSandBox  29m                    kubelet, ncn-w001  Failed to create pod
    sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
    ...
    ```

    If the preceding error is displayed, then remove all files in the following directories on all worker nodes:

    * /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
    * /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf

1. Check that spire pods have started.

    ```bash
    ncn-m001# kubectl get pods -n spire -o wide | grep spire-jwks
    ```

    Example output:

    ```
    spire-jwks-6b97457548-gc7td    2/3  CrashLoopBackOff   9    23h   10.44.0.117  ncn-w002 <none>   <none>
    spire-jwks-6b97457548-jd7bd    2/3  CrashLoopBackOff   9    23h   10.36.0.123  ncn-w003 <none>   <none>
    spire-jwks-6b97457548-lvqmf    2/3  CrashLoopBackOff   9    23h   10.39.0.79   ncn-w001 <none>   <none>
    ```

1. If spire pods indicate `CrashLoopBackOff`, then restart the spire pods.

    ```bash
    ncn-m001# kubectl rollout restart -n spire deployment spire-jwks
    ```

1. Check if any pods are in CrashLoopBackOff due to errors connecting to vault. If so, restart the vault operator, the vault pods and finally the pod which is in CrashLoopBackOff. For example:

    1. Find the pods in CrashLoopBackOff.

        ```bash
        ncn-m001# kubectl get pods -A | grep CrashLoopBackOff
        ```

        Example output:

        ```
        services     cray-console-node-1        2/3     CrashLoopBackOff   206        6d21h
        ```

    2. View the logs for the pods in CrashLoopBackOff.

        ```bash
        ncn-m001# kubectl -n services logs cray-console-node-1 cray-console-node | grep "connection failure" | grep vault
        ```

        Example output:

        ```
        2021/08/26 16:39:28 Error: &api.ResponseError{HTTPMethod:"PUT", URL:"http://cray-vault.vault:8200/v1/auth/kubernetes/login", StatusCode:503, RawError:true, Errors:[]string{"upstream connect error or disconnect/reset before headers. reset reason: connection failure"}}
        panic: Error: &api.ResponseError{HTTPMethod:"PUT", URL:"http://cray-vault.vault:8200/v1/auth/kubernetes/login", StatusCode:503, RawError:true, Errors:[]string{"upstream connect error or disconnect/reset before headers. reset reason: connection failure"}}
        ```

    3. Restart the vault-operator.

        ```bash
        ncn-m001# kubectl delete pods -n vault -l app.kubernetes.io/name=vault-operator
        ```

    4. Wait for the cray-vault pods to restart with 5/5 Ready and Running.
        
        ```bash
        ncn-m001#  kubectl get pods -n vault -l app.kubernetes.io/name=vault-operator
        ```

        Example output:

        ```
        NAME                                  READY   STATUS    RESTARTS   AGE
        cray-vault-operator-69b4b6887-dfn2f   2/2     Running   2          1m
        ```

    5. Restart the pod(s).

        In this example, cray-console-node-1 is the pod.

        ```bash
        ncn-m001# kubectl delete pod cray-console-node-1 -n services
        ```

    6. Wait for the pod(s) to restart with 3/3 Ready and Running.

        In this example, cray-console-node-1 is the pod.

        ```
        ncn-m001# kubectl get pods -n services | grep  cray-console-node-1
        ```

        Example output:

        ```
        cray-console-node-1      3/3     Running            0          2m
        ```

1. Determine whether the cfs-state-reporter service is failing to start on each manager/master and worker NCN while trying to contact CFS.

    ```bash
    ncn-m001# pdsh -w ncn-m00[1-3],ncn-w00[1-3] systemctl status cfs-state-reporter
    ```

    Example output:

    ```
    ncn-w001:  cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
    ncn-w001:    Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: disabled)
    ncn-w001:    Active: activating (start) since Thu 2021-03-18 22:29:15 UTC; 21h ago
    ncn-w001:  Main PID: 5192 (python3)
    ncn-w001:     Tasks: 1
    ncn-w001:    CGroup: /system.slice/cfs-state-reporter.service
    ncn-w001:            └─5192 /usr/bin/python3 -m cfs.status_reporter
    ncn-w001:
    ncn-w001: Mar 19 19:33:19 ncn-w001 python3[5192]: Expecting value: line 1 column 1 (char 0)
    ncn-w001: Mar 19 19:33:49 ncn-w001 python3[5192]: Attempt 2482 of contacting CFS...
    ncn-w001: Mar 19 19:33:49 ncn-w001 python3[5192]: Unable to contact CFS to report component status: CFS returned a non-json response: Unauthorized Request
    ncn-w001: Mar 19 19:33:49 ncn-w001 python3[5192]: Expecting value: line 1 column 1 (char 0)
    ncn-w001: Mar 19 19:34:19 ncn-w001 python3[5192]: Attempt 2483 of contacting CFS...
    ncn-w001: Mar 19 19:34:20 ncn-w001 python3[5192]: Unable to contact CFS to report component status: CFS returned a non-json response: Unauthorized Request
    ncn-w001: Mar 19 19:34:20 ncn-w001 python3[5192]: Expecting value: line 1 column 1 (char 0)
    ncn-w001: Mar 19 19:34:50 ncn-w001 python3[5192]: Attempt 2484 of contacting CFS...
    ncn-w001: Mar 19 19:34:50 ncn-w001 python3[5192]: Unable to contact CFS to report component status: CFS returned a non-json response: Unauthorized Request
    ncn-w001: Mar 19 19:34:50 ncn-w001 python3[5192]: Expecting value: line 1 column 1 (char 0)
    pdsh@ncn-m001: ncn-w001: ssh exited with exit code 3
    ```

    1. On each NCN where cfs-state-reporter is stuck in "activating" as shown in the preceding error messages, restart the cfs-state-reporter service. For example:

        ```bash
        ncn-m001# systemctl restart cfs-state-reporter
        ```

    2. Check the status again.

        ```bash
        ncn-m001# pdsh -w ncn-m00[1-3],ncn-w00[1-3] systemctl status cfs-state-reporter
        ```

### VERIFY BGP PEERING SESSIONS

1. Check the status of the Border Gateway Protocol \(BGP\). For more information, see [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

1. Check the status and health of etcd clusters, see [Check the Health and Balance of etcd Clusters](../kubernetes/Check_the_Health_and_Balance_of_etcd_Clusters.md).

### CHECK CRON JOBS

1. Display all the k8s cron jobs.

    ```bash
    ncn-m001# kubectl get cronjobs.batch -A
    ```

    Example output:

    ```
    NAMESPACE     NAME                              SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    kube-system   kube-etcdbackup                   */10 * * * *   False     0        2d1h            29d
    operators     kube-etcd-defrag                  0 0 * * *      False     0        18h             29d
    operators     kube-etcd-defrag-cray-hbtd-etcd   0 */4 * * *    False     0        178m            29d
    operators     kube-etcd-periodic-backup-cron    0 * * * *      False     0        58m             29d
    services      cray-dns-unbound-manager          */3 * * * *    False     0        63s             18h
    services      hms-discovery                     */3 * * * *    False     1        63s             18h
    services      hms-postgresql-pruner             */5 * * * *    False     0        3m3s            18h
    services      sonar-sync                        */1 * * * *    False     0        63s             18h
    sma           sma-pgdb-cron                     10 4 * * *     False     0        14h             27d
    ```

    **Attention:** It is normal for the hms-discovery service to be suspended at this point if liquid-cooled cabinets have not been powered on. The hms-discovery service is un-suspended during the liquid-cooled cabinet power on procedure. Do not re-create the hms-discovery cron job at this point.

1. Check for cron jobs that have a `LAST SCHEDULE` time that is older than the `SCHEDULE` time. These cron jobs must be restarted.

1. Check any cron jobs in question for errors.

    ```bash
    ncn-m001# kubectl describe cronjobs.batch -n kube-system kube-etcdbackup | egrep -A 15 Events
    ```

    Example output:

    ```
    Events:
      Type     Reason            Age                      From                Message
      ----     ------            ----                     ----                -------
      Warning  FailedNeedsStart  4m15s (x15156 over 42h)  cronjob-controller  Cannot determine if job needs to be \
                                                                              started: too many missed start time (> 100). \
                                                                              Set or decrease .spec.startingDeadlineSeconds \
                                                                              or check clock skew
    ```

1. For any cron jobs producing errors, get the YAML representation of the cron job and edit the YAML file:

    ```bash
    ncn-m001# cd ~/k8s
    ncn-m001# kubectl get cronjobs.batch -n NAMESPACE CRON_JOB_NAME -o yaml > CRON_JOB_NAME-cronjob.yaml
    ncn-m001# vi CRON_JOB_NAME-cronjob.yaml
    ```

    1. Delete all lines that contain `uid:`.

    2. Delete the entire `status:` section including the `status` key.

    3. Save the file and quit the editor.

1. Delete the cron job.

    ```bash
    ncn-m001# kubectl delete -f CRON_JOB_NAME-cronjob.yaml
    ```

1. Apply the cron job.

    ```bash
    ncn-m001# kubectl apply -f CRON_JOB_NAME-cronjob.yaml
    ```

1. Verify that the cron job has been scheduled.

    ```bash
    ncn-m001# kubectl get cronjobs -n backups benji-k8s-backup-backups-namespace
    ```

    Example output:

    ```
    NAME                                 SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    kube-etcdbackup                      */10 * * * *  False     0        92s             29
    ```

### CHECK THE HSM INVENTORY STATUS OF NCNs

1. Use the `sat` command to check for management NCNs in an Off state.

    ```bash
    ncn-m001# sat status --filter role=management
    ```

    Example output:

    ```
    +----------------+------+----------+-------+---------+---------+------+-------+-------------+----------+
    | xname          | Type | NID      | State | Flag    | Enabled | Arch | Class | Role        | Net Type |
    +----------------+------+----------+-------+---------+---------+------+-------+-------------+----------+
    | x3000c0s10b0n0 | Node | 100001   | On    | OK      | True    | X86  | River | Management  | Sling    |
    | x3000c0s12b0n0 | Node | 100002   | Off   | OK      | True    | X86  | River | Management  | Sling    |
    | x3000c0s14b0n0 | Node | 100003   | On    | Warning | True    | X86  | River | Management  | Sling    |
    | x3000c0s16b0n0 | Node | 100004   | Ready | OK      | True    | X86  | River | Management  | Sling    |
    | x3000c0s18b0n0 | Node | 100005   | Ready | OK      | True    | X86  | River | Management  | Sling    |
    | x3000c0s20b0n0 | Node | 100006   | Off   | OK      | True    | X86  | River | Management  | Sling    |
    | x3000c0s22b0n0 | Node | 100007   | On    | OK      | True    | X86  | River | Management  | Sling    |
    | x3000c0s24b0n0 | Node | 100008   | On    | OK      | True    | X86  | River | Management  | Sling    |
    | x3000c0s26b0n0 | Node | 100009   | On    | OK      | True    | X86  | River | Management  | Sling    |

    ```

    **Attention:** When the NCNs are brought back online after a power outage or planned shutdown, `sat status` may report them as being Off.

1. If NCNs are listed as OFF, run a manual discovery of NCNs in the Off state.

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x3000c0s12b0,x3000c0s20b0
    ```

    Example output:

    ```
    [[results]]
    URI = "/hsm/v2/Inventory/DiscoveryStatus/0"
    ```

1. Check for NCN status.

    ```bash
    ncn-m001# sat status --filter Role=Management
    ```

    Example output:

    ```
    +----------------+------+--------+-------+------+---------+------+-------+------------+----------+
    | xname          | Type | NID    | State | Flag | Enabled | Arch | Class | Role       | Net Type |
    +----------------+------+--------+-------+------+---------+------+-------+------------+----------+
    | x3000c0s10b0n0 | Node | 100001 | On    | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s12b0n0 | Node | 100002 | On    | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s14b0n0 | Node | 100003 | On    | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s16b0n0 | Node | 100004 | Ready | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s18b0n0 | Node | 100005 | Ready | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s20b0n0 | Node | 100006 | On    | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s22b0n0 | Node | 100007 | On    | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s24b0n0 | Node | 100008 | On    | OK   | True    | X86  | River | Management | Sling    |
    | x3000c0s26b0n0 | Node | 100009 | On    | OK   | True    | X86  | River | Management | Sling    |
    +----------------+------+--------+-------+------+---------+------+-------+------------+----------+
    ```

1. To check the health and status of the management cluster after a power cycle, refer to the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md).

1. If NCNs must have access to Lustre, start the Lustre file system. See [Power On the External Lustre File System](Power_On_the_External_Lustre_File_System.md).
