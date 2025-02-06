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

There may be times when HPE requests the gathering of `pprof` profiles as an
aid to debug certain classes of problems within HMS services.  `PProf` is a
profiling and debug tool that is part of the Go programming languade tool
set.  These profiles can be useful when debugging performance issues and
resource leaks.  This is a new feature that was added to most (but not all)
HMS services in the CSM 1.6.1 release.

By default, HMS services are deployed with container images that do not
include built in `pprof` support.  Profiling can incur overhead, which we
generally prefer to avoid in production.  When necessary, HPE may request
that `pprof` enabled images be put into place so that profiles can be
gathered and sent back to HPE for review.

Throughout the documentation below, we will use PCS (Power Control
Service) in the provided examples.

## Deploying `PProf` Enabled Container Images

### Edit Deployment

1. (`ncn#`) First, edit the deployment:

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

    Refer to [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
    for the deployment names of other HMS services.

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
completed restarting by watching them with:

    ```bash
    watch -n1 "kubectl get pods -n services | grep -e cray-power-control -e NAME"
    ```

1. Once the pods have been restarted, `pprof` profiles may be gathered.
However, it may take time for performance issues or resoure leaks to recur.
HPE Support will communicate when to gather profiles in your open support
case.

### Possibly Scale Down Replicas

TBD

### Important Note On Persistence

Should the deployed service be upgraded or downgraded to a different version
of that service, the use of the `pprof` enabled image will not persist and
the changes previously made to use the `pprof` enabled image will need to be
repeated.

### Restore The Non-`PProf` Enabled Container Image When Done

After the necessary profiles have been collected and no further debugging
with `pprof` is required, set the service's image back to its production
image.

1. (`ncn#`) First, edit the deployment:

    ```bash
    kubectl -n services edit deployment/cray-power-control
    ```

    Refer to [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
    for the deployment names of other HMS services.

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
completed restarting by watching them with:

    ```bash
    watch -n1 "kubectl get pods -n services | grep -e cray-power-control -e NAME"
    ```

1. Once the pods have been restarted you are complete.


## Gathering Profiles

tbd

### Using Curl

See [Deployment Name And PProf URL Reference](#deployment-name-and-pprof-url-reference)
for the base `pprof` URL for each HMS service.

## Send Profile Back To HPE

Any profiles gathered should be attached to your support case.  HPE will
analyze and provide feedback.

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