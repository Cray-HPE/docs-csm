## Update NCN Passwords

Change the passwords for non-compute nodes (NCNs) on the system using the
`rotate-pw-mgmt-nodes.yml` Ansible playbook provided by CSM or by running
the CSM `site.yml` playbook.

The NCNs deploy with a default password, which are changed during the system
install. See [Change NCN Image Root Password and SSH Keys](Change_NCN_Image_Root_Password_and_SSH_Keys.md)
for more information.

It is a recommended best practice for system security to change the root
password after the install is complete.

The NCN root user password is stored in the HashiCorp Vault instance, and
applied with the `csm.password` Ansible role via a CFS session.

> NOTE: The root password is also updated when applying the CSM configuration
layer during NCN personalization using the `site.yml` playbook. See the
[Configure Non-compute Nodes with CFS](../CSM_product_management/Configure_Non_Compute_Nodes.md#set_root_password)
procedure for more information.

Use the following procedure with the `rotate-pw-mgmt-nodes.yml` playbook to
change the root password as a quick alternative to running a full NCN
personalization.

### Procedure

1. Generate a new password hash for the root user. Replace `PASSWORD` with the
   root password that will be used.

   ```bash
   ncn# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) PASSWORD
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
   export VAULT_ADDR=http://cray-vault:8200
   vault login
   vault write secret/csm/management_nodes root_password='HASH'
   vault read secret/csm/management_nodes
   exit
   ```

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
   HashiCorp Vault and create the CFS session as long as the branch of the CSM
   configuration management repository has not changed.

