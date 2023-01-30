# Software Management Services health checks

1. [SMS test execution](#31-sms-test-execution)
1. [Interpreting `cmsdev` Results](#32-interpreting-cmsdev-results)
1. [Known issues with SMS tests](#33-known-issues-with-sms-tests)

## 3.1 SMS test execution

The test in this section requires that the [Cray CLI is configured](../../operations/configure_cray_cli.md#configure-the-cray-command-line-interface-cray-cli) on nodes where the test is executed.

The following test can be run on any Kubernetes node (any master or worker node, but **not** on the PIT node).

```bash
/usr/local/bin/cmsdev test -q all
```

- The `cmsdev` tool logs to `/opt/cray/tests/cmsdev.log`
- The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
  - The same amount of data is written to the log file in either case.

## 3.2 Interpreting `cmsdev` results

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

Additional test execution details can be found in `/opt/cray/tests/cmsdev.log`.

## 3.3 Known issues with SMS tests

If an Etcd restore has been performed on one of the SMS services (such as BOS), then the first Etcd pod that
comes up after the restore will not have a PVC (Persistent Volume Claim) attached to it (until the pod is restarted).
The Etcd cluster is in a healthy state at this point, but the SMS health checks will detect the above condition and
may report test failures similar to the following:

```text
ERROR (run tag 1khv7-bos): persistentvolumeclaims "cray-bos-etcd-ncchqgnczg" not found
```

In this case, these errors can be ignored, or the pod with the same name as the PVC mentioned in the output can be restarted
(as long as the other two Etcd pods are healthy).
