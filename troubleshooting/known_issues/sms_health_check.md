# Software Management Services Health Check - Known Issues

This document describes known issues and troubleshooting guidance for the `cmsdev` test suite used to validate Software Management Services (SMS) in CSM.

> For comprehensive documentation including all available tests, command-line options, and usage examples, see 
[`cmsdev` Tests](../cmsdev_tests.md).

* [Quick reference](#quick-reference)
* [Known issues](#known-issues)
    * [Cray CLI not configured](#cray-cli-not-configured)
    * [Invalid CFS component](#invalid-cfs-component)
    * [VCS subtest command failure](#vcs-subtest-command-failure)
* [Additional resources](#additional-resources)

## Quick reference

(`ncn-mw#`) The following command runs the SMS health checks:

```bash
/usr/local/bin/cmsdev test -q all
```

(`ncn-mw#`) Show the `cmsdev` version by running the following command:

```bash
/usr/local/bin/cmsdev version
```

The test log location is: `/opt/cray/tests/install/logs/cmsdev/YYMMDD_HHMMSS_microseconds_PID/cmsdev.log`

For detailed usage information, see [`cmsdev` Tests](../cmsdev_tests.md).

## Known issues

This section documents common issues that may occur when running the `cmsdev` test suite.

* [Cray CLI not configured](#cray-cli-not-configured)
* [Invalid CFS component](#invalid-cfs-component)
* [VCS subtest command failure](#vcs-subtest-command-failure)

### Cray CLI not configured

**Symptom**: Some subtests fail with CLI-related errors.

**Cause**: The Cray CLI is not properly configured on the management NCN where `cmsdev` is executed.

**Resolution**:

Configure the Cray CLI before running tests. For information on how to do this, see the following resources:

* [Cray command line interface](../../operations/validate_csm_health.md#0-cray-command-line-interface)
* [Configure the Cray CLI](../../operations/configure_cray_cli.md)

**Note**: CLI tests are only run when using the `--include-cli` flag. See [Test control options](../cmsdev_tests.md#test-control-options) for details.

### Invalid CFS component

**Symptom**: The `cmsdev` CFS subtest fails with errors related to component ID validation.

**Cause**: A CFS component exists with a zero-length string for its `id` field.

The error messages vary by `cmsdev` version:

* **`cmsdev` versions 1.25 or higher**:

    ```text
    ERROR (run tag fhn3C-cfs): In first item listed, 'id' field maps to a 0-length string, but it should have non-0 length
    ```

* **`cmsdev` versions 1.16.2 to 1.24**:

    ```text
    ERROR (run tag sosdD-cfs): GET https://api-gw-service-nmn.local/apis/cfs/v3/components/: expected status code 200, got 404
    ERROR (run tag sosdD-cfs): GET https://api-gw-service-nmn.local/apis/cfs/v2/components/: expected status code 200, got 404
    ERROR (run tag sosdD-cfs): CLI command (cfs v3 components describe  --format json) failed with exit code 2
    ERROR (run tag sosdD-cfs): CLI command (cfs v2 components describe  --format json) failed with exit code 2
    ```

* **`cmsdev` versions less than 1.16.2**:

    ```text
    ERROR (run tag fhn3C-cfs): First list item has empty value for "id" field
    ```

**Resolution**:

See [CFS Component With Zero-Length ID](CFS_Component_With_Zero_Length_ID.md) for detailed remediation steps.

### VCS subtest command failure

**Symptom**: The VCS subtest fails with a command error.

The error message resembles the following:

```text
ERROR (run tag Xe9tC-vcs): Command failed
```

If the test is run in verbose mode, or the `cmsdev` log file is examined, a line similar to the following is found:

```text
fatal: unable to access 'https://crayvcs:BPuN/M846JL5XKTTWVqcV2mhuZfzOC64nnZ/e54ri1M=@api-gw-service-nmn.local/vcs/test-cmsdev-zvkEP50G/harf-zEK1SuiP.git/': URL using bad/illegal format or missing URL
```

**Cause**: The VCS administrative password contains illegal characters that are not properly URL-encoded.

**Resolution**:

See [VCS Password With Illegal Characters](VCS_Password_With_Illegal_Characters.md) for detailed remediation steps.

**To view detailed errors**:

* Run test in verbose mode: `/usr/local/bin/cmsdev test -v vcs`
* Or examine the log file: `/opt/cray/tests/install/logs/cmsdev/YYMMDD_HHMMSS_microseconds_PID/cmsdev.log`

See [Logging](../cmsdev_tests.md#logging) for more information on logging.

## Additional resources

* [`cmsdev` Tests](../cmsdev_tests.md) - Complete test suite reference
* [Configure the Cray CLI](../../operations/configure_cray_cli.md)
* [Validate CSM health](../../operations/validate_csm_health.md)
