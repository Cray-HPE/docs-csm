# Stage 5 - Perform NCN Personalization

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Start typescript](#start-typescript)
- [Procedure](#procedure)
- [Stop typescript](#stop-typescript)
- [Stage completed](#stage-completed)

## Start typescript

1. (`ncn-m002#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m002#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_5.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Procedure

1. If custom configuration content was merged with content from a previous CSM
   installation, then merge the new CSM configuration in with it in the `csm-config-management`
   Git repository. This is not necessary if the NCN personalization configuration
   was using a commit on a `cray/csm/VERSION` branch (that is, using the default
   configuration).

   (`ncn-m002#`) The new CSM configuration content is found in the `cray-product-catalog`
   Kubernetes `ConfigMap`. If using the default CSM configuration, simply note the value in
   the `commit` field.

   ```bash
   kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
   ```

   The output will contain a section resembling the following:

   ```yaml
   1.3.0:
     configuration:
       clone_url: https://vcs.cmn.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
       commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
       import_branch: cray/csm/1.10.0
       import_date: 2022-07-28 03:26:01.869501
       ssh_url: git@vcs.cmn.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
   ```

   The specific dates, commits, and other values may not be the same as the output above.

1. (`ncn-m002#`) View the current `ncn-personalization` configuration and write it to a JSON file.

   ```bash
   cray cfs configurations describe ncn-personalization --format json | tee ncn-personalization.json
   ```

1. (`ncn-m002#`) Run the `apply_csm_configuration.sh` script. This script will update the CSM
   layer in the `ncn-personalization` configuration, enable configuration of
   the NCNs, and monitor the progress of the NCN personalization process.

   > **IMPORTANT:**
   >
   > - If using a different branch than the default to include custom
       changes, use the `--git-commit` argument to specify the desired commit on
       the branch including the customizations. Otherwise this argument is not needed.
   > - By default the latest available CSM release will be applied. Otherwise, the
       release may be specified explicitly using the `--csm-release` argument.
       This argument is not needed if using the default CSM configuration found in the
       product catalog in the earlier step.
   > - If the existing `ncn-personalization` configuration contains layers other than
       the CSM layer from the `csm-config-management` repository, then the arguments
       to the script should include `--ncn-config-file`. If this argument is not specified,
       then any existing non-`csm` layers will not be preserved in the new
       `ncn-personalization` configuration.

   ```bash
   /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
            [--csm-release 1.3.0] [--git-commit COMMIT] [--ncn-config-file  /path/to/ncn-personalization.json]
   ```

   For more information on this script, see [Automatically Apply CSM Configuration to NCNs](../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#option-1-automatically-apply-csm-configuration).

1. (`ncn-m002#`) Review the new `ncn-personalization` configuration and write it to a JSON file.

   ```bash
   cray cfs configurations describe ncn-personalization --format json | tee ncn-personalization.json.new
   ```

## Stop typescript

Stop any typescripts that were started during this stage.

## Stage completed

This stage is completed. Proceed to [Validate CSM health](README.md#3-validate-csm-health) on the main upgrade page.
