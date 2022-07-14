# Interpreting HMS Health Check Results

## Table of contents

- [Introduction](#introduction)
- [HMS smoke tests](#hms-smoke-tests)
- [HMS functional tests](#hms-functional-tests)
- [Additional troubleshooting](#additional-troubleshooting)
  - [`smd_discovery_status_test_ncn-smoke.sh`](#smd_discovery_status_test_ncn-smokesh)
    - [`HTTPsGetFailed`](#httpsgetfailed)
    - [`ChildVerificationFailed`](#childverificationfailed)
    - [`DiscoveryStarted`](#discoverystarted)
- [Install blocking vs. Non-blocking failures](#install-blocking-vs-non-blocking-failures)
- [Known issues](#known-issues)
  - [Warning flags incorrectly set in HSM for Mountain BMCs](#warning-flags-incorrectly-set-in-hsm-for-mountain-bmcs)
  - [BMCs set to `On` state in HSM](#bmcs-set-to-on-state-in-hsm)
  - [`ComponentEndpoints` of Redfish subtype `AuxiliaryController` in HSM](#componentendpoints-of-redfish-subtype-auxiliarycontroller-in-hsm)
  - [Custom Roles and SubRoles for Components in HSM](#custom-roles-and-subroles-for-components-in-hsm)

## Introduction

This document describes how to interpret the results of the HMS health check scripts and techniques for troubleshooting when failures occur.

## HMS smoke tests

The HMS smoke tests consist of bash scripts that check the status of HMS service pods and jobs in Kubernetes and verify HTTP status codes returned by the HMS service APIs. Additionally, there is one
test called `smd_discovery_status_test_ncn-smoke.sh` which verifies that the system hardware has been discovered successfully. The `hms_run_ct_smoke_tests_ncn-resources.sh` wrapper script checks for
executable files in the HMS smoke test directory on the NCN and runs all tests found in succession.

```bash
ncn-mw# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
```

Example output:

```text
searching for HMS CT smoke tests...
found 11 HMS CT smoke tests...
running HMS CT smoke tests...
```

A summary of the test results is printed at the bottom of the output.

```text
HMS smoke tests ran with 2/11 failures
exiting with status code: 1
```

The tests print the commands being executed while running. They also print the command output and status code if failures occur in order to help with debugging.

The following is an example of a pod status failure:

```text
running '/opt/cray/tests/ncn-smoke/hms/hms-reds/reds_smoke_test_ncn-smoke.sh'...
Running reds_smoke_test...
(11:40:33) Running '/opt/cray/tests/ncn-resources/hms/hms-test/hms_check_pod_status_ncn-resources_remote-resources.sh cray-reds'...
services         cray-reds-867c65879d-cr4mg                                        1/2     CrashLoopBackOff   266        24h

Pod status: CrashLoopBackOff
ERROR: '/opt/cray/tests/ncn-resources/hms/hms-test/hms_check_pod_status_ncn-resources_remote-resources.sh cray-reds' failed with error code: 1
FAIL: reds_smoke_test ran with failures
cleaning up...
'/opt/cray/tests/ncn-smoke/hms/hms-reds/reds_smoke_test_ncn-smoke.sh' exited with status code: 1
```

The following is an example of an API call failure:

```text
running '/opt/cray/tests/ncn-smoke/hms/hms-capmc/capmc_smoke_test_ncn-smoke.sh'...
Running capmc_smoke_test...
(11:40:27) Running '/opt/cray/tests/ncn-resources/hms/hms-test/hms_check_pod_status_ncn-resources_remote-resources.sh cray-capmc'...
(11:40:27) Running 'kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}''...
(11:40:27) Running 'curl -k -i -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=${CLIENT_SECRET} https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token'...
(11:40:28) Testing 'curl -k -i -s -S -o /tmp/capmc_smoke_test_out-${DATETIME}.${RAND}.curl${NUM}.tmp -X POST -d '{}' -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap_capabilities'...
HTTP/2 503
ERROR: 'curl -k -i -s -S -o /tmp/capmc_smoke_test_out-${DATETIME}.${RAND}.curl${NUM}.tmp -X POST -d '{}' -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/capmc/capmc/v1/get_power_cap_capabilities' did not return "200" or "204" status code as expected

MAIN_ERRORS=1
FAIL: capmc_smoke_test ran with failures
cleaning up...
'/opt/cray/tests/ncn-smoke/hms/hms-capmc/capmc_smoke_test_ncn-smoke.sh' exited with status code: 1
```

## HMS functional tests

The HMS functional tests consist of Tavern-based API tests for HMS services that are written in YAML and execute within `hms-pytest` containers on the NCNs that are spun up using `podman`. The
functional tests are more rigorous than the smoke tests and verify the behavior of HMS service APIs in greater detail. The `hms_run_ct_functional_tests_ncn-resources.sh` wrapper script checks for
executable files in the HMS functional test directory on the NCN and runs all tests found in succession.

```bash
ncn-mw# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh
```

Initial output will resemble the following:

```text
searching for HMS CT functional tests...
found 4 HMS CT functional tests...
running HMS CT functional tests...
```

A summary of the test results is printed at the bottom of the output.

```text
HMS functional tests ran with 1/4 failures
exiting with status code: 1
```

The tests print the commands being executed while running. They also print the command output and status code if failures occur in order to help with debugging.

The following is an example of an `hms-pytest` container spin-up failure, which may occur if the `hms-pytest` image is unavailable or missing from the local image registry on the NCN:

```text
(20:06:04) Running '/usr/bin/hms-pytest --tavern-global-cfg=/opt/cray/tests/ncn-functional/hms/hms-bss/common.yaml /opt/cray/tests/ncn-functional/hms/hms-bss'...
Trying to pull registry.local/cray/hms-pytest:1.1.1...
  manifest unknown: manifest unknown
Error: unable to pull registry.local/cray/hms-pytest:1.1.1: Error initializing source docker://registry.local/cray/hms-pytest:1.1.1: Error reading manifest 1.1.1 in registry.local/cray/hms-pytest: manifest unknown: manifest unknown
FAIL: bss_tavern_api_test ran with failures
cleaning up...
```

A summary of the test suites executed and their results is printed for each HMS service tested. Period '.' characters represent test cases that passed and letter 'F' characters represent test cases that failed within each test suite.

The following is an example of a `pytest` summary table for Tavern test suites executed against a service:

```text
============================= test session starts ==============================
platform linux -- Python 3.8.5, pytest-6.1.2, py-1.10.0, pluggy-0.13.1
rootdir: /opt/cray/tests/ncn-functional/hms/hms-smd, configfile: pytest.ini
plugins: tap-3.2, tavern-1.12.2
collected 38 items

test_smd_component_endpoints_ncn-functional_remote-functional.tavern.yaml . [  2%]
......                                                                   [ 18%]
test_smd_components_ncn-functional_remote-functional.tavern.yaml F.F.... [ 36%]
                                                                         [ 36%]
test_smd_discovery_status_ncn-functional_remote-functional.tavern.yaml . [ 39%]
                                                                         [ 39%]
test_smd_groups_ncn-functional_remote-functional.tavern.yaml .           [ 42%]
test_smd_hardware_ncn-functional_remote-functional.tavern.yaml ....F     [ 55%]
test_smd_memberships_ncn-functional_remote-functional.tavern.yaml .      [ 57%]
test_smd_partitions_ncn-functional_remote-functional.tavern.yaml .       [ 60%]
test_smd_redfish_endpoints_ncn-functional_remote-functional.tavern.yaml . [ 63%]
                                                                         [ 63%]
test_smd_service_endpoints_ncn-functional_remote-functional.tavern.yaml . [ 65%]
...F........                                                             [ 97%]
test_smd_state_change_notifications_ncn-functional_remote-functional.tavern.yaml . [100%]
```

When API test failures occur, output from Tavern is printed by `pytest` indicating the following:

- The `Source test stage` that was executing when the failure occurred which is a portion of the source code for the failed test case.
- The `Formatted stage` that was executing when the failure occurred which is a portion of the source code for the failed test case with its variables filled in with the values that were set at the
  time of the failure. This includes the request header, method, URL, and other options of the failed test case which is useful for attempting to reproduce the failure using the `curl` command.
- The specific `Errors` encountered when processing the API response that caused the failure. **This is the first place to look when debugging API test failures.**

The following is an example `Source test stage`:

```yaml
Source test stage (line 179):
  - name: Ensure the boot script service can provide the bootscript for a given node
    request:
      url: "{base_url}/bss/boot/v1/bootscript?nid={nid}"
      method: GET
      headers:
        Authorization: "Bearer {access_token}"
      verify: !bool "{verify}"
    response:
      status_code: 200
```

The following is an example `Formatted stage`:

```yaml
Formatted stage:
  name: Ensure the boot script service can provide the bootscript for a given node
  request:
    headers:
      Authorization: Bearer <REDACTED>
    method: GET
    url: 'https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?nid=None'
    verify: !bool 'False'
  response:
    status_code: 200
```

The following is an example `Errors` section:

```yaml
Errors:
E   tavern.util.exceptions.TestFailError: Test 'Ensure the boot script service can provide the bootscript for a given node' failed:
    - Status code was 400, expected 200:
        {"type": "about:blank", "title": "Bad Request", "detail": "Need a mac=, name=, or nid= parameter", "status": 400}
```

## Additional troubleshooting

This section provides guidance for handling specific HMS health check failures that may occur.

### `smd_discovery_status_test_ncn-smoke.sh`

This test verifies that the system hardware has been discovered successfully.

The following is an example of a failed test execution:

```text
Running smd_discovery_status_test...
(22:19:34) Running 'kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}''...
(22:19:34) Running 'curl -k -i -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=<REDACTED> https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token'...
(22:19:35) Testing 'curl -s -k -H "Authorization: Bearer <REDACTED>" https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/RedfishEndpoints'...
(22:19:35) Processing response with: 'jq '.RedfishEndpoints[] | { ID: .ID, LastDiscoveryStatus: .DiscoveryInfo.LastDiscoveryStatus}' -c | sort -V | jq -c'...
(19:06:02) Verifying endpoint discovery statuses...
{"ID":"x3000c0s1b0","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3000c0s9b0","LastDiscoveryStatus":"ChildVerificationFailed"}
{"ID":"x3000c0s19b999","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3000c0s27b0","LastDiscoveryStatus":"ChildVerificationFailed"}
FAIL: smd_discovery_status_test found 4 endpoints that failed discovery, maximum allowable is 1
'/opt/cray/tests/ncn-smoke/hms/hms-smd/smd_discovery_status_test_ncn-smoke.sh' exited with status code: 1
```

The expected state of `LastDiscoveryStatus` is `DiscoverOK` for all endpoints with the exception of the BMC for `ncn-m001`, which is not normally connected to the site network and expected to be
`HTTPsGetFailed`. If the test fails because of two or more endpoints not having been discovered successfully, then take the following additional steps in order to determine the cause of the failure:

#### `HTTPsGetFailed`

1. Check to see if the failed component name (xname) resolves using the `nslookup` command.

    If not, then the problem may be a DNS issue.

    ```bash
    ncn-mw# nslookup <xname>
    ```

1. Check to see if the failed component name (xname) responds to the `ping` command.

    If not, then the problem may be a network or hardware issue.

    ```bash
    ncn-mw# ping -c 1 <xname>
    ```

1. Check to see if the failed component name (xname) responds to a Redfish query.

    If not, then the problem may be a credentials issue. Use the password set in the REDS sealed secret.

    ```bash
    ncn-mw# curl -s -k -u root:<password> https://<xname>/redfish/v1/Managers | jq
    ```

#### `ChildVerificationFailed`

Check the SMD logs to determine the cause of the bad Redfish path encountered during discovery.

1. Get the SMD pod names.

    ```bash
    ncn-mw# kubectl -n services get pods -l app.kubernetes.io/name=cray-smd
    ```

    Example output:

    ```text
    NAME                        READY   STATUS    RESTARTS   AGE
    cray-smd-5b9d574756-9b2lj   2/2     Running   0          24d
    cray-smd-5b9d574756-bnztf   2/2     Running   0          24d
    cray-smd-5b9d574756-hhc5p   2/2     Running   0          24d
    ```

1. Get the logs from each of the SMD pods.

    ```bash
    ncn-mw# kubectl -n services logs <cray-smd-pod1> cray-smd > smd_pod1_logs
    ncn-mw# kubectl -n services logs <cray-smd-pod2> cray-smd > smd_pod2_logs
    ncn-mw# kubectl -n services logs <cray-smd-pod3> cray-smd > smd_pod3_logs
    ```

#### `DiscoveryStarted`

The endpoint is in the process of being inventoried by Hardware State Manager (HSM). Wait for the current discovery operation to end which should result in a new `LastDiscoveryStatus` state being set for the endpoint.

Use the following command to check the current discovery status of the endpoint:

```bash
ncn-mw# cray hsm inventory redfishEndpoints describe <xname>
```

## Install blocking vs. Non-blocking failures

The HMS health checks include tests for multiple types of system components, some of which are critical for the installation of the system, while others are not.

The following types of HMS test failures should be considered blocking for system installations:

- HMS service pods not running
- HMS service APIs unreachable through the API Gateway or Cray CLI
- Failures related to HMS discovery (for example: unreachable BMCs, unresponsive controller hardware, or no Redfish connectivity)

The following types of HMS test failures should **not** be considered blocking for system installations:

- Failures due to hardware issues on individual compute nodes (alerts or warning flags set in HSM)

It is typically safe to postpone the investigation and resolution of non-blocking failures until after the CSM installation or upgrade has completed.

## Known issues

This section outlines known issues that cause HMS health check failures.

- [Warning flags incorrectly set in HSM for Mountain BMCs](#warning-flags-incorrectly-set-in-hsm-for-mountain-bmcs)
- [BMCs set to `On` state in HSM](#bmcs-set-to-on-state-in-hsm)
- [`ComponentEndpoints` of Redfish subtype `AuxiliaryController` in HSM](#componentendpoints-of-redfish-subtype-auxiliarycontroller-in-hsm)
- [Custom Roles and SubRoles for Components in HSM](#custom-roles-and-subroles-for-components-in-hsm)

### Warning flags incorrectly set in HSM for Mountain BMCs

The HMS functional tests include a check for unexpected flags that may be set in Hardware State Manager (HSM) for the BMCs on the system. There is a known issue that can cause Warning flags to be
incorrectly set in HSM for Mountain BMCs and result in test failures.

The following HMS functional test may fail due to this issue:

- `test_smd_components_ncn-functional_remote-functional.tavern.yaml`

The symptom of this issue is the test fails with error messages about Warning flags being set on one or more BMCs. It may look similar to the following in the test output:

```text
=================================== FAILURES ===================================
_ /opt/cray/tests/ncn-functional/hms/hms-smd/test_smd_components_ncn-functional_remote-functional.tavern.yaml::Ensure that we can conduct a query for all Node BMCs in the Component collection _

Errors:
E   tavern.util.exceptions.TestFailError: Test 'Verify the expected response fields for all NodeBMCs' failed:
   - Error calling validate function '<function validate_pykwalify at 0x7f44666179d0>':
      Traceback (most recent call last):
         File "/usr/lib/python3.8/site-packages/tavern/schemas/files.py", line 106, in verify_generic
            verifier.validate()
         File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
            raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
      pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
         - Enum 'Warning' does not exist. Path: '/Components/9/Flag'.
         - Enum 'Warning' does not exist. Path: '/Components/10/Flag'.
         - Enum 'Warning' does not exist. Path: '/Components/11/Flag'.
         - Enum 'Warning' does not exist. Path: '/Components/12/Flag'.
         - Enum 'Warning' does not exist. Path: '/Components/13/Flag'.
         - Enum 'Warning' does not exist. Path: '/Components/14/Flag'.: Path: '/'>
```

If this failure is encountered, then perform the following steps:

1. Retrieve the component names (xnames) of all Mountain BMCs with Warning flags set in HSM.

    ```bash
    ncn-mw# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v1/State/Components?Type=NodeBMC\&Class=Mountain\&Flag=Warning | 
                jq '.Components[] | { ID: .ID, Flag: .Flag, Class: .Class }' -c | sort -V | jq -c
    ```

    Example output:

    ```json
    {"ID":"x5000c1s0b0","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s0b1","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s1b0","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s1b1","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s2b0","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s2b1","Flag":"Warning","Class":"Mountain"}
    ```

1. For each Mountain BMC xname, check its Redfish BMC Manager status:

    ```bash
    ncn-mw# curl -s -k -u root:${BMC_PASSWORD} https://x5000c1s0b0/redfish/v1/Managers/BMC | jq '.Status'
    ```

    Example output:

    ```json
    {
      "Health": "OK",
      "State": "Online"
    }
    ```

Test failures and HSM Warning flags for Mountain BMCs with the Redfish BMC Manager status shown above can be safely ignored.

### BMCs set to `On` state in HSM

The following HMS functional test may fail due to a known issue because of CMMs setting BMC states to `On` instead of `Ready` in HSM:

- `test_smd_components_ncn-functional_remote-functional.tavern.yaml`

This issue looks similar to the following in the test output:

```text
      Traceback (most recent call last):
            verifier.validate()
         File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
            raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
      pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
         - Enum 'On' does not exist. Path: '/Components/9/State'.
         - Enum 'On' does not exist. Path: '/Components/10/State'.: Path: '/'>
```

Failures of this test caused by BMCs in the `On` state can be safely ignored.

### `ComponentEndpoints` of Redfish subtype `AuxiliaryController` in HSM

The following HMS functional test may fail due to a known issue because of `ComponentEndpoints` of Redfish subtype `AuxiliaryController` in HSM:

- `test_smd_component_endpoints_ncn-functional_remote-functional.tavern.yaml`

This issue looks similar to the following in the test output:

```text
        Traceback (most recent call last):
          File "/usr/lib/python3.8/site-packages/tavern/schemas/files.py", line 106, in verify_generic
            verifier.validate()
          File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
            raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
        pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
         - Enum 'AuxiliaryController' does not exist. Path: '/ComponentEndpoints/32/RedfishSubtype'.
         - Enum 'AuxiliaryController' does not exist. Path: '/ComponentEndpoints/83/RedfishSubtype'.
         - Enum 'AuxiliaryController' does not exist. Path: '/ComponentEndpoints/92/RedfishSubtype'.
         - Enum 'AuxiliaryController' does not exist. Path: '/ComponentEndpoints/106/RedfishSubtype'.
         - Enum 'AuxiliaryController' does not exist. Path: '/ComponentEndpoints/126/RedfishSubtype'.: Path: '/'>
```

Failures of this test caused by `AuxiliaryController` endpoints for Cassini mezzanine cards can be safely ignored.

### Custom Roles and SubRoles for Components in HSM

The following HMS functional test may fail due to a known issue because of Components with custom Roles or SubRoles set in HSM:

- `test_smd_components_ncn-functional_remote-functional.tavern.yaml`

This issue looks similar to the following in the test output:

```text
        Traceback (most recent call last):
          File "/usr/lib/python3.8/site-packages/tavern/schemas/files.py", line 106, in verify_generic
            verifier.validate()
          File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
            raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
        pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
         - Enum 'DVS' does not exist. Path: '/Components/7/SubRole'.
         - Enum 'VizNode' does not exist. Path: '/Components/20/SubRole'.
         - Enum 'CrayDataServices' does not exist. Path: '/Components/147/SubRole'.
         - Enum 'MI' does not exist. Path: '/Components/165/SubRole'.
         - Enum 'NearNodeTier0' does not exist. Path: '/Components/198/SubRole'.
         - Enum 'DataMovers' does not exist. Path: '/Components/1499/SubRole'.: Path: '/'>
```

Failures of this test caused by custom Component Roles or SubRoles can be safely ignored.
