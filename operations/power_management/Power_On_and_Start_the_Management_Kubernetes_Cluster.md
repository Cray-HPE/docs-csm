

## Power On and Start the Management Kubernetes Cluster

Power on and start management services on the HPE Cray EX management Kubernetes cluster.

### Prerequisites

* All management rack PDUs are connected to facility power and facility power is ON.
* An authentication token is required to access the API gateway and to use the `sat` command. See the [System Security and Authentication](../security_and_authentication/System_Security_and_Authentication.md) and "SAT Authentication" in the SAT repository for more information.

### Procedure

First run `sat bootsys boot --stage ncn-power` to power on and boot the management NCNs. Then the run `sat bootsys boot --stage platform-services` to start platform services on the system.

1.  If necessary, power on the management cabinet CDU and chilled doors.

2.  Set all management cabinet PDU circuit breakers to ON \(all cabinets that contain Kubernetes master nodes, worker nodes, or storage nodes\).

3.  Power on the HPE Cray EX cabinets and standard rack cabinet PDUs.

    See [Power On Compute and IO Cabinets](Power_On_Compute_and_IO_Cabinets.md).

    Be sure that management switches in all racks and CDU cabinets are powered on and healthy.

4.  From a remote system, start the Lustre file system, if it was stopped.

5.  Activate the serial console window to ncn-m001.

    ```bash
    remote$ ipmitool -I lanplus -U root -P PASSWORD -H NCN_M001_BMC_HOSTNAME sol activate
    ```

6.  In a separate window, power on the master node 1 \(ncn-m001\) chassis using IPMI tool.

    ```bash
    remote$ ipmitool -I lanplus -U root -P PASSWORD -H NCN_M001_BMC_HOSTNAME chassis power on
    ```

    Wait for the login prompt.

7.  Wait for the ncn-m001 node to boot, then ping the node to check status.

    ```bash
    remote$ ping NCN_M001_HOSTNAME
    ```

8. Log in to ncn-m001 as root.

   ```bash
   remote$ ssh root@NCN_M001_HOSTNAME
   ```


**POWER ON ALL OTHER MANAGEMENT NCNs**

9.  Power on and boot other management NCNs.

    ```screen
    ncn-m001# sat bootsys boot --stage ncn-power
    ```

10. Use `tail` to monitor the log files in `/var/log/cray/console_logs` for each NCN.

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
**VERIFY ACCESS TO LUSTRE FILE SYSTEM**

11. Verify that the Lustre file system is available from the management cluster.
    
**CHECK STATUS OF THE MANAGEMENT CLUSTER**
    
12. If Ceph is frozen, use the following commands as workaround.

    ```bash
    ncn-m001# ceph osd unset noout
    noout is unset
    ncn-m001# ceph osd unset nobackfill
    nobackfill is unset
    ncn-m001# ceph osd unset norecover
    norecover is unset
    ```

13. Check Ceph status.

    ```bash
    ncn-m001# ceph -s
      cluster:
        id:     e6536923-2bf5-4fb1-b132-2532b4d01eae
        health: HEALTH_OK
     
      services:
        mon: 3 daemons, quorum ncn-s003,ncn-s002,ncn-s001 (age 12m)
        mgr: ncn-s002(active, since 12m), standbys: ncn-s001, ncn-s003
        mds: cephfs:1 {0=ncn-s003=up:active} 2 up:standby
        osd: 24 osds: 24 up (since 12m), 24 in (since 26h)
        rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)
     
      task status:
        scrub status:
            mds.ncn-s003: idle
     
      data:
        pools:   11 pools, 816 pgs
        objects: 25.93k objects, 40 GiB
        usage:   128 GiB used, 42 TiB / 42 TiB avail
        pgs:     816 active+clean
     
      io:
        recovery: 3.6 MiB/s, 1 objects/s
    ```

14. If Ceph does not recover and become healthy, refer to [Manage Ceph Services](../utility_storage/Manage_Ceph_Services.md).

    
**START KUBERNETES \(k8s\)**

15. Use `sat bootsys` to start the k8s cluster.

    ```bash
    ncn-m001# sat bootsys boot --stage platform-services 
    ```

