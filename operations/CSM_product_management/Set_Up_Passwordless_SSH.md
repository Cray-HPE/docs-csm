# Set up passwordless SSH

- [Overview]
- [Options to set SSH keys]
    - [Option 1: Use the CSM-provided SSH keys](#option-1-use-the-csm-provided-ssh-keys)
    - [Option 2: Provide custom SSH keys](#option-2-provide-custom-ssh-keys)
    - [Option 3: Disable CSM-provided passwordless SSH](#option-3-disable-csm-provided-passwordless-ssh)
    - [Option 4: Restore CSM-provided SSH keys](#option-4-restore-csm-provided-ssh-keys)
- [SSH configuration files](#ssh-configuration-files)
    - [Back up the SSH configuration to Vault](#back-up-the-ssh-configuration-to-vault)
    - [Delete the SSH configuration from Vault](#delete-the-ssh-configuration-from-vault)
    - [Restore the SSH configuration from Vault](#restore-the-ssh-configuration-from-vault)
- [Apply configuration with CFS node personalization](#apply-configuration-with-cfs-node-personalization)

## Overview

This procedure sets up passwordless SSH from management nodes to other management nodes and from
management nodes to managed nodes such as compute nodes running User Services Software (USS)
and User Access Nodes (UANs). This procedure **does not** configure passwordless SSH from managed
nodes to management nodes.

This procedure should be run during CSM installation and any later time when the SSH keys need to be
changed per site requirements.

An SSH key pair is automatically created and maintained by a Kubernetes deployment provided by Cray
System Management (CSM). The public and private keys are store in a Kubernetes ConfigMap
(`csm-public-key`) and a Kubernetes secret (`csm-private-key`) in the `services` namespace,
respectively. Administrators can use these provided keys, provide their own keys, or use their own
solution for authentication.

The CSM product provides two Ansible roles which configure nodes with this SSH keypair. The
`passwordless-ssh` role puts the public and private key files in the SSH configuration directory.
The `passwordless-ssh` role is only used on management nodes, ensuring that passwordless SSH is only
configured from management nodes to other nodes. The `trust-csm-ssh-keys` Ansible role adds the CSM
public key to the `authorized_keys` file, which allows passwordless SSH with the CSM private key.
The `trust-csm-ssh-keys` role is used on management nodes and on managed nodes, ensuring that
passwordless SSH works to either of these node types.

> **`NOTE`** CFS itself does not use the CSM-provided (or user-supplied) SSH keys to make
> connections between nodes. CFS will continue to function if passwordless SSH is disabled between
> as described in [Option 3: Disable CSM-provided passwordless SSH](#option-3-disable-csm-provided-passwordless-ssh)

[SSH configuration files](#ssh-configuration-files) can be used to further simplify the process of using passwordless SSH.

## Options to set SSH keys

There are four options to choose from to set up passwordless SSH. Choose only one
of the following options:

- [Option 1: Use the CSM-provided SSH keys](#option-1-use-the-csm-provided-ssh-keys)
- [Option 2: Provide custom SSH keys](#option-2-provide-custom-ssh-keys)
- [Option 3: Disable CSM-provided passwordless SSH](#option-3-disable-csm-provided-passwordless-ssh)
- [Option 4: Restore CSM-provided SSH keys](#option-4-restore-csm-provided-ssh-keys)

### Option 1: Use the CSM-provided SSH keys

The installation of CSM automatically provides an SSH keypair in a Kubernetes ConfigMap and secret,
and the default CSM Ansible plays enable passwordless SSH. No further action is necessary to accept
this CSM default.

In order to make passwordless SSH more convenient, see [SSH configuration files](#ssh-configuration-files).

### Option 2: Provide custom SSH keys

(`ncn-mw#`) Administrators may elect to replace the CSM-provided keys with their own custom
keys.

1. Set variables to the locations of the public and private SSH key files.

    > Replace the values in the examples below with the paths to the desired
    > key files on the system.

    ```bash
    PUBLIC_KEY_FILE=/path/to/id_rsa-csm.pub
    PRIVATE_KEY_FILE=/path/to/id_rsa-csm
    ```

1. Provide the custom keys by script or manually.

    There are two options for providing the keys.

    - Provide custom SSH keys by script.

        The `replace_ssh_keys.sh` script can be used to replace the keys from files.

        > The `docs-csm` RPM must be installed in order to use this script. See
        > [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation)

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/replace_ssh_keys.sh \
                --public-key-file "${PUBLIC_KEY_FILE}" --private-key-file "${PRIVATE_KEY_FILE}"
        ```

    - Manually provide custom SSH keys.

        The keys stored in Kubernetes can be updated directly.

        1. Replace the private key half:

            ```bash
            KEY64=$(cat "${PRIVATE_KEY_FILE}" | base64) &&
                 kubectl get secret -n services csm-private-key -o json | \
                    jq --arg value "$KEY64" '.data["value"]=$value' | kubectl apply -f - &&
                 unset KEY64
            ```

        1. Replace the public key half:

            ```bash
            kubectl delete configmap -n services csm-public-key &&
                    cat "${PUBLIC_KEY_FILE}" | base64 > ./value &&
                    kubectl create configmap --from-file value csm-public-key --namespace services &&
                    rm ./value
            ```

Passwordless SSH with the provided keys will be set up once node personalization
runs on the management nodes.

> **`NOTE`**: This keypair may be the same keypair used for the `root` user on management nodes, but
> it is not required to be the same. Either option is valid.

In order to apply this change, see [Apply configuration with CFS node personalization](#apply-configuration-with-cfs-node-personalization).

In order to make passwordless SSH more convenient, see [SSH configuration files](#ssh-configuration-files).

### Option 3: Disable CSM-provided passwordless SSH

Local site security requirements may preclude use of passwordless SSH access between
management nodes. A variable has been added to the associated Ansible roles that
allows disabling of passwordless SSH setup to any or all nodes.

(`ncn-mw#`) From the cloned `csm-config-management` repository directory:

```bash
grep csm_passwordless_ssh_enabled roles/trust-csm-ssh-keys/defaults/main.yaml
```

Example output:

```yaml
csm_passwordless_ssh_enabled: 'false'
```

This variable can be overwritten using either a host-specific setting or `global` to affect
all nodes where the playbook is run. See
[Customize Configuration Values](../configuration_management/Customize_Configuration_Values.md)
for more detailed information. Do not modify the value in the `roles/trust-csm-ssh-keys/defaults/main.yaml`
file.

Published roles within product configuration repositories can contain more comprehensive
information regarding these role-specific flags. Reference any role-specific associated `Readme.md`
documents for additional information, because role documentation is updated more frequently as
changes are introduced.

Consult the manual for each product in order to change the default configuration by
referring to the [HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-S-8000)
on the HPE Customer Support Center. Similar configuration values for disabling the
role will be required in these product-specific configuration repositories.

Modifying Ansible plays in a configuration repository will require a new commit
and subsequent update of the configuration layer associated with the product. For more information on
configuration layers, see [CFS Configurations](../configuration_management/CFS_Configurations.md).

Proceed to [Apply configuration with CFS node personalization](#apply-configuration-with-cfs-node-personalization).

### Option 4: Restore CSM-provided SSH keys

Use this procedure if switching from custom keys to the default CSM SSH keys only.

(`ncn-mw#`) In order to restore the default CSM keys, there are two options:

- Restore by script.

    > The `docs-csm` RPM must be installed in order to use this script. See
    > [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation)

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/restore_ssh_keys.sh
    ```

- Restore manually.

    The keys can be deleted from Kubernetes directly. The `csm-ssh-keys` Kubernetes deployment
    provided by CSM periodically checks the ConfigMap and secret containing the key information.
    If these entries do not exist, it will recreate them from the default CSM keys. Therefore, in
    order to manually restore the keys, delete the associated ConfigMap and secret. The default CSM-provided
    keys will be republished.

    1. Delete the `csm-private-key` Kubernetes secret.

        ```bash
        kubectl delete secret -n services csm-private-key
        ```

    1. Delete the `csm-public-key` Kubernetes ConfigMap.

        ```bash
        kubectl delete configmap -n services csm-public-key
        ```

Proceed to [Apply configuration with CFS node personalization](#apply-configuration-with-cfs-node-personalization).

## SSH configuration files

(`ncn#`) Completing [Option 1](#option-1-use-the-csm-provided-ssh-keys) or [Option 2](#option-2-provide-custom-ssh-keys)
allows commands like the following to work without having to specify a password:

```bash
ssh -i /root/.ssh/csm-ecdsa x3000c0s10b4n0
```

The path to the key file does not need to be specified if an appropriate SSH configuration file is created with
path `/root/.ssh/config` on the NCNs from which the SSH commands will be run. Here is an example of possible contents
of this file:

```text
Host nid*
  IdentityFile /root/.ssh/csm-ecdsa
  StrictHostKeyChecking no

Host uan* 
  IdentityFile /root/.ssh/csm-ecdsa
  StrictHostKeyChecking no

Host app*
  IdentityFile /root/.ssh/csm-ecdsa
  StrictHostKeyChecking no

Host lnet*
  IdentityFile /root/.ssh/csm-ecdsa
  StrictHostKeyChecking no

Host x*c?s*b?n?
  IdentityFile /root/.ssh/csm-ecdsa
  StrictHostKeyChecking no
```

This file must be manually created by administrators. Note that this file does not persist across node rebuilds.
CSM provides some tools to help backup and restore the contents of this file.

- [Back up the SSH configuration to Vault](#back-up-the-ssh-configuration-to-vault)
- [Delete the SSH configuration from Vault](#delete-the-ssh-configuration-from-vault)
- [Restore the SSH configuration from Vault](#restore-the-ssh-configuration-from-vault)

### Back up the SSH configuration to Vault

(`ncn#`) The contents of the root SSH configuration file can be written to Vault by running the following script:

> The `docs-csm` RPM must be installed in order to use this script. See
> [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation)

```bash
/usr/share/doc/csm/scripts/operations/configuration/write_ssh_config_to_vault.py
```

By default the script will copy the contents of `/root/.ssh/config`. Run the script with the `--help` option for
information on how to use a different file as the source. For more information on this and related tools, see
[Update Root Secrets In Vault](../security_and_authentication/Update_Root_Secrets_In_Vault.md).

Note that there is a single SSH configuration location in Vault for all management NCNs -- if this script is run on multiple NCNs,
each will overwrite the data from the previous. The expectation is that all NCNs will use the same root SSH configuration file.

### Delete the SSH configuration from Vault

(`ncn#`) The contents of the root SSH configuration file can be deleted from Vault by running the following script:

> The `docs-csm` RPM must be installed in order to use this script. See
> [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation)

```bash
/usr/share/doc/csm/scripts/operations/configuration/write_ssh_config_to_vault.py --delete
```

### Restore the SSH configuration from Vault

(`ncn#`) The contents of the root SSH configuration file can be restored from Vault using the following script:

> The `docs-csm` RPM must be installed in order to use this script. See
> [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation)

```bash
/usr/share/doc/csm/scripts/operations/configuration/restore_ssh_config_from_vault.py
```

By default, the script will do nothing and pass if the SSH configuration does not exist in Vault. If the configuration
is in Vault, then by default it will be written to `/root/.ssh/config`, and will fail if that file already exists.
Run the script with the `--help` option for information on how to change these default behaviors. For more information
on this and related tools, see [Update Root Secrets In Vault](../security_and_authentication/Update_Root_Secrets_In_Vault.md).

## Apply configuration with CFS node personalization

This step is only necessary if performing this procedure as an operational task. If performing
this procedure as part of a CSM install, skip this step and return to
[Configure Administrative Access](../../install/configure_administrative_access.md).

After the SSH keys have been set in the Kubernetes secret and ConfigMap, passwordless SSH will be
configured on management nodes during node personalization. CFS automatically re-configures the
management nodes via the CFS Batcher whenever the CFS configuration applied to the components
changes, the nodes reboot, or the component state is cleared in CFS.
See [Automatic Configuration Management](../configuration_management/Automatic_Configuration_Management.md)
for more information about the CFS Batcher. Since the changes here are made in a Kubernetes secret
and ConfigMap, the CFS Batcher will not automatically apply the new passwordless SSH configuration.

See the [Re-run node personalization on management nodes](../configuration_management/Management_Node_Personalization.md#re-run-node-personalization-on-management-nodes)
procedure to re-run NCN node personalization on management nodes.
