# Configure Non-Compute Nodes with CFS

Non-compute node (NCN) personalization applies post-boot configuration to the
HPE Cray EX management nodes. Several HPE Cray EX product environments outside
of CSM require NCN personalization to function. Consult the manual for each
product to configure them on NCNs by referring to the [1.5 HPE Cray EX System
Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-gsg) on
the HPE Customer Support Center.

This procedure defines the NCN personalization process for the CSM product using
the [Configuration Framework Service (CFS)](../configuration_management/Configuration_Management.md).

<a name="set_up_passwordless_ssh"></a>
## Set Up Passwordless SSH

This procedure should be run during CSM installation and afterwards whenever
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
The SSH keypair is applied to management nodes via NCN personalization.


### Option 1: Use the CSM-provided SSH Keys

The default CSM Ansible plays are already configured to enable Passwordless SSH
by default. No further action is necessary before running NCN personalization
with CFS.

### Option 2: Provide Custom SSH Keys

Administrators may elect to replace the CSM-provided keys with their own custom
keys. The `replace_ssh_keys.sh` script can be used to replace the keys from
files.

```bash
ncn-m001# /usr/share/doc/csm/scripts/operations/configuration/replace_ssh_keys.sh \
--public-key-file ./id_rsa-csm.pub --private-key-file ./id_rsa-csm
```

Alternatively, the keys stored in Kubernetes can be updated directly. 

1. Replace the private key half:
   ```bash
   ncn# kubectl get secret -n services csm-private-key -o json | jq --arg value "$(cat ~/.ssh/id_rsa-csm | base64)" '.data["value"]=$value' | kubectl apply -f -
   ```
   where `~/.ssh/id_rsa-csm` is a local file containing a valid SSH private key.

1. Replace the public key half:
   ```bash
   ncn# kubectl delete configmap -n services csm-public-key && \
      cat ~/.ssh/id_rsa-csm.pub | \
      base64 > ./value && kubectl create configmap --from-file \
      value csm-public-key --namespace services && rm ./value
   ```
   where `~/.ssh/id_rsa-csm.pub` is a local file containing a valid public key
   intended for CSM and downstream products.

Passwordless SSH with the provided keys will be set up once NCN personalization
runs on the NCNs.

**NOTE**: This key pair may or may not be the same key pair used for the NCN
`root` user. See the _Configure the Root Password and Root SSH Keys in Vault_
procedure below for setting the root user SSH keys on NCNs.

###  Option 3: Disable CSM-provided Passwordless SSH

Local site security requirements may preclude use of passwordless SSH access between
management nodes. A variable has been added to the associated ansible roles that will
allow you to disable passwordless SSH setup to any or all nodes. From the cloned
csm-config-management repository directory:

    ```
    ncn# grep csm_passwordless_ssh_enabled roles/trust-csm-ssh-keys/defaults/main.yaml
    ```
    
    Example output:

    ```
    csm_passwordless_ssh_enabled: 'false'
    ```

This variable can be overwritten using either a host-specific setting or 'global' to affect
all nodes where the playbook is run. Please reference [Customize Configuration Values](../configuration_management/Customize_Configuration_Values.md)
for more detailed information. Do not modify the value in the `roles/trust-csm-ssh-keys/defaults/main.yaml`
file.

Published roles within product configuration repositories can contain more comprehensive
information regarding these role-specific flags. Please reference any role specific associated Readme.md
documents for additional information, as role documentation is updated more frequently as
changes are introduced.

Consult the manual for each product to change the default configuration by 
referring to the [1.5 HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-gsg)
on the HPE Customer Support Center. Similar configuration values for disabling the
role will be required in these product specific configuration repositories.

Modifying Ansible plays in a configuration repository will require a new commit
and subsequent update of the [configuration layer](../configuration_management/Configuration_Layers.md)
associated with the product.

> __NOTE__: CFS itself does not use the CSM-provided (or user-supplied) SSH keys
> to make connections between nodes. CFS will continue to function if
> passwordless SSH is disabled between CSM and other product environments.

### Restore CSM-provided SSH Keys

> Use this procedure if switching from custom keys to the default CSM SSH keys
> only, otherwise it can be skipped.

To restore the default CSM keys, administrators can run the
`restore_ssh_keys.sh` script.

```bash
ncn-m001# /usr/share/doc/csm/scripts/operations/configuration/restore_ssh_keys.sh
```

Alternatively, the keys can be deleted from Kubernetes directly.
The `csm-ssh-keys` Kubernetes deployment provided by CSM periodically checks the
ConfigMap and secret containing the key information. If these entries do not
exist, it will recreate them from the default CSM keys. To manually restore
keys, delete the associated ConfigMap and secret, and the default CSM-provided
keys will be republished.

1. Delete the `csm-private-key` Kubernetes secret.
   ```bash
   ncn# kubectl delete secret -n services csm-private-key
   ```
1. Delete the `csm-public-key` Kubernetes configmap.
   ```bash
   ncn# kubectl delete configmap -n services csm-public-key
   ```

<a name="set_root_password"></a>
## Configure the Root Password and Root SSH Keys in Vault

