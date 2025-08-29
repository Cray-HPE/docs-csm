# Update NCN User SSH Keys

Change the SSH keys for users on non-compute nodes (NCNs) on the system using
the `rotate-ssh-keys-mgmt-nodes.yml` Ansible playbook provided by CSM or through
NCN node personalization (`site.yml`).

The NCNs deploy with SSH keys for the root user that are changed during the system
install. See [Change NCN Image Root Password and SSH Keys](Change_NCN_Image_Root_Password_and_SSH_Keys.md)
for more information on changing the default keys during install. It is a
recommended best practice for system security to change the SSH keys after the
install is complete on a schedule. This procedure defines how to change the keys
once the system is operational.

The NCN root user keys are stored in the [HashiCorp Vault](HashiCorp_Vault.md)
instance, and applied with the `csm.ssh_keys` Ansible role via a CFS session. If
no keys are added to Vault as in the procedure below, this Ansible role will
skip any updates.

* [Procedure: Configure root SSH keys in Vault](#procedure-configure-root-ssh-keys-in-vault)
* [Procedure: Apply root SSH keys to NCNs (standalone)](#procedure-apply-root-ssh-keys-to-ncns-standalone)
* [Procedure for other users](#procedure-for-other-users)

## Procedure: Configure root SSH keys in Vault

1. Generate a new SSH key pair for the root user.

   Use `ssh-keygen` to generate a new pair or stage an existing pair, as per site security policies and procedures.

1. Write the private and public halves of the key pair to the [HashiCorp Vault](HashiCorp_Vault.md).

    See [Update Root Secrets In Vault](Update_Root_Secrets_In_Vault.md).

## Procedure: Apply root SSH keys to NCNs (standalone)

Use the following procedure with the `rotate-ssh-keys-mgmt-nodes.yml` playbook to **only** change the root SSH keys on NCNs.
This is a quick alternative to running a full management node personalization, as documented in the
[Re-run node personalization on management nodes procedure](../configuration_management/Management_Node_Personalization.md#re-run-node-personalization-on-management-nodes)
in the [Management Node Personalization](../configuration_management/Management_Node_Personalization.md) topic.

1. (`ncn-mw#`) Create a CFS configuration layer to run the SSH key change Ansible playbook.

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
            "name": "ncn-root-keys-update",
            "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "playbook": "rotate-ssh-keys-mgmt-nodes.yml",
            "commit": "<INSERT GIT COMMIT ID>"
          }
        ]
      }
      ```

   1. Create the `ncn-root-keys-update` configuration in CFS.

      Replace the `<INSERT FILE PATH HERE>` text with the path to the file created in the previous step.
      If a CFS configuration already exists with this name, the following command will overwrite it.

      ```bash
      cray cfs v3 configurations update ncn-root-keys-update --file <INSERT FILE PATH HERE>
      ```

1. (`ncn-mw#`) Create a CFS configuration session to apply the SSH keys update.

   ```bash
   cray cfs v3 sessions create --name ncn-root-keys-update-`date +%Y%m%d%H%M%S` --configuration-name ncn-root-keys-update
   ```

1. Monitor the CFS session.

   See [Track the Status of a Session](../configuration_management/Track_the_Status_of_a_Session.md).

## Procedure for other users

The `csm.ssh_key` Ansible role supports setting SSH keys for non-root users.

1. Make a copy of the `rotate-ssh-keys-mgmt-nodes.yml` Ansible playbook and modify the role variables to specify
   a different `ssh_keys_username`.

1. Using that username, add the SSH keys to Vault.

    Follow [Procedure: Configure root SSH keys in Vault](#procedure-configure-root-ssh-keys-in-vault).

1. Create a configuration layer using the new Ansible playbook and create a CFS session using that layer.

[operations/security_and_authentication/SSH_Keys.md](#procedure-apply-root-ssh-keys-to-ncns-standalone)
