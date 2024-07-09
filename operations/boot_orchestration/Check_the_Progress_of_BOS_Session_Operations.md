# Check the Progress of BOS Session Operations

Describes how to view the logs of BOS operations with Kubernetes.

When a Boot Orchestration Service \(BOS\) session is created, it will return a job ID. This ID can be used to locate the Boot Orchestration Agent \(BOA\) Kubernetes job that executes the session. For example:

```bash
ncn-mw# cray bos session create --template-uuid SESSIONTEMPLATE_NAME --operation boot --format toml
```

Example output:

```toml
operation = "boot"
templateName = "SESSIONTEMPLATE_NAME"
[[links]]
href = "foo-c7faa704-3f98-4c91-bdfb-e377a184ab4f"
jobId = "boa-a939bd32-9d27-433f-afc2-735e77ec8e58"
rel = "session"
type = "GET"
```

All BOS Kubernetes pods operate in the services namespace.

## Find the BOA Kubernetes job

Use the following command to locate the Kubernetes BOA pod.

```bash
ncn-mw# kubectl get pods -n services | grep -E "NAME | BOS_SESSION_JOB_ID"
```

For example:

```bash
ncn-mw# kubectl get pods -n services | grep -E "NAME | boa-a939bd32-9d27-433f-afc2-735e77ec8e58"
```

Example output:

```text
NAME                                                              READY   STATUS      RESTARTS   AGE
boa-a939bd32-9d27-433f-afc2-735e77ec8e58-ztscd                    0/2     Completed   0          16m
```

Use the following command to locate the Kubernetes BOA job.

```bash
ncn-mw# kubectl get jobs -n services BOS_SESSION_JOB_ID
```

For example:

```bash
ncn-mw# kubectl get jobs -n services boa-a939bd32-9d27-433f-afc2-735e77ec8e58
```

Example output:

```text
NAME                                       COMPLETIONS   DURATION   AGE
boa-a939bd32-9d27-433f-afc2-735e77ec8e58   1/1           13m        15m
```

The Kubernetes BOA pod name is not a one-to-one match with the BOA job name. The pod name has `-XXXX` appended to it, where `X` is a hexadecimal digit.

## View the BOA log

Use the following command to look at the BOA pod's logs.

```bash
ncn-mw# kubectl logs -n services KUBERNETES_BOA_POD_ID -c boa
```

For example:

```bash
ncn-mw# kubectl logs -n services boa-a939bd32-9d27-433f-afc2-735e77ec8e58 -c boa
```

## View the Configuration Framework Service \(CFS\) log

If a session template has CFS enabled, then BOA will attempt to configure the nodes during a boot, reboot, or configure operation. Use the BOA job ID to find the CFS job that BOA launched to configure the nodes.

```bash
ncn-mw# cray cfs sessions describe BOA_JOB_ID
```

For example:

```bash
ncn-mw# cray cfs sessions describe boa-86b78489-1d76-4957-9c0e-a7b1d6665c35 --format json
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
            "job": "cfs-85e3e48f-6795-4570-b379-347b05b39dbe", <<-- Kubernetes CFS job ID
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

Use the Kubernetes CFS job ID in the returned output above to find the CFS pod ID. It is the pod with three containers listed, not two.

```bash
ncn-mw# kubectl -n services get pods|grep KUBERNETES_CFS_JOB_ID
```

Example output:

```text
cfs-85e3e48f-6795-4570-b379-347b05b39dbe-59645667b-ffznt     2/2   Running     0   3h57m
cfs-85e3e48f-6795-4570-b379-347b05b39dbe-cvr54               0/3   Completed   0   3h57m
```

View the pod logs for the Ansible container:

```bash
ncn-mw# kubectl -n services logs -f -c ansible KUBERNETES_CFS_POD_ID
```

## View the BOS log

The BOS log shows when a session was launched. It also logs any errors encountered while attempting to launch a session.

The BOS Kubernetes pod ID can be found with the following command:

```bash
ncn-mw# kubectl get pods -n services | grep bos | grep -v etcd
```

Example output:

```text
cray-bos-d97cf465c-klcrw                             2/2     Running     0          90s
```

Examine the logs:

```bash
ncn-mw# kubectl logs BOS_POD_ID
```

BOS uses an etcd database. Looking at the etcd logs is typically not necessary.
