# Prepare for Upgrade

Before beginning an upgrade to a new version of CSM, there are a few things to do on the system first.

1. Understand that management service resiliency is reduced during the upgrade.

   **Warning:** Although it is expected that compute nodes and application nodes will continue to provide their services
   without interruption, it is important to be aware that the degree of management services resiliency is reduced during the
   upgrade. If, while one node is being upgraded, another node of the same type has an unplanned fault that removes it from service,
   there may be a degraded system. For example, if there are three Kubernetes master nodes and one is being upgraded, the quorum is
   maintained by the remaining two nodes. If one of those two nodes has a fault before the third node completes its upgrade,
   then quorum would be lost.

1. Optional system health checks.

    1. Use the System Diagnostic Utility (SDU) to capture current state of system before the shutdown.

        **Important:** SDU takes about 15 minutes to run on a small system \(longer for large systems\).

        ```bash
        ncn-m001# sdu --scenario triage --start_time '-4 hours' --reason "saving state before powerdown/up"
        ```

        Refer to the HPE Cray EX System Diagnostic Utility (SDU) Administration Guide for more information and troubleshooting steps.

    1. Check Ceph status.

        ```bash
        ncn-m001# ceph -s | tee ceph.status
        ```

    1. Check Kubernetes pod status for all pods.

        ```bash
        ncn-m001# kubectl get pods -o wide -A | tee k8s.pods
        ```

        Additional Kubernetes status check examples :

        ```bash
        ncn-m001# egrep "CrashLoopBackOff" k8s.pods | tee k8s.pods.CLBO
        ncn-m001# egrep "ContainerCreating" k8s.pods | tee k8s.pods.CC
        ncn-m001# egrep -v "Run|Completed" k8s.pods | tee k8s.pods.errors
        ```

1. Check for BOS, CFS, CRUS, FAS, or NMD sessions.

    1. Ensure that these services do not have any sessions in progress.

        > This SAT command has `shutdown` as one of the command line options, but it will not start a shutdown process on the system.

        ```bash
        ncn-m001# sat bootsys shutdown --stage session-checks
        ```

        Example output:

        ```text
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

        If active sessions are running, then either wait for them to complete or shut down, cancel, or delete them.

    1. Coordinate with the site to prevent new sessions from starting in these services.

        There is currently no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

1. Validate CSM Health

    Run the CSM health checks to ensure that everything is working properly before the upgrade starts.

    **`IMPORTANT`**: See the `CSM Install Validation and Health Checks` procedures in the documentation for the **`CURRENT`** CSM version on
    the system. The validation procedures in the CSM documentation are not all intended to work on previous versions of CSM.

1. Validate Lustre Health

   If a Lustre file system is being used, then see the ClusterStor documentation for details on how to check
   for Lustre health.

After completing the above steps, proceed to [Upgrade Management Nodes and CSM Services](index.md#upgrade_management_nodes_csm_services).
