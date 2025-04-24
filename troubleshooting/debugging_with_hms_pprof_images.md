# Debugging With HMS `PProf` Images

- [Introduction](#introduction)
- [Deploying `PProf` Enabled Container Images](#deploying-pprof-enabled-container-images)
    - [Edit Deployment](#edit-deployment)
    - [Possibly Scale Down Replicas](#possibly-scale-down-replicas)
    - [Important Note On Persistence](#important-note-on-persistence)
    - [Restore Production Container Image](#restore-production-container-image)
- [Gather Profiles](#gather-profiles)
- [Sending Profiles To HPE Service](#sending-profiles-to-hpe-service)
- [Deployment Name And `PProf` URL Reference](#deployment-name-and-pprof-url-reference)

## Introduction

There may be times when HPE Service requests the gathering of `pprof`
profiles as an aid to debug certain classes of problems within HMS
services.  `PProf` is a profiling and debug tool that is part of the
Go programming language tool set.  These profiles can be useful when
debugging performance issues and resource leaks.  This is a new
capability that was added to most (but not all) HMS services in the
CSM 1.6.1 release.  Support for the remaining HMS services was added
in the CSM 1.7.0 release.

By default, HMS services are deployed with container images that do
not include `pprof` support.  Profiling can incur overhead, which we
generally prefer to avoid in production.  When necessary, HPE may
request that `pprof` enabled images be temporarily put into place so
that profiles can be gathered and sent back to HPE for review.

Throughout this documentation, we will refer to PCS (Power Control
Service) in the provided examples.

## Deploying `PProf` Enabled Container Images

### Edit The Deployment

1. (`ncn#`) First, edit the deployment for the target service:

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

    Refer to [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
    further below on this page for all deployment names.

1. (`ncn#`) Search for the container image by looking for the text
  string `image:`

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control:2.7.0
    ```

1. (`ncn#`) Append the string `-pprof` to the end of the image name:

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control-pprof:2.7.0
    ```

1. (`ncn#`) After saving your changes to the deployment, the pods will
restart using the `pprof` enabled image.  You can determine when they have
completed restarting by watching them restart with:

    ```bash
    watch -n1 "kubectl get pods -n services | grep -e cray-power-control -e NAME"
    ```

1. Once all of the pods have been restarted, `pprof` profiles may then be
gathered. However, it may take time for performance issues or resource
leaks to recur. HPE Support will communicate how long to wait before
gathering the necessary profiles.

#### Important Note On Image Persistence

Should the deployed service be upgraded or downgraded to a different
version of that service, the image deployed will revert to the image
without `pprof` support.  The procedure documented above will need to be
repeated after any upgrade or downgrade using helm.

### Possibly Scale Down Replicas

When any request is sent to an HMS service, it first goes through the
API gateway which load balances requests across all of a service's
replicas, or pods. This means that the `pprof` profile that is returned
could have been generated on any one of the replicas.

There may be times when a profile from a specific replica is required.
If this level of specification is necessary, the deployment may need to
be scaled down to a single replica so that we're assured the profile was
generated on that replica.  Scaling down should be done before the
specific condition the profile hopes to capture has occurred because the
scale down process is somewhat random in which replicas it stops.

(`ncn#`) To scale a deployment down to a single replica:

  ```bash
  kubectl scale deployment -n services cray-power-control --replicas=1
  ```

(`ncn#`) To scale it back up to the appropriate replica count (e.g. 3):

  ```bash
  kubectl scale deployment -n services cray-power-control --replicas=3
  ```

Note that scaling down a deployment to a single replica may not always be
possible.  Larger systems may require more that more than one replica
always be running in order to maintain proper functionality.  In these
situations there may be other ways to gather profiles, which won't be
covered here.

HPE Service will work with you to determine if scaling down a deployment
is necessary and if not, how we might alternatively gather a profile.

### Restore Production Container Image

After the necessary profiles have been collected and no further debugging
with `pprof` is required, reset the service's deployed image back to its
production image.

1. (`ncn#`) First, edit the deployment:

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

    Refer to [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
    further below for all deployment names.

1. (`ncn#`) Search for the `pprof` enabled container image by looking for
the text string `image:`

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control-pprof:2.7.0
    ```

1. (`ncn#`) Remove the substring `-pprof` from the end of the image name:

    ```yaml
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control:2.7.0
    ```

1. (`ncn#`) After saving your changes to the deployment, the pods will
restart using the production image.  You can determine when they have
completed restarting by watching them restart with:

    ```bash
    watch -n1 "kubectl get pods -n services | grep -e cray-power-control -e NAME"
    ```

1. Once all of the pods have been restarted you are complete.

## Gathering Profiles

In order to gather a `pprof` profile, you must provide a valid
authentication token with your request.  Perform the following to set
up a `TOKEN` environment variable containing it:

```bash
export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

### Service Mesh Considerations

Gathering profiles from outside of the service mesh is generally easier
than gathering them from inside the service mesh. However, not all HMS
services are available outside the service mesh.  Refer to the
[Deployment Name And `PProf` URL Reference](#deployment-name-and-pprof-url-reference)
table further below to determine which services are accessible outside
vs inside the service mesh.

#### Gathering Profiles From Outside the Service Mesh

The following `curl` command demonstrates how to request a `pprof` profile
from the PCS service:

```bash
curl -sk -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/power-control/v1/debug/pprof/heap -o pcs.heap.02062024.pprof
```

Note the descriptive nature of the profile's output file.  It is always
good to be as descriptive as possible, especially when multiple profiles
are generated. Consider using a timestamp as well, if appropriate.  If the
pod name, including hash, is available, consider using that in the filename
as well (the deployment must have been scaled down).

For the example above, we requested a "heap" `pprof` profile.  There are
several different types of profiles that may be requested.  Some examples:

- `cmdline`: The running program's command line
- `profile`: A sampling of CPU usage
- `heap`: A sampling of heap allocations
- `goroutine`: Stack traces of all current go routines
- `block`: Stack traces that led to blocking on synchronization primitives
- `mutex`: Stack traces of holder of contended mutexes

Refer to [Deployment Name And `PProf` URL Reference](#deployment-name-and-pprof-url-reference)
for the base `pprof` URL for each HMS service.  You would append the name
of the profile type to the base URL, replacing `heap` in the above example.

There may also be additional arguments to pass to `curl` when requesting a
profile.

HPE Service will communicate which profiles to gather and any additional
arguments that may be necessary.

#### Gathering Profiles From Inside the Service Mesh

A few more steps are required to gather profiles from inside the service
mesh for those services unavailable outside of the service mesh.  There
are nuances for each service, so each is documented individually or as
pairs.  The first example, `hmcollector-ingress` will be given in a bit
more detail, while the remaining will be abbreviated.

##### `hmcollector-ingress`

(`ncn#`) First, select a specific pod for the request:

```bash
> kubectl get pods -n services | grep -e cray-hms-hmcollector-ingress -e NAME
NAME                                                              READY   STATUS      RESTARTS        AGE
cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp                     2/2     Running     0               2d
cray-hms-hmcollector-ingress-6b7fd6566c-lsgwj                     2/2     Running     0               2d
cray-hms-hmcollector-ingress-6b7fd6566c-wmcvf                     2/2     Running     0               2d
```

Let's choose `cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp` for this
example.

(`ncn#`) Next, use the `kubectl` command to `exec` into the pod and use
the `curl` command to generate the profile inside of the pod:

```bash
kubectl -n services exec -it cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp -- curl http://cray-hms-hmcollector-ingress/debug/pprof/heap -o /tmp/hmcollector-ingress.heap.04242025.pprof
```

(`ncn#`) Then, copy the profile out of the pod:

```bash
kubectl -n services cp cray-hms-hmcollector-ingress-6b7fd6566c-9kcvp:/tmp/hmcollector-ingress.heap.04242025.pprof hmcollector-ingress.heap.04242025.pprof
```

##### `hmcollector-poll`

(`ncn#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-hms-hmcollector-poll-78d458b567-fph2p -- curl http://cray-hms-hmcollector-poll/debug/pprof/heap -o /tmp/hmcollector-poll.heap.04242025.pprof

kubectl -n services cp cray-hms-hmcollector-poll-78d458b567-fph2p:/tmp/hmcollector-poll.heap.04242025.pprof hmcollector-poll.heap.04242025.pprof
```

##### MEDS

(`ncn#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-meds-778577d9bb-kmv8h -- curl http://cray-meds/debug/pprof/heap -o /tmp/meds.heap.04242025.pprof

kubectl -n services cp cray-meds-778577d9bb-kmv8h:/tmp/meds.heap.04242025.pprof meds.heap.04242025.pprof
```

##### RTS

(`ncn#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-hms-rts-6df8f8859d-fb4f7 -c cray-hms-rts -- curl -k https://cray-hms-rts/debug/pprof/heap -o /tmp/rts.heap.04242025.pprof

kubectl -n services cp cray-hms-rts-6df8f8859d-fb4f7:/tmp/rts.heap.04242025.pprof -c cray-hms-rts rts.heap.04242025.pprof
```

##### RTS-SNMP

(`ncn#`) Abbreviated example after identifying the target pod:

```bash
kubectl -n services exec -it cray-hms-rts-snmp-6cbb9d55b7-r5hp2 -c cray-hms-rts -- curl -k https://cray-hms-rts-snmp/debug/pprof/heap -o /tmp/rts-snmp.heap.04242025.pprof

kubectl -n services cp cray-hms-rts-snmp-6cbb9d55b7-r5hp2:/tmp/rts-snmp.heap.04242025.pprof -c cray-hms-rts rts-snmp.heap.04242025.pprof
```

## Sending Profiles To HPE Service

Simply attach any gathered profiles to your open case. Invariably, HPE
Service will also request output from the following commands.  Please
gather this additional data around the same time as the `pprof` profile.

(`ncn#`) General pod status:

```bash
kubectl get pods -n services | grep -e NAME -e cray-power-control
```

(`ncn#`) Pod resource utilization:

```bash
kubectl top pod -n services --containers=true | grep -e NAME -e cray-power-control
```

## Deployment Name And `PProf` URL Reference

| Service               | Deployment Name                | Base `PProf` URL                                                      |
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
| RTS-SNMP              | `cray-hms-rts-snmp`            | unavailable outside service mesh
| SCSD                  | `cray-scsd`                    | `https://api-gw-service-nmn.local/apis/scsd/v1/debug/pprof/`           |
| SLS                   | `cray-sls`                     | `https://api-gw-service-nmn.local/apis/sls/v1/debug/pprof/`           |
| SMD                   | `cray-smd`                     | `https://api-gw-service-nmn.local/apis/smd/hsm/v2/debug/pprof/`       |
