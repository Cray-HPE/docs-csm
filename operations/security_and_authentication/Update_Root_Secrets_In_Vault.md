# Update Root Secrets In Vault

* [Overview](#overview)
* [Automated tools](#automated-tools)
* [Manual procedures](#manual-procedures)

## Overview

Several CSM root user credentials are optionally stored in the [HashiCorp Vault](HashiCorp_Vault.md),
acting as a secure backup and allowing them to be automatically configured by the
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs).
These credentials include:

* Password hash
* SSH public key
* SSH private key
* SSH configuration

The path to the secret and the SSH key fields are configurable locations in the CSM `csm.ssh_keys`
Ansible role located in the CSM configuration management Git repository that is in use.
See `roles/csm.ssh_keys/README.md` in the repository for more information.

The path to the secret and the password field are configurable locations in
the CSM `csm.password` Ansible role located in the CSM configuration
management Git repository that is in use. See `roles/csm.password/README.md` in the
repository for more information.

If the default path or keys have been changed, then CSM does not provide an automated way
to update their values in Vault. In this case, the [Manual procedures](#manual-procedures) must be used.

If the path and key fields are at their default values, then CSM provides [Automated tools](#automated-tools)
to safely update the data in Vault.

## Automated tools

> The `docs-csm` RPM must be installed in order to use these tools. See
> [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation)

### `write_root_secrets_to_vault.py`

(`ncn-mw#`) The `/usr/share/doc/csm/scripts/operations/configuration/write_root_secrets_to_vault.py` script can be used to
set the password, SSH keys, and/or SSH configuration for the root user. It can also be used to delete any of
these values from Vault.  Run the script with the `--help` argument to see the different options.

### `write_ssh_config_to_vault.py`

(`ncn-mw#`) If only wanting to update or delete the root user SSH configuration, then the
`/usr/share/doc/csm/scripts/operations/configuration/write_ssh_config_to_vault.py` script can be used. Run it with
the `--help` option to see its usage.

### `restore_ssh_config_from_vault.py`

(`ncn-mw#`) The `/usr/share/doc/csm/scripts/operations/configuration/restore_ssh_config_from_vault.py` script
copies the root SSH configuration out of Vault and into a file on the local system. Run it with the `--help` option to
see its usage.

## Manual procedures

### Password hash

The path to the secret and the password field are configurable locations in
the CSM `csm.password` Ansible role located in the CSM configuration
management Git repository that is in use.

If not using the defaults as shown in the command examples, ensure that the paths are consistent between Vault and
the values in the Ansible role. See `roles/csm.password/README.md` in the repository for more information.

1. (`ncn-mw#`) Get the Vault root token.

    ```bash
    kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
    ```

1. (`ncn-mw#`) Open an interactive shell in the Vault Kubernetes pod.

    ```bash
    kubectl exec -itn vault cray-vault-0 -c vault -- sh
    ```

1. (`cray-vault#`) Write the password hash to Vault.

   > ***WARNING***: The CSM instance of Vault does not support the `patch` operation. Ensure that if the
   > `password` field in the `secret/csm/users/root` secret is being updated,
   > then any other desired fields are also included in the `write` command. For example the user's
   > [SSH keys](#ssh-keys).
   > **Any fields omitted from the `write` command will be cleared from Vault.**

    * The `vault login` command will request the token value from the output of the previous step.
    * **`NOTE`**: It is important to enclose the hash in single quotes to preserve any special characters.
    * The `vault read` command allows the administrator to verify that the contents of the secret were stored correctly.

    ```bash
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/csm/users/root password='<INSERT HASH HERE>' [... other fields (see warning above) ...]
    vault read secret/csm/users/root
    exit
    ```

### SSH keys

The path to the secret and the SSH key fields are configurable locations in
the CSM `csm.ssh_keys` Ansible role located in the CSM configuration
management Git repository that is in use.

If not using the defaults as shown in the command examples, ensure that the paths are consistent between Vault and
the values in the Ansible role. See `roles/csm.ssh_keys/README.md` in the repository for more information.

1. (`ncn-mw#`) Get the Vault root token.

    ```bash
    kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
    ```

1. (`ncn-mw#`) Open an interactive shell in the Vault Kubernetes pod.

    ```bash
    kubectl exec -itn vault cray-vault-0 -c vault -- sh
    ```

1. (`cray-vault#`) Write the SSH keys to Vault.

   > ***WARNING***: The CSM instance of Vault does not support the `patch` operation. Ensure that if the
   > `ssh_private_key` and `ssh_public_key` fields in the `secret/csm/users/root` secret are being updated,
   > then any other desired fields are also included in the `write` command. For example the user's
   > [password hash](#password-hash).
   > **Any fields omitted from the `write` command will be cleared from Vault.**

    * The `vault login` command will request the token value from the output of the previous step.
    * The `ssh_private_key` and `ssh_public_key` fields should contain the exact content from the
      `id_rsa` and `id_rsa.pub` files (if using RSA key types).
    * **`NOTE`**: It is important to enclose the key content in single quotes to preserve any special characters.
    * The `vault read` command allows the administrator to verify that the contents of the secret were stored correctly.

    ```bash
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/csm/users/root ssh_private_key='...' ssh_public_key='...' [... other fields (see warning above) ...]
    vault read secret/csm/users/root
    exit
    ```
