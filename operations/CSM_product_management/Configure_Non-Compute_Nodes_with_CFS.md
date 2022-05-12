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

This procedure should be run during CSM installation and any later time when
the SSH keys need to be changed.

The goal of passwordless SSH is to enable an easy way for interactive
passwordless SSH from and between CSM product environments (management nodes) to
downstream managed product environments (COS, UAN, etc), without requiring each
downstream environment to create and apply individual changes to NCNs.
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

### Option 1: Use the CSM-provided SSH Keys

The default CSM Ansible plays are already configured to enable Passwordless SSH
by default. No further action is necessary before running NCN personalization
with CFS.

### Option 2: Provide Custom SSH Keys

Administrators may elect to replace the CSM-provided keys with their own custom
keys. The keys stored in Kubernetes can be updated directly.

1. Set variables to the locations of the public and private SSH key files.

    > Replace the values in the examples below with the paths to the desired
    > key files on the system.

    ```bash
    ncn# PUBLIC_KEY_FILE=/root/.ssh/id_rsa-csm.pub
    ncn# PRIVATE_KEY_FILE=/root/.ssh/id_rsa-csm
    ```

1. Replace the private key half:

    ```bash
    ncn# KEY64=$(cat "${PRIVATE_KEY_FILE}" | base64) &&
         kubectl get secret -n services csm-private-key -o json | \
            jq --arg value "$KEY64" '.data["value"]=$value' | kubectl apply -f - &&
         unset KEY64
    ```

1. Replace the public key half:

    ```bash
    ncn# kubectl delete configmap -n services csm-public-key && \
            cat "${PUBLIC_KEY_FILE}" | base64 > ./value && \
            kubectl create configmap --from-file value csm-public-key --namespace services && \
            rm ./value
    ```

Passwordless SSH with the provided keys will be setup once NCN personalization
runs on the NCNs.

### Option 3: Disable CSM-provided Passwordless SSH

Local site security requirements may preclude use of passwordless SSH access. If
this is the case, remove or comment out the invocation of the
`trust-csm-public-keys` role in Ansible plays in the configuration repositories
of the environments where it is configured. By default, the HPE Cray Operating
System (COS) and User Access Node (UAN) configurations enable passwordless SSH.
Refer to the following in the documentation for each product stream to change
the default configuration:

  * COS: Refer to the _VCS Configuration_ section in the _Install or Upgrade COS_
    procedure.
  * UAN: Refer to _Create UAN Boot Images_ and _UAN Ansible Roles_ procedures.

Modifying Ansible plays in a configuration repository will require a new commit
and subsequent update of the [configuration layer](../configuration_management/Configuration_Layers.md)
associated with the product.

> **NOTE:** CFS itself does not use the CSM-provided (or user-supplied) SSH keys
> to make connections between nodes. CFS will continue to function if
> passwordless SSH is disabled between CSM and other product environments.

### Restore CSM-provided SSH Keys

> Use this procedure if switching from custom keys to the default CSM SSH keys
> only; otherwise it can be skipped.

The `csm-ssh-keys` Kubernetes deployment
provided by CSM periodically checks the ConfigMap and secret containing the key information.
If these entries do not exist, it will recreate them from the default CSM keys. Therefore, in
order to manually restore the keys, delete the associated ConfigMap and secret. The default CSM-provided
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

## Configure the Root Password in Vault

The root password is applied to NCNs by using the `csm.password` Ansible role
located in the CSM configuration management repository. Root passwords are set
and managed in Vault.

1. Set the password in Vault by following the _Configure Root Password in Vault_
   procedure in [Update NCN Passwords](../security_and_authentication/Update_NCN_Passwords.md).
1. Apply the Vault password to the NCNs in the
   [NCN personalization](#run_ncn_personalization) procedure.

<a name="run_ncn_personalization"></a>

## Run NCN Personalization

After completing the previous procedures, apply the configuration to the NCNs
by running NCN personalization with [CFS](../configuration_management/Configuration_Management.md).

Prior to running NCN personalization, gather the following information:

* HTTP clone URL for the configuration repository in [VCS](../configuration_management/Version_Control_Service_VCS.md).
* Path to the Ansible play to run in the repository.
* Commit ID in the repository for CFS to pull and run on the nodes.

| Field | Value  | Description  |
|:----------|:----------|:----------|
| `cloneUrl` | `https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git` | CSM configuration repository |
| `commit`  | **Example:** `5081c1ecea56002df41218ee39f6030c3eebdf27` | CSM configuration commit hash |
| `name` | **Example:** `csm-ncn-<version>` | CSM Configuration layer name |
| `playbook` | `site.yml` | Default site-wide Ansible playbook for CSM |

1. Retrieve the commit in the repository to use for configuration. If changes
   have been made to the default branch that was imported during a CSM
   installation or upgrade, use the commit containing the changes.

1. If no changes have been made, the latest commit on the default branch for
   this version of CSM should be used. Find the commit in the
   `cray-product-catalog` for the current version of CSM. For example:

   ```bash
   ncn# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
   ```

   Look for something similar to the following in the output:

   ```yaml
   1.0.1:
      configuration:
         clone_url: https://vcs.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
         commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
         import_branch: cray/csm/1.6.12
         import_date: 2021-07-28 03:26:01.869501
         ssh_url: git@vcs.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
   ```

   The commit will be different for each system and version of CSM. In the above
   example, it is `43ecfa8236bed625b54325ebb70916f55884b3a4`.

1. Craft a new configuration layer entry for the new CSM:

   ```json
         {
            "name": "csm-ncn-<version>",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "playbook": "site.yml",
            "commit": "<retrieved git commit>"
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
