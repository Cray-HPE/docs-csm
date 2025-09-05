# Software Management Services health checks

- [SMS test execution](#sms-test-execution)
- [Interpreting `cmsdev` Results](#interpreting-cmsdev-results)
- [Known issues with SMS tests](#known-issues-with-sms-tests)
    - [Cray CLI](#cray-cli)
    - [CRUS CLI](#crus-cli)
    - [Etcd restores](#etcd-restores)
    - [BOS subtest hangs](#bos-subtest-hangs)
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

- The `cmsdev` tool logs to `/opt/cray/tests/install/logs/cmsdev/cmsdev.log`
    - This is a change in CSM 1.4. In prior CSM release, the log file location was `/opt/cray/tests/cmsdev.log`
- The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
    - The same amount of data is written to the log file in either case.

## Interpreting `cmsdev` results

- If all checks are passed, the following will be true:
    - The return code will be zero.
    - The final line of output will begin with `SUCCESS`.
        - For example: `SUCCESS: All 7 service tests passed: bos, cfs, conman, crus, ims, tftp, vcs`
- If one or more checks are failed, the following will be true:
    - The return code will be non-zero.
    - The final line of output will begin with `FAILURE` and lists the failed checks.
        - For example: `FAILURE: 2 service tests FAILED (conman, ims), 5 passed (bos, cfs, crus, tftp, vcs)`
    - After remediating a test failure for a particular service, just that single service test can be rerun by replacing
    `all` in the `cmsdev` command line with the name of the service. For example: `/usr/local/bin/cmsdev test -q cfs`

Additional test execution details can be found in `/opt/cray/tests/install/logs/cmsdev/cmsdev.log`.

## Version

(`ncn-mw#`) The following command displays the version of the `cmsdev` test tool.

```bash
/usr/local/bin/cmsdev version
```

## Known issues with SMS tests

- [Cray CLI](#cray-cli)
- [CRUS CLI](#crus-cli)
- [Etcd restores](#etcd-restores)
- [BOS subtest hangs](#bos-subtest-hangs)
- [Invalid CFS component](#invalid-cfs-component)
- [VCS subtest command failure](#vcs-subtest-command-failure)

### Cray CLI

Some of the subtests may fail if the Cray CLI is not configured on the management NCN where `cmsdev` is executed.
See the following for more information:

- [Cray command line interface](../../operations/validate_csm_health.md#0-cray-command-line-interface)
- [Configure the Cray CLI](../../operations/configure_cray_cli.md)

### CRUS CLI

In CSM 1.4.0, the CRUS subtest of `cmsdev` may fail with an error resembling the following:

```text
ERROR (run tag KPEqc-crus): CLI command failed (and does not look like a CLI config issue) (crus session list --format json)
```

This is because of a known issue in CSM 1.4.0 that is fixed in CSM 1.4.1. For more information, see
[CRUS Subcommands Missing From Cray CLI](CRUS_Subcommands_Missing_From_Cray_CLI.md).

### Etcd restores

If an Etcd restore has been performed on one of the SMS services (such as BOS or CRUS), then the first Etcd pod that
comes up after the restore will not have a PVC (Persistent Volume Claim) attached to it (until the pod is restarted).
The Etcd cluster is in a healthy state at this point, but the SMS health checks will detect the above condition and
may report test failures similar to the following:

```text
ERROR (run tag 1khv7-bos): persistentvolumeclaims "cray-bos-etcd-ncchqgnczg" not found
ERROR (run tag 1khv7-crus): persistentvolumeclaims "cray-crus-etcd-ffmszl7bvh" not found
```

In this case, these errors can be ignored, or the pod with the same name as the PVC mentioned in the output can be restarted
(as long as the other two Etcd pods are healthy).

### BOS subtest hangs

On systems where too many BOS v1 sessions exist, the `cmsdev` test will hang when trying to
list BOS v1 sessions. See [Hang Listing BOS V1 Sessions](Hang_Listing_BOS_V1_Sessions.md) for more
information.

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
    ERROR (run tag sosdD-cfs): GET https://api-gw-service-nmn.local/apis/cfs/v2/components/: expected status code 200, got 404
    ERROR (run tag sosdD-cfs): CLI command (cfs components v2 describe  --format json) failed with exit code 2
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

[`troubleshooting/known_issues/sms_health_check.md`](#invalid-cfs-component)
