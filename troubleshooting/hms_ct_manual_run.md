# Running HMS CT Tests Manually

Use the following commands to run the HMS CT tests manually. These are the same tests that run as part of the CSM health validation procedures.

## CSM-1.3

To run all of the HMS CT tests:

```bash
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh
```

To run the CT tests for an individual HMS service:

```bash
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh -t <service>
```

To list the HMS services that can be tested:

```bash
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh -l
```

Examine the output. If one or more failures occur, investigate the cause of each failure. See [Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) for more information.

## CSM-1.2 and Prior Releases

To run the HMS CT smoke tests:

```text
/opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
```

Examine the output. If one or more failures occur, investigate the cause of each failure. See
[Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) for more information.

To run the HMS CT functional tests:

```bash
/opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh
```

Examine the output. If one or more failures occur, investigate the cause of each failure. See [Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) for more information.
