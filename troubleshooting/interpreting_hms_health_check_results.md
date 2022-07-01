# Interpreting HMS Health Check Results

### Table of contents:
1. [Introduction](#introduction)
2. [Overview](#overview)
3. [Execution](#execution)
4. [Failure Analysis](#failure-analysis)
5. [Tavern Output](#tavern-output)
6. [Additional Troubleshooting](#additional-troubleshooting)
7. [Install Blocking vs. Non-Blocking Failures](#install-blocking-vs-non-blocking-failures)

### Introduction

This document describes how to interpret the results of the HMS Health Check scripts and techniques for troubleshooting when failures occur.

### Overview

The HMS CT tests are API tests intended to verify that HMS services are installed, operational, and behaving as expected. There are two types of CT tests for HMS services: smoke and functional. Both types of tests are executed via Helm test jobs that are defined in the Helm chart for the service that they test. The CT smoke and functional tests are invoked using the `helm test` command on master or worker NCNs (if applicable). Admins execute the HMS CT tests using a wrapper script called `run_hms_ct_tests.sh` as part of the CSM health validation procedures.

The CT smoke tests are basic API tests that make simple calls to HMS service APIs and verify that the expected status codes are returned. They run first and are useful for verifying that HMS services are installed and responsive. These tests will fail if the service being tested is not installed, unhealthy, or unresponsive.

The CT functional tests are more rigorous API tests that inspect the API response bodies and verify that the fields, values, and form of the data returned are as expected. They run after the CT smoke tests and verify that HMS service APIs behave correctly and in accordance with their API specification. They also detect issues that prevent the management and expected use of hardware in the system.

### Execution

The `run_hms_ct_tests.sh` script executes all HMS CT tests in parallel. It waits for each Helm test job to complete, logs the results in a file for the test run, and prints a summary of the results. The script returns a status code of zero if all tests pass and non-zero if there are one or more failures.

```text
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh
Log file for run is: /opt/cray/tests/hms_ct_test-<datetime>.log
Running all tests...
DONE.
SUCCESS: All 9 service tests passed: bss, capmc, fas, hbtd, hmnfd, hsm, reds, scsd, sls
echo $?
0
```

The following is an example of a single service failure:

```text
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh
Log file for run is: /opt/cray/tests/hms_ct_test-<datetime>.log
Running all tests...
DONE.
FAILURE: 1 service test FAILED (hsm), 8 passed (bss, capmc, fas, hbtd, hmnfd, reds, scsd, sls)
For troubleshooting and manual steps, see: https://github.com/Cray-HPE/docs-csm/blob/main/troubleshooting/hms_ct_manual_run.md
echo $?
1
```

The following is an example of multiple service failures:

```text
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh
Log file for run is: /opt/cray/tests/hms_ct_test-<datetime>.log
Running all tests...
DONE.
FAILURE: All 9 service tests FAILED: bss, capmc, fas, hbtd, hmnfd, hsm, reds, scsd, sls
For troubleshooting and manual steps, see: https://github.com/Cray-HPE/docs-csm/blob/main/troubleshooting/hms_ct_manual_run.md
echo $?
1
```

### Failure Analysis

If one or more service tests fail, the log file for the run should be inspected to determine which test job(s) failed.

The following is an example of a smoke test failure:

```text
cat /opt/cray/tests/hms_ct_test-<datetime>.log
<snip>
NAME: cray-hms-smd
LAST DEPLOYED: Thu Jun 16 15:46:10 2022
NAMESPACE: services
STATUS: deployed
REVISION: 9
TEST SUITE:     cray-hms-smd-test-smoke
Last Started:   Fri Jul  1 21:12:58 2022
Last Completed: Fri Jul  1 21:14:25 2022
Phase:          Failed
```

In this case, the HSM smoke test job failed. Find the name of the job and inspect its output to determine the cause of the failure.

```text
kubectl -n services get pods | grep -E "smd|NAME"
NAME                                                              READY   STATUS             RESTARTS   AGE
cray-hms-smd-test-smoke-2npqz                                     1/2     NotReady           0          83s
cray-smd-747b59d979-2vvdw                                         2/2     Running            0          4d6h
cray-smd-747b59d979-c5rhl                                         2/2     Running            0          4d5h
cray-smd-747b59d979-vcv6c                                         2/2     Running            0          4d6h

kubectl -n services logs cray-hms-smd-test-smoke-2npqz smoke
Running smoke tests...
<snip>
2022-07-01 21:13:05,853 Testing {"path": "hsm/v2/service/ready", "expected_status_code": 200, "method": "GET", "body": null, "headers": {}, "url": "http://cray-smd/hsm/v2/service/ready"}
2022-07-01 21:13:05,863 Starting new HTTP connection (1): cray-smd:80
2022-07-01 21:13:05,873 FAIL: HTTPConnectionPool(host='cray-smd', port=80): Max retries exceeded with url: /hsm/v2/service/ready (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7faf6fdf6460>: Failed to establish a new connection: [Errno 111] Connection refused'))
<snip>
2022-07-01 21:13:09,282 FAIL: hsm-smoke-tests
2022-07-01 21:13:09,282 failed!
2022-07-01 21:13:09,282 FAIL: hsm-smoke-tests ran with failures
```

The following is an example of a functional test failure:

```text
cat /opt/cray/tests/hms_ct_test-<datetime>.log
<snip>
NAME: cray-hms-smd
LAST DEPLOYED: Thu Jun 16 15:46:10 2022
NAMESPACE: services
STATUS: deployed
REVISION: 9
TEST SUITE:     cray-hms-smd-test-functional
Last Started:   Fri Jul  1 21:12:58 2022
Last Completed: Fri Jul  1 21:14:25 2022
Phase:          Failed
```

In this case, the HSM functional test job failed. Find the name of the job and inspect its output to determine the cause of the failure.

```text
kubectl -n services get pods | grep -E "smd|NAME"
NAME                                                              READY   STATUS             RESTARTS   AGE
cray-hms-smd-test-functional-fs8b4                                1/2     NotReady           0          61s
cray-hms-smd-test-smoke-2npqz                                     0/2     Completed          0          103s
cray-smd-747b59d979-2vvdw                                         2/2     Running            0          4d6h
cray-smd-747b59d979-c5rhl                                         2/2     Running            0          4d5h
cray-smd-747b59d979-vcv6c                                         2/2     Running            0          4d6h

kubectl -n services logs cray-hms-smd-test-functional-fs8b4 functional
Running functional tests...
============================= test session starts ==============================
platform linux -- Python 3.10.4, pytest-7.1.2, pluggy-1.0.0 -- /usr/bin/python3
cachedir: .pytest_cache
rootdir: /src/app, configfile: pytest.ini
plugins: tap-3.3, tavern-1.23.1
collecting ... collected 38 items
<snip>
test_components.tavern.yaml::Ensure that we can conduct a query for all Nodes in the Component collection FAILED [ 21%]
<snip>
=================================== FAILURES ===================================
_ /src/app/test_components.tavern.yaml::Ensure that we can conduct a query for all Nodes in the Component collection _
<snip>
Errors:
E   tavern.util.exceptions.TestFailError: Test 'Verify the expected response fields for all Nodes' failed:
    - Error calling validate function '<function validate_pykwalify at 0x7f34e3ebf6d0>':
        Traceback (most recent call last):
          File "/usr/lib/python3.10/site-packages/tavern/schemas/files.py", line 106, in verify_generic
            verifier.validate()
          File "/usr/lib/python3.10/site-packages/pykwalify/core.py", line 194, in validate
            raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
        pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
         - Enum 'Alert' does not exist. Path: '/Components/8/Flag' Enum: ['OK'].: Path: '/'>
<snip>
=========================== short test summary info ============================
FAILED test_components.tavern.yaml::Ensure that we can conduct a query for all Nodes in the Component collection
======================== 1 failed, 37 passed in 29.06s =========================
2022-07-01 21:13:09,282 FAIL
```

### Tavern Output

Tavern is a pytest-based API testing framework. The CT functional tests consist of Tavern tests for HMS services that are written in yaml and execute via Helm test jobs. This section describes the output format of Tavern and where to look when investigating functional test failures.

First, a summary of the test suites executed and their results is printed:

```text
============================= test session starts ==============================
platform linux -- Python 3.10.4, pytest-7.1.2, pluggy-1.0.0 -- /usr/bin/python3
cachedir: .pytest_cache
rootdir: /src/app, configfile: pytest.ini
plugins: tap-3.3, tavern-1.23.1
collecting ... collected 10 items

test_component_endpoints.tavern.yaml::Query the ComponentEndpoints collection PASSED [  2%]
test_components.tavern.yaml::Ensure that we can conduct a query for all Nodes in the Component collection PASSED [ 21%]
test_discovery_status.tavern.yaml::Ensure that we can gather the system discovery status information PASSED [ 39%]
test_groups.tavern.yaml::Verify POST, GET, PATCH, and DELETE methods for various /groups APIs PASSED [ 42%]
test_hardware.tavern.yaml::Query the Hardware collection PASSED          [ 44%]
test_memberships.tavern.yaml::Ensure that we can gather information from the memberships collection PASSED [ 57%]
test_partitions.tavern.yaml::Verify POST, GET, PATCH, and DELETE methods for various /partitions APIs PASSED [ 60%]
test_redfish_endpoints.tavern.yaml::Ensure that we can gather information from the RedfishEndpoints collection PASSED [ 63%]
test_service_endpoints.tavern.yaml::Query the ServiceEndpoints collection PASSED [ 65%]
test_state_change_notifications.tavern.yaml::Ensure that we can gather information from the state change notifications collection PASSED [100%]

============================= 10 passed in 24.87s ==============================
2022-07-01 21:14:57,296 PASS
```

When test failures occur, additional output is printed below the summary table that includes the following:

* The `Source test stage` that was executing when the failure occurred. This is a portion of the source code for the failed test case.
* The `Formatted stage` that was executing when the failure occurred. This is a portion of the source code for the failed test case with its variables filled in with the values that were set at the time of the failure. This includes the request header, method, url, and other data from the failed test case which is useful for attempting to reproduce the failure manually with `curl`.
* The specific *Errors* encountered when processing the API response that caused the failure. **This is the first place to look when debugging Tavern test failures.**

The following is an example `Source test stage`:

```text
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
      Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJXcXFhelBLNnNVSnpUV250bThmYWh3cGVLOGRjeTB4SjFpSmRWRGZaLV8wIn0.eyJqdGkiOiI4ZGZkNTQ0YS1jNTY5LTQyNmUtYThiYy02NDg4MzgxOWUyOTAiLCJleHAiOjE2NDQ0MzczODEsIm5iZiI6MCwiaWF0IjoxNjEyOTAxMzgxLCJpc3MiOiJodHRwczovL2FwaS1ndy1zZXJ2aWNlLW5tbi5sb2NhbC9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjpbImdhdGVrZWVwZXIiLCJzaGFzdGEiLCJhY2NvdW50Il0sInN1YiI6IjJjNDFiYjgwLTM2NGEtNGNkOS1hMGZkLTQyYzQ5ODRmMTM2ZSIsInR5cCI6IkJlYXJlciIsImF6cCI6ImFkbWluLWNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjEzZGQ1YmY2LWQxNGMtNDcwZC05ZWI0LTQ5MDFmYzc3YWYwOSIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7InNoYXN0YSI6eyJyb2xlcyI6WyJhZG1pbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwiY2xpZW50SG9zdCI6IjEwLjMyLjAuMSIsImNsaWVudElkIjoiYWRtaW4tY2xpZW50IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtYWRtaW4tY2xpZW50IiwiY2xpZW50QWRkcmVzcyI6IjEwLjMyLjAuMSJ9.c37RtSOzcM_-6poyPecS7HP_t1hnqURkgjRcXTQj2S0IEZAkMyfeOVYRFr1gDlAFP-BnRPkf_X2_B7d63j9gI15M1gksYcv8PP0bZFX3PAOaBu-hHGfIw2pDsNsJEA-L72Pb9nmcaPR1CnnVijwRFV-jAmGBJ_vv612mjR5nbI_YJUHDkgdzDfWbpWKQzuCxiJ8USxPD-ASqx_pLecUzcihorb6PNngMaeisc2TqLTV8YRhSZYeL3cssEcXyTxRBe3zjPDawlPArjY2FUkEdzbtl-Tq3D2Ulii44esOf4_ooGmUsOc9vrvYvM_JNPAVamv0-0709PRwwNjFl9nEd5g
    method: GET
    url: 'https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?nid=None'
    verify: !bool 'False'
  response:
    status_code: 200
```

The following is an example `Errors` section:

```text
Errors:
E   tavern.util.exceptions.TestFailError: Test 'Ensure the boot script service can provide the bootscript for a given node' failed:
    - Status code was 400, expected 200:
        {"type": "about:blank", "title": "Bad Request", "detail": "Need a mac=, name=, or nid= parameter", "status": 400}
```

### Additional Troubleshooting

This section provides guidance for handling specific HMS Health Check failures that may occur.

#### hsm_discovery_status_test.sh

This test verifies that the system hardware has been discovered successfully.

The following is an example of a failed test execution:

```text
Running hsm_discovery_status_test...
(22:19:34) Running 'kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}''...
(22:19:34) Running 'curl -k -i -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=4c591ddc-b770-41c8-a4de-465ec034c7cf https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token'...
(22:19:35) Testing 'curl -s -k -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJEdDZ3ZGNMSzNvT196LWFKaGNkYzBMTkpNSVY5cXRiX25GSXhlRUxCaWFRIn0.eyJqdGkiOiI2NGI0OWE0Zi03YzFiLTRkMjQtYmI2Zi1lYzRhYjczYTI0MDIiLCJleHAiOjE2NTk2NTE1NzQsIm5iZiI6MCwiaWF0IjoxNjI4MTE1NTc0LCJpc3MiOiJodHRwczovL2FwaS1ndy1zZXJ2aWNlLW5tbi5sb2NhbC9rZXljbG9hay9yZWFsbXMvc2hhc3RhIiwiYXVkIjpbImdhdGVrZWVwZXIiLCJzaGFzdGEiLCJhY2NvdW50Il0sInN1YiI6IjdhNGM3YWI5LTMyY2EtNGE5Ny04NGJiLWIzNjc3NmUyZTUwZSIsInR5cCI6IkJlYXJlciIsImF6cCI6ImFkbWluLWNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6ImZjOTdiMzVlLWVjMmUtNGZmYy05NjEzLTg2MDZhY2RiODUxMyIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7InNoYXN0YSI6eyJyb2xlcyI6WyJhZG1pbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJlbWFpbCBwcm9maWxlIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJjbGllbnRIb3N0IjoiMTAuNDYuMC4wIiwiY2xpZW50SWQiOiJhZG1pbi1jbGllbnQiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtYWRtaW4tY2xpZW50IiwiY2xpZW50QWRkcmVzcyI6IjEwLjQ2LjAuMCJ9.Moecw0ygc_G5whueojAwT3V6Tqtyp7pmqJlvMS5fMz0NxLhb6-3FYK60N5XIqK4RgXeP8TY004hxMyfel9ZqHwI1e5jC8ZHx0y4N41-1t3dgPZnmxvKiaIE14WfovYFDJGU3xcugZcFAnpylVFIABrPQG4Sk66MVaiOubsqW-i855Z0GZurSJOJMAl6LceJ_ek6OWhVlEsEh3S2phCmUA4C-lxRNviDcXhHThPZ0ruOb9bhtQV5uVD7BviIA_VBBN1BSrNJIfIyps5ZwpYr0KwbnntwbYap8zf56UC5MVz0kOyGk1n6qMlVNKn2W0tB4oTJynBdGgehNIqv93rXZyA" https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/RedfishEndpoints'...
(22:19:35) Processing response with: 'jq '.RedfishEndpoints[] | { ID: .ID, LastDiscoveryStatus: .DiscoveryInfo.LastDiscoveryStatus}' -c | sort -V | jq -c'...
(19:06:02) Verifying endpoint discovery statuses...
{"ID":"x3000c0s1b0","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3000c0s9b0","LastDiscoveryStatus":"ChildVerificationFailed"}
{"ID":"x3000c0s19b999","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3000c0s27b0","LastDiscoveryStatus":"ChildVerificationFailed"}
FAIL: hsm_discovery_status_test found 4 endpoints that failed discovery, maximum allowable is 1
'/opt/cray/csm/scripts/hms_verification/hsm_discovery_status_test.sh' exited with status code: 1
```

The expected state of LastDiscoveryStatus is `DiscoverOK` for all endpoints with the exception of the BMC for `ncn-m001`, which is not normally connected to the site network and expected to be `HTTPsGetFailed`. If the test fails because of two or more endpoints not having been discovered successfully, the following additional steps can be taken to determine the cause of the failure:

##### HTTPsGetFailed

1. Check to see if the failed component name (xname) resolves using the `nslookup` command. If not, then the problem may be a DNS issue.
```bash
nslookup <xname>
```
2. Check to see if the failed component name (xname) responds to the `ping` command. If not, then the problem may be a network or hardware issue.
```bash
ping -c 1 <xname>
```
3. Check to see if the failed component name (xname) responds to a Redfish query. If not, then the problem may be a credentials issue. Use the password set in the REDS sealed secret when creating site init.
```bash
curl -s -k -u root:<password> https://<xname>/redfish/v1/Managers | jq
```

If discovery failures for Gigabyte CMCs with component names (xnames) of the form `xXc0sSb999` occur, verify that the root service account is configured for the CMC and add it if needed by following the steps outlined in [Add Root Service Account for Gigabyte Controllers](../operations/security_and_authentication/Add_Root_Service_Account_for_Gigabyte_Controllers.md).

If discovery failures for HPE PDUs with component names (xnames) of the form `xXmM` occur, this may indicate that configuration steps have not yet been executed which are required for the PDUs to be discovered. Refer to [HPE PDU Admin Procedures](../operations/hpe_pdu/hpe_pdu_admin_procedures.md) for additional configuration for this type of PDU. The steps to run will depend on if the PDU has been set up yet, and whether or not an upgrade or fresh install of CSM is being performed.

##### ChildVerificationFailed

Check the SMD logs to determine the cause of the bad Redfish path encountered during discovery.

```bash
# get the SMD pod names
ncn # kubectl -n services get pods -l app.kubernetes.io/name=cray-smd
NAME                        READY   STATUS    RESTARTS   AGE
cray-smd-5b9d574756-9b2lj   2/2     Running   0          24d
cray-smd-5b9d574756-bnztf   2/2     Running   0          24d
cray-smd-5b9d574756-hhc5p   2/2     Running   0          24d

# get the logs from each of the SMD pods
kubectl -n services logs <cray-smd-pod1> cray-smd > smd_pod1_logs
kubectl -n services logs <cray-smd-pod2> cray-smd > smd_pod2_logs
kubectl -n services logs <cray-smd-pod3> cray-smd > smd_pod3_logs
```

##### DiscoveryStarted

The endpoint is in the process of being inventoried by Hardware State Manager (HSM). Wait for the current discovery operation to end which should result in a new LastDiscoveryStatus state being set for the endpoint.

Use the following command to check the current discovery status of the endpoint:

```bash
cray hsm inventory redfishEndpoints describe <xname>
```

### Install Blocking vs. Non-Blocking Failures

The HMS Health Checks include tests for multiple types of system components, some of which are critical for the installation of the system, while others are not.

The following types of HMS test failures should be considered blocking for system installations:

* HMS service pods not running
* HMS service APIs unreachable through the API Gateway or Cray CLI
* Failures related to HMS discovery (unreachable BMCs, unresponsive controller hardware, no Redfish connectivity)

The following types of HMS test failures should **not** be considered blocking for system installations:

* Failures due to hardware issues on individual compute nodes

It is typically safe to postpone the investigation and resolution of non-blocking failures until after the CSM installation has completed.
