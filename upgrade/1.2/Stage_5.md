# Stage 5 - Perform NCN Personalization

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Procedure

1. Set the `root` user password and SSH keys before running NCN personalization.
   The location where the password is stored in Vault has changed since previous
   CSM versions. See
   [Configure the Root Password and Root SSH Keys in Vault](../../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#set_root_password).

1. If custom configuration content was merged with content from a previous CSM
   installation, then merge the new CSM configuration in with it in the `csm-config-management`
   Git repository. This is not necessary if the NCN personalization configuration
   was using a commit on a `cray/csm/VERSION` branch (that is, using the default
   configuration).

   The new CSM configuration content is found in the `cray-product-catalog`
   Kubernetes `ConfigMap`. If using the default CSM configuration, simply note the value in
   the `commit` field.

   ```bash
   ncn-m002# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
   ```

   The output will contain a section resembling the following:

   ```yaml
   1.2.1:
     configuration:
       clone_url: https://vcs.cmn.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
       commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
       import_branch: cray/csm/1.9.24
       import_date: 2022-07-28 03:26:01.869501
       ssh_url: git@vcs.cmn.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
   ```

   The specific dates, commits, and other values may not be the same as the output above.

1. View the current `ncn-personalization` configuration and write it to a JSON file.

   ```bash
   ncn-m002# cray cfs configurations describe ncn-personalization --format json | tee ncn-personalization.json
   ```

1. Run the `apply_csm_configuration.sh` script. This script will update the CSM
   layer in the `ncn-personalization` configuration, enable configuration of
   the NCNs, and monitor the progress of the NCN personalization process.

   > **IMPORTANT:**
   >
   > * If using a different branch than the default to include custom
       changes, use the `--git-commit` argument to specify the desired commit on
       the branch including the customizations. Otherwise this argument is not needed.
   > * By default the latest available CSM release will be applied. Otherwise, the
       release may be specified explicitly using the `--csm-release` argument.
       This argument is not needed if using the default CSM configuration found in the
       product catalog in the earlier step.
   > * If the existing `ncn-personalization` configuration contains layers other than
       the CSM layer from the `csm-config-management` repository, then the arguments
       to the script should include `--ncn-config-file`. If this argument is not specified,
       then any existing non-`csm` layers will not be preserved in the new
       `ncn-personalization` configuration.

   ```bash
   ncn-m002# /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
                [--csm-release 1.2.1] [--git-commit COMMIT] [--ncn-config-file  /path/to/ncn-personalization.json]
   ```

   For more information on this script, see [Automatically Apply CSM Configuration to NCNs](../../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#auto_apply_csm_config).

1. Review the new `ncn-personalization` configuration and write it to a JSON file.

   ```bash
   ncn-m002# cray cfs configurations describe ncn-personalization --format json | tee ncn-personalization.json.new
   ```

## Stage completed

This stage is completed. Continue to [Validate CSM Health](../index.md#validate_csm_health) on the main upgrade page.
