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
Reading in SSH private key from '/root/.ssh/id_rsa' file
Reading in SSH public key from '/root/.ssh/id_rsa.pub' file
Reading in file '/etc/shadow'
Found root user line in /etc/shadow
Initializing Kubernetes client
Making GET request to http://10.22.183.206:8200/v1/secret/csm/users/root
Writing updated CSM root secret to Vault
Making POST request to http://10.22.183.206:8200/v1/secret/csm/users/root
Making GET request to http://10.22.183.206:8200/v1/secret/csm/users/root
Secrets read back from Vault match desired values
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

See [NCN Node Personalization](../configuration_management/NCN_Node_Personalization.md).
