# HMS Resource Leaks

Resource leaks have been discovered in several HMS services (PCS, SMD,
hmcollector, and FAS).  The symptoms are quite varied and are generally not
detrimental to system functionality due to the resiliency provided by
Kubernetes.  On this page we document the symptoms, known impacts to
functionality, and include some examples of how to proactively check your
system for this issue.

The fixes for these issues are included in the CSM 1.5.3 and CSM 1.6.1
releases.

Additionally, there is a hotfix for the CSM 1.5.2 release that includes only
the PCS fix.

## Symptoms

The symptoms described below have been observed on some systems.  They can be
transient and may not ever be encountered on some systems.  There are many
possible additional symptoms that are not enumerated here.

### All Services

* OOM (Out Of Memory) conditions that lead to pod restarts
* Failed liveness and/or readiness probes that lead to pod restarts
* Communication with BMCs timeout with "context deadline exceeded"

### PCS

* Power status for components reported as "undefined"
* Failed power transitions

### hmcollector

* Long latencies associated with telemetry reporting

### FAS

* Failure to update firmware

## Examples

### Check for Pod Restarts

In the following example we see that both PCS and SMD experienced pod
restarts because there are non-zero values in the RESTARTS column:

```console
> kubectl get pods -n services | grep -e RESTARTS -e cray-smd -e cray-power-control -e cray-hms-hmcollector -e cray-fas
NAME                                                              READY   STATUS      RESTARTS         AGE
cray-fas-7d7dd579b4-4pqtx                                         2/2     Running     0                15d
cray-fas-bitnami-etcd-0                                           2/2     Running     0                15d
cray-fas-bitnami-etcd-1                                           2/2     Running     0                15d
cray-fas-bitnami-etcd-2                                           2/2     Running     0                15d
cray-fas-bitnami-etcd-snapshotter-28960800-lcfg4                  0/2     Completed   0                53m
cray-fas-wait-for-etcd-8-tbkxz                                    0/1     Completed   0                15d
cray-hms-hmcollector-ingress-bb5945686-q8gh2                      2/2     Running     0                14d
cray-hms-hmcollector-ingress-bb5945686-wc7zc                      2/2     Running     0                14d
cray-hms-hmcollector-ingress-bb5945686-wt49s                      2/2     Running     0                14d
cray-hms-hmcollector-poll-7bd6b79978-95n8d                        2/2     Running     0                12d
cray-power-control-5785fdf495-69mp8                               2/2     Running     41               6d21h
cray-power-control-5785fdf495-d7gkq                               2/2     Running     12               6d21h
cray-power-control-5785fdf495-k5r4k                               2/2     Running     13               6d21h
cray-power-control-bitnami-etcd-0                                 2/2     Running     0                6d21h
cray-power-control-bitnami-etcd-1                                 2/2     Running     0                6d21h
cray-power-control-bitnami-etcd-2                                 2/2     Running     0                6d21h
cray-power-control-bitnami-etcd-snapshotter-28960800-vmjnp        0/2     Completed   0                53m
cray-power-control-wait-for-etcd-2-67nkh                          0/1     Completed   0                6d21h
cray-power-control-wait-for-etcd-47-d7blr                         0/1     Completed   0                20d
cray-smd-984f56ccf-67lf5                                          2/2     Running     3                46h
cray-smd-984f56ccf-7g5tm                                          2/2     Running     6                46h
cray-smd-984f56ccf-z978s                                          2/2     Running     5                46h
cray-smd-init-2jgwn                                               0/2     Completed   0                46h
cray-smd-postgres-0                                               3/3     Running     0                79d
cray-smd-postgres-1                                               3/3     Running     0                79d
cray-smd-postgres-2                                               3/3     Running     0                79d
cray-smd-wait-for-postgres-8-2h2hr                                0/3     Completed   0                46h
logical-backup-cray-smd-postgres-28956970-5sdq6                   0/2     Completed   0                2d16h
logical-backup-cray-smd-postgres-28958410-l8ksx                   0/2     Completed   0                40h
logical-backup-cray-smd-postgres-28959850-gbrp8                   0/2     Completed   0                16h
```

### Check Pod Resource Usage

While we check the resource consumption in this section, please note that if
one pod has greater memory consumption than other pods that does not
necessarily mean there is a memory leak.  If the difference is substantial,
then it is more likely.  If you suspect a memory leak, capture the current
usage today and capture again in a few days or weeks to compare.

In the following example we see one PCS pod with a larger memory footprint
compared to the others:

