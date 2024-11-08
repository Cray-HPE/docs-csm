# Software Management Services health checks

- [SMS test execution](#sms-test-execution)
- [Interpreting `cmsdev` Results](#interpreting-cmsdev-results)
- [Known issues with SMS tests](#known-issues-with-sms-tests)
    - [Cray CLI](#cray-cli)
    - [Invalid CFS component](#invalid-cfs-component)

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
    - This was a change in CSM 1.4. In CSM releases prior to 1.4, the log file location was `/opt/cray/tests/cmsdev.log`
- The -q (quiet) and -v (verbose) flags can be used to decrease or increase the amount of information sent to the screen.
    - The same amount of data is written to the log file in either case.

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

Additional test execution details can be found in `/opt/cray/tests/install/logs/cmsdev/cmsdev.log`.

## Version

(`ncn-mw#`) The following command displays the version of the `cmsdev` test tool.

```bash
/usr/local/bin/cmsdev version
```

## Known issues with SMS tests

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
