## Update NCN Passwords

Change the passwords for users on non-compute nodes (NCNs) on the system using
the `rotate-pw-mgmt-nodes.yml` Ansible playbook provided by CSM or through
NCN node personalization (`site.yml`).

The NCNs deploy with a default password, which are changed during the system
install. See [Change NCN Image Root Password and SSH Keys](change_ncn_image_root_password_and_ssh_keys.md)
for more information.

It is a recommended best practice for system security to change the root
password after the install is complete.

The NCN root user password is stored in the [Hashicorp Vault](HashiCorp_Vault.md)
instance, and applied with the `csm.password` Ansible role via a CFS session. If
no password is added to Vault as in the procedure below, this Ansible role will
skip any password updates.

NOTE: The root password is also updated when applying the CSM Configuration Layer
during NCN personalization using the `site.yml` playbook if the password has
been added to [Hashicorp Vault](HashiCorp_Vault.md). See the
[Managing Configuration with CFS](operations/managing_configuration_with_CFS.md)
procedure for more information.

Use the following procedure with the `rotate-pw-mgmt-nodes.yml` playbook to
change the root password as a quicker alternative to running a full NCN
personalization.

### Procedure for `root` User

1. Generate a new password hash for the root user. Replace `PASSWORD` with the
   root password that will be used.

   ```bash
   ncn# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) PASSWORD
   ```

1. Get the [Hashicorp Vault](HashiCorp_Vault.md) root token:

   ```bash
   ncn# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
   ```

1. Write the password hash from step 1 to the [Hashicorp Vault](HashiCorp_Vault.md).
   The `vault login` command will request the token value from the output of
   step 2 above. The `vault read` command verifies the hash was stored
   correctly.

   ***NOTE***: It is important to enclose the hash in single quotes to preserve
   any special characters.

   ```bash
   ncn# kubectl exec -itn vault cray-vault-0 -- sh
   export VAULT_ADDR=http://cray-vault:8200
   vault login
   vault write secret/csm/users/root password='HASH' [... other fields ...]
   vault read secret/csm/users/root
   exit
   ```

   ***NOTE***: The CSM instance of [Hashicorp Vault](HashiCorp_Vault.md) does
   not support the `patch` operation. Ensure that if you are updating the
   `password` field in the `secret/csm/users/root` secret that you are also
   update the other fields, for example the user's [SSH keys](SSH_Keys.md).

   The path to the secret and the password field are configurable locations in
   the CSM `csm.password` Ansible role located in the CSM configuration
   management Git repository that is in use. If not using the defaults as shown
   in the command above, ensure that the paths are consistent between Vault and
   the values in the Ansible role. See `roles/csm.password/README.md` in the
   repository for more information.

1. Create a CFS configuration layer to run the password change Ansible playbook.
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
         "name": "ncn-password-update",
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
         "playbook": "rotate-pw-mgmt-nodes.yml",
         "branch": "ADD BRANCH NAME HERE"
       }
     ]
   }
   ncn# cray cfs configurations update ncn-password-update --file ./config.json
   ```

1. Create a CFS configuration session to apply the password update.

   ```bash
   ncn# cray cfs sessions create --name ncn-password-update-`date +%Y%m%d%H%M%S` --configuration-name ncn-password-update
   ```

   ***NOTE***: Subsequent password changes need only update the password hash in
   Hashicorp Vault and create the CFS session as long as the branch of the CSM
   configuration management repository hasn't changed.

### Procedure for Other Users

The `csm.password` Ansible role supports setting passwords for non-root users.
Make a copy of the `rotate-pw-mgmt-nodes.yml` Ansible playbook and modify the
role variables to specify a different `password_username` and use that username
when adding the hashed password to Vault as in the procedure above. Follow the
procedure to create a configuration layer using the new Ansible playbook and
create a CFS session using that layer.

