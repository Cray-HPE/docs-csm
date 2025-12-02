# Software Management Services health checks

- [SMS test execution](#sms-test-execution)
- [Interpreting `cmsdev` Results](#interpreting-cmsdev-results)
- [Version](#version)
- [Logging](#logging)
    - [Log changes](#log-changes)
        - [Log file migration](#log-file-migration)
        - [Run tags](#run-tags)
- [Known issues with SMS tests](#known-issues-with-sms-tests)
    - [Cray CLI](#cray-cli)
    - [Invalid CFS component](#invalid-cfs-component)
    - [VCS subtest command failure](#vcs-subtest-command-failure)

## SMS test execution

This test requires that the Cray CLI is configured on nodes where the test is executed.
See [Cray command line interface](../../operations/validate_csm_health.md#0-cray-command-line-interface).

This test can be run on any Kubernetes NCN (any master or worker NCN, but **not** the PIT node).
When run on a Kubernetes master NCN, the TFTP file transfer subtest is omitted. However, that TFTP subtest is
run on a worker NCN as part of the Goss NCN health checks.

(`ncn-mw#`) The following command runs the entire SMS test suite (with the possible exception of the TFTP file
transfer subtest, as noted in the previous paragraph).

```bash
/usr/local/bin/cmsdev test -q all
```

The -q (quiet) or -v (verbose) flags can be added to decrease or increase the amount of information sent to the screen.
The same amount of data is written to the log file in either case. For more details on the log file, see [Logging](#logging).

## Interpreting `cmsdev` results

- If all checks are passed, the following will be true:
    - The return code will be zero.
    - The final line of output will begin with `SUCCESS`.
        - For example: `SUCCESS: All 6 service tests passed: bos, cfs, conman, ims, tftp, vcs`
- If one or more checks are failed, the following will be true:
    - The return code will be non-zero.
    - The final line of output will begin with `FAILURE` and lists the failed checks.
        - For example: `FAILURE: 2 service tests FAILED (conman, ims), 4 passed (bos, cfs, tftp, vcs)`
    - After remediating a test failure for a particular service, just that single service test can be rerun by replacing
      `all` in the `cmsdev` command line with the name of the service. For example: `/usr/local/bin/cmsdev test -q cfs`

Additional test execution details can be found in the log file.
For more details on the log file, see [Logging](#logging).

## Version

(`ncn-mw#`) The following command displays the version of the `cmsdev` test tool.

```bash
/usr/local/bin/cmsdev version
```

## Logging

> NOTE: `cmsdev` logging changed in `cmsdev` version 1.34.0. See [Log changes](#log-changes) for details.

Each `cmsdev` test run creates a timestamped subdirectory in `/opt/cray/tests/install/logs/cmsdev/`,
with a naming format of `YYMMDD_HHMMSS_microseconds_PID`. Inside of that directory, `cmsdev` logs to
a file named `cmsdev.log`. For example: `/opt/cray/tests/install/logs/cmsdev/20251012_050305_414367785_990773/cmsdev.log`.
In the case of a failure, a file named `artifacts.tgz` will also be saved to that directory.
It contains additional information that can help to debug the failures, if necessary.
For example, logs from relevant Kubernetes pods.

### Log changes

The logging behavior of `cmsdev` depends on the version of `cmsdev` being run.
See the [Version](#version) section above for details on how to find the version.

| *CSM versions*     | `cmsdev` *versions* | *Logging*                                                         |
| ------------------ | ------------------- | ----------------------------------------------------------------- |
| >= 1.7.0           | >= 1.34.0           | Timestamped log directories, as described above. Previous log file converted using [Log file migration](#log-file-migration) |
| >= 1.4.0, <= 1.7.0 | >= 1.12.0, < 1.34.0 | Single log file: `/opt/cray/tests/install/logs/cmsdev/cmsdev.log` |
| < 1.4.0            | < 1.12.0            | Single log file: `/opt/cray/tests/cmsdev.log`                     |

#### Log file migration

The upgrade to `cmsdev` 1.34.0 or later automatically migrates the single log file into the new format,
if needed. It performs the following procedure if it finds the legacy single log file.

1. Scans the legacy `cmsdev.log` file and identifies all unique [run tags](#run-tags)
1. For each run tag:
    1. Identifies the earliest timestamp in `cmsdev.log` for that tag
    1. Creates a subdirectory using the timestamp (without PID, because it is unknown for legacy runs)
    1. Extracts log entries for that run tag and writes the filtered results to `cmsdev.log` in the new subdirectory
    1. If an artifact file exists for this run tag, moves it into the subdirectory and renames it to `artifacts.tgz`
1. Remove the original `cmsdev.log` file located at `/opt/cray/tests/install/logs/cmsdev/`

This ensures backward compatibility and preserves historical test data in the new organized structure.

#### Run tags

Prior to `cmsdev` 1.34.0, every execution of `cmsdev` had an associated "run tag", which was just a short, random
alphanumeric string. Every line in the log file had this run tag included. This allowed users to extract the logs
for an individual test run from the monolithic log file. Run tags are used in the [Log file migration](#log-file-migration)
procedure to automatically convert the monolithic log file into the new per-execution format.

With the move to separate log files per execution, this tag no longer serves a purpose, and is no longer generated or logged.

## Known issues with SMS tests

- [Cray CLI](#cray-cli)
- [Invalid CFS component](#invalid-cfs-component)
- [VCS subtest command failure](#vcs-subtest-command-failure)

### Cray CLI

Some of the subtests may fail if the Cray CLI is not configured on the management NCN where `cmsdev` is executed.
See the following for more information:

- [Cray command line interface](../../operations/validate_csm_health.md#0-cray-command-line-interface)
- [Configure the Cray CLI](../../operations/configure_cray_cli.md)

### Invalid CFS component

If a CFS component exists with a zero-length string for its `id` field, then it may cause the `cmsdev`
CFS subtest to fail. The `cmsdev` test failure symptom will depend on the version of `cmsdev` being run.
(See the [Version](#version) section above for details on how to find the version).

- For `cmsdev` versions 1.25 or higher, the CFS subtest failures will resemble the following:

    ```text
    ERROR (run tag fhn3C-cfs): In first item listed, 'id' field maps to a 0-length string, but it should have non-0 length
    ```

- For `cmsdev` versions less than 1.25 but at least 1.16.2, the CFS subtest failures will resemble the following:

    ```text
    ERROR (run tag sosdD-cfs): GET https://api-gw-service-nmn.local/apis/cfs/v3/components/: expected status code 200, got 404
    ERROR (run tag sosdD-cfs): GET https://api-gw-service-nmn.local/apis/cfs/v2/components/: expected status code 200, got 404
    ERROR (run tag sosdD-cfs): CLI command (cfs v3 components describe  --format json) failed with exit code 2
    ERROR (run tag sosdD-cfs): CLI command (cfs v2 components describe  --format json) failed with exit code 2
    ```

- For `cmsdev` versions less than 1.16.2, the CFS subtest failure will resemble the following:

    ```text
    ERROR (run tag fhn3C-cfs): First list item has empty value for "id" field
    ```

For details on how to correct this problem, see [CFS Component With Zero-Length ID](CFS_Component_With_Zero_Length_ID.md).

### VCS subtest command failure

If the VCS administrative password contains illegal characters, it can cause the VCS subtest to fail with an error
message that resembles the following:

```text
ERROR (run tag Xe9tC-vcs): Command failed
```

If the test is run in verbose mode, or the `cmsdev` log file is examined, a line similar to the following is found:

```text
fatal: unable to access 'https://crayvcs:BPuN/M846JL5XKTTWVqcV2mhuZfzOC64nnZ/e54ri1M=@api-gw-service-nmn.local/vcs/test-cmsdev-zvkEP50G/harf-zEK1SuiP.git/': URL using bad/illegal format or missing URL
```

See [VCS Password With Illegal Characters](VCS_Password_With_Illegal_Characters.md) for more information on this problem, including
remediation steps.
See [SMS test execution](#sms-test-execution) for more information on running the test in verbose mode and locating its log file.
