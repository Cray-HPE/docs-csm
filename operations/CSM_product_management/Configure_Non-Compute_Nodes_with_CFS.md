# Configure Non-Compute Nodes with CFS

Non-compute node (NCN) personalization applies post-boot configuration to the
HPE Cray EX management nodes. Several HPE Cray EX product environments outside
of CSM require NCN personalization to function. Consult the manual for each
product to configure them on NCNs by referring to the
[HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-S-8000)
on the HPE Customer Support Center.

This procedure defines the NCN personalization process for the CSM product using
the [Configuration Framework Service (CFS)](../configuration_management/Configuration_Management.md).

During a fresh install, carry out these procedures in order. Later, individual
procedures may be re-run as needed. These procedures are not done as part of CSM upgrades.
In particular, during upgrades, different procedures are provided that handle management NCN
personalization. Review the upgrade documentation for more information.

1. [Set up passwordless SSH](#1-set-up-passwordless-ssh)
   - [Option 1: Use the CSM-provided SSH keys](#option-1-use-the-csm-provided-ssh-keys)
   - [Option 2: Provide custom SSH keys](#option-2-provide-custom-ssh-keys)
   - [Option 3: Disable CSM-provided passwordless SSH](#option-3-disable-csm-provided-passwordless-ssh)
   - [Restore CSM-provided SSH keys](#restore-csm-provided-ssh-keys)
2. [Configure the `root` password and SSH keys in Vault](#2-configure-the-root-password-and-ssh-keys-in-vault)
   - [Option 1: Automated default](#option-1-automated-default)
   - [Option 2: Manual](#option-2-manual)
3. [Perform management NCN personalization](#3-perform-management-ncn-personalization)
   - [Option 1: Automatic configuration](#option-1-automatic-configuration)
     - [Automatic configuration: CSM fresh install](#automatic-configuration-csm-fresh-install)
     - [Automatic configuration: Apply changes](#automatic-configuration-apply-changes)
     - [Automatic configuration: Modes of operation](#automatic-configuration-modes-of-operation)
     - [Automatic configuration: Usage](#automatic-configuration-usage)
     - [Automatic configuration: Parameters](#automatic-configuration-parameters)
   - [Option 2: Manual configuration](#option-2-manual-configuration)

## 1. Set up passwordless SSH

This procedure should be run during CSM installation and any later time when
the SSH keys need to be changed per site requirements.

The goal of passwordless SSH is to enable an easy way for interactive
passwordless SSH from and between CSM product environments (management nodes) to
downstream managed product environments (COS, UAN, etc), without requiring each
downstream environment to create and apply individual changes to NCNs, and as a
primary way to manage passwordless SSH configuration between management nodes.
Passwordless SSH from downstream nodes into CSM management nodes is not intended
or supported.

Passwordless SSH keypairs for the Cray System Management (CSM) are created
automatically and maintained with a Kubernetes deployment and staged into
Kubernetes secrets (`csm-private-key`) and ConfigMaps (`csm-public-key`) in the
`services` namespace. Administrators can use these provided keys, provide their
own keys, or use their own solution for authentication.

The management of keys on NCNs is achieved by the `trust-csm-ssh-keys` and
`passwordless-ssh` Ansible roles in the CSM configuration management repository.
The SSH keypair is applied to management nodes using NCN personalization.

> **`NOTE`** CFS itself does not use the CSM-provided (or user-supplied) SSH keys
> to make connections between nodes. CFS will continue to function if
> passwordless SSH is disabled between CSM and other product environments.

### Option 1: Use the CSM-provided SSH keys

The default CSM Ansible plays are already configured to enable Passwordless SSH
by default. No further action is necessary before proceeding to
[Configure the `root` password and SSH keys in Vault](#2-configure-the-root-password-and-ssh-keys-in-vault).

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

    - Manually provide custom SSH keys

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

Passwordless SSH with the provided keys will be set up once NCN personalization
runs on the NCNs.

> **`NOTE`**: This keypair may be the same keypair used for the NCN `root` user, but it
is not required to be the same. Either option is valid.

Proceed [Configure the `root` password and SSH keys in Vault](#2-configure-the-root-password-and-ssh-keys-in-vault).

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
and subsequent update of the [configuration layer](../configuration_management/Configuration_Layers.md)
associated with the product.

Proceed [Configure the `root` password and SSH keys in Vault](#2-configure-the-root-password-and-ssh-keys-in-vault).

### Restore CSM-provided SSH keys

> Use this procedure if switching from custom keys to the default CSM SSH keys
> only; otherwise it should be skipped.

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

## 2. Configure the `root` password and SSH keys in Vault

The `root` user password and SSH keys are managed on NCNs by using the
`csm.password` and `csm.ssh_keys` Ansible roles, respectively, located in the
CSM configuration management repository. `root` user passwords and SSH keys are
set and managed in Vault.

There are two options for setting the `root` password and SSH keys in Vault:
[automated default](#option-1-automated-default) or [manual](#option-2-manual).

After these have been set in Vault, they will automatically be applied to NCNs during NCN personalization.
For more information on how to configure and run NCN personalization, see
[3. Perform management NCN personalization](#3-perform-management-ncn-personalization).

### Option 1: Automated default

The automated default method uses the `write_root_secrets_to_vault.py` script to read in the current
`root` user password and SSH keys from the NCN where it is run, and write those to Vault. All of the NCNs are
booted from images which already had their `root` passwords and SSH keys customized during the
[Deploy Management Nodes](../../install/deploy_non-compute_nodes.md#2-deploy-management-nodes)
procedure of the CSM install. In most cases, these are the same password and keys that should be
written to Vault, and this script provides an easy way to do that.

Specifically, the `write_root_secrets_to_vault.py` script reads the following from the NCN where it is run:

- The `root` user password hash from the `/etc/shadows` file.
- The private SSH key from `/root/.ssh/id_rsa`.
- The public SSH key from `/root/.ssh/id_rsa.pub`.

This script can be run on any NCN which is configured to access the Kubernetes cluster.

> The `docs-csm` RPM must be installed in order to use this script. See
> [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation)

(`ncn-mw#`) Run the script with the following command:

```bash
/usr/share/doc/csm/scripts/operations/configuration/write_root_secrets_to_vault.py
```

A successful execution will exit with return code 0 and will have output similar to the following:

```text
Reading in file '/root/.ssh/id_rsa'
Reading in file '/root/.ssh/id_rsa.pub'
Reading in file '/etc/shadow'
Found root user line in /etc/shadow

Initializing Kubernetes client

Getting Vault token from vault/cray-vault-unseal-keys Kubernetes secret

Examining Kubernetes cray-vault service to determine URL for Vault API endpoint of secret/csm/users/root

Writing SSH keys and root password hash to secret/csm/users/root in Vault
Making POST request to http://10.18.232.40:8200/v1/secret/csm/users/root
Response status code = 204

Read back secrets from Vault to verify that the values were correctly saved
Making GET request to http://10.18.232.40:8200/v1/secret/csm/users/root
Response status code = 200

Validating that Vault contents match what was written to it
All secrets successfully written to Vault

SUCCESS
```

Proceed to [3. Perform management NCN personalization](#3-perform-management-ncn-personalization).

### Option 2: Manual

> **`NOTE`**: Information on writing the `root` user password and the SSH keys to Vault is documented
> in two separate procedures. However, if both the password and the SSH keys are to be stored
> in Vault (the standard case), then the two procedures must be combined. Specifically, only
> a single `write` command must be made to Vault, containing both the password and the
> SSH keys. If multiple `write` commands are performed, only the information from the
> final command will persist.

Set the `root` user password and SSH keys in Vault by combining the following two procedures:

- The `Configure Root Password in Vault` procedure in [Update NCN User Passwords](../security_and_authentication/Update_NCN_Passwords.md#procedure-configure-root-password-in-vault).
- The `Configure Root SSH Keys in Vault` procedure in [Update NCN User SSH Keys](../security_and_authentication/SSH_Keys.md#procedure-apply-root-ssh-keys-to-ncns-standalone).

Proceed to [3. Perform management NCN personalization](#3-perform-management-ncn-personalization).

## 3. Perform management NCN personalization

The previous procedures on this page did not make any changes to the NCNs on the system. They merely
specified how the NCNs should be configured. In order for these configurations to be applied to the NCNs,
a process called NCN personalization takes place using [CFS](../configuration_management/Configuration_Management.md).

There are two steps:

1. Create or update the NCN personalization configuration in CFS, if needed.
1. Update CFS to set the NCN personalization configuration as the desired configuration for the NCNs.

These can be accomplished by following [Option 1: Automatic configuration](#option-1-automatic-configuration) or [Option 2: Manual configuration](#option-2-manual-configuration).

### Option 1: Automatic configuration

This option uses a script to create or update the NCN personalization configuration in CFS, and then to
apply the configuration to the NCNs.

> The `docs-csm` RPM must be installed in order to use this script. See
> [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

The options used with the script depend on the context in which this procedure is being followed.

- If this procedure is being run for the first time, during a CSM fresh install, then follow the
  [Automatic configuration: CSM fresh install](#automatic-configuration-csm-fresh-install) procedure.
- If this procedure is being run later in order to make changes to passwordless SSH, root user password, or root user SSH keys,
  then follow the [Automatic configuration: Apply changes](#automatic-configuration-apply-changes) procedure. That is also the
  procedure to follow in order to force NCN personalization to be re-run on all of the NCNs.

In either case, although it is not usually required, it is possible to further customize the behavior of the script.
For more information, see:

- [Automatic configuration: Modes of operation](#automatic-configuration-modes-of-operation)
- [Automatic configuration: Usage](#automatic-configuration-usage)
- [Automatic configuration: Parameters](#automatic-configuration-parameters)

#### Automatic configuration: CSM fresh install

> At this point in the fresh install process, the only product installed on the system is CSM. Therefore the CFS configuration
> that the script creates for management NCN personalization will only contain the CSM layer.

(`ncn-mw#`) When performing this procedure during a CSM fresh install, the recommended command to run is the following:

```bash
/usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh
```

#### Automatic configuration: Apply changes

(`ncn-mw#`) In order to force NCN personalization to run on all of the management NCNs, run the following command:

```bash
/usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh --no-config-change --clear-state
```

#### Automatic configuration: Modes of operation

The script has two basic modes of operation:

- In the default mode (which can be explicitly specified by using the
  `--config-change` parameter), the script will create or update a CFS configuration and then apply it to the management NCNs.
  In this mode, the script performs the following steps:

  1. Finds the latest installed release version of the CSM product stream.
  1. Finds the CSM configuration version associated with the given release.
  1. Finds the latest commit on the corresponding release branch of the `csm-config-management` repository.
  1. Finds all nodes in HSM with the `Management` role.
  1. Disables all management NCNs in CFS.
  1. Updates the `ncn-personalization` configuration in CFS to contain only the CSM layer for the latest installed CSM release.
  1. In CFS, enables all management NCNs, clears their error count, and sets their desired configuration to `ncn-personalization`.
  1. Monitors CFS until all management NCNs have successfully completed or failed configuration.

- In its other mode (specified by using the `--no-config-change`), the script applies an existing CFS configuration to
  the management NCNs. In this mode, the script performs the following steps:

  1. Finds all nodes in HSM with the `Management` role.
  1. In CFS, enables all management NCNs, clears their error count, and sets their desired configuration to `ncn-personalization`.
  1. Monitors CFS until all management NCNs have successfully completed or failed configuration.

#### Automatic configuration: Usage

(`ncn-mw#`) View a usage message for the script, documenting all of its parameters, by running the following command:

```bash
/usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh -h
```

#### Automatic configuration: Parameters

The script also supports several flags to override the default behaviors described previously.
Some of these flags apply to both modes of operation, whereas others apply only to the
`--config-change` mode.

- Common parameters
  - `--clear-state`: Clears existing state from components to ensure that CFS runs, even if no
    changes have been made to the content of the CFS configuration.
  - `--config-name`: For `--config-change` mode, this is the name of the CFS configuration that
    is created or updated. For `--no-config-change` mode, this is the name of the existing CFS configuration
    to use on the management NCNs. In either case, it defaults to `ncn-personalization`.
  - `--no-clear-err`: By default, the error count is cleared on all of the management NCN CFS components. If this
    parameter is specified, the error count is not cleared.
  - `--xnames`: A comma-separated list of component names (xnames) to deploy to. Defaults to all
    `Management` nodes in HSM.
- `--config-change` parameters
  - `--csm-release`: Overrides the version of the CSM release that is used.

    (`ncn-mw#`) Available versions can be found in the `cray-product-catalog` ConfigMap.

    ```bash
    kubectl -n services get cm cray-product-catalog
    ```

    If not specified, the script chooses the latest version found in the above ConfigMap.
  - `--csm-config-version`: Overrides the version of the CSM configuration. This corresponds
    to the version of a branch starting with `cray/csm/` in the `csm` repository in VCS.
  - `--git-commit`: Overrides the Git commit cloned for the configuration content.
    Defaults to the latest commit on the `csm-release` branch.
  - `--git-clone-url`: Overrides the source of the configuration content. Defaults
    to `https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git`.
  - `--ncn-config-file`: This argument is used in order to base the new CFS configuration
    on the specified file, rather than creating a new one that contains only the CSM layer.
    If a file is specified, then the new CFS configuration made by the script will have the
    contents of the specified file, except that the CSM layer will be added or updated to
    use the new Git commit.

### Option 2: Manual configuration

> This is only recommended for experienced administrators with specific reasons not to use the automatic procedure.

In order to manually run management NCN personalization, first gather the following information:

- HTTP clone URL for the configuration repository in [VCS](../configuration_management/Version_Control_Service_VCS.md).
- Path to the Ansible play to run in the repository.
- Git commit ID in the repository for CFS to pull and run on the nodes.

| Field | Value  | Description  |
|:----------|:----------|:----------|
| `cloneUrl` | `https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git` | CSM configuration repository |
| `commit`  | **Example:** `5081c1ecea56002df41218ee39f6030c3eebdf27` | CSM configuration commit hash |
| `name` | **Example:** `csm-1.9.21` | CSM configuration layer name |
| `playbook` | `site.yml` | Default site-wide Ansible playbook for CSM |

1. Retrieve the commit in the repository to use for configuration. If changes
   have been made to the default branch that was imported during a CSM
   installation or upgrade, use the commit containing the changes.

1. If no changes have been made, then the latest commit on the default branch for
   this version of CSM should be used.

   (`ncn-mw#`) Find the commit in the `cray-product-catalog` ConfigMap for the current version of CSM. For example:

   ```bash
   kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
   ```

   Look for something similar to the following in the output:

   ```yaml
   1.2.0:
      configuration:
         clone_url: https://vcs.cmn.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
         commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
         import_branch: cray/csm/1.9.24
         import_date: 2021-07-28 03:26:01.869501
         ssh_url: git@vcs.cmn.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
   ```

   The commit will be different for each system and version of CSM. For
   this example, it is `43ecfa8236bed625b54325ebb70916f55884b3a4`.

1. Craft a new configuration layer entry for the new CSM.

    ```json
    {
        "name": "csm-<version>",
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
        "playbook": "site.yml",
        "commit": "<retrieved git commit ID>"
    }
    ```

1. Create or update the NCN personalization configuration in CFS.

    > **`NOTE`** The CSM configuration layer **MUST** be the first layer in the
    > NCN personalization CFS configuration.

    Follow the option that applies to the current situation:

    - If a CSM fresh install is being performed, then create a management NCN personalization CFS configuration.

      Create a CFS configuration whose only layer is the CSM configuration layer, using the JSON
      from the previous step. See [Perform NCN Personalization](Perform_NCN_Personalization.md).

    - Otherwise, update the existing management NCN personalization CFS configuration, replacing the
      existing CSM configuration layer with the JSON from the previous step. See
      [Perform NCN Personalization](Perform_NCN_Personalization.md).
