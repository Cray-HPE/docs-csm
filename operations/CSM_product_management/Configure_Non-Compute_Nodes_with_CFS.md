# Configure Non-Compute Nodes with CFS

Non-compute node (NCN) personalization applies post-boot configuration to the
HPE Cray EX management nodes. Several HPE Cray EX product environments outside
of CSM require NCN personalization to function. Consult the manual for each
product to configure them on NCNs by referring to the
[`HPE Cray EX System Software Getting Started Guide (S-8000) 22.06`](http://www.hpe.com/support/ex-gsg-042120221040)
on the `HPE Customer Support Center`.

This procedure defines the NCN personalization process for the CSM product using
the [Configuration Framework Service (CFS)](../configuration_management/Configuration_Management.md).

During a fresh install, carry out these procedures in order. Later, individual
procedures may be re-run as needed.

1. [Set Up Passwordless SSH](#set_up_passwordless_ssh)
   - [Option 1: Use the CSM-provided SSH Keys](#set_up_passwordless_ssh_option_1)
   - [Option 2: Option 2: Provide Custom SSH Keys](#set_up_passwordless_ssh_option_2)
   - [Option 3: Disable CSM-provided Passwordless SSH](#set_up_passwordless_ssh_option_3)
   - [Restore CSM-provided SSH Keys](#set_up_passwordless_ssh_restore)
2. [Configure the Root Password and Root SSH Keys in Vault](#set_root_password)
   - [Option 1: Automated Default](#set_root_password_option_1)
   - [Option 2: Manual](#set_root_password_option_2)
3. [Perform NCN Personalization](#perform_ncn_personalization)
   - [Option 1: Automatically Apply CSM Configuration](#auto_apply_csm_config)
     - [Automatic CSM Configuration Steps](#auto_apply_csm_config_steps)
     - [Automatic CSM Configuration Overrides](#auto_apply_csm_config_overrides)
   - [Option 2: Manually Apply CSM Configuration](#manual_apply_csm_config)

<a name="set_up_passwordless_ssh"></a>

## 1. Set Up Passwordless SSH

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

<a name="set_up_passwordless_ssh_option_1"></a>

### Option 1: Use the CSM-provided SSH Keys

The default CSM Ansible plays are already configured to enable Passwordless SSH
by default. No further action is necessary before running NCN personalization
with CFS.

<a name="set_up_passwordless_ssh_option_2"></a>

### Option 2: Provide Custom SSH Keys

Administrators may elect to replace the CSM-provided keys with their own custom
keys.

1. Set variables to the locations of the public and private SSH key files.

    > Replace the values in the examples below with the paths to the desired
    > key files on the system.

    ```bash
    ncn# PUBLIC_KEY_FILE=/root/.ssh/id_rsa-csm.pub
    ncn# PRIVATE_KEY_FILE=/root/.ssh/id_rsa-csm
    ```

1. Provide the custom keys by script or manually.

    There are two options for providing the keys.

    - Provide custom SSH keys by script.

        The `replace_ssh_keys.sh` script can be used to replace the keys from files.

        > The `docs-csm` RPM must be installed in order to use this script. See
        > [Check for Latest Documentation](../../update_product_stream/index.md#documentation)

        ```bash
        ncn# /usr/share/doc/csm/scripts/operations/configuration/replace_ssh_keys.sh \
                --public-key-file "${PUBLIC_KEY_FILE}" --private-key-file "${PRIVATE_KEY_FILE}"
        ```

    - Manually provide custom SSH keys

        The keys stored in Kubernetes can be updated directly.

        1. Replace the private key half:

            ```bash
            ncn# KEY64=$(cat "${PRIVATE_KEY_FILE}" | base64) &&
                 kubectl get secret -n services csm-private-key -o json | \
                    jq --arg value "$KEY64" '.data["value"]=$value' | kubectl apply -f - &&
                 unset KEY64
            ```

        1. Replace the public key half:

            ```bash
            ncn# kubectl delete configmap -n services csm-public-key &&
                    cat "${PUBLIC_KEY_FILE}" | base64 > ./value &&
                    kubectl create configmap --from-file value csm-public-key --namespace services &&
                    rm ./value
            ```

Passwordless SSH with the provided keys will be set up once NCN personalization
runs on the NCNs.

**NOTE**: This keypair may or may not be the same keypair used for the NCN
`root` user. See the [Configure the Root Password and Root SSH Keys in Vault](#set_root_password)
procedure below for setting the root user SSH keys on NCNs.

<a name="set_up_passwordless_ssh_option_3"></a>

### Option 3: Disable CSM-provided Passwordless SSH

Local site security requirements may preclude use of passwordless SSH access between
management nodes. A variable has been added to the associated Ansible roles that
allows disabling of passwordless SSH setup to any or all nodes. From the cloned
`csm-config-management` repository directory:

```bash
ncn# grep csm_passwordless_ssh_enabled roles/trust-csm-ssh-keys/defaults/main.yaml
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
referring to the [`HPE Cray EX System Software Getting Started Guide (S-8000) 22.06`](http://www.hpe.com/support/ex-gsg-042120221040)
on the `HPE Customer Support Center`. Similar configuration values for disabling the
role will be required in these product-specific configuration repositories.

Modifying Ansible plays in a configuration repository will require a new commit
and subsequent update of the [configuration layer](../configuration_management/Configuration_Layers.md)
associated with the product.

> **NOTE:** CFS itself does not use the CSM-provided (or user-supplied) SSH keys
> to make connections between nodes. CFS will continue to function if
> passwordless SSH is disabled between CSM and other product environments.

<a name="set_up_passwordless_ssh_restore"></a>

### Restore CSM-provided SSH Keys

> Use this procedure if switching from custom keys to the default CSM SSH keys
> only; otherwise it can be skipped.

In order to restore the default CSM keys, there are two options:

- Restore by script.

    > The `docs-csm` RPM must be installed in order to use this script. See
    > [Check for Latest Documentation](../../update_product_stream/index.md#documentation)

    ```bash
    ncn# /usr/share/doc/csm/scripts/operations/configuration/restore_ssh_keys.sh
    ```

- Restore manually.

    The keys can be deleted from Kubernetes directly. The `csm-ssh-keys` Kubernetes deployment
    provided by CSM periodically checks the ConfigMap and secret containing the key information.
    If these entries do not exist, it will recreate them from the default CSM keys. Therefore, in
    order to manually restore the keys, delete the associated ConfigMap and secret. The default CSM-provided
    keys will be republished.

    1. Delete the `csm-private-key` Kubernetes secret.

        ```bash
        ncn# kubectl delete secret -n services csm-private-key
        ```

    1. Delete the `csm-public-key` Kubernetes ConfigMap.

        ```bash
        ncn# kubectl delete configmap -n services csm-public-key
        ```

<a name="set_root_password"></a>

## 2. Configure the Root Password and Root SSH Keys in Vault

The root user password and SSH keys are managed on NCNs by using the
`csm.password` and `csm.ssh_keys` Ansible roles, respectively, located in the
CSM configuration management repository. Root user passwords and SSH keys are
set and managed in Vault.

There are two options for setting the root password and SSH keys in Vault: automated default or manual.

After these have been set in Vault, they will automatically be applied to NCNs during NCN personalization.
For more information on how to configure and run NCN personalization, see the
[Perform NCN Personalization](#perform_ncn_personalization) procedure later in this page.

<a name="set_root_password_option_1"></a>

### Option 1: Automated Default

The automated default method uses the `write_root_secrets_to_vault.py` script to read in the current
root password and SSH keys from the NCN where it is run, and write those to Vault. All of the NCNs are
booted from images which already had their root passwords and SSH keys customized during the
[Deploy Management Nodes](../../install/deploy_management_nodes.md#deploy)
procedure of the CSM install. In most cases, these are the same password and keys that should be
written to Vault, and this script provides an easy way to do that.

Specifically, the `write_root_secrets_to_vault.py` script reads the following from the NCN where it is run:

- The `root` user password hash from the `/etc/shadows` file.
- The private SSH key from `/root/.ssh/id_rsa`.
- The public SSH key from `/root/.ssh/id_rsa.pub`.

This script can be run on any NCN which is configured to access the Kubernetes cluster.

> The `docs-csm` RPM must be installed in order to use this script. See
> [Check for Latest Documentation](../../update_product_stream/index.md#documentation)

Run the script with the following command:

```bash
ncn# /usr/share/doc/csm/scripts/operations/configuration/write_root_secrets_to_vault.py
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

<a name="set_root_password_option_2"></a>

### Option 2: Manual

> **NOTE**: Information on writing the `root` user password and the SSH keys to Vault is documented
> in two separate procedures. However, if both the password and the SSH keys are to be stored
> in Vault (the standard case), then the two procedures must be combined. Specifically, only
> a single `write` command must be made to Vault, containing both the password and the
> SSH keys. If multiple `write` commands are performed, only the information from the
> final command will persist.

Set the `root` user password and SSH keys in Vault by combining the following two procedures:

- The `Configure Root Password in Vault` procedure in [Update NCN User Passwords](../security_and_authentication/Update_NCN_Passwords.md#configure_root_password_in_vault).
- The `Configure Root SSH Keys in Vault` procedure in [Update NCN User SSH Keys](../security_and_authentication/SSH_Keys.md#configure_root_keys_in_vault).

<a name="perform_ncn_personalization"></a>

## 3. Perform NCN Personalization

After completing the previous procedures, apply the configuration to the NCNs
by running NCN personalization with [CFS](../configuration_management/Configuration_Management.md).
This can be accomplished by running the `apply_csm_configuration.sh` script, or by
running the steps manually.

<a name="auto_apply_csm_config"></a>

### Option 1: Automatically Apply CSM Configuration

> The `docs-csm` RPM must be installed in order to use this script. See
> [Check for Latest Documentation](../../update_product_stream/index.md#documentation)

By default the script will select the latest available CSM release. However, for clarity
providing the CSM release version using the `--csm-release` parameter is recommended.

```bash
ncn# /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh --csm-release <version e.g. 1.0.11>
```

<a name="auto_apply_csm_config_steps"></a>

#### Automatic CSM Configuration Steps

By default, the script will perform the following steps:

1. Finds the latest installed release version of the CSM product stream.
1. Finds the CSM configuration version associated with the given release.
1. Finds the latest commit on the release branch of the `csm-config-management` repository.
1. Creates or updates the `ncn-personalization.json` configuration file.
1. Finds all nodes in HSM with the `Management` role.
1. Disables configuration for all NCNs.
1. Updates the `ncn-personalization` configuration in CFS from the `ncn-personalization.json` file.
1. Enables configuration for all NCN nodes, and sets their desired configuration to `ncn-personalization`.
1. Monitors CFS until all NCN nodes have successfully completed or failed configuration.

<a name="auto_apply_csm_config_overrides"></a>

#### Automatic CSM Configuration Overrides

The script also supports several flags to override these behaviors:

- `--csm-release`: Overrides the version of the CSM release that is used. Defaults
  to the latest version. Available versions can be found in the `cray-product-catalog`.

  ```bash
  ncn-m001# kubectl -n services get cm cray-product-catalog
  ```

- `--csm-config-version`: Overrides the version of the CSM configuration. This corresponds
  to the version of a branch starting with `cray/csm/` in the `csm` repository in VCS.
- `--git-commit`: Overrides the Git commit cloned for the configuration content.
  Defaults to the latest commit on the `csm-release` branch.
- `--git-clone-url`: Overrides the source of the configuration content. Defaults
  to `https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git`.
- `--ncn-config-file`: Sets a file other than `ncn-personalization.json` to be
  used for the configuration.
- `--xnames`: A comma-separated list of component names (xnames) to deploy to. Defaults to all
  `Management` nodes in HSM.
- `--clear-state`: Clears existing state from components to ensure that CFS runs. This
   can be used if configuration needs to be re-run on successful nodes with no
   change to the Git content since the previous run; for example, if the SSH
   keys have changed.

<a name="manual_apply_csm_config"></a>

### Option 2: Manually Apply CSM Configuration

In order to manually run NCN personalization, first gather the following information:

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
   this version of CSM should be used. Find the commit in the
   `cray-product-catalog` for the current version of CSM. For example:

   ```bash
   ncn# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
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

1. Craft a new configuration layer entry for the new CSM:

   ```json
         {
            "name": "csm-<version>",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "playbook": "site.yml",
            "commit": "<retrieved git commit ID>"
         }
   ```

1. (Install Only) Follow the procedure in [Perform NCN Personalization](Perform_NCN_Personalization.md),
   adding a CSM configuration layer to the NCN personalization using the JSON
   from step 3.

1. (Upgrade Only) Follow the procedure in [Perform NCN Personalization](Perform_NCN_Personalization.md),
   replacing the existing CSM configuration layer to the NCN personalization
   using the JSON from step 3.

> **NOTE:** The CSM configuration layer **MUST** be the first layer in the
> NCN personalization CFS configuration.
