## Interpreting HMS Health Check Results

### Table of contents:
1. [Introduction](#introduction)
2. [HMS Smoke Tests](#hms-smoke-tests)
3. [HMS Functional Tests](#hms-functional-tests)
4. [Additional Troubleshooting](#additional-troubleshooting)
5. [Known Issues](#known-issues)

<a name="introduction"></a>
### Introduction

This document describes how to interpret the results of the HMS health check scripts and techniques for troubleshooting when failures occur.

<a name="hms-smoke-tests"></a>
### HMS Smoke Tests

The HMS smoke tests consist of bash scripts that check the status of HMS service pods and jobs in Kubernetes and verify HTTP status codes returned by the HMS service APIs. Additionally, there is one test called *smd_discovery_status_test_ncn-smoke.sh* which verifies that the system hardware has been discovered successfully. The *hms_run_ct_smoke_tests_ncn-resources.sh* wrapper script checks for executable files in the HMS smoke test directory on the NCN and runs all tests found in succession.

```
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
searching for HMS CT smoke tests...
found 11 HMS CT smoke tests...
running HMS CT smoke tests...
```

A summary of the test results is printed at the bottom of the output.

```
HMS smoke tests ran with 2/11 failures
exiting with status code: 1
```

The tests print the commands being executed while running. They also print the command output and status code if failures occur in order to help with debugging.

The following is an example of a pod status failure:

```
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

```
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

<a name="hms-functional-tests"></a>
### HMS Functional Tests

The HMS functional tests consist of Tavern-based API tests for HMS services that are written in yaml and execute within *hms-pytest* containers on the NCNs that are spun up using podman. The functional tests are more rigorous than the smoke tests and verify the behavior of HMS service APIs in greater detail. The *hms_run_ct_functional_tests_ncn-resources.sh* wrapper script checks for executable files in the HMS functional test directory on the NCN and runs all tests found in succession.

```
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh
searching for HMS CT functional tests...
found 4 HMS CT functional tests...
running HMS CT functional tests...
```

A summary of the test results is printed at the bottom of the output.

```
HMS functional tests ran with 1/4 failures
exiting with status code: 1
```

The tests print the commands being executed while running. They also print the command output and status code if failures occur in order to help with debugging.

The following is an example of an *hms-pytest* container spin-up failure, which may occur if the *hms-pytest* image is unavailable or missing from the local image registry on the NCN:

```
(20:06:04) Running '/usr/bin/hms-pytest --tavern-global-cfg=/opt/cray/tests/ncn-functional/hms/hms-bss/common.yaml /opt/cray/tests/ncn-functional/hms/hms-bss'...
Trying to pull registry.local/cray/hms-pytest:1.1.1...
  manifest unknown: manifest unknown
Error: unable to pull registry.local/cray/hms-pytest:1.1.1: Error initializing source docker://registry.local/cray/hms-pytest:1.1.1: Error reading manifest 1.1.1 in registry.local/cray/hms-pytest: manifest unknown: manifest unknown
FAIL: bss_tavern_api_test ran with failures
cleaning up...
```

A summary of the test suites executed and their results is printed for each HMS service tested. Period '.' characters represent test cases that passed and letter 'F' characters represent test cases that failed within each test suite.

The following is an example of a *pytest* summary table for Tavern test suites executed against a service:

```
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

When API test failures occur, output from Tavern is printed by *pytest* indicating the following:

* The *Source test stage* that was executing when the failure occurred which is a portion of the source code for the failed test case.
* The *Formatted stage* that was executing when the failure occurred which is a portion of the source code for the failed test case with its variables filled in with the values that were set at the time of the failure. This includes the request header, method, url, and other options of the failed test case which is useful for attempting to reproduce the failure using the *curl* command.
* The specific *Errors* encountered when processing the API response that caused the failure. **This is the first place to look when debugging API test failures.**

The following is an example *Source test stage*:

```
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

The following is an example *Formatted stage*:

```
Formatted stage:
  name: Ensure the boot script service can provide the bootscript for a given node
  request:
    headers:
      Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJXcXFhelBLNnNVSnpUV250bThmYWh3cGVLOGRjeTB4SjFpSmRWRGZaLV8wIn0.eyJqdGkiOiI4ZGZkNTQ0YS1jNTY5LTQyNmUtYThiYy02NDg4MzgxOWUyOTAiLCJleHAiOjE2NDQ0MzczODEsIm5iZiI6MCwiaWF0IjoxNjEyOTAxMzgxLCJpc3MiOiJodHRwczovL2FwaS1ndy1zZXJ2aWNlLW5tbi5sb2NhbC9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjpbImdhdGVrZWVwZXIiLCJzaGFzdGEiLCJhY2NvdW50Il0sInN1YiI6IjJjNDFiYjgwLTM2NGEtNGNkOS1hMGZkLTQyYzQ5ODRmMTM2ZSIsInR5cCI6IkJlYXJlciIsImF6cCI6ImFkbWluLWNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjEzZGQ1YmY2LWQxNGMtNDcwZC05ZWI0LTQ5MDFmYzc3YWYwOSIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7InNoYXN0YSI6eyJyb2xlcyI6WyJhZG1pbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwiY2xpZW50SG9zdCI6IjEwLjMyLjAuMSIsImNsaWVudElkIjoiYWRtaW4tY2xpZW50IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtYWRtaW4tY2xpZW50IiwiY2xpZW50QWRkcmVzcyI6IjEwLjMyLjAuMSJ9.c37RtSOzcM_-6poyPecS7HP_t1hnqURkgjRcXTQj2S0IEZAkMyfeOVYRFr1gDlAFP-BnRPkf_X2_B7d63j9gI15M1gksYcv8PP0bZFX3PAOaBu-hHGfIw2pDsNsJEA-L72Pb9nmcaPR1CnnVijwRFV-jAmGBJ_vv612mjR5nbI_YJUHDkgdzDfWbpWKQzuCxiJ8USxPD-ASqx_pLecUzcihorb6PNngMaeisc2TqLTV8YRhSZYeL3cssEcXyTxRBe3zjPDawlPArjY2FUkEdzbtl-Tq3D2Ulii44esOf4_ooGmUsOc9vrvYvM_JNPAVamv0-0709PRwwNjFl9nEd5g
    method: GET
    url: 'https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?nid=None'
    verify: !bool 'False'
  response:
    status_code: 200
```

The following is an example *Errors* section:

```
Errors:
E   tavern.util.exceptions.TestFailError: Test 'Ensure the boot script service can provide the bootscript for a given node' failed:
    - Status code was 400, expected 200:
        {"type": "about:blank", "title": "Bad Request", "detail": "Need a mac=, name=, or nid= parameter", "status": 400}
```

<a name="additional-troubleshooting"></a>
### Additional Troubleshooting

This section provides guidance for handling specific HMS Health Check failures that may occur.

#### smd_discovery_status_test_ncn-smoke.sh

This test verifies that the system hardware has been discovered successfully.

The following is an example of a failed test execution:

```
Running smd_discovery_status_test...
(22:19:34) Running 'kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}''...
(22:19:34) Running 'curl -k -i -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=4c591ddc-b770-41c8-a4de-465ec034c7cf https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token'...
(22:19:35) Testing 'curl -s -k -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJEdDZ3ZGNMSzNvT196LWFKaGNkYzBMTkpNSVY5cXRiX25GSXhlRUxCaWFRIn0.eyJqdGkiOiI2NGI0OWE0Zi03YzFiLTRkMjQtYmI2Zi1lYzRhYjczYTI0MDIiLCJleHAiOjE2NTk2NTE1NzQsIm5iZiI6MCwiaWF0IjoxNjI4MTE1NTc0LCJpc3MiOiJodHRwczovL2FwaS1ndy1zZXJ2aWNlLW5tbi5sb2NhbC9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjpbImdhdGVrZWVwZXIiLCJzaGFzdGEiLCJhY2NvdW50Il0sInN1YiI6IjdhNGM3YWI5LTMyY2EtNGE5Ny04NGJiLWIzNjc3NmUyZTUwZSIsInR5cCI6IkJlYXJlciIsImF6cCI6ImFkbWluLWNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6ImZjOTdiMzVlLWVjMmUtNGZmYy05NjEzLTg2MDZhY2RiODUxMyIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7InNoYXN0YSI6eyJyb2xlcyI6WyJhZG1pbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJlbWFpbCBwcm9maWxlIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJjbGllbnRIb3N0IjoiMTAuNDYuMC4wIiwiY2xpZW50SWQiOiJhZG1pbi1jbGllbnQiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtYWRtaW4tY2xpZW50IiwiY2xpZW50QWRkcmVzcyI6IjEwLjQ2LjAuMCJ9.Moecw0ygc_G5whueojAwT3V6Tqtyp7pmqJlvMS5fMz0NxLhb6-3FYK60N5XIqK4RgXeP8TY004hxMyfel9ZqHwI1e5jC8ZHx0y4N41-1t3dgPZnmxvKiaIE14WfovYFDJGU3xcugZcFAnpylVFIABrPQG4Sk66MVaiOubsqW-i855Z0GZurSJOJMAl6LceJ_ek6OWhVlEsEh3S2phCmUA4C-lxRNviDcXhHThPZ0ruOb9bhtQV5uVD7BviIA_VBBN1BSrNJIfIyps5ZwpYr0KwbnntwbYap8zf56UC5MVz0kOyGk1n6qMlVNKn2W0tB4oTJynBdGgehNIqv93rXZyA" https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/RedfishEndpoints'...
(22:19:35) Processing response with: 'jq '.RedfishEndpoints[] | { ID: .ID, LastDiscoveryStatus: .DiscoveryInfo.LastDiscoveryStatus}' -c | sort -V | jq -c'...
(19:06:02) Verifying endpoint discovery statuses...
{"ID":"x3000c0s1b0","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3000c0s9b0","LastDiscoveryStatus":"ChildVerificationFailed"}
{"ID":"x3000c0s19b999","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3000c0s27b0","LastDiscoveryStatus":"ChildVerificationFailed"}
FAIL: smd_discovery_status_test found 4 endpoints that failed discovery, maximum allowable is 1
'/opt/cray/tests/ncn-smoke/hms/hms-smd/smd_discovery_status_test_ncn-smoke.sh' exited with status code: 1
```

The expected state of LastDiscoveryStatus is *DiscoverOK* for all endpoints with the exception of the BMC for ncn-m001 which is not normally connected to the site network and expected to be *HTTPsGetFailed*. If the test fails because of two or more endpoints not having been discovered successfully, the following additional steps can be taken to determine the cause of the failure:

##### HTTPsGetFailed

1. Check to see if the failed xname resolves using the *nslookup* command. If not, then the problem may be a DNS issue.
```
ncn# nslookup <xname>
```
2. Check to see if the failed xname responds to the *ping* command. If not, then the problem may be a network or hardware issue.
```
ncn# ping -c 1 <xname>
```
3. Check to see if the failed xname responds to a Redfish query. If not, then the problem may be a credentials issue. Use the password set in the REDS sealed secret when creating site init.
```
ncn# curl -s -k -u root:<password> https://<xname>/redfish/v1/Managers | jq
```

##### ChildVerificationFailed

Check the SMD logs to determine the cause of the bad Redfish path encountered during discovery.

```
# get the SMD pod names
ncn # kubectl -n services get pods -l app.kubernetes.io/name=cray-smd
NAME                        READY   STATUS    RESTARTS   AGE
cray-smd-5b9d574756-9b2lj   2/2     Running   0          24d
cray-smd-5b9d574756-bnztf   2/2     Running   0          24d
cray-smd-5b9d574756-hhc5p   2/2     Running   0          24d

# get the logs from each of the SMD pods
ncn# kubectl -n services logs <cray-smd-pod1> cray-smd > smd_pod1_logs
ncn# kubectl -n services logs <cray-smd-pod2> cray-smd > smd_pod2_logs
ncn# kubectl -n services logs <cray-smd-pod3> cray-smd > smd_pod3_logs
```

##### DiscoveryStarted

The endpoint is in the process of being inventoried by Hardware State Manager (HSM). Wait for the current discovery operation to end which should result in a new LastDiscoveryStatus state being set for the endpoint.

Use the following command to check the current discovery status of the endpoint:

```
ncn# cray hsm inventory redfishEndpoints describe <xname>
```

<a name="known-issues"></a>
### Known Issues

This section outlines known issues that cause HMS Health Check failures.

* [Warning flags incorrectly set in HSM for Mountain BMCs (SDEVICE-3319)](#hms-known-issue-mountain-bmcs-warning-flags)
* [BMCs set to "On" state in HSM (CASMHMS-5239)](#hms-bmcs-set-to-on-state-in-hsm)

<a name="hms-known-issue-mountain-bmcs-warning-flags"></a>
#### Warning flags incorrectly set in HSM for Mountain BMCs (SDEVICE-3319)

The HMS functional tests include a check for unexpected flags that may be set in Hardware State Manager (HSM) for the BMCs on the system. There is a known issue [SDEVICE-3319](https://connect.us.cray.com/jira/browse/SDEVICE-3319) that can cause Warning flags to be incorrectly set in HSM for Mountain BMCs and result in test failures.

The following HMS functional test may fail due to this issue:
* `test_smd_components_ncn-functional_remote-functional.tavern.yaml`

The symptom of this issue is the test fails with error messages about Warning flags being set on one or more BMCs. It may look similar to the following in the test output:

```
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

If you see this, perform the following steps:

1. Retrieve the xnames of all Mountain BMCs with Warning flags set in HSM:

    ```
    ncn-mw# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/smd/hsm/v1/State/Components?Type=NodeBMC\&Class=Mountain\&Flag=Warning | jq '.Components[] | { ID: .ID, Flag: .Flag, Class: .Class }' -c | sort -V | jq -c
    {"ID":"x5000c1s0b0","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s0b1","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s1b0","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s1b1","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s2b0","Flag":"Warning","Class":"Mountain"}
    {"ID":"x5000c1s2b1","Flag":"Warning","Class":"Mountain"}
    ```

1. For each Mountain BMC xname, check its Redfish BMC Manager status:

    ```
    ncn-mw# curl -s -k -u root:${BMC_PASSWORD} https://x5000c1s0b0/redfish/v1/Managers/BMC | jq '.Status'
    {
    "Health": "OK",
    "State": "Online"
    }
    ```

Test failures and HSM Warning flags for Mountain BMCs with the Redfish BMC Manager status shown above can be safely ignored.

<a name="hms-bmcs-set-to-on-state-in-hsm"></a>
#### BMCs set to "On" state in HSM (CASMHMS-5239)

The following HMS functional test may fail due to known issue [CASMHMS-5239](https://connect.us.cray.com/jira/browse/CASMHMS-5239) because of CMMs setting BMC states to "On" instead of "Ready" in HSM:
* `test_smd_components_ncn-functional_remote-functional.tavern.yaml`

This issue looks similar to the following in the test output:

```
      Traceback (most recent call last):
            verifier.validate()
         File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
            raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
      pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
         - Enum 'On' does not exist. Path: '/Components/9/State'.
         - Enum 'On' does not exist. Path: '/Components/10/State'.: Path: '/'>
```

Failures of this test caused by BMCs in the "On" state can be safely ignored.
