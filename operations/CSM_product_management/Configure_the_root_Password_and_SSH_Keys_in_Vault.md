# Configure the `root` password and SSH keys in Vault

This procedure sets the `root` user password and SSH keys on management nodes. The `root` password
and SSH keys are set and managed in Vault, and they are applied on management nodes by the
`csm.password` and `csm.ssh_keys` Ansible roles provided by the CSM product.

This procedure should be run during CSM installation and any later time when the `root` password or
SSH keys need to be changed per site requirements.

## Options for setting `root` password and SSH keys in Vault

Choose one of the following options for setting the `root` password and SSH keys in Vault:

- [Option 1: Automated default](#option-1-automated-default)
- [Option 2: Manual](#option-2-manual)

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

Proceed to [Apply configuration with CFS node personalization](#apply-configuration-with-cfs-node-personalization).

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

Proceed to [Apply configuration with CFS node personalization](#apply-configuration-with-cfs-node-personalization).

## Apply configuration with CFS node personalization

This step is only necessary if performing this procedure as an operational task. If performing
this procedure as part of a CSM install, skip this step and return to
[Configure Administrative Access](../../install/configure_administrative_access.md).

After the `root` password and SSH keys have been set in Vault, they will be applied to management
nodes during node personalization. CFS automatically re-configures the management nodes via the CFS
Batcher whenever the CFS configuration applied to the components changes, the nodes reboot, or the
component state is cleared in CFS.
See [Configuration Management with the CFS Batcher](../configuration_management/Configuration_Management_with_the_CFS_Batcher.md)
for more information about the CFS Batcher. Since the changes here are made in Vault, the CFS
Batcher will not automatically apply the new `root` password and SSH Keys.

See the [Re-run node personalization on management nodes](../configuration_management/Management_Node_Personalization.md#re-run-node-personalization-on-management-nodes)
procedure to re-run NCN node personalization on management nodes.
