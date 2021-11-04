# Prepare for Upgrade

Before beginning an upgrade to a new version of CSM, there are a few things to do on the system first.

1. Graceful Shutdown of Workloads affected by CSM Upgrade

   **Warning:** Although it is expected that compute nodes and application nodes will continue to provide their services
   without interruption when the management nodes and services are being upgraded by CSM, it is important to
   be aware of the possibility of interruption of running jobs. The management nodes will undergo a rolling upgrade
   that should maintain enough nodes of each type to continue to provide services. However, while one node is being upgraded,
   if another node of the same type has an unplanned fault that removes it from service, there may be a degraded system. For
   example, if there are three Kubernetes master nodes and one is being upgraded, the quorum is maintained by the remaining
   two nodes. If one of those two nodes has a fault before the third node completes its upgrade, then quorum would be lost.
   There is a similar issue on small systems which have only three worker nodes for some services which have a data store that
   is based on three copies of `etcd` or `postgres` because some of those pods have anti-affinity to avoid two pods of that type
   being on the same worker node.

1. Optional system health checks.

   1. Use the System Dump Utility \(SDU\) to capture current state of system before the shutdown.

      **Important:** SDU takes about 15 minutes to run on a small system \(longer for large systems\).

      ```screen
      ncn-m001# sdu --scenario triage --start_time '-4 hours' \
      --reason "saving state before powerdown/up"
      ```
      Refer to the HPE Cray EX System Dump Utility (SDU) Administration Guide for more information and troubleshooting steps.

   1. Check Ceph status.

      ```screen
      ncn-m001# ceph -s > ceph.status
      ```

   1. Check Kubernetes pod status for all pods.

      ```screen
      ncn-m001# kubectl get pods -o wide -A > k8s.pods
      ```

      Additional Kubernetes status check examples :

      ```screen
      ncn-m001# kubectl get pods -o wide -A | egrep "CrashLoopBackOff" > k8s.pods.CLBO
      ncn-m001# kubectl get pods -o wide -A | egrep "ContainerCreating" > k8s.pods.CC
      ncn-m001# kubectl get pods -o wide -A | egrep -v "Run|Completed" > k8s.pods.errors
      ```

1. Check for running sessions.

    Ensure that these services do not have any sessions in progress: BOS, CFS, CRUS, FAS, or NMD.
    > This SAT command has `shutdown` as one of the command line options, but it will not start a shutdown process on the system.

    ```screen
    ncn-m001# sat bootsys shutdown --stage session-checks
    Checking for active BOS sessions.
    Found no active BOS sessions.
    Checking for active CFS sessions.
    Found no active CFS sessions.
    Checking for active CRUS upgrades.
    Found no active CRUS upgrades.
    Checking for active FAS actions.
    Found no active FAS actions.
    Checking for active NMD dumps.
    Found no active NMD dumps.
    No active sessions exist. It is safe to proceed with the shutdown procedure.
    ```

    If active sessions are running, either wait for them to complete or shut down/cancel/delete the session.

1. Coordinate with the site to prevent new sessions from starting in the services listed (BOS, CFS, CRUS, FAS, NMD).

    There is currently no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

1. Validate CSM Health

   Run the CSM health checks to ensure that everything is working properly before the upgrade starts. It is always best to 
   perform all possible health checks. Be sure to run the validation procedures appropriate for your **current** CSM version.

   **NOTE**: Booting the barebones image on the compute nodes may be skipped if all compute nodes are currently running
   application workloads. However, **it is recommended to do this test if possible**, because it validates that boot services
   are still working properly.

   * If upgrading **from CSM 1.0 (Shasta 1.5)**, follow the [Validate CSM Health](../operations/validate_csm_health.md) procedures.

   * If upgrading **from CSM 0.9 (Shasta 1.4)**, see the [CSM Install Validation and Health Checks](https://github.com/Cray-HPE/docs-csm/blob/release/0.9/008-CSM-VALIDATION.md) procedures **`in the CSM 0.9 documentation`**. The validation procedures in the CSM 1.0 documentation are not all intended to work on CSM 0.9.

1. Validate Lustre Health

   If a Lustre file system is being used, see the ClustreStor documentation for details on how to check
   for Lustre health. Here are a few commands which could be used to validate Lustre health. This example
   is for a ClusterStor providing the cls01234 filesystem.

   1. SSH to the primary management node.
      For example, on system cls01234.

      ```screen
      remote$ ssh -l admin cls01234n000.systemname.com
      ```

   1. Check that the shared storage targets are available for the management nodes.

      ```screen
      [n000]$ pdsh -g mgmt cat /proc/mdstat | dshbak -c
      ----------------
      cls01234n000
      ----------------
      Personalities : [raid1] [raid6] [raid5] [raid4] [raid10]
      md64 : active raid10 sda[0] sdc[3] sdw[2] sdl[1]
      1152343680 blocks super 1.2 64K chunks 2 near-copies [4/4] [UUUU]
      bitmap: 2/9 pages [8KB], 65536KB chunk
      md127 : active raid1 sdy[0] sdz[1]
      439548848 blocks super 1.0 [2/2] [UU]
      unused devices: <none>
      ----------------
      cls01234n001
      ----------------
      Personalities : [raid1] [raid6] [raid5] [raid4] [raid10]
      md67 : active raid1 sdi[0] sdt[1]
      576171875 blocks super 1.2 [2/2] [UU]
      bitmap: 0/5 pages [0KB], 65536KB chunk
      md127 : active raid1 sdy[0] sdz[1]
      439548848 blocks super 1.0 [2/2] [UU]
      unused devices: <none>
      ```

   1. Check HA status.

      ```screen
      [n000]$ sudo crm_mon -1r
      ```

      The output indicates whether all resources are started and balanced between two nodes.

   1. Check the status of the nodes.

      ```screen
      [n000]# pdsh -a date
      cls01234n000: Thu Aug 7 01:29:28 PDT 2014
      cls01234n003: Thu Aug 7 01:29:28 PDT 2014
      cls01234n002: Thu Aug 7 01:29:28 PDT 2014
      cls01234n001: Thu Aug 7 01:29:28 PDT 2014
      cls01234n007: Thu Aug 7 01:29:28 PDT 2014
      cls01234n006: Thu Aug 7 01:29:28 PDT 2014
      cls01234n004: Thu Aug 7 01:29:28 PDT 2014
      cls01234n005: Thu Aug 7 01:29:28 PDT 2014
      ```

   1. Check the health of the Lustre file system.

      ```screen
      [n000]# cscli csinfo
      [n000]# cscli show_nodes
      [n000]# cscli fs_info
      ```
