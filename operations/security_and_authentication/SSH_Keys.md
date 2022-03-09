## Update NCN SSH Keys

Change the SSH keys for users on non-compute nodes (NCNs) on the system using
the `rotate-ssh-keys-mgmt-nodes.yml` Ansible playbook provided by CSM or through
NCN node personalization (`site.yml`).

The NCNs deploy with ssh keys for the root user that are changed during the system
install. See [Change NCN Image Root Password and SSH Keys](Change_NCN_Image_Root_Password_and_SSH_Keys.md)
for more information.

It is a recommended best practice for system security to change the SSH keys
after the install is complete on a schedule.

The NCN root user keys are stored in the [Hashicorp Vault](HashiCorp_Vault.md)
instance, and applied with the `csm.ssh_keys` Ansible role via a CFS session. If
no keys are added to Vault as in the procedure below, this Ansible role will
skip any updates.

**NOTE:** The root SSH keys are also updated when applying the CSM Configuration
Layer during NCN personalization using the `site.yml` playbook if the keys have
been added to [Hashicorp Vault](HashiCorp_Vault.md). See the
[Perfrom NCN Personalization](../CSM_product_management/Perform_NCN_Personalization.md)
procedure for more information.

Use the following procedure with the `rotate-ssh-keys-mgmt-nodes.yml` playbook
to change the root user SSH keys as a quicker alternative to running a full NCN
personalization.

### Procedure for `root` User

1. Generate a new SSH key pair for the root user. Use `ssh-keygen` to generate a
   a new pair or stage an existing pair as desired as per your security policies
   and procedures.

1. Get the [Hashicorp Vault](HashiCorp_Vault.md) root token:

   ```bash
   ncn# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
   ```

1. Write the private and public halves of the key pair gathered in step 1 to the
   [Hashicorp Vault](HashiCorp_Vault.md). The `vault login` command will request
   the token value from the output of step 2 above. The `vault read` command
   verifies the keys were stored correctly.

   The `ssh_private_key` and `ssh_public_key` fields should contain the exact
   content from the `id_rsa` and `id_rsa.pub` files (if using RSA key types).

   ***NOTE***: It is important to enclose the key content in single quotes to
   preserve any special characters.

   ```bash
   ncn# kubectl exec -itn vault cray-vault-0 -- sh
   export VAULT_ADDR=http://cray-vault:8200
   vault login
   vault write secret/csm/users/root ssh_private_key='...' ssh_public_key='...' [... other fields ...]
   vault read secret/csm/users/root
   exit
   ```

   ***NOTE***: The CSM instance of [Hashicorp Vault](HashiCorp_Vault.md) does
   not support the `patch` operation. Ensure that if you are updating the
   `ssh_private_key` and `ssh_public_key` field in the `secret/csm/users/root`
   secret that you are also update the other fields, for example the user's
   [password](Update_NCN_Passwords.md).

   The path to the secret and the ssh key fields are configurable locations in
   the CSM `csm.ssh_keys` Ansible role located in the CSM configuration
   management Git repository that is in use. If not using the defaults as shown
   in the command above, ensure that the paths are consistent between Vault and
   the values in the Ansible role. See `roles/csm.ssh_keys/README.md` in the
   repository for more information.

1. Create a CFS configuration layer to run the ssh key change Ansible playbook.
   Replace the branch name in the JSON below with the branch in the CSM
   configuration management Git repository that is in use. Alternatively, the
   `branch` key can be replaced with the `commit` key and the git commit id
   that is in use. See [Use Branches in Configuration Layers](#operations/configuration_management/Configuration_Layers.md)
   for more information.

   ```bash
   ncn# cat config.json
   {
     "layers": [
       {
         "name": "ncn-root-keys-update",
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
         "playbook": "rotate-ssh-keys-mgmt-nodes.yml",
         "branch": "ADD BRANCH NAME HERE"
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
   Hashicorp Vault and create the CFS session as long as the branch of the CSM
   configuration management repository hasn't changed.

### Procedure for Other Users

The `csm.ssh_key` Ansible role supports setting SSH keys for non-root users.
Make a copy of the `rotate-ssh-keys-mgmt-nodes.yml` Ansible playbook and modify
the role variables to specify a different `ssh_keys_username` and use that
username when adding the ssh keypair content to Vault as in the procedure above.
Follow the procedure to create a configuration layer using the new Ansible
playbook and create a CFS session using that layer.
