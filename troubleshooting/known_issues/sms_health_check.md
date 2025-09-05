# Software Management Services health checks

- [SMS test execution](#sms-test-execution)
- [Interpreting `cmsdev` Results](#interpreting-cmsdev-results)
- [Known issues with SMS tests](#known-issues-with-sms-tests)
  - [Cray CLI](#cray-cli)
  - [Etcd restores](#etcd-restores)
  - [BOS subtest hangs](#bos-subtest-hangs)
  - [Invalid CFS component](#invalid-cfs-component)
  - [VCS subtest command failure](#vcs-subtest-command-failure)

## SMS test execution

This test requires that the Cray CLI is configured on nodes where the test is executed.
See [Cray command line interface](../../operations/validate_csm_health.md#0-cray-command-line-interface).

The following test can be run on any Kubernetes node (any master or worker node, but **not** on the PIT node).

```bash
/usr/local/bin/cmsdev test -q all
```

- The `cmsdev` tool logs to `/opt/cray/tests/cmsdev.log`
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

Additional test execution details can be found in `/opt/cray/tests/cmsdev.log`.

## Version

(`ncn-mw#`) The following command displays the version of the `cmsdev` test tool.

```bash
/usr/local/bin/cmsdev version
```

## Known issues with SMS tests

- [Cray CLI](#cray-cli)
- [Etcd restores](#etcd-restores)
- [BOS subtest hangs](#bos-subtest-hangs)
- [Invalid CFS component](#invalid-cfs-component)
- [VCS subtest command failure](#vcs-subtest-command-failure)

### Cray CLI

Some of the subtests may fail if the Cray CLI is not configured on the management NCN where `cmsdev` is executed.
See the following for more information:

- [Cray command line interface](../../operations/validate_csm_health.md#0-cray-command-line-interface)
- [Configure the Cray CLI](../../operations/configure_cray_cli.md)

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
CFS subtest to fail. The CFS subtest failure will resemble the following:

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
