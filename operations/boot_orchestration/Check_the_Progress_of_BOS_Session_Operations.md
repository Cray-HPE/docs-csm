# Check the Progress of BOS Session Operations

> **`NOTE`** This section is for BOS v1 only. For similar functionality in BOS v2, refer to [View the Status of a BOS Session](View_the_Status_of_a_BOS_Session.md).

This page describes how to view the logs of BOS operations with Kubernetes.

- [Overview](#overview)
- [Find the BOA Kubernetes pod and job](#find-the-boa-kubernetes-pod-and-job)
- [View the BOA log](#view-the-boa-log)
- [View the CFS log](#view-the-cfs-log)
- [View the BOS log](#view-the-bos-log)

## Overview

When a Boot Orchestration Service \(BOS\) session is created, it will return a job ID. This ID can be used to locate the Boot Orchestration Agent \(BOA\) Kubernetes job that executes the session.

(`ncn-mw#`) For example:

```bash
cray bos v1 session create --template-uuid SESSIONTEMPLATE_NAME --operation Boot --format toml
```

Example output:

```toml
operation = "Boot"
templateUuid = "TEMPLATE_UUID"
[[links]]
href = "foo-c7faa704-3f98-4c91-bdfb-e377a184ab4f"
jobId = "boa-a939bd32-9d27-433f-afc2-735e77ec8e58"
rel = "session"
type = "GET"
```

All BOS Kubernetes pods operate in the `services` namespace.

## Find the BOA Kubernetes pod and job

1. (`ncn-mw#`) Locate the Kubernetes BOA pod.

    > In the following command, replace `BOS_SESSION_JOB_ID` with the actual BOS session `jobId` from the output
    > of the session creation command.

    ```bash
    kubectl get pods -n services | grep -E "^(NAME|BOS_SESSION_JOB_ID)"
    ```

    Example output:

    ```text
    NAME                                                              READY   STATUS      RESTARTS   AGE
    boa-a939bd32-9d27-433f-afc2-735e77ec8e58-ztscd                    0/2     Completed   0          16m
    ```

1. (`ncn-mw#`) Locate the Kubernetes BOA job.

    > In the following command, replace `BOS_SESSION_JOB_ID` with the actual BOS session `jobId` from the output
    > of the session creation command.

    ```bash
    kubectl get jobs -n services BOS_SESSION_JOB_ID
    ```

    Example output:

    ```text
    NAME                                       COMPLETIONS   DURATION   AGE
    boa-a939bd32-9d27-433f-afc2-735e77ec8e58   1/1           13m        15m
    ```

    The Kubernetes BOA pod name is not a one-to-one match with the BOA job name. The pod name is the job name, with an additional
    hexadecimal suffix separated by a `-` character.

## View the BOA log

(`ncn-mw#`) Look at the BOA pod's logs.

> In the following command, replace `KUBERNETES_BOA_POD_ID` with the actual BOA pod name identified
> in the previous section.

```bash
kubectl logs -n services KUBERNETES_BOA_POD_ID -c boa
```

## View the CFS log

If a session template has the Configuration Framework Service (CFS) enabled, then BOA will attempt to configure the nodes during a boot, reboot, or configure operation.

1. (`ncn-mw#`) Use the BOA job ID to find the CFS job that BOA launched to configure the nodes.

    > In the following command, replace `BOA_JOB_ID` with the actual BOA job name identified earlier.

    ```bash
    cray cfs sessions describe BOA_JOB_ID --format json
    ```

    Example output:

    ```json
    {
        "ansible": {
            "limit": "x3000c0s19b4n0,x3000c0s19b3n0,x3000c0s19b2n0,x3000c0s19b1n0",
            "playbook": "site.yml"
        },
        "id": "ffdda2c6-2277-11ea-8db8-b42e993b706a",
        "links": [
            {
                "href": "/apis/cfs/sessions/boa-86b78489-1d76-4957-9c0e-a7b1d6665c35",
                "rel": "self"
            },
            {
                "href": "/apis/cms.cray.com/v1/namespaces/services/cfsessions/boa-86b78489-1d76-4957-9c0e-a7b1d6665c35",
                "rel": "k8s"
            }
        ],
        "name": "boa-86b78489-1d76-4957-9c0e-a7b1d6665c35",
        "repo": {
            "branch": "master",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
        },
        "status": {
            "artifacts": [],
            "session": {
                "completionTime": "2019-12-19T16:05:11+00:00",
                "job": "cfs-85e3e48f-6795-4570-b379-347b05b39dbe",
                "startTime": "2019-12-19T15:55:37+00:00",
                "status": "complete",
                "succeeded": "true"
            },
            "targets": {
                "failed": 0,
                "running": 0,
                "success": 0
            }
        },
        "target": {
            "definition": "dynamic",
            "groups": []
        }
    }
    ```

1. (`ncn-mw#`) Find the CFS pod ID.

    > In the following command, replace `KUBERNETES_CFS_JOB_ID` with the contents of the `job` field in the command output
    > from the previous step.

    In the output of the following command, look for the pod with three containers listed, not two.

    ```bash
    kubectl -n services get pods|grep KUBERNETES_CFS_JOB_ID
    ```

    Example output:

    ```text
    cfs-85e3e48f-6795-4570-b379-347b05b39dbe-59645667b-ffznt     2/2   Running     0   3h57m
    cfs-85e3e48f-6795-4570-b379-347b05b39dbe-cvr54               0/3   Completed   0   3h57m
    ```

1. (`ncn-mw#`) View the pod's logs for the Ansible container.

    > In the following command, replace `KUBERNETES_CFS_POD_ID` with the name of the CFS pod identified
    > in the previous step.

    ```bash
    kubectl -n services logs -f -c ansible KUBERNETES_CFS_POD_ID
    ```

## View the BOS log

The BOS log shows when a session was launched. It also logs any errors encountered while attempting to launch a session.

1. (`ncn-mw#`) Find the BOS Kubernetes pod ID.

    > BOS uses an etcd database. Looking at the etcd logs is typically not necessary, which is why the following
    > command excludes them from the output.

    ```bash
    kubectl get pods -n services | grep cray-bos | grep -v etcd
    ```

1. (`ncn-mw#`) Examine the BOS pod logs.

    > In the following command, replace `BOS_POD_ID` with the name of the pod identified in the previous step.

    ```bash
    kubectl logs -n services BOS_POD_ID -c cray-bos
    ```
