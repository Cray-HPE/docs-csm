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

* [Procedure: Configure `root` password in Vault](#procedure-configure-root-password-in-vault)
* [Procedure: Apply `root` password to NCNs (standalone)](#procedure-apply-root-password-to-ncns-standalone)

<a name="configure_root_password_in_vault"></a>

## Procedure: Configure `root` password in Vault

1. Generate a new password hash for the `root` user.

   > This script uses `read -s` to prevent the password from being echoed to the screen or saved
   > in the shell history. It unsets the plaintext password variables at the end, so that they
   > cannot be viewed later.

   ```bash
   linux# read -r -s -p "New root password for NCN images: " PW1 ; echo ; if [[ -z ${PW1} ]]; then
            echo "ERROR: Password cannot be blank"
          else
            read -r -s -p "Enter again: " PW2
            echo
            if [[ ${PW1} != ${PW2} ]]; then
              echo "ERROR: Passwords do not match"        
            else
              echo -n "${PW1}" | openssl passwd -6 -salt $(< /dev/urandom tr -dc ./A-Za-z0-9 | head -c4) --stdin
            fi
          fi ; unset PW1 PW2
   ```

1. Get the HashiCorp Vault root token.

   ```bash
   ncn-mw# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
   ```

1. Write the password hash to the [HashiCorp Vault](HashiCorp_Vault.md).

   1. Open an interactive shell in the Vault Kubernetes pod.

      ```bash
      ncn-mw# kubectl exec -itn vault cray-vault-0 -c vault -- sh
      ```

   1. Write the password hash to Vault.

      * The `vault login` command will request the token value from the output of the previous step.
      * Use the password hash generated in the earlier step.
        * **`NOTE`**: It is important to enclose the hash in single quotes to preserve any special characters.
      * The `vault read` command allows the administrator to verify that the contents of the secret were stored correctly.

      ```bash
      cray-vault# export VAULT_ADDR=http://cray-vault:8200
      cray-vault# vault login
      cray-vault# vault write secret/csm/management_nodes root_password='HASH'
      cray-vault# vault read secret/csm/management_nodes
      cray-vault# exit
      ```

## Procedure: Apply `root` password to NCNs (standalone)

Use the following procedure with the `rotate-pw-mgmt-nodes.yml` playbook to **only** change the root password on NCNs.
This is a quick alternative to running a full management NCN personalization, as documented in the
[Configure Non-Compute Nodes with CFS](../CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md) procedure.

1. Create a CFS configuration layer to run the password change Ansible playbook.

   **`NOTE`** This step only needs to be done once, as long as the commit in the CSM
   configuration management Git repository has not changed. If the commit has not changed since the
   last time this step was run, this step may be skipped, because the previously created CFS configuration
   will still work.

   1. Create a file containing only this CFS configuration layer.

      The file contents should be as follows, except replace the `<INSERT GIT COMMIT ID>` text with the commit in the
      CSM configuration management Git repository that is in use.

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

   1. Create the `ncn-password-update` configuration in CFS.

      Replace the `<INSERT FILE PATH HERE>` text with the path to the file created in the previous step.
      If a CFS configuration already exists with this name, the following command will overwrite it.

      ```bash
      ncn-mw# cray cfs configurations update ncn-password-update --file <INSERT FILE PATH HERE>
      ```

1. Create a CFS configuration session to apply the password update.

   ```bash
   ncn-mw# cray cfs sessions create --name ncn-password-update-`date +%Y%m%d%H%M%S` --configuration-name ncn-password-update
   ```

1. Monitor the CFS session.

   See [Track the Status of a Session](../configuration_management/Track_the_Status_of_a_Session.md).
