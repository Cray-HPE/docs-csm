# Running HMS CT Tests Manually

Use the following commands to run the HMS CT tests manually. These are the same tests that run as part of the CSM health validation procedures.

Note: The information in this documentation generally, and on this page in particular, differs based on the version of CSM installed on the system. If
viewing this documentation online, be sure that the CSM version of this documentation matches the CSM version on the system.

(`ncn-mw#`) To run all of the HMS CT tests:

```bash
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh
```

(`ncn-mw#`) To run the CT tests for an individual HMS service:

```bash
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh -t <service>
```

(`ncn-mw#`) To list the HMS services that can be tested:

```bash
/opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh -l
```

Examine the output. If one or more failures occur, investigate the cause of each failure. See [Interpreting HMS Health Check Results](../troubleshooting/interpreting_hms_health_check_results.md) for more information.
