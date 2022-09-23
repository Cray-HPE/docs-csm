# Set NCN User Passwords

The management node images do not contain a default root password or default SSH keys.

Use one of these methods to change or set the root password in the image.

* If the PIT node is booted, see
[Change NCN Image Root Password and SSH Keys on PIT Node](Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md)
for more information.

* If the PIT node is not booted, see
[Change NCN Image Root Password and SSH Keys](Change_NCN_Image_Root_Password_and_SSH_Keys.md)
for more information.

The rest of this procedure describes how to change the root password stored in the HashiCorp
Vault instance and then apply it immediately to management nodes with the `csm.password` Ansible
role via a CFS session. The same root password from Vault will be applied anytime that the NCN
personalization including the CSM layer is run. If no password is added to Vault as in the
procedure below, this Ansible role will skip any password updates.

## New in CSM release 1.2.0

The location of the password secret in Vault has changed in CSM version 1.2. The
previous location (`secret/csm/management_nodes root_password=...`) has been
changed to `secret/csm/users/root password=...`. You must set the password in
the new location using the _Configure Root Password in Vault_ procedure below
for it to be applied to the NCNs.

<a name="configure_root_password_in_vault"></a>

## Procedure: Configure `root` password in Vault

1. Generate a new password hash for the `root` user.

   > This script uses `read -s` to prevent the password from being echoed to the screen or saved
   > in the shell history. It unsets the plaintext password variables at the end, so that they
   > cannot be viewed later.

   ```bash
   ncn# read -r -s -p "New root password for NCN images: " PW1 ; echo ; if [[ -z ${PW1} ]]; then
            echo "ERROR: Password cannot be blank"
        else
            read -r -s -p "Enter again: " PW2
            echo
            if [[ ${PW1} != ${PW2} ]]; then
                echo "ERROR: Passwords do not match"        
            else
                echo -n "${PW1}" | openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Za-z0-9 | head -c4) --stdin
            fi
        fi ; unset PW1 PW2
   ```

1. Get the [HashiCorp Vault](HashiCorp_Vault.md) root token:

   ```bash
   ncn-mw# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
   ```

1. Write the password hash from step 1 to the [HashiCorp Vault](HashiCorp_Vault.md).
   The `vault login` command will request the token value from the output of
   step 2 above. The `vault read` command verifies the hash was stored
   correctly.

   **NOTE:**: It is important to enclose the hash in single quotes to preserve
   any special characters.

   ```bash
   ncn-mw# kubectl exec -itn vault cray-vault-0 -- sh
   cray-vault-0# export VAULT_ADDR=http://cray-vault:8200
   cray-vault-0# vault login
   cray-vault-0# vault write secret/csm/users/root password='<INSERT HASH HERE>' [... other fields (see warning below) ...]
   cray-vault-0# vault read secret/csm/users/root
   cray-vault-0# exit
   ```

   > **WARNING**: The CSM instance of [HashiCorp Vault](HashiCorp_Vault.md) does
   > not support the `patch` operation, only `write`. Ensure that if the `password`
   > field in the `secret/csm/users/root` secret is being updated that the other
   > fields, for example the user's [SSH keys](SSH_Keys.md#configure_root_keys_in_vault),
   > are also updated. Updating the password without including values for the
   > other fields will result in loss of data of the other fields.

   The path to the secret and the password field are configurable locations in
   the CSM `csm.password` Ansible role located in the CSM configuration
   management Git repository that is in use. If not using the defaults as shown
   in the command above, ensure that the paths are consistent between Vault and
   the values in the Ansible role. See `roles/csm.password/README.md` in the
   repository for more information.

## Procedure: Apply `root` password to NCNs (standalone)

Use the following procedure with the `rotate-pw-mgmt-nodes.yml` playbook to
**only** change the root password on NCNs. This is a quick alternative to
running a [full NCN personalization](../CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#set_root_password),
where passwords are also applied using the password stored in Vault set in the
procedure above.

1. Create a CFS configuration layer to run the password change Ansible playbook.
   Replace the branch name in the JSON below with the commit in the CSM
   configuration management Git repository that is in use.

   ```bash
   ncn# cat ncn-password-update-config.json
   ```

   Example output:

   ```json
   {
     "layers": [
       {
         "name": "ncn-password-update",
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
         "playbook": "rotate-pw-mgmt-nodes.yml",
         "commit": "<INSERT GIT COMMIT ID>"
       }
     ]
   }
   ```

   ```bash
   ncn# cray cfs configurations update ncn-password-update --file ./ncn-password-update-config.json
   ```

1. Create a CFS configuration session to apply the password update.

   ```bash
   ncn# cray cfs sessions create --name ncn-password-update-`date +%Y%m%d%H%M%S` --configuration-name ncn-password-update
   ```

   **NOTE:** Subsequent password changes need only update the password hash in
   HashiCorp Vault and create the CFS session as long as the commit in the CSM
   configuration management repository has not changed. If the commit has
   changed, repeat this procedure from the beginning.

## Procedure for other users

The `csm.password` Ansible role supports setting passwords for non-root users.
Make a copy of the `rotate-pw-mgmt-nodes.yml` Ansible playbook and modify the
role variables to specify a different `password_username` and use that username
when adding the hashed password to Vault as in the _Configure Root Password in Vault_
above. Follow the procedure and then create a configuration layer using the new
Ansible playbook and create a CFS session using that layer.
