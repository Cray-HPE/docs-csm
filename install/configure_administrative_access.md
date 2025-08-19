# Configure Administrative Access

There are several operations which configure administrative access to different parts of the system.
Ensuring that the `cray` CLI can be used with administrative credentials enables use of many
management services via commands. Authentication of the `sat` CLI allows the use of additional
administrative commands. The management nodes can be locked from accidental manipulation by the
`cray power` and `cray fas` commands when the intent is to work on the entire system except the
management nodes. The `cray scsd` command can change the SSH keys, NTP server, `syslog` server,
and BMC/controller passwords.

## Topics

1. [Configure the Cray and SAT command line interfaces](#1-configure-the-cray-and-sat-command-line-interfaces)
    - [Cray CLI configuration](#cray-cli-configuration)
        - [Automatic configuration using temporary Keycloak account](#automatic-configuration-using-temporary-keycloak-account)
        - [Manual configuration](#manual-configuration)
    - [SAT CLI configuration](#sat-cli-configuration)
1. [Set `Management` role on the BMCs of management nodes](#2-set-management-role-on-the-bmcs-of-management-nodes)
1. [Lock management nodes](#3-lock-management-nodes)
1. [Configure BMC and controller parameters with SCSD](#4-configure-bmc-and-controller-parameters-with-scsd)
1. [Set up passwordless SSH](#5-set-up-passwordless-ssh)
1. [Configure the root password and SSH keys in Vault](#6-configure-the-root-password-and-ssh-keys-in-vault)
1. [Add switch admin password to Vault](#7-add-switch-admin-password-to-vault)
1. [iSCSI SBPS configuration](#8-iscsi-sbps-configuration)
1. [Configure management nodes with CFS](#9-configure-management-nodes-with-cfs)
1. [Restart Rack Resiliency critical services](#10-restart-rack-resiliency-critical-services)
1. [Proceed to next topic](#11-proceed-to-next-topic)

> **`NOTE`** The procedures in this section of installation documentation are intended to be done in order, even though the topics are
> administrative or operational procedures. The topics themselves do not have navigational links to the next topic in the sequence.

## 1. Configure the Cray and SAT command line interfaces

The `cray` command line interface (CLI) is a framework created to integrate all of the system
management REST APIs into easily usable commands. The [System Admin Toolkit (SAT)](../glossary.md#system-admin-toolkit-sat)
CLI (`sat`) is an additional CLI that automates common administrative workflows.

Later procedures in the installation workflow use the `cray` and `sat` commands to interact with
multiple services. The `cray` and `sat` CLI configurations need to be initialized for the Linux
account. The Keycloak user who initializes these CLI configurations needs to be authorized for
administrative actions.

### Cray CLI configuration

There are two options to proceed with `cray` CLI authentication:

- [Automatic configuration using temporary Keycloak account](#automatic-configuration-using-temporary-keycloak-account)
- [Manual configuration](#manual-configuration)

#### Automatic configuration using temporary Keycloak account

Configure all NCNs with a temporary Keycloak account for the duration of the install.

See [Configure All NCNs With Temporary Keycloak User](../operations/configure_cray_cli.md#configure-all-ncns-with-temporary-keycloak-user).

#### Manual configuration

Manually configure the `cray` CLI with a valid Keycloak account using the following steps:

1. Configure Keycloak account

    Upcoming steps in the installation workflow require an account to be configured in Keycloak for
    authentication. This can be either a local Keycloak account or an external Identity Provider (IdP),
    such as LDAP. Having an account in Keycloak with administrative credentials enables the use of many
    management services via the `cray` command.

    See [Configure Keycloak Account](../operations/CSM_product_management/Configure_Keycloak_Account.md).

1. Initialize and authorize the `cray` CLI on each NCN being used.

    See [Single User Already Configured in Keycloak](../operations/configure_cray_cli.md#single-user-already-configured-in-keycloak).

### SAT CLI configuration

Follow the procedures in [SAT Configuration](../operations/system_admin_toolkit/configuration/README.md)
to configure `sat` and authenticate to the API Gateway.

## 2. Set `Management` role on the BMCs of management nodes

The [Baseboard Management Controllers (BMCs)](../glossary.md#baseboard-management-controller-bmc) that control management nodes
will not have been marked with the `Management` role in the [Hardware State Manager (HSM)](../glossary.md#hardware-state-manager-hsm).
It is important to mark them with the `Management` role so that they can be easily included in the locking/unlocking operations required
for protection from actions by the [Firmware Action Service (FAS)](../glossary.md#firmware-action-service-fas) and the
[Power Control Service (PCS)](../glossary.md#power-control-service-pcs).

**Set BMC `Management` roles now!**

See [Set BMC `Management` Role](../operations/hardware_state_manager/Set_BMC_Management_Role.md).

## 3. Lock management nodes

The management nodes are unlocked at this point in the installation. Locking the management nodes and their BMCs will
prevent actions from FAS to update their firmware or PCS to power off or do a power reset. Doing any of these by
accident will take down a management node. If the management node is a Kubernetes master or worker node, this can have
serious negative effects on system operation.

If a single node is taken down by mistake, it is possible that things will recover. However, if all management
nodes are taken down, or all Kubernetes worker nodes are taken down by mistake, the system is dead and has to be
completely restarted.

**Lock the management nodes now!**

(`ncn-mw#`) Run the `lock_management_nodes.py` script to lock all management nodes and their BMCs that are not already locked:

```bash
/opt/cray/csm/scripts/admin_access/lock_management_nodes.py
```

The return value of the script is 0 if locking was successful. Otherwise, a non-zero return means that manual intervention may be needed to lock the nodes and their BMCs.

For more information about locking and unlocking nodes, see [Lock and Unlock Nodes](../operations/hardware_state_manager/Lock_and_Unlock_Management_Nodes.md).

## 4. Configure BMC and controller parameters with SCSD

> **`NOTE`** If there are no liquid-cooled cabinets present in the HPE Cray EX system, then this step can be skipped.

The [System Configuration Service (SCSD)](../glossary.md#system-configuration-service-scsd) allows administrators to set
various BMC and controller parameters for components in liquid-cooled cabinets. At this point in the install, SCSD should
be used to set the SSH key in the node controllers (BMCs) to enable troubleshooting. If any of the nodes fail to power
down or power up as part of the compute node booting process, it may be necessary to look at the logs on the BMC for node
power down or node power up.

See [Configure BMC and Controller Parameters with SCSD](../operations/system_configuration_service/Configure_BMC_and_Controller_Parameters_with_scsd.md).

## 5. Set up passwordless SSH

See [Set up passwordless SSH](../operations/CSM_product_management/Set_Up_Passwordless_SSH.md)
for the procedure to configure passwordless SSH between management nodes and from management nodes
to managed nodes.

This procedure sets up resources in Kubernetes (a Kubernetes Secret and ConfigMap) which are later
applied to the management nodes by the [Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs)
during node personalization in section [9. Configure management nodes with CFS](#9-configure-management-nodes-with-cfs) below.

## 6. Configure the root password and SSH keys in Vault

See [Configure the `root` password and SSH keys in Vault](../operations/CSM_product_management/Configure_the_root_Password_and_SSH_Keys_in_Vault.md)
for the procedure to configure the `root` password and SSH keys in Vault.

This procedure writes the `root` password hash and SSH keys to Vault which are later
applied to the management nodes by CFS during node personalization in section
[9. Configure management nodes with CFS](#9-configure-management-nodes-with-cfs) below.

## 7. Add switch admin password to Vault

If CSM has been installed and Vault is running, then add the switch credentials into Vault. Certain
tests, including `goss-switch-bgp-neighbor-aruba-or-mellanox` use these credentials to test the
state of the switch. This step is not required to configure the management network. If Vault is
unavailable, this step can be temporarily skipped. Any automated tests that depend on the switch
credentials being in Vault will fail until they are added.

(`ncn-m001#`) The following script will prompt for the password, write it to Vault, and then read it back
to verify that it was written correctly.

```bash
/usr/share/doc/csm/scripts/operations/configuration/write_sw_admin_pw_to_vault.py
```

On success, the script will exit with return code 0 and its final lines of output will look similar to the following:

```text
Writing switch admin password to Vault
Password read from Vault matches what was written
SUCCESS
```

## 8. iSCSI SBPS configuration

In CSM 1.6, all the worker nodes were configured and enabled as iSCSI SBPS targets. Starting in CSM 1.7.0, selective
node personalization is supported. All worker nodes are still **configured** for iSCSI, but selective node
personalization gives administrators control over which worker nodes are actually enabled as iSCSI SBPS targets.
The default behavior is still the same as in CSM 1.6, so if no action is taken to use this feature, then all
worker nodes will be enabled as iSCSI targets.

For administrators who do not wish to use this feature, no action is required, and this step can be skipped.
Otherwise, before proceeding with the install, follow the procedure in the
[CSM install](../operations/iscsi_sbps/Managing_Selective_Node_Personalization.md#csm-install) section of
[Managing Selective Node Personalization](../operations/iscsi_sbps/Managing_Selective_Node_Personalization.md).

Later in the install process, [SAT Bootprep](../operations/system_admin_toolkit/usage/SAT_Bootprep.md) adds the
iSCSI configuration layer to the NCN CFS configurations. If the above procedure to enable this feature has not
been done when that CFS configuration is applied to the NCNs, then all of the worker nodes will be enabled as
iSCSI targets.

## 9. Configure management nodes with CFS

Management nodes need to be configured after booting for administrative access, security, and other
purposes. The [Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs)
is used to apply post-boot configuration in a decoupled, layered manner. Individual software products
provide one or more layers included in a CFS configuration. The CFS configuration is applied to node
images (during image customization) and to booted nodes (during node personalization). This includes
both management nodes and managed nodes.

The procedure in this step creates a CFS configuration that contains only the base layers provided by the CSM product, and then applies
that configuration to the booted management nodes. Later, [SAT Bootprep](../operations/system_admin_toolkit/usage/SAT_Bootprep.md)
will generate the full CFS configuration including additional CSM layers and all product layers.

1. (`ncn-mw#`) Set the variable `CSM_RELEASE` to the CSM release version.

    For example:

    ```bash
    CSM_RELEASE="1.7.0"
    ```

1. (`ncn-mw#`) Run the `apply_csm_configuration.sh` script.

    This script creates a new CFS configuration named `management-csm-${CSM_RELEASE}`
    and applies it to the management node components in CFS, enables them,
    and clears their state and error count. It then waits for all the management nodes
    to complete their configuration.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --config-name "management-csm-${CSM_RELEASE}" --clear-state
    ```

    Successful output will end with a message similar to the following:

    ```text
    Configuration complete. 9 component(s) completed successfully.  0 component(s) failed.
    ```

    The number reported should match the number of management nodes in the system.
    If there are failures, see [Troubleshoot CFS Issues](../operations/configuration_management/Troubleshoot_CFS_Issues.md).

## 10. Restart Rack Resiliency critical services

> Skip this step if the Rack Resiliency feature is not enabled.
> For more information, see
> [Enable Rack Resiliency During Install or Upgrade](../operations/rack_resiliency/Enable_Rack_Resiliency_During_Install_or_Upgrade.md).

(`ncn-mw#`) Restart the critical services for Rack Resiliency.

```bash
python3 /usr/share/doc/csm/upgrade/scripts/k8s/rr_critical_service_restart.py
```

## 11. Proceed to next topic

After completing the operational procedures above which configure administrative access, the next
step is to validate the health of management nodes and CSM services.

See [Validate CSM Health](README.md#6-validate-csm-health).
