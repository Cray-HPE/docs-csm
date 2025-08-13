# Debugging With HMS `pprof` Images

- [Introduction](#introduction)
- [Deploying `pprof` enabled container images](#deploying-pprof-enabled-container-images)
    - [Edit the deployment](#edit-the-deployment)
        - [Important note on image persistence](#important-note-on-image-persistence)
    - [Possibly scale down replicas](#possibly-scale-down-replicas)
    - [Restore production container image](#restore-production-container-image)
- [Gathering profiles](#gathering-profiles)
    - [Gathering profiles from outside the service mesh](#gathering-profiles-from-outside-the-service-mesh)
    - [Gathering profiles from inside the service mesh](#gathering-profiles-from-inside-the-service-mesh)
        - [`hmcollector-ingress`](#hmcollector-ingress)
        - [`hmcollector-poll`](#hmcollector-poll)
        - [MEDS](#meds)
        - [RTS](#rts)
        - [`RTS-SNMP`](#rts-snmp)
- [Sending profiles to HPE Service](#sending-profiles-to-hpe-service)
- [Deployment name and `pprof` URL reference](#deployment-name-and-pprof-url-reference)

## Introduction

There may be times when HPE Service requests the gathering of `pprof`
profiles as an aid to debug certain classes of problems within HMS
services. `pprof` is a profiling and debug tool that is part of the
Go programming language tool set. These profiles can be useful when
debugging performance issues and resource leaks. This
capability was added to most (but not all) HMS services in the
CSM 1.6.1 release. Support for the remaining HMS services was added
in the CSM 1.7.0 release.

By default, HMS services are deployed with container images that do
not include `pprof` support, because profiling can incur overhead.
When necessary, HPE Support may request that `pprof` enabled images
be temporarily put into place so that profiles can be gathered and
sent back to HPE for review.

Throughout this documentation, the provided examples will refer to the
[Power Control Service (PCS)](../glossary.md#power-control-service-pcs).

## Deploying `pprof` enabled container images

### Edit the deployment

1. (`ncn-mw#`) Edit the deployment for the target service:

    > For all deployment names, see
    > [Deployment name and `pprof` URL reference](#deployment-name-and-pprof-url-reference).

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

1. Search for the container image by looking for the text string `image:`

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control:2.7.0
    ```

1. Append the string `-pprof` to the end of the image name:

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control-pprof:2.7.0
    ```

1. (`ncn-mw#`) After saving the changes to the deployment, the pods will
   restart using the `pprof` enabled image. Administrators can determine when the
   pods have completed restarting by watching them restart.

    ```bash
    watch -n1 "kubectl get pods -n services | grep -e cray-power-control -e NAME"
    ```

Once all of the pods have been restarted, `pprof` profiles may then be
gathered. However, it may take time for performance issues or resource
leaks to recur. HPE Support will communicate how long to wait before
gathering the necessary profiles.

#### Important note on image persistence

Should the deployed service be upgraded or downgraded to a different
version of that service, the image deployed will revert to the image
without `pprof` support. The procedure documented above will need to be
repeated after any upgrade or downgrade using Helm.

### Possibly scale down replicas

When any request is sent to an HMS service, it first goes through the
API gateway. The API gateway load balances requests across all of a service's
replicas or pods. This means that the `pprof` profile that is returned
could have been generated on any one of the replicas.

There may be times when a profile from a specific replica is required.
If this level of specification is necessary, the deployment may need to
be scaled down to a single replica to ensure that the profile was
generated on that replica. Scaling down should be done before the
specific condition the profile hopes to capture has occurred, because the
scale down process is somewhat random in which replicas it stops.

- (`ncn-mw#`) To scale a deployment down to a single replica:

    ```bash
    kubectl scale deployment -n services cray-power-control --replicas=1
    ```

- (`ncn-mw#`) To scale it back up to the appropriate replica count (e.g. 3):

    ```bash
    kubectl scale deployment -n services cray-power-control --replicas=3
    ```

Note that scaling down a deployment to a single replica may not always be
possible. Larger systems may require that more than one replica
always be running in order to maintain proper functionality. In these
situations, there may be other ways to gather profiles, which are not
covered here.

HPE Service will work with administrators to determine if scaling down a
deployment is necessary and, if not, how to alternatively gather a profile.

### Restore production container image

After the necessary profiles have been collected and no further debugging
with `pprof` is required, reset the service's deployed image back to its
production image.

1. (`ncn-mw#`) Edit the deployment:

    > For all deployment names, see
    > [Deployment name and `pprof` URL reference](#deployment-name-and-pprof-url-reference).

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

1. Search for the `pprof` enabled container image by looking for the text string `image:`

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control-pprof:2.7.0
    ```

1. Remove the substring `-pprof` from the end of the image name:

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control:2.7.0
    ```

1. (`ncn-mw#`) After saving the changes to the deployment, the pods will
   restart using the production image. Administrators can determine when the
   pods have completed restarting by watching them restart.

    ```bash
    watch -n1 "kubectl get pods -n services | grep -e cray-power-control -e NAME"
    ```

Once all of the pods have been restarted, the restore is complete.

## Gathering profiles

Gathering profiles from outside of the service mesh is generally easier
than gathering them from inside the service mesh. However, not all HMS
services are available outside the service mesh. Refer to the
[Deployment name and `pprof` URL reference](#deployment-name-and-pprof-url-reference)
table to determine which services are accessible outside
vs inside the service mesh.

### Gathering profiles from outside the service mesh

(`ncn-mw#`) In order to gather a `pprof` profile from outside the service mesh,
a valid authentication token must be provided with the request. Perform the following
to set up a `TOKEN` environment variable containing the authentication token.

```bash
export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

The following `curl` command demonstrates how to request a `pprof` profile
from the PCS service:

```bash
curl -sk -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/power-control/v1/debug/pprof/heap -o pcs.heap.02062024.pprof
```

Note the descriptive nature of the profile's output file. It is always
good to be as descriptive as possible, especially when multiple profiles
are generated. Consider using a timestamp as well, if appropriate. If the
pod name, including hash, is available, consider using that in the filename
as well (the deployment must have been scaled down).

The example above requested a `heap` `pprof` profile. There are
several different types of profiles that may be requested. Some examples:

- `cmdline`: The running program's command line
- `profile`: A sampling of CPU usage
- `heap`: A sampling of heap allocations
- `goroutine`: Stack traces of all current go routines
- `block`: Stack traces that led to blocking on synchronization primitives
- `mutex`: Stack traces of holder of contended mutexes

Refer to [Deployment name and `pprof` URL reference](#deployment-name-and-pprof-url-reference)
for the base `pprof` URL for each HMS service. Append the name
of the profile type to the base URL, replacing `heap` in the above example.

There may also be additional arguments to pass to `curl` when requesting a
profile.

HPE Service will communicate which profiles to gather and any additional
arguments that may be necessary.

### Gathering profiles from inside the service mesh

A few more steps are required to gather profiles from inside the service
mesh for those services unavailable outside of the service mesh.  There
are nuances for each service, so each is documented individually or as
pairs.  The first example, `hmcollector-ingress` will be given in a bit
more detail, while the remaining will be abbreviated.

#### `hmcollector-ingress`

1. (`ncn-mw#`) List the service pods.

    ```bash
    kubectl get pods -n services | grep -e cray-hms-hmcollector-ingress -e NAME
    ```

    Example output:

    ```text
    NAME                                                              READY   STATUS      RESTARTS        AGE
    cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp                     2/2     Running     0               2d
    cray-hms-hmcollector-ingress-6b7fd6566c-lsgwj                     2/2     Running     0               2d
    cray-hms-hmcollector-ingress-6b7fd6566c-wmcvf                     2/2     Running     0               2d
    ```

1. Select a specific pod for the request.

    This example will use `cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp`.

1. (`ncn-mw#`) Use the `kubectl` command to `exec` into the pod and use the `curl` command to generate the profile inside of the pod.

    ```bash
    kubectl -n services exec -it cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp -- curl http://cray-hms-hmcollector-ingress/debug/pprof/heap -o /tmp/hmcollector-ingress.heap.04242025.pprof
    ```

1. (`ncn-mw#`) Copy the profile out of the pod.

    ```bash
    kubectl -n services cp cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp:/tmp/hmcollector-ingress.heap.04242025.pprof hmcollector-ingress.heap.04242025.pprof
    ```

#### `hmcollector-poll`

(`ncn-mw#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-hms-hmcollector-poll-78d458b567-fph2p -- curl http://cray-hms-hmcollector-poll/debug/pprof/heap -o /tmp/hmcollector-poll.heap.04242025.pprof
kubectl -n services cp cray-hms-hmcollector-poll-78d458b567-fph2p:/tmp/hmcollector-poll.heap.04242025.pprof hmcollector-poll.heap.04242025.pprof
```

#### MEDS

(`ncn-mw#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-meds-778577d9bb-kmv8h -- curl http://cray-meds/debug/pprof/heap -o /tmp/meds.heap.04242025.pprof
kubectl -n services cp cray-meds-778577d9bb-kmv8h:/tmp/meds.heap.04242025.pprof meds.heap.04242025.pprof
```

#### RTS

(`ncn-mw#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-hms-rts-6df8f8859d-fb4f7 -c cray-hms-rts -- curl -k https://cray-hms-rts/debug/pprof/heap -o /tmp/rts.heap.04242025.pprof
kubectl -n services cp cray-hms-rts-6df8f8859d-fb4f7:/tmp/rts.heap.04242025.pprof -c cray-hms-rts rts.heap.04242025.pprof
```

#### `RTS-SNMP`

(`ncn-mw#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-hms-rts-snmp-6cbb9d55b7-r5hp2 -c cray-hms-rts -- curl -k https://cray-hms-rts-snmp/debug/pprof/heap -o /tmp/rts-snmp.heap.04242025.pprof
kubectl -n services cp cray-hms-rts-snmp-6cbb9d55b7-r5hp2:/tmp/rts-snmp.heap.04242025.pprof -c cray-hms-rts rts-snmp.heap.04242025.pprof
```

## Sending profiles to HPE Service

Simply attach any gathered profiles to the open service case.
HPE Service will also request output from the following commands.
Gather this additional data around the same time as the `pprof` profile.

- (`ncn-mw#`) General pod status.

    ```bash
    kubectl get pods -n services | grep -e NAME -e cray-power-control
    ```

- (`ncn-mw#`) Pod resource utilization.

    ```bash
    kubectl top pod -n services --containers=true | grep -e NAME -e cray-power-control
    ```

## Deployment name and `pprof` URL reference

| Service               | Deployment Name                | Base `pprof` URL                                                      |
|-----------------------|--------------------------------|-----------------------------------------------------------------------|
| BSS                   | `cray-bss`                     | `https://api-gw-service-nmn.local/apis/bss/debug/pprof/`              |
| FAS                   | `cray-fas`                     | `https://api-gw-service-nmn.local/apis/fas/v1/debug/pprof/`           |
| HBTD                  | `cray-hbtd`                    | `https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/debug/pprof/`      |
| `hmcollector-ingress` | `cray-hms-hmcollector-ingress` | unavailable outside service mesh                                      |
| `hmcollector-poll`    | `cray-hms-hmcollector-poll`    | unavailable outside service mesh
| HMNFD                 | `cray-hmnfd`                   | `https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/debug/pprof/`     |
| MEDS                  | `cray-meds`                    | unavailable outside service mesh
| PCS                   | `cray-power-control`           | `https://api-gw-service-nmn.local/apis/power-control/v1/debug/pprof/` |
| RTS                   | `cray-hms-rts`                 | unavailable outside service mesh
| `RTS-SNMP`            | `cray-hms-rts-snmp`            | unavailable outside service mesh
| SCSD                  | `cray-scsd`                    | `https://api-gw-service-nmn.local/apis/scsd/v1/debug/pprof/`           |
| SLS                   | `cray-sls`                     | `https://api-gw-service-nmn.local/apis/sls/v1/debug/pprof/`           |
| SMD                   | `cray-smd`                     | `https://api-gw-service-nmn.local/apis/smd/hsm/v2/debug/pprof/`       |
