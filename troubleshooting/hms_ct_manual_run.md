# Running CT Tests Manually

To run the tests manually:

```
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
```

Examine the output. If one or more failures occur, investigate the cause of each failure. See the [interpreting_hms_health_check_results](../troubleshooting/interpreting_hms_health_check_results.md) documentation for more information.

Otherwise, run the HMS functional tests.

```
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_functional_tests_ncn-resources.sh
```

Examine the output. If one or more failures occur, investigate the cause of each failure. See the [interpreting_hms_health_check_results](../troubleshooting/interpreting_hms_health_check_results.md) documentation for more information.

