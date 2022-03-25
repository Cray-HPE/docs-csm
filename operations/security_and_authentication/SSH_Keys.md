# Update NCN User SSH Keys

Change the SSH keys for users on non-compute nodes (NCNs) on the system using
the `rotate-ssh-keys-mgmt-nodes.yml` Ansible playbook provided by CSM or through
NCN node personalization (`site.yml`).

The NCNs deploy with ssh keys for the root user that are changed during the system
install. See [Change NCN Image Root Password and SSH Keys](Change_NCN_Image_Root_Password_and_SSH_Keys.md)
for more information on changing the default keys during install. It is a
recommended best practice for system security to change the SSH keys after the
install is complete on a schedule. This procedure defines how to change the keys
once the system is operational.

The NCN root user keys are stored in the [HashiCorp Vault](HashiCorp_Vault.md)
instance, and applied with the `csm.ssh_keys` Ansible role via a CFS session. If
no keys are added to Vault as in the procedure below, this Ansible role will
skip any updates.

<a name="configure_root_keys_in_vault"></a>
### Procedure: Configure Root SSH Keys in Vault

1. Generate a new SSH key pair for the root user. Use `ssh-keygen` to generate a
   a new pair or stage an existing pair as desired as per your security policies
   and procedures.

1. Get the [HashiCorp Vault](HashiCorp_Vault.md) root token:

   ```bash
   ncn# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
   ```

1. Write the private and public halves of the key pair gathered in step 1 to the
   [HashiCorp Vault](HashiCorp_Vault.md). The `vault login` command will request
   the token value from the output of step 2 above. The `vault read` command
   verifies the keys were stored correctly.

   The `ssh_private_key` and `ssh_public_key` fields should contain the exact
   content from the `id_rsa` and `id_rsa.pub` files (if using RSA key types).

   ***NOTE***: It is important to enclose the key content in single quotes to
   preserve any special characters.

   ```bash
   ncn# kubectl exec -itn vault cray-vault-0 -- sh
   cray-vault-0# export VAULT_ADDR=http://cray-vault:8200
   cray-vault-0# vault login
   cray-vault-0# vault write secret/csm/users/root ssh_private_key='...' ssh_public_key='...' [... other fields (see warning below) ...]
   cray-vault-0# vault read secret/csm/users/root
   cray-vault-0# exit
   ncn# 
   ```

   > ***WARNING***: The CSM instance of [HashiCorp Vault](HashiCorp_Vault.md) does
   > not support the `patch` operation. Ensure that if you are updating the
   > `ssh_private_key` and `ssh_public_key` field in the `secret/csm/users/root`
   > secret that you are also update the other fields, for example the user's
   > [password](Update_NCN_Passwords.md#configure_root_password_in_vault).

   The path to the secret and the ssh key fields are configurable locations in
   the CSM `csm.ssh_keys` Ansible role located in the CSM configuration
   management Git repository that is in use. If not using the defaults as shown
   in the command above, ensure that the paths are consistent between Vault and
   the values in the Ansible role. See `roles/csm.ssh_keys/README.md` in the
   repository for more information.

### Procedure: Apply Root SSH Keys to NCNs (Standalone)

Use the following procedure with the `rotate-ssh-keys-mgmt-nodes.yml` playbook to
**only** change the root SSH keys on NCNs. This is a quick alternative to
running a [full NCN personalization](../CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#set_root_password),
where keys are also applied using the secrets stored in Vault set in the
procedure above.

1. Create a CFS configuration layer to run the ssh key change Ansible playbook.
   Replace the branch name in the JSON below with the branch in the CSM
   configuration management Git repository that is in use.

   ```bash
   ncn# cat config.json
   {
     "layers": [
       {
         "name": "ncn-root-keys-update",
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
         "playbook": "rotate-ssh-keys-mgmt-nodes.yml",
         "commit": "<INSERT GIT COMMIT ID>"
       }
     ]
   }
   ncn# cray cfs configurations update ncn-root-keys-update --file ./config.json
   ```

1. Create a CFS configuration session to apply the ssh keypair update.

   ```bash
   ncn# cray cfs sessions create --name ncn-root-keys-update-`date +%Y%m%d%H%M%S` --configuration-name ncn-root-keys-update
   ```

   ***NOTE***: Subsequent SSH key changes need only update the field contents in
   HashiCorp Vault and create the CFS session as long as the branch of the CSM
   configuration management repository has not changed. If the commit has
   changed, repeat this procedure from the beginning.

### Procedure for Other Users

The `csm.ssh_key` Ansible role supports setting SSH keys for non-root users.
Make a copy of the `rotate-ssh-keys-mgmt-nodes.yml` Ansible playbook and modify
the role variables to specify a different `ssh_keys_username` and use that
username when adding the ssh keypair content to Vault as in the procedure above.
Follow the procedure to create a configuration layer using the new Ansible
playbook and create a CFS session using that layer.
