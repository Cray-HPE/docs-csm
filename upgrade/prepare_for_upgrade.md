# Prepare For Upgrade

Before beginning an upgrade to a new version of CSM, there are a few things to do on the system first.

- [Reduced resiliency during upgrade](#reduced-resiliency-during-upgrade)
- [Preparation steps]

   1. [Start typescript](#1-start-typescript)
   1. [Ensure latest documentation installed](#2-ensure-latest-documentation-is-installed)
   1. [Export Nexus data](#3-export-nexus-data)
   1. [Disable encryption for upgrade if enabled](#4-disable-encryption-for-upgrade-if-enabled)
   1. [Running sessions](#5-running-sessions)
   1. [Health validation](#6-health-validation)
   1. [Stop typescript](#7-stop-typescript)

- [Preparation completed](#preparation-completed)

## Reduced resiliency during upgrade

**Warning:** Management service resiliency is reduced during the upgrade.

Although it is expected that [compute nodes](../glossary.md#compute-node-cn) and
[application nodes](../glossary.md#application-node-an) will continue to provide their
services without interruption, it is important to be aware that the degree of management services
resiliency is reduced during the upgrade. While one node is being upgraded, if another node of the
same type has an unplanned fault that removes it from service, then this may result in a degraded system. For
example, if there are three Kubernetes master nodes and one is being upgraded, the quorum is
maintained by the remaining two nodes. If one of those two nodes has a fault before the third node
completes its upgrade, then quorum would be lost.

## Preparation steps

### 1. Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with
   the `exit` command.

1. (`ncn-m001#`) Start a typescript.

   ```bash
   script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).prepare_for_upgrade.txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

If additional shells are opened during this procedure, then record those with typescripts as well.
When resuming a procedure after a break, always be sure that a typescript is running before proceeding.

### 2. Ensure latest documentation is installed

Before following the steps to prepare for the upgrade, make sure that the latest CSM documentation RPMs are
installed on any NCNs where preparation procedures are being performed. These should be for the **`CURRENT`**
CSM version on the system -- not the target version of the upgrade.
See [Check for latest documentation](../update_product_stream/README.md#check-for-latest-documentation) for instructions.

### 3. Export Nexus data

**Warning:** This process can take multiple hours where Nexus is unavailable and should be done during scheduled maintenance periods.

Prior to the upgrade it is recommended that a Nexus export is taken. This is not a required step but
highly recommend to protect the data in Nexus.
If there is no maintenance period available, then skip this step until after the upgrade process.

Reference [Nexus Export and Restore Procedure](../operations/package_repository_management/Nexus_Export_and_Restore.md) for details.

### 4. Disable encryption for upgrade if enabled

While it is possible to upgrade with Kubernetes encryption enabled, disabling encryption is recommended for the duration of the upgrade if it has been enabled.

See [Kubernetes Encryption](../operations/kubernetes/encryption/README.md) for details.

Once the upgrade is complete, then encryption can be turned back on.

### 5. Running sessions

[Boot Orchestration Service (BOS)](../glossary.md#boot-orchestration-service-bos),
[Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs),
[Compute Rolling Upgrade Service (CRUS)](../glossary.md#compute-rolling-upgrade-service-crus),
[Firmware Action Service (FAS)](../glossary.md#firmware-action-service-fas), and
[Node Memory Dump (NMD)](../glossary.md#node-memory-dump-nmd) sessions should not be started or underway during the CSM upgrade process.

1. (`ncn-m001#`) Ensure that these services do not have any sessions in progress.

   > This [System Admin Toolkit (SAT)](../glossary.md#system-admin-toolkit-sat) command has `shutdown` as one of the command line options,
   > but it will **not** start a shutdown process on the system.

   ```bash
   sat bootsys shutdown --stage session-checks
   ```

    Example output:

   ```text
   Checking for active BOS sessions.
   Found no active BOS sessions.
   Checking for active CFS sessions.
   Found no active CFS sessions.
   Checking for active FAS actions.
   Found no active FAS actions.
   Checking for active NMD dumps.
   Found no active NMD dumps.
   No active sessions exist. It is safe to proceed with the shutdown procedure.
   ```

   If active sessions are running, then either wait for them to complete, or shut down, cancel, or
   delete them.

1. Coordinate with the site to prevent new sessions from starting in these services.

    There is currently no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway.

### 6. Health validation

1. Validate CSM health.

   Run the CSM health checks to ensure that everything is working properly before the upgrade
   starts. After the upgrade is completed, another health check is performed, and it is important to know
   if any problems observed at that time existed prior to the upgrade.

   **`IMPORTANT`**: See the `CSM Install Validation and Health Checks` procedures in the
   documentation for the **`CURRENT`** CSM version on the system. The validation procedures in the CSM
   documentation are only intended to work with that specific version of CSM.

1. Validate Lustre health.

   If a Lustre file system is being used, then see the ClusterStor documentation for details on how to validate Lustre health.

### 7. Stop typescript

For any typescripts that were started during this preparation stage, stop them with the `exit` command.

## Preparation completed

After completing the above steps, proceed to
[Upgrade Management Nodes and CSM Services](README.md#2-upgrade-management-nodes-and-csm-services).