16. If the previous step fails with the following, or similar message, restart Ceph services and wait for services to be healthy.

    ```bash
    Executing step: Check health of Ceph cluster and unfreeze state.
    ERROR: Ceph is not healthy. The following fatal Ceph health warnings were found: POOL_NO_REDUNDANCY
    ERROR: Fatal error in step "Check health of Ceph cluster and unfreeze state." of platform services start: Ceph is not healthy. Please correct Ceph health and try again.
    
    ```

    The warning message will vary. In this example, it is POOL\_NO\_REDUNDANCY. See [Manage Ceph Services](../utility_storage/Manage_Ceph_Services.md).

    From storage node ncn-s001, restart Ceph services.

    ```bash
    ncn-s001# ansible ceph_all -m shell -a "systemctl restart ceph-osd.target"
    ansible ceph_all -m shell -a "systemctl restart ceph-radosgw.target"
    ansible ceph_all -m shell -a "systemctl restart ceph-mon.target"
    ansible ceph_all -m shell -a "systemctl restart ceph-mgr.target"
    ansible ceph_all -m shell -a "systemctl restart ceph-mds.target"
    ```

17. Check the space available on the Ceph cluster.

    ```bash
    ncn-m001# ceph df
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

18. If `%USED` for any pool approaches 80% used, resolve the space issue.

    To resolve the space issue, see [Troubleshoot Ceph OSDs Reporting Full](../utility_storage/Troubleshoot_Ceph_OSDs_Reporting_Full.md).

19. Monitor the status of the management cluster and which pods are restarting as indicated by either a `Running` or `Completed` state.

    ```bash
    ncn-m001# kubectl get pods -A -o wide | grep -v -e Running -e Completed
    ```

    The pods and containers are normally restored in approximately 10 minutes.

    Because no containers are running, all pods first transition to an `Error` state. The error state indicates that their containers were stopped. The kubelet on each node restarts the containers for each pod. The `RESTARTS` column of the kubectl get pods -A command increments as each pod progresses through the restart sequence.

    If there are pods in the `MatchNodeSelector` state, delete these pods. Then verify that the pods restart and are in the `Running` state.

20. Check the status of the `slurmctld` and `slurmdbd` pods to determine if they are starting:

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
    
    -   /var/lib/cni/networks/macvlan-slurmctld-nmn-conf
    -   /var/lib/cni/networks/macvlan-slurmdbd-nmn-conf
    
21. Check that spire pods have started.

    ```bash
    ncn-m001# kubectl get pods -n spire -o wide | grep spire-jwks
    spire-jwks-6b97457548-gc7td    2/3  CrashLoopBackOff   9    23h   10.44.0.117  ncn-w002 <none>   <none>
    spire-jwks-6b97457548-jd7bd    2/3  CrashLoopBackOff   9    23h   10.36.0.123  ncn-w003 <none>   <none>
    spire-jwks-6b97457548-lvqmf    2/3  CrashLoopBackOff   9    23h   10.39.0.79   ncn-w001 <none>   <none>
    ```

22. If spire pods indicate `CrashLoopBackOff`, then restart the spire pods.

    ```bash
    ncn-m001# kubectl rollout restart -n spire deployment spire-jwks
    ```

23. Determine whether the cfs-state-reporter service is failing to start on each manager/master and worker NCN while trying to contact CFS.

    ```bash
    ncn-m001# pdsh -w ncn-m00[1-3],ncn-w00[1-3] systemctl status cfs-state-reporter
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

    1.  On each NCN where cfs-state-reporter is stuck in "activating" as shown in the preceding error messages, restart the cfs-state-reporter service. For example:

        ```bash
        ncn-m001# systemctl restart cfs-state-reporter
        ```

    2.  Check the status again.

        ```bash
        ncn-m001# pdsh -w ncn-m00[1-3],ncn-w00[1-3] systemctl status cfs-state-reporter
        ```

    

**VERIFY BGP PEERING SESSIONS**

**Attention:** All HSN switches and their associated HSN adapters must be up before the HSN can initialized. See [Bring Up the Slingshot Fabric](Bring_up_the_Slingshot_Fabric.md).

1.  Check the status of the Border Gateway Protocol \(BGP\). For more information, see [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md).

2.  Check the status and health of etcd clusters, see [Check the Health and Balance of etcd Clusters](../kubernetes/Check_the_Health_and_Balance_of_etcd_Clusters.md).

    

