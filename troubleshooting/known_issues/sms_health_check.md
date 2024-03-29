# Software Management Services health checks

- [SMS test execution](#sms-test-execution)
- [Interpreting `cmsdev` Results](#interpreting-cmsdev-results)
- [Known issues with SMS tests](#known-issues-with-sms-tests)
  - [Cray CLI](#cray-cli)
  - [CRUS CLI](#crus-cli)
  - [Etcd-restores](#etcd-restores)
  - [BOS subtest hangs](#bos-subtest-hangs)

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

## Known issues with SMS tests

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
