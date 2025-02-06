# Debugging With HMS `PProf` Images

- [Interpreting HMS Health Check Results](#interpreting-hms-health-check-results)
    - [Introduction](#introduction)
    - [Prerequisites](#prerequisites)
    - [Overview](#overview)
    - [Execution](#execution)
        - [Test all HMS services](#test-all-hms-services)
        - [Test specific HMS service](#test-specific-hms-service)
        - [Example output](#example-output)
    - [Failure analysis](#failure-analysis)
        - [Smoke test failure](#smoke-test-failure)
        - [Functional test failure](#functional-test-failure)
    - [Tavern output](#tavern-output)
    - [Additional troubleshooting](#additional-troubleshooting)
        - [`run_hms_ct_tests.sh`](#run_hms_ct_testssh)
            - [`cray-hms-smd-test-functional`](#cray-hms-smd-test-functional)
                - [`test_components.tavern.yaml` and `test_hardware.tavern.yaml`](#test_componentstavernyaml-and-test_hardwaretavernyaml)
                - [`test_components.tavern.yaml`](#test_componentstavernyaml)
            - [`cray-hms-firmware-action-test-functional`](#cray-hms-firmware-action-test-functional)
                - [`test_actions.tavern.yaml`](#test_actionstavernyaml)
            - [`cray-power-control-test-functional`](#cray-power-control-test-functional)
                - [`test_power-status.tavern.yaml`](#test_power-statustavernyaml)
        - [`hsm_discovery_status_test.sh`](#hsm_discovery_status_testsh)
            - [`HTTPsGetFailed`](#httpsgetfailed)
            - [`ChildVerificationFailed`](#childverificationfailed)
            - [`DiscoveryStarted`](#discoverystarted)
    - [Install blocking vs. Non-blocking failures](#install-blocking-vs-non-blocking-failures)

## Introduction

There may be times when HPE Service requests the gathering of `pprof`
profiles as an aid to debug certain classes of problems within HMS
services.  `PProf` is a profiling and debug tool that is part of the
Go programming language tool set.  These profiles can be useful when
debugging performance issues and resource leaks.  This is a new
capability that was added to most (but not all) HMS services in the
CSM 1.6.1 release.

By default, HMS services are deployed with container images that do
not include `pprof` support.  Profiling can incur overhead, which we
generally prefer to avoid in production.  When necessary, HPE may
request that `pprof` enabled images be temporarily put into place so
that profiles can be gathered and sent back to HPE for review.

Throughout this documentation, we will refer to PCS (Power Control
Service) in the provided examples.

## Deploying `PProf` Enabled Container Images

### Edit Deployment

1. (`ncn#`) First, edit the deployment for the target service:

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

    Refer to [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
    for all deployment names.

1. (`ncn#`) Search for the container image by looking for the text
  string `image:`

    ```bash
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control:2.7.0
    ```

1. (`ncn#`) Append the string `-pprof` to the end of the image name:

    ```bash
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control-pprof:2.7.0
    ```

1. (`ncn#`) After saving your changes to the deployment, the pods will
restart using the `pprof` enabled image.  You can determine when they have
completed restarting by watching them restart with:

    ```bash
    watch -n1 "kubectl get pods -n services | grep -e cray-power-control -e NAME"
    ```

1. Once all of the pods have been restarted, `pprof` profiles may be
gathered. However, it may take time for performance issues or resoure
leaks to recur. HPE Support will communicate how long to wait before
gathing any profiles.

### Possibly Scale Down Replicas

When any request is sent to an HMS service, it first goes through the
API gateway which load balances requests across all of a service's
replicas, or pods. This means that a returned `pprof` profile could
have been generated on any one of the replicas.

There may be times when we want to a profile from a specific replica.
If this level of control is necessary, the deployment must be scaled
down to a single replica.  That is the only way to insure that a
profile was generated on a specific replica.

(`ncn#`) To scale a deployment down to a single replica:

  ```bash
  kubectl scale deployment -n services cray-power-control --replicas=1
  ```

(`ncn#`) To scale it back up to the appropriate replica count (eg. 3):

  ```bash
  kubectl scale deployment -n services cray-power-control --replicas=3
  ```

Note that scaling down a deployment to a single replica may not always be
possible.  Larger systems may require more that more than one replica
always be running in order to maintain proper functionality.

HPE Service will work with you to determine if scaling down a deployment
is necessary.

### Important Note On Persistence

Should the deployed service be upgraded or downgraded to a different version
of that service, the change to the `pprof` enabled image will not persist.
You must repeat the steps above after the upgrade or downgrade in order to
put the `pprof` enabled container image back into place.

### Restore The Non-`PProf` Enabled Container Image When Done

After the necessary profiles have been collected and no further debugging
with `pprof` is required, set the service's image back to its production
image.

1. (`ncn#`) First, edit the deployment:

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

    Refer to [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
    for all deployment names.

1. (`ncn#`) Search for the `pprof` enabled container image by looking for
the text string `image:`

    ```bash
    image: artifactory.algol60.net/csm-docker/stable/cray-power-control-pprof:2.7.0
    ```

1. (`ncn#`) Remove the substring `-pprof` from the end of the image name:

    ```bash
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

In order to request a `pprof` profile, you must provide a valid
authentication token along with your request.  Perform the following
to set up a `TOKEN` environment variable with containing it:

```bash
export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

The following `curl` command demonstrates how to request a `pprof` profile
from the PCS service:

```bash
curl -sk -H "Authorization: Bearer ${TOKEN}" https://localhost:8088/apis/power-control/v1/debug/pprof/heap -o pcs.heap.02062024.pprof
```

Note the descriptive nature of the profile's output file.  It is always
good to be as descriptive as possible, especially when multiple profiles
are generated. Consider using a timestamp if appropriate.  If the pod
name, including hash, is available, consider using that in the filename
as well (deployment must have been scaled down).

For the example above, we requested a "heap" `pprof` profile.  There are
several different types of profiles that can be requested.  Some examples:

- cmdline: The running program's command line
- profile: A sampling of cpu usage
- heap: A sampling of heap allocations
- goroutine: Stack traces of all current goroutines
- block: Stack traces that led to blocking on synchronization primitives
- mutex: Stack traces of holder of contended mutexes

Refer to [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
for the base `pprof` URL for each HMS service.  You would append the name
of the profile type to the base URL.

There may also be additional arguments to pass to `curl` when requesting a
profile.

HPE Service will communicate which profiles to gather and any additional
arguments that may be necessary.

## Provide Profile To HPE Service

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

## Deployment Name And PProf URL Reference

tbd

| Service             | Deployment Name              | Base `PProf` URL                                                    |
|---------------------|------------------------------|---------------------------------------------------------------------|
| BSS                 | cray-bss                     | https://api-gw-service-nmn.local/apis/bss/debug/pprof/              |
| FAS                 | cray-fas                     | https://api-gw-service-nmn.local/apis/fas/v1/debug/pprof/           |
| HBTD                | cray-hbtd                    | https://api-gw-service-nmn.local/apis/hbtd/hmi/v1/debug/pprof/      |
| hmcollector-ingress | cray-hms-hmcollector-ingress | unavailable outside service mesh                                    |
| hmcollector-poll    | cray-hms-hmcollector-poll    | not yet supported                                                   |
| HMNFD               | cray-hmnfd                   | https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/debug/pprof/     |
| MEDS                | cray-meds                    | not yet supported                                                   |
| PCS                 | cray-power-control           | https://api-gw-service-nmn.local/apis/power-control/v1/debug/pprof/ |
| RTS                 | cray-hms-rts                 | not yet supported                                                   |
| SCSD                | cray-scsd                    | not yet supported                                                   |
| SLS                 | cray-sls                     | https://api-gw-service-nmn.local/apis/sls/v1/debug/pprof/           |
| SMD                 | cray-smd                     | https://api-gw-service-nmn.local/apis/smd/hsm/v2/debug/pprof/       |