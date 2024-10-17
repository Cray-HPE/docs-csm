<!-- markdownlint-disable MD013 -->
# Prepare For Upgrade

Before beginning an upgrade to a new version of CSM, there are a few things to do on the system
first.

- [Reduced resiliency during upgrade](#reduced-resiliency-during-upgrade)
- [Preparation steps]

   1. [Start typescript](#1-start-typescript)
   1. [Ensure latest documentation installed](#2-ensure-latest-documentation-is-installed)
   1. [Export Nexus data](#3-export-nexus-data)
   1. [Adding switch admin password to Vault](#4-adding-switch-admin-password-to-vault)
   1. [Ensure SNMP is configured on the management network switches](#5-ensure-snmp-is-configured-on-the-management-network-switches)
   1. [Running sessions](#6-running-sessions)
   1. [Health validation](#7-health-validation)
   1. [Stop typescript](#8-stop-typescript)

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

**Warning:** This process can take multiple hours where Nexus is unavailable and should be done
during scheduled maintenance periods.

Prior to the upgrade it is recommended that a Nexus export is taken. This is not a required step but
highly recommend to protect the data in Nexus.
If there is no maintenance period available, then skip this step until after the upgrade process.

Reference [Nexus Export and Restore Procedure](../operations/package_repository_management/Nexus_Export_and_Restore.md)
for details.

### 4. Adding switch admin password to Vault

If it has not been done previously, record in Vault the `admin` user password for the management switches in the system.

See [Adding switch admin password to Vault](../operations/network/management_network/README.md#adding-switch-admin-password-to-vault).

### 5. Ensure SNMP is configured on the management network switches
<!-- snmp-authentication-tag -->
<!-- When updating this information, search the docs for the snmp-authentication-tag to find related content -->
<!-- These comments can be removed once we adopt HTTP/lw-dita/Generated docs with re-usable snippets -->

To ensure proper operation of the HMS Discovery hardware discovery process,
[Power Control Service (PCS)](../glossary.md#power-control-service-pcs)/[Redfish Translation Service (RTS)](../glossary.md#redfish-translation-service-rts)
management switch availability monitoring, and the Prometheus SNMP Exporter, validate the following:

- SNMP is enabled on the management network switches.
- The SNMP credentials on the switches match the credentials stored in all of the following locations:
    - Vault
    - `customizations.yaml` (stored as a sealed secret)
    - [SNMP custom configuration](../operations/network/management_network/canu/custom_config.md), if applicable. If a
      custom configuration was used with the [CSM Automatic Network Utility (CANU)](../glossary.md#csm-automatic-network-utility-canu)
      when generating the management network switch configurations, also check that
      the credentials in this custom configuration match.

These checks help avoid failure scenarios that can impact the ability to add new hardware to the system.
It is not uncommon for CSM upgrades to be paired with system maintenance such as hardware layout changes, expansion,
or management network upgrades. If management network switches are reconfigured or new switches are added, and a
custom CANU configuration with SNMP settings was not used, it is possible that an administrator may unknowingly push new switch
configurations that omit SNMP. If in the process of fixing SNMP, an administrator then adds SNMP credentials to the switches
that do not match what is stored in Vault and `customizations.yaml`, then the resulting HMS Discovery, PCS/RTS, and Prometheus errors can be
difficult to diagnose and resolve.

CANU custom configuration files should be stored in a version controlled repository so that they can be re-used for
future management network maintenance.

For more information, see [Configure SNMP](../operations/network/management_network/configure_snmp.md). That page
contains the following relevant information:

- Links to vendor-specific switch documentation, which provides more information about configuring SNMP on the management switches.
- Other SNMP information related to HMS Discovery hardware discovery, PCS/RTS management switch availability monitoring, and the Prometheus SNMP Exporter
- Links to related procedures with Vault, `customizations.yaml`, sealed secrets, and more.

Return here after verifying that SNMP is properly configured on the management network switches.

### 6. Running sessions

[Boot Orchestration Service (BOS)](../glossary.md#boot-orchestration-service-bos),
[Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs),
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

   There is currently no method to prevent new sessions from being created as long as the service
   APIs are accessible on the API gateway.

### 7. Health validation

1. Validate CSM health.

   Run the CSM health checks to ensure that everything is working properly before the upgrade
   starts. After the upgrade is completed, another health check is performed, and it is important to know
   if any problems observed at that time existed prior to the upgrade.

   **`IMPORTANT`**: See the [`CSM Install Validation and Health Checks`](../operations/validate_csm_health.md) procedures in the
   documentation for the **`CURRENT`** CSM version on the system. The validation procedures in the CSM
   documentation are only intended to work with that specific version of CSM.

1. Validate Lustre health.

   If a Lustre file system is being used, then see the ClusterStor documentation for details on how
   to validate Lustre health.

### 8. Stop typescript

For any typescripts that were started during this preparation stage, stop them with the `exit` command.
