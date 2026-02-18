# IUF waits for 10 minutes to get workflow status before executing

## Issue Description

When running IUF commands, the `iuf-cli` waits for 10 minutes before starting execution. During this time, it repeatedly displays a warning message: "Unable to get workflow status."

## Error Identification

While executing IUF commands the following warning is displayed by `iuf-cli` for 10 minutes.

```sh
ncn-m001:~ # iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run --site-vars "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r management-nodes-rollout --limit-management-rollout ncn-w003
INFO All logs will be stored in /etc/cray/upgrade/csm/iuf/install-products/log/20250306145455
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
WARN Unable to get workflow status. Retrying after 10 seconds...
INFO [ACTIVITY: install-products                               ] BEG Install started at 2025-03-06 14:54:55.095146
INFO [IUF SESSION: install-products-h16zj                      ] BEG Started at 2025-03-06 15:04:15.305532
INFO [STAGE: management-nodes-rollout                          ] BEG Argo workflow: install-products-h16zj-management-nodes-rollout-vg48w 
```

## Error Conditions

If an IUF session is abruptly terminated (e.g., using Ctrl+C), the running workflow is also terminated.  Although IUF stores workflow data in a state file `(activity_dict.yaml)`, the termination causes the workflow status to become "Unknown."

When IUF attempts to retrieve the workflow status, it fails because the workflow no longer exists. This results in a discrepancy between the activity data stored by IUF and the `Argo` workflow server.

## Workaround Description

To resolve this issue, follow these steps:

1. Locate the `activity_dict.yaml` file in the state directory of the activity.

    ```sh
    cd /etc/cray/upgrade/csm/iuf/${ACTIVITY_NAME}/state
    ```

2. Identify the workflow with the **"Unknown"** status. For example, for the workflow `install-products-2kh2l-management-nodes-rollout-gnqzj` with "Unknown" status, the entry would look like this:

    ```sh
    '2025-03-06t10:44:08':
          args:
            activity: install-products
            base_dir: null
            begin_stage: null
            bootprep_config_dir: /etc/cray/upgrade/csm/admin
            bootprep_config_managed: /etc/cray/upgrade/csm/admin/bootprep/compute-and-uan-bootprep.yaml
            bootprep_config_management: /etc/cray/upgrade/csm/admin/bootprep/management-bootprep.yaml
            concurrency: null
            concurrent_management_rollout_percentage: 20
            dryrun: false
            end_stage: null
            force: false
            func: *id001
            input_file: null
            level: INFO
            limit_managed_rollout:
            - Compute
            limit_management_rollout:
            - ncn-w001
            log_dir: /etc/cray/upgrade/csm/iuf/install-products/log
            managed_rollout_strategy: stage
            mask_recipe_prods: null
            media_dir: /etc/cray/upgrade/csm/media/install-products
            media_host: ncn-m001
            recipe_vars: /etc/cray/upgrade/csm/admin/product_vars.yaml
            relative_bootprep_config_dir: .bootprep-install-products/admin
            relative_bootprep_config_managed: .bootprep-install-products/compute-and-uan-bootprep.yaml
            relative_bootprep_config_management: .bootprep-install-products/management-bootprep.yaml
            run_stages:
            - management-nodes-rollout
            site_vars: /etc/cray/upgrade/csm/admin/site_vars.yaml
            skip_stages: []
            state_dir: /etc/cray/upgrade/csm/iuf/install-products/state
    verbose: false
            write_input_file: false
          command: iuf -a install-products -m /etc/cray/upgrade/csm/media/install-products
            run --site-vars /etc/cray/upgrade/csm/admin/site_vars.yaml -bpcd /etc/cray/upgrade/csm/admin
            -r management-nodes-rollout --limit-management-rollout ncn-w001
          comment: Run management-nodes-rollout
          session: install-products-2kh2l
          state: in_progress
          status: Unknown
          workflow_id: install-products-2kh2l-management-nodes-rollout-gnqzj 
    ```

3. Remove the workflow entry with the "Unknown" status from the file, which is the entire block shown above.

4. Re-run the IUF command.