```console
> kubectl top pod -n services --sort-by=memory | grep -e NAME -e cray-power-control
NAME                                                              CPU(cores)   MEMORY(bytes)
cray-power-control-5785fdf495-d7gkq                               52m          764Mi
cray-power-control-bitnami-etcd-2                                 97m          142Mi
cray-power-control-bitnami-etcd-0                                 95m          140Mi
cray-power-control-bitnami-etcd-1                                 73m          134Mi
cray-power-control-5785fdf495-69mp8                               5m           99Mi
```

The following example will show the memory usage for the containers inside
the pods.  Here we can see that the istio-proxy container is responsible
for most of the excess memory consumption:

```console
> kubectl top pod -n services --containers=true | grep -e NAME -e cray-power-control
POD                                                               NAME                           CPU(cores)   MEMORY(bytes)
cray-power-control-5785fdf495-69mp8                               cray-power-control             3m           11Mi
cray-power-control-5785fdf495-69mp8                               istio-proxy                    4m           86Mi
cray-power-control-5785fdf495-d7gkq                               cray-power-control             9m           28Mi
cray-power-control-5785fdf495-d7gkq                               istio-proxy                    6m           736Mi
cray-power-control-5785fdf495-k5r4k                               cray-power-control             4m           11Mi
cray-power-control-5785fdf495-k5r4k                               istio-proxy                    31m          93Mi
cray-power-control-bitnami-etcd-0                                 etcd                           89m          48Mi
cray-power-control-bitnami-etcd-0                                 istio-proxy                    14m          97Mi
cray-power-control-bitnami-etcd-1                                 etcd                           68m          47Mi
cray-power-control-bitnami-etcd-1                                 istio-proxy                    7m           86Mi
cray-power-control-bitnami-etcd-2                                 etcd                           89m          52Mi
cray-power-control-bitnami-etcd-2                                 istio-proxy                    12m          90Mi
```

### Check for OOMs

```console
> kubectl get events -n services | grep -e MESSAGE -e cray-smd -e cray-power-control -e cray-hms-hmcollector -e cray-fas | grep -i OOM
```

### Check for Failed Liveness and Readiness Probes

```console
> kubectl get events -n services | grep -e MESSAGE -e cray-smd -e cray-power-control -e cray-hms-hmcollector -e cray-fas | grep -e MESSAGE -e "Liveness probe" -e "Readiness probe"
```

### Check PCS for "undefined" Power Status

Here we have an example of counting the power states for all components.
If more than a couple are in the "undefined" state, this may be a symptom
of a PCS resource leak:

```console
> cray power status list --format json | jq -r '.status[] | select(.xname | test("x\\d*c\\d*s\\d*b\\d*n\\d*$")) | .powerState' | sort | uniq -c
      1 off
   5719 on
    185 undefined
```

### Check Service Logs for "context deadline exceeded"

Services can timeout when communicating with BMCs.  Here is an example
of checking for these in the PCS logs:

```console
> kubectl logs -n services -l app.kubernetes.io/name=cray-power-control -c cray-power-control --tail -1 | grep -i "context deadline exceeded"
```

The messages to look for can vary, but should always include the string
"context deadline exceeded".  A few examples:

```text
time="2024-10-23T16:14:00Z" level=error msg="getHWStatesFromHW: ERROR no response body for 'x3000c0s17b0' 'x3000c0s17b0' '/redfish/v1/Systems/system', err: context deadline exceeded" func=github.com/Cray-HPE/hms-power-control/internal/domain.getHWStatesFromHW file="/go/src/github.com/Cray-HPE/hms-power-control/internal/domain/power-status.go:547"
```

```text
time="2024-10-23T16:50:46Z" level=error msg="getHWStatesFromHW: ERROR reading response body for 'x3001c0s33b0' 'x3001c0s33b0' '/redfish/v1/Managers/BMC': context deadline exceeded" func=github.com/Cray-HPE/hms-power-control/internal/domain.getHWStatesFromHW file="/go/src/github.com/Cray-HPE/hms-power-control/internal/domain/power-status.go:539"
```

```text
time="2024-10-23T23:48:31Z" level=trace msg="getStatusCode, no response, err: 'GET https://x3000c0s9b0/redfish/v1/Managers/BMC_0 giving up after 1 attempt(s): context deadline exceeded'" func=github.com/Cray-HPE/hms-power-control/internal/domain.getStatusCode file="/go/src/github.com/Cray-HPE/hms-power-control/internal/domain/power-status.go:414"
```
