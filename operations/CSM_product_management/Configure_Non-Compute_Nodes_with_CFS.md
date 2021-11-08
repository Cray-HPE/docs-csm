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
primary way to manage passwordless ssh configuration between management nodes.
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
keys.

1. Replace the private key half:
   ```bash
   ncn# kubectl get secret -n services csm-private-key -o json | jq --arg value "$(cat ~/.ssh/id_rsa | base64)" '.data["value"]=$value' | kubectl apply -f -
   ```
   `~/.ssh/id_rsa` is a local file containing a valid SSH private key.

1. Replace the public key half:
   ```bash
   ncn# kubectl delete configmap -n services csm-public-key && \
      cat ~/.ssh/id_rsa.pub | \
      base64 > ./value && kubectl create configmap --from-file \
      value csm-public-key --namespace services && rm ./value
   ```
   `~/.ssh/id_rsa.pub` is a local file containing a valid public key intended for
    CSM and downstream products.

Passwordless SSH with the provided keys will be setup once NCN personalization
runs on the NCNs.

###  Option 3: Disable CSM-provided Passwordless SSH

Local site security requirements may preclude use of passwordless SSH access between
management nodes. A variable has been added to the associated ansible roles that will
allow you to disable passwordless ssh setup to any or all nodes.

    ```
    ncn-w:~ # grep csm_passwordless_ssh_enabled roles/trust-csm-ssh-keys/defaults/main.yaml
    csm_passwordless_ssh_enabled: 'false'
    ```

This variable can be overwritten using either a host specific setting or 'global' to affect
all nodes where the playbook is run. Please reference [Customize Configuration Values](../configuration_management/Customize_Configuration_Values.md)
for more detailed information.

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

The `csm-ssh-keys` Kubernetes deployment provided by CSM periodically checks the
ConfigMap and secret containing the key information. If these entries do not
exist, it will recreate them from the default CSM keys. In this case, deleting
the associated ConfigMap and secrets will republish them with the default
CSM-provided keys.

1. Delete the `csm-private-key` Kubernetes secret.
   ```bash
   ncn# kubectl delete secret -n services csm-private-key
   ```
1. Delete the `csm-public-key` Kubernetes configmap.
   ```bash
   ncn# kubectl delete configmap -n services csm-public-key
   ```

<a name="set_root_password"></a>
## Set the Root Password

This procedure should be run during CSM installation and afterwards whenever
the password needs to be changed per site requirements.

The root password is managed on NCNs by using the `csm.password` Ansible role
located in the CSM configuration management repository. Root passwords are set
and managed in Vault.

1. Set the password in Vault by following steps 1-3 in the
   [Update NCN Passwords](../security_and_authentication/Update_NCN_Passwords.md)
   procedure.
1. Run [NCN personalization](#run_ncn_personalization).

<a name="run_ncn_personalization"></a>
## Run NCN Personalization

After completing the previous procedures, apply the configuration to the NCNs
by running NCN personalization with [CFS](../configuration_management/Configuration_Management.md).

Prior to running NCN personalization, gather the following information: 

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