# IUF does not run the next stage for an activity

## Issue Description

During the CSM upgrade, IUF reports that multiple sessions are in progress for an activity. The next stage for the activity does not run due to above error.
This issue is seen after pre-install-check stage or management-nodes-rollout stage of iuf run.

This issue causes the session associated with the activity to continue to be in "in progress" even after workflow associated with the stage has successfully completed.

## Error Identification

When the issue occurs the following errors are emitted by iuf cli:

```sh
iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout ${WORKER_CANARY}
INFO All logs will be stored in /etc/cray/upgrade/csm/iuf/update-csm-1.6.0/log/20241021025621
INFO [ACTIVITY: update-csm-1.6.0                               ] BEG Install started at 2024-10-21 02:56:21.778284
INFO Neither --recipe-vars nor --bootprep-config-dir were specified, so
product_vars.yaml will be pulled from the branch
cray/hpc-csm-software-recipe/25.1.0-alpha-20241019174014-8f492eb of the
hpc-csm-software-recipe git repo.
INFO [IUF SESSION:                                             ] BEG Started at 2024-10-21 02:56:30.375445
WARN multiple sessions found.  Taking the first one...
INFO [IUF SESSION:                                             ] END Completed at 2024-10-21 02:56:30.568155
INFO [ACTIVITY: update-csm-1.6.0                               ] END Completed in 0:00:08
```

## Error Conditions

There is a race condition in `cray-nls` that is hit when multiple `cray-nls` pods are starting at the same time.
This happens during a `cray-nls` chart upgrade and sometimes when a node with multiple `cray-nls` pods is drained, which causes these pods to start simultaneously on another node.

## Workaround Description

Step 1: Identify the session for the previous stage which ran successfully for the activity being run.

```bash
2024-10-21T01:40:09.731277Z INFO [IUF SESSION: update-csm-1-6-0-h0y63                 ] BEG Started at 2024-10-21 01:40:09.731167
2024-10-21T01:40:13.585718Z DBG  Next workflow update-csm-1-6-0-h0y63-management-nodes-rollout-wnbpb
```

Step 2: Find the configmap associated with the session from previous step in argo namespace.

```bash
kubectl get cm -n argo --selector type=iuf_session |grep <session_name>
```

Step 3: Make a backup of the configmap since it will be edited in the next step.

```bash
kubectl get cm -n argo <session_name> -o yaml > <session_name>_cm_backup.yaml
```

Step 4: Edit the configmap to modify "current_state" to "completed" if "current_state" is "in_progress".

```bash
kubectl edit configmap -n argo <session_name> -o json
```