The root user password and SSH keys are managed on NCNs by using the
`csm.password` and `csm.ssh_keys` Ansible roles, respectively, located in the
CSM configuration management repository. Root user passwords and SSH keys are
set and managed in Vault.

1. Set the root user password in Vault by following the _Configure Root Password in Vault_
   procedure in [Update NCN User Passwords](../security_and_authentication/Update_NCN_Passwords.md#configure_root_password_in_vault).
1. Set the root user SSH keys in Vault by following the _Configure Root SSH Keys in Vault_
   procedure in [Update NCN User SSH Keys](../security_and_authentication/SSH_Keys.md#configure_root_keys_in_vault).
1. Apply the Vault password to the NCNs in the
   [Perform NCN personalization](#perform_ncn_personalization) procedure.

<a name="perform_ncn_personalization"></a>
## Perform NCN Personalization

After completing the previous procedures, apply the configuration to the NCNs
by running NCN personalization with [CFS](../configuration_management/Configuration_Management.md).
This can be accomplished by running the `apply_csm_configuration.sh` script, or
running the steps manually. For more information on the script, see
[Automatically Apply CSM Configuration to NCNs](#auto_apply_csm_config).

```bash
ncn-m001# /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh
```

To manually run NCN personalization, first gather the following information: 

* HTTP clone URL for the configuration repository in [VCS](../configuration_management/Version_Control_Service_VCS.md)
* Path to the Ansible play to run in the repository
* Commit ID in the repository for CFS to pull and run on the nodes.


| Field | Value  | Description  |
|:----------|:----------|:----------|
| cloneUrl | https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git | CSM configuration repo |
| commit  | **Example:** `5081c1ecea56002df41218ee39f6030c3eebdf27` | CSM configuration commit hash |
| name | **Example:** `csm-ncn-<version>` | CSM Configuration layer name |
| playbook | `site.yml` | Default site-wide Ansible playbook for CSM | 

1. Retrieve the commit in the repository to use for configuration. If changes
   have been made to the default branch that was imported during a CSM
   installation or upgrade, use the commit containing the changes. 

1. If no changes have been made, the latest commit on the default branch for
   this version of CSM should be used. Find the commit in the
   `cray-product-catalog` for the current version of CSM. For example:
   ```bash
   ncn# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'

   1.0.0:
      configuration:
         clone_url: https://vcs.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
         commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
         import_branch: cray/csm/1.6.12
         import_date: 2021-07-28 03:26:01.869501
         ssh_url: git@vcs.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
      ...
   ```
   The commit will be different for each system and version of CSM. For
   this example, it is:

         43ecfa8236bed625b54325ebb70916f55884b3a4

1. Craft a new configuration layer entry for the new CSM:

         {
            "name": "csm-ncn-<version>",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "playbook": "site.yml",
            "commit": "<retrieved git commit>"
         }

1. (Install Only) Follow the procedure in [Perform NCN Personalization](Perform_NCN_Personalization.md),
   adding a CSM configuration layer to the NCN personalization using the JSON
   from step 3.

1. (Upgrade Only) Follow the procedure in [Perform NCN Personalization](Perform_NCN_Personalization.md),
   replacing the existing CSM configuration layer to the NCN personalization
   using the JSON from the step 3.

> **NOTE:** The CSM configuration layer _MUST_ be the first layer in the
> NCN personalization CFS configuration.

<a name="auto_apply_csm_config"></a>
## Automatically Apply CSM Configuration to NCNs

CSM configuration can automatically be applied to NCNs by running the
`apply_csm_configuration.sh` script.

```bash
ncn-m001# /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh
```

### Automatic CSM Configuration Steps
 
By default the script will perform the following steps:
1. Finds the latest installed release version of the CSM product stream.
1. Finds the latest commit on the release branch of the `csm-config-management` repo.
1. Creates or updates the `ncn-personalization.json` configuration file.
1. Finds all nodes in HSM with the `Management` role.
1. Disables configuration for all NCNs.
1. Updates the `ncn-personalization` configuration in CFS from the `ncn-personalization.json` file.
1. Enables configuration for all NCN nodes, and sets their desired configuration to `ncn-personalization`.
1. Monitors CFS until all NCN nodes have successfully completed, or failed, configuration.

### Automatic CSM Configuration Overrides

The script also supports several flags to override these behaviors:
- `csm-release:` Overrides the version of the CSM release that is used. Defaults
  to the latest version.
- `git-commit`: Overrides the git commit cloned for the configuration content.
  Defaults to the latest commit on the csm-release branch.
- `git-clone-url`: Overrides the source of the configuration content. Defaults
  to `https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git`.
- `ncn-config-file`: Sets a file other than `ncn-personalization.json` to be
  used for the configuration.
- `xnames`: A comma-separated list xnames to deploy to. Defaults to all
  `Management` nodes in HSM.
- `clear-state`: Clears existing state from components to ensure CFS runs. This
   can be used if configuration needs to be re-run on successful nodes with no
   change to the git content since the previous run. For examples, if the ssh
   keys have changed. 