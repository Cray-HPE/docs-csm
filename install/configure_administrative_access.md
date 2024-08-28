# Configure Administrative Access

There are several operations which configure administrative access to different parts of the system.
Ensuring that the `cray` CLI can be used with administrative credentials enables use of many
management services via commands. Authentication of the `sat` CLI allows the use of additional
administrative commands. The management nodes can be locked from accidental manipulation by the
`cray power` and `cray fas` commands when the intent is to work on the entire system except the
management nodes. The `cray scsd` command can change the SSH keys, NTP server, `syslog` server,
and BMC/controller passwords.

## Topics

- [Configure Administrative Access](#configure-administrative-access)
    - [Topics](#topics)
    - [1. Configure the Cray and SAT command line interfaces](#1-configure-the-cray-and-sat-command-line-interfaces)
        - [Automatic configuration using temporary Keycloak account](#automatic-configuration-using-temporary-keycloak-account)
        - [Manual configuration](#manual-configuration)
    - [2. Set `Management` role on the BMCs of management nodes](#2-set-management-role-on-the-bmcs-of-management-nodes)
    - [3. Lock management nodes](#3-lock-management-nodes)
    - [4. Configure BMC and controller parameters with SCSD](#4-configure-bmc-and-controller-parameters-with-scsd)
    - [5. Set up passwordless SSH](#5-set-up-passwordless-ssh)
    - [6. Configure the root password and SSH keys in Vault](#6-configure-the-root-password-and-ssh-keys-in-vault)
    - [7. Add switch admin password to Vault](#7-add-switch-admin-password-to-vault)
    - [8. Configure management nodes with CFS](#8-configure-management-nodes-with-cfs)
    - [9. Proceed to next topic](#9-proceed-to-next-topic)

> **`NOTE`** The procedures in this section of installation documentation are intended to be done in order, even though the topics are
> administrative or operational procedures. The topics themselves do not have navigational links to the next topic in the sequence.

## 1. Configure the Cray and SAT command line interfaces

The `cray` command line interface (CLI) is a framework created to integrate all of the system
management REST APIs into easily usable commands. The System Admin Toolkit (SAT) CLI, `sat`, is an
additional CLI that automates common administrative workflows.

Later procedures in the installation workflow use the `cray` and `sat` commands to interact with
multiple services. The `cray` and `sat` CLI configurations need to be initialized for the Linux
account. The Keycloak user who initializes these CLI configurations needs to be authorized for
administrative actions.

### Cray CLI Configuration

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

### SAT CLI Configuration

Follow the procedures in [SAT Configuration](../operations/system_admin_toolkit/configuration/README.md)
to configure `sat` and authenticate to the API Gateway.

## 2. Set `Management` role on the BMCs of management nodes

The BMCs that control management nodes will not have been marked with the `Management` role in HSM. It is important
to mark them with the `Management` role so that they can be easily included in the locking/unlocking operations required
as protections for FAS and PCS actions.

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

The System Configuration Service (SCSD) allows administrators to set various BMC and controller parameters for
components in liquid-cooled cabinets. At this point in the install, SCSD should be used to set the
SSH key in the node controllers (BMCs) to enable troubleshooting. If any of the nodes fail to power
down or power up as part of the compute node booting process, it may be necessary to look at the logs
on the BMC for node power down or node power up.

See [Configure BMC and Controller Parameters with SCSD](../operations/system_configuration_service/Configure_BMC_and_Controller_Parameters_with_scsd.md).

## 5. Set up passwordless SSH

See [Set up passwordless SSH](../operations/CSM_product_management/Set_Up_Passwordless_SSH.md)
for the procedure to configure passwordless SSH between management nodes and from management nodes
to managed nodes.

This procedure sets up resources in Kubernetes (a Kubernetes Secret and ConfigMap) which are later
applied to the management nodes using CFS node personalization in section
[7. Configure management nodes with CFS](#8-configure-management-nodes-with-cfs) below.

## 6. Configure the root password and SSH keys in Vault

See [Configure the `root` password and SSH keys in Vault](../operations/CSM_product_management/Configure_the_root_Password_and_SSH_Keys_in_Vault.md)
for the procedure to configure the `root` password and SSH keys in Vault.

This procedure writes the `root` password hash and SSH keys to Vault which are later
applied to the management nodes using CFS node personalization in section
[7. Configure management nodes with CFS](#8-configure-management-nodes-with-cfs) below.

## 7. Add switch admin password to Vault

If CSM has been installed and Vault is running, add the switch credentials into Vault. Certain
tests, including `goss-switch-bgp-neighbor-aruba-or-mellanox` use these credentials to test the
state of the switch. This step is not required to configure the management network. If Vault is
unavailable, this step can be temporarily skipped. Any automated tests that depend on the switch
credentials being in Vault will fail until they are added.

(`ncn-m001#`) The following script will prompt for the password, write it to Vault, and then read it back
to verify that it was written correctly.

```bash
/usr/share/doc/csm/scripts/operations/configuration/write_sw_admin_pw_to_vault.py
```

On success, the script will exit with return code 0 and have the following final lines
of output:

```text
Writing switch admin password to Vault
Password read from Vault matches what was written
SUCCESS
```

## 8. Configure management nodes with CFS

Management nodes need to be configured after booting for administrative access, security, and other
purposes. The [Configuration Framework Service (CFS)](../operations/configuration_management/Configuration_Management.md)
is used to apply post-boot configuration in a decoupled, layered manner. Individual software products
provide one or more layers included in a CFS configuration. The CFS configuration is applied to components,
including management nodes, during post-boot node personalization.

The procedure here creates a CFS configuration that contains only the layer provided by the CSM product and
then applies that configuration to the management nodes.

1. (`ncn-m001#`) Set the variable `CSM_RELEASE` to the CSM release version.

    For example:

    ```bash
    CSM_RELEASE="1.6.0"
    ```

1. (`ncn-m001#`) Run the `apply_csm_configuration.sh` script.

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

    The number reported should match the number of management nodes in the system. If there are failures, see [Troubleshoot CFS Issues](../operations/configuration_management/Troubleshoot_CFS_Issues.md).

## 9. Proceed to next topic

After completing the operational procedures above which configure administrative access, the next
step is to validate the health of management nodes and CSM services.

See [Validate CSM Health](README.md#6-validate-csm-health).
