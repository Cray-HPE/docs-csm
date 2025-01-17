# IUF CLI reports false error that `management-nodes-rollout` failed

## Problem description

When upgrading master nodes with IUF during the CSM 1.6.0 upgrade, the IUF CLI may say that the master node upgrade failed.
The specific error is: `The management-nodes-rollout stage failed, but argo must run to the completion of the stage`.
This is a bug in the IUF CLI and it happens because while master nodes are upgrading, the IUF CLI is momentarily unable to connect to the `cray-nls` service.
The IUF CLI erroneously reports that the `management-nodes-rollout stage failed` even though `management-nodes-rollout` is likely continuing successfully in the background.

This problem has been resolved in CSM 1.6.1.

## Observed error

The following error can be seen when upgrading master nodes with IUF.

```text
INFO [backup-m ] BEG backup-m001
INFO [backup-m ] BEG backup-m001(0)
INFO [backup-m ] END backup-m001 [Succeeded]
INFO [backup-m ] END backup-m001(0) [Succeeded]
INFO [upgrade-m ] BEG upgrade-m001
INFO [upgrade-m ] BEG upgrade-m001(0)
ERR Workflow activity1-wjtdt-management-nodes-rollout-bf9nx not found.
INFO [STAGE: management-nodes-rollout ] END Unknown in 0:03:18
WARN The management-nodes-rollout stage failed, but argo must run to the completion of the stage.
WARN Still waiting for workflow startup after 15 seconds.
WARN Still waiting for workflow startup after 30 seconds.

[...]

ERR Giving up after 10 minutes. Check to ensure the ARGO backend is functional then try again.

Error Summary:
Workflow activity1-wjtdt-management-nodes-rollout-bf9nx not found.
Giving up after 10 minutes. Check to ensure the ARGO backend is functional then try again.

Error Summary:
   Giving up after 10 minutes.  Check to ensure the ARGO backend is functional then try again.
```

## Resolution

The [Observed error](#observed-error) is a false negative. No action is needed other than manually monitoring the `management-nodes-rollout` Argo workflow continuing successfully in the background.
The IUF workflow can be monitored in either of the following two ways.

1. Use the Argo UI to monitor the workflow. See [using the Argo UI](../../operations/argo/Using_the_Argo_UI.md) for details on accessing the UI.

1. (`ncn-m001#`) Monitor the logs of the pod running the `management-nodes-rollout` Argo workflow.

    1. Get pods in the `argo` namespace, `grep` for 'management'.

        ```bash
        kubectl get pods -n argo | grep management
        ```

    1. Follow the logs for the pod running the `management-nodes-rollout` stage.

        ```bash
        kubectl logs -n argo <pod_name> -f
        ```

Continue monitoring the `management-nodes-rollout` workflow until it completes successfully.
If it fails, investigate the logs from the sources above to find the error.
Additionally, a master node upgrade will print its upgrade output to `/root/output.log`.
This file will be on `ncn-m001` when `ncn-m002` or `ncn-m003` are being upgraded and the file will be on `ncn-m002` when `ncn-m001` is being upgraded.
This file can be used to debug a failed master node upgrade.
