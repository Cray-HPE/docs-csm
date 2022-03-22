# Stage 5 - Perform NCN Personalization

## Procedure

1. If custom configuration content was merged with content from a previous CSM
   installation, merge the new CSM configuration in with it in the `csm-config-management`
   git repository. This is not necessary if the NCN personalization configuration
   was using a commit on a `cray/csm/VERSION` branch (i.e using default
   configuration).

   The new CSM configuration content is found in the `cray-product-catalog`
   config map. If using the default CSM configuration, simply note the value in
   the `commit` field.

   ```bash
   ncn# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'

   1.2.0:
     configuration:
       clone_url: https://vcs.cmn.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
       commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
       import_branch: cray/csm/1.9.24
       import_date: 2022-07-28 03:26:01.869501
       ssh_url: git@vcs.cmn.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
   ...
   ```

   The specific dates, commits, and other values may not be the same as the output above.

1. Write out the current `ncn-personalization` configuration to a JSON file.

   ```bash
   ncn-m001# cray cfs configurations describe ncn-personalization --format json > ncn-personalization.json
   ```

1. Run the `apply_csm_configuration.sh` script. This script will update the CSM
   layer in the `ncn-personalization` configuration, enable configuration of
   the NCNs, and monitor the progress of the NCN personalization process.

   **IMPORTANT:**

   > * If you are using a different branch than the default to include custom
       changes, use the `--git-commit` option to override the commit to the
       commit on your branch.
   > * If you are using the default CSM configuration found in the product
       catalog above, you may omit this option, but you should use the `--csm-release`
       option to explicitly set the release version, otherwise the latest available
       release will be applied.

   ```bash
   ncn-m001# /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh [--git-commit COMMIT]
   ```

   For more information on this script, see [Automatically Apply CSM Configuration to NCNs](../../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#automatically-apply-csm-configuration-to-ncns)

Once `Stage 5` upgrade is complete, proceed to [*Validate CSM Health*](../index.md#validate_csm_health) on the main upgrade page.
