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
   is based on three copies of etcd or postrgres because some of those pods have anti-affinity to avoid two pods of that type
   being on the same worker node.

1. Optional system health checks.

    1.  Use the System Dump Utility \(SDU\) to capture current state of system before the shutdown.

        **Important:** SDU takes about 15 minutes to run on a small system \(longer for large systems\).

        ```screen
        ncn-m001# sdu --scenario triage --start_time '-4 hours' \
        --reason "saving state before powerdown/up"
        ```
    1.  Check Ceph status.

        ```screen
        ncn-m001# ceph -s > ceph.status
        ```

    1.  Check Kubernetes pod status for all pods.

        ```screen
        ncn-m001# kubectl get pods -o wide -A > k8s.pods
        ```

        Additional Kubernetes status check examples :

        ```screen
        ncn-m001# kubectl get pods -o wide -A | egrep "CrashLoopBackOff" > k8s.pods.CLBO
        ncn-m001# kubectl get pods -o wide -A | egrep "ContainerCreating" > k8s.pods.CC
        ncn-m001# kubectl get pods -o wide -A | egrep -v "Run|Completed" > k8s.pods.errors
        ```
1.  Check for running sessions.

    Ensure that these services do not have any sessions in progress: BOS, CFS, CRUS, FAS, or NMD.
    > This SAT command has "shutdown" as one of the commandline options, but it will not start a shutdown process on the system.

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

    If active sessions are running, either wait for them to complete or shutdown/cancel/delete the session.

1.  Coordinate with the site to prevent new sessions from starting in the services listed (BOS, CFS, CRUS, FAS, NMD).

    In version Shasta v1.4, there is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.


1. Validate CSM Health

   Run the CSM health checks to ensure that everything is working properly before the upgrade starts.

   Some of the CSM health checks, such as booting the barebones image on the compute nodes, could be skipped.

   See the `CSM Install Validation and Health Checks` procedures **in the CSM 0.9 documentation**. The validation procedures in the CSM 1.0 documentation are not all intended to work on CSM 0.9.

<a name="next-topic"></a>
# Next Topic

   After completing this procedure the next step is to update the management network.

   * See [Update Management Network](index.md#update_management_network)

