# Update NCN Passwords

The management nodes deploy with a default password in the image, so it is a recommended best
practice for system security to change the root password in the image so that it is
not the documented default password. In addition to the root password in the image, NCN
personalization should be used to change the password as part of post-boot CFS. The password
in the image should be used when console access is desired during the network boot of a management
node that is being rebuilt, but this password should be different than the one stored in Vault
that is applied by CFS during post-boot NCN personalization to change the on-disk password. Once
NCN personalization has been run, then the password in Vault should be used for console access.

Use one of these methods to change the root password in the image.

1. If the PIT node is booted, see
[Change NCN Image Root Password and SSH Keys on PIT Node](Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md)
for more information.

1. If the PIT node is not booted, see
[Change NCN Image Root Password and SSH Keys](Change_NCN_Image_Root_Password_and_SSH_Keys.md)
for more information.

The rest of this procedure describes how to change the root password stored in the HashiCorp
Vault instance and then apply it immediately to management nodes with the `csm.password` Ansible
role via a CFS session. The same root password from Vault will be applied anytime that the NCN
personalization including the CSM layer is run.

## Procedure: Configure Root Password in Vault


1. Generate a new password hash for the root user. Type in your new password
   after running the `read` command. The echo will verify that the hash is set
   to the password you expect.

   ```bash
   ncn# read -s NEWPASSWORD
   ncn# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) "$NEWPASSWORD"
   ncn# echo "Password: $NEWPASSWORD"
   ```

1. Get the HashiCorp Vault root token:

   ```bash
   ncn# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
   ```

1. Write the password hash from step 1 to the HashiCorp Vault. The `vault login`
   command will request the token value from the output of step 2 above. The
   `vault read` command verifies the hash was stored correctly.

   ***NOTE***: It is important to enclose the hash in single quotes to preserve
   any special characters.

   ```bash
   ncn# kubectl exec -itn vault cray-vault-0 -- sh

   cray-vault-0# export VAULT_ADDR=http://cray-vault:8200
   cray-vault-0# vault login
   cray-vault-0# vault write secret/csm/management_nodes root_password='HASH'
   cray-vault-0# vault read secret/csm/management_nodes
   cray-vault-0# exit
   ```

## Procedure: Apply Root Password to NCNs (Standalone)

Use the following procedure with the `rotate-pw-mgmt-nodes.yml` playbook to
**only** change the root password on NCNs. This is a quick alternative to
running a [full NCN personalization](../CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#set_root_password),
where passwords are also applied using the password stored in Vault set in the
procedure above.

1. Create a CFS configuration layer to run the password change Ansible playbook.

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
