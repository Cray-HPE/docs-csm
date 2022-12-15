# Prepare for Upgrade

Before beginning an upgrade to a new version of CSM, there are a few things to do on the system first.

- [Reduced resiliency during upgrade](#reduced-resiliency-during-upgrade)
- [Export Nexus data](#export-nexus-data)
- [Start typescript](#start-typescript)
- [Running sessions](#running-sessions)
- [Health validation](#health-validation)
- [Stop typescript](#stop-typescript)
- [Preparation completed](#preparation-completed)

## Reduced resiliency during upgrade

**Warning:** Management service resiliency is reduced during the upgrade.

Although it is expected that compute nodes and application nodes will continue to provide their services
without interruption, it is important to be aware that the degree of management services resiliency is reduced during the
upgrade. If, while one node is being upgraded, another node of the same type has an unplanned fault that removes it from service,
there may be a degraded system. For example, if there are three Kubernetes master nodes and one is being upgraded, the quorum is
maintained by the remaining two nodes. If one of those two nodes has a fault before the third node completes its upgrade,
then quorum would be lost.

## Export Nexus data

**Warning:** This process can take multiple hours where Nexus is unavailable and should be done during scheduled maintenance periods.

Prior to the upgrade it is recommended that a Nexus export is taken. This is not a required step but highly recommend to protect the data in Nexus.
If there is no maintenance period available then this step should be skipped until after the upgrade process.

Reference [Nexus Export and Restore Procedure](../operations/package_repository_management/Nexus_Export_and_Restore.md) for details.

## Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).prepare_for_upgrade.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Running sessions

BOS, CFS, CRUS, FAS, and NMD sessions should not be started or underway during the CSM upgrade process.

1. (`ncn-m001#`) Ensure that these services do not have any sessions in progress.

    > This SAT command has `shutdown` as one of the command line options, but it will not start a shutdown process on the system.

    ```bash
    sat bootsys shutdown --stage session-checks
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

## Health validation

1. Validate CSM health.

    Run the CSM health checks to ensure that everything is working properly before the upgrade starts.

    **`IMPORTANT`**: See the `CSM Install Validation and Health Checks` procedures in the documentation for the **`CURRENT`** CSM version on
    the system. The validation procedures in the CSM documentation are only intended to work with that specific version of CSM.

1. Validate Lustre health.

   If a Lustre file system is being used, then see the ClusterStor documentation for details on how to validate Lustre health.

## Stop typescript

For any typescripts that were started during this preparation stage, stop them with the `exit` command.

## Preparation completed

After completing the above steps, proceed to
[Upgrade Management Nodes and CSM Services](README.md#3-upgrade-management-nodes-and-csm-services).
