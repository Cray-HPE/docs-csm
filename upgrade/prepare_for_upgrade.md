<!-- markdownlint-disable MD013 -->
# Prepare for Upgrade

Before beginning an upgrade to a new version of CSM, there are a few things to do on the system
first.

- [Reduced resiliency during upgrade](#reduced-resiliency-during-upgrade)
- [Export Nexus data](#export-nexus-data)
- [Adding Switch Admin Password to Vault](#adding-switch-admin-password-to-vault)
- [Ensure SNMP is Configured on the Management Network Switches](#ensure-snmp-is-configured-on-the-management-network-switches)
- [Start typescript](#start-typescript)
- [Running sessions](#running-sessions)
- [Health validation](#health-validation)
- [Stop typescript](#stop-typescript)
- [Preparation completed](#preparation-completed)

## Reduced resiliency during upgrade

**Warning:** Management service resiliency is reduced during the upgrade.

Although it is expected that compute nodes and application nodes will continue to provide their
services without interruption, it is important to be aware that the degree of management services
resiliency is reduced during the upgrade. If, while one node is being upgraded, another node of the
same type has an unplanned fault that removes it from service, there may be a degraded system. For
example, if there are three Kubernetes master nodes and one is being upgraded, the quorum is
maintained by the remaining two nodes. If one of those two nodes has a fault before the third node
completes its upgrade, then quorum would be lost.

## Export Nexus data

**Warning:** This process can take multiple hours where Nexus is unavailable and should be done
during scheduled maintenance periods.

Prior to the upgrade it is recommended that a Nexus export is taken. This is not a required step but
highly recommend to protect the data in Nexus.
If there is no maintenance period available then this step should be skipped until after the upgrade
process.

Reference [Nexus Export and Restore Procedure](../operations/package_repository_management/Nexus_Export_and_Restore.md)
for details.

## Adding Switch Admin Password to Vault

If CSM has been installed and Vault is running, add the switch credentials into Vault. Certain
tests, including `goss-switch-bgp-neighbor-aruba-or-mellanox` use these credentials to test the
state of the switch. This step is not required to configure the management network. If Vault is
unavailable, this step can be temporarily skipped. Any automated tests that depend on the switch
credentials being in Vault will fail until they are added.

First, write the switch admin password to the `SWITCH_ADMIN_PASSWORD` variable if it isn't already
set.

```bash
read -s SWITCH_ADMIN_PASSWORD
```

Once the `SWITCH_ADMIN_PASSWORD` variable is set, run the following commands to add the switch admin
password to Vault.

```bash
VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
vault kv put secret/net-creds/switch_admin admin=$SWITCH_ADMIN_PASSWORD
```

Note: The use of `read -s` is a convention used throughout this documentation which allows for the
user input of secrets without echoing them to the terminal or saving them in history.

## Ensure SNMP is Configured on the Management Network Switches
<!-- snmp-authentication-tag -->
<!-- When updating this information, search the docs for the snmp-authentication-tag to find related content -->
<!-- These comments can be removed once we adopt HTTP/lw-dita/Generated docs with re-usable snippets -->

To ensure proper operation of the REDS Hardware Discovery process, and the Prometheus SNMP Exporter, validate that
SNMP is enabled on the management network switches.  Additionally, validate that the SNMP credentials on the
switches match the credentials stored in Vault, and in customizations.yaml (stored as a sealed secret).  If an
[SNMP custom config](../operations/network/management_network/canu/custom_config.md) was used with CANU when generating the management network switch configurations,
that custom config should also be checked to ensure it uses the same credentials as Vault and customizations.yaml.

This check is recommended to avoid failure scenarios that can impact the ability to add new hardware to the system.
It's not uncommon for CSM upgrades to be paired with system maintenance such as hardware layout changes, expansion,
or management network upgrades.  If management network switches are reconfigured or new switches are added, and a
custom CANU config with SNMP settings was not used, it's possible that an admin may unknowingly push new switch
configs that omit SNMP.  If in the process of fixing SNMP, and admin then adds SNMP credentials to the switches
that do not match what is stored in Vault and customizations.yaml, the resulting REDS and Prometheus errors can be
difficult to diagnose and resolve.

It is recommended that CANU custom configuration files be stored in a version controlled repository so that they
can be re-used for future management network maintenance.

More information about configuring SNMP on the management switches can be found in the vendor specific switch
documentation.  Links to these pages, and other SNMP information related to REDS Hardware Discovery and the
Prometheus SNMP Exporter, [can be found on the Configure SNMP page.](../operations/network/management_network/configure_snmp.md).  This page contains links
to procedures for working with Vault, sealed secrets in customizations.yaml, and more.

Be sure to return here once you have verified that SNMP is properly configured on the management network switches.

## Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with
   the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).prepare_for_upgrade.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well.
When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Running sessions

BOS, CFS, CRUS, FAS, and NMD sessions should not be started or underway during the CSM upgrade
process.

1. (`ncn-m001#`) Ensure that these services do not have any sessions in progress.

   > This SAT command has `shutdown` as one of the command line options, but it will not start a
   shutdown process on the system.

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

   If active sessions are running, then either wait for them to complete or shut down, cancel, or
   delete them.

1. Coordinate with the site to prevent new sessions from starting in these services.

   There is currently no method to prevent new sessions from being created as long as the service
   APIs are accessible on the API gateway.

## Health validation

1. Validate CSM health.

   Run the CSM health checks to ensure that everything is working properly before the upgrade
   starts.

   **`IMPORTANT`**: See the `CSM Install Validation and Health Checks` procedures in the
   documentation for the **`CURRENT`** CSM version on
   the system. The validation procedures in the CSM documentation are only intended to work with
   that specific version of CSM.

1. Validate Lustre health.

   If a Lustre file system is being used, then see the ClusterStor documentation for details on how
   to validate Lustre health.

## Stop typescript

For any typescripts that were started during this preparation stage, stop them with the `exit`
command.

## Preparation completed

After completing the above steps, proceed to
[Upgrade Management Nodes and CSM Services](README.md#3-upgrade-management-nodes-and-csm-services).