**CHECK CRON JOBS**

3.  Display all the k8s cron jobs.

    ```bash
    ncn-m001# kubectl get cronjobs.batch -A
    NAMESPACE     NAME                                 SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    **backups       benji-k8s-backup-backups-namespace   \*/5 \* \* \* \*    False     0        13d             39d**
    backups       benji-k8s-cleanup                    00 05 * * *    False     0        10h             39d
    backups       benji-k8s-enforce                    00 04 * * *    False     0        11h             39d
    kube-system   kube-etcdbackup                      */10 * * * *   False     0        9m37s           40d
    operators     kube-etcd-defrag                     0 0 * * *      False     0        15h             39d
    operators     kube-etcd-periodic-backup-cron       0 * * * *      False     0        39m             39d
    services      cray-dns-unbound-manager             */1 * * * *    False     1        97s             32d
    services      hms-discovery                        */3 * * * *    False     1        37s             17d
    services      hms-postgresql-pruner                */5 * * * *    False     0        4m37s           39d
    services      sonar-jobs-watcher                   */1 * * * *    False     0        37s             2d17h
    services      sonar-sync                           */1 * * * *    False     1        37s             2d17h
    sma           sma-pgdb-cron                        10 4 * * *     False     0        11h             39d
    ```

    **Attention:** It is normal for the hms-discovery service to be suspended at this point if liquid-cooled cabinets have not been powered on. The hms-discovery service is un-suspended during the liquid-cooled cabinet power on procedure. Do not re-create the hms-discovery cron job at this point.

4.  Check for cron jobs that have a `LAST SCHEDULE` time that is older than the `SCHEDULE` time. These cron jobs must be restarted.

5.  Check the cron jobs in question for errors.

    ```bash
    ncn-m001# kubectl describe cronjobs.batch -n backups benji-k8s-backup-backups-namespace \
    | egrep -A 15 Events
    Events:
      Type     Reason            Age                        From                Message
      ----     ------            ----                       ----                -------
      Warning  FailedNeedsStart  4m46s (x22771 over 2d16h)  cronjob-controller  Cannot determine if job needs to be \
                                                                                started: too many missed start time (> 100). \
                                                                                Set or decrease .spec.startingDeadlineSeconds \
                                                                                or check clock skew
    ```

6.  For any cron jobs producing errors, get the YAML representation of the cron job and edit the YAML file:

    ```bash
    ncn-m001# cd ~/k8s
    ncn-m001# kubectl get cronjobs.batch -n NAMESPACE CRON_JOB_NAME -o yaml > CRON_JOB_NAME-cronjob.yaml
    ncn-m001# vi CRON_JOB_NAME-cronjob.yaml 
    ```

    1.  Delete all lines that contain `uid:`.

    2.  Delete the entire `status:` section including the `status` key.

    3.  Save the file and quit the editor.

7.  Delete the cron job.

    ```bash
    ncn-m001# kubectl delete -f CRON_JOB_NAME-cronjob.yaml
    ```

8.  Apply the cron job.

    ```bash
    ncn-m001# kubectl apply -f CRON_JOB_NAME-cronjob.yaml
    ```

9.  Verify that the cron job has been scheduled.

    ```bash
    ncn-m001# kubectl get cronjobs -n backups benji-k8s-backup-backups-namespace
    NAME                                 SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    benji-k8s-backup-backups-namespace   */5 * * * *   False     0        92s             64d
    ```


**CHECK THE HSM INVENTORY STATUS OF NCNs**

10. Use the `sat` command to check for management NCNs in an Off state.

    ```bash
    ncn-m001# sat status --filter role=management
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

11. If NCNs are listed as OFF, run a manual discovery of NCNs in the Off state.

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x3000c0s12b0,x3000c0s20b0
    [[results]]
    URI = "/hsm/v1/Inventory/DiscoveryStatus/0"
    ```

12. Check for NCN status.

    ```bash
    ncn-m001# sat status --filter Role=Management
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

13. To check the health and status of the management cluster after a power cycle, refer to the "Platform Health Checks" section in [Validate CSM Health](../validate_csm_health.md).

14. If NCNs must have access to Lustre, start the Lustre file system. See [Power On the External Lustre File System](Power_On_the_External_Lustre_File_System.md).





