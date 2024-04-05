# CFS V2 Failures On Large Systems

This page describes a known issue in CSM 1.5. Most of it will be fixed in CSM 1.5.1,
and all of it will be fixed in CSM 1.6.0.

> Some commands on this page require the Cray CLI to be configured.
> See [Configure the Cray CLI](../../operations/configure_cray_cli.md).

* [Overview](#overview)
* [Impacted systems](#impacted-systems)
* [Symptoms](#symptoms)
    * [`cmsdev` CFS test failures](#cmsdev-cfs-test-failures)
    * [BOS v2 sessions not progressing](#bos-v2-sessions-not-progressing)
    * [SAT status CFS error](#sat-status-cfs-error)
* [Workaround](#workaround)
* [Fix](#fix)

## Overview

CSM 1.5 introduces [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
v3, featuring paging of API responses. This limits the size of responses from some CFS endpoints to a
user-configurable value (`1000` by default). When using CFS v3 endpoints, if a response exceeds this number of
items, then it will include information that can be used to perform subsequent API queries, to get additional
pages of response data. When using CFS v2 endpoints, however, paging is not supported; if a response
from a v2 endpoint exceeds the configured default page size, then it will respond with an error.

In CSM 1.5, some CSM services can encounter situations where their calls to CFS fail because
of this. The known examples of this are:

* `cmsdev` CFS test
* [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v2 sessions
* [System Admin Toolkit (SAT)](../../glossary.md#system-admin-toolkit-sat) status

For more information on the CFS paging feature, see
[Paging CFS Records](../../operations/configuration_management/Paging_CFS_Records.md).

## Impacted systems

This will only happen on systems where the total number of components in CFS is larger than
the CFS default page size.

1. (`ncn-mw#`) Display the current CFS default page size:

    ```bash
    cray cfs v3 options list --format json | jq -r '.default_page_size'
    ```

    Example output:

    ```text
    1000
    ```

1. (`ncn-mw#`) Display the total number of components in CFS:

    ```bash
    cray cfs v3 components list --limit 10000000 --format json | jq '.components | length'
    ```

    Example output:

    ```text
    570
    ```

If the CFS default page size is greater than or equal to the number of components in CFS, then the
system should not be impacted by this issue.

## Symptoms

### `cmsdev` CFS test failures

The `cmsdev` CFS test includes a calls to CFS v2 that are impacted by this issue. This is indicated
by lines like the following in the test output:

```text
ERROR (run tag qdthp-cfs): GET https://api-gw-service-nmn.local/apis/cfs/v2/components: expected status code 200, got 400
ERROR (run tag qdthp-cfs): CLI command (cfs components list --format json) failed with exit code 2
```

### BOS v2 sessions not progressing

The BOS v2 status operator is responsible for progressing BOS v2 sessions, and it includes a call to
CFS that is impacted by this issue. As a consequence, BOS v2 sessions will not carry out their work.
Note that this will happen regardless of the number of nodes involved in the BOS v2 session -- the
problem only depends on the total number of components in CFS.

(`ncn-mw#`) This problem can be confirmed by looking at the BOS status operator logs while a BOS v2
session is running.

```bash
kubectl logs -n services -l app.kubernetes.io/name=cray-bos-operator-status
```

Lines resembling the following confirm that this problem is happening:

```text
2024-03-28 17:54:20,658 - ERROR   - bos.operators.base - Unhandled exception detected: 400 Client Error: Bad Request for url: http://cray-cfs-api/v2/components
Traceback (most recent call last):
  File "/usr/lib/python3.11/site-packages/bos/operators/base.py", line 99, in run
    self._run()
  File "/usr/lib/python3.11/site-packages/bos/operators/status.py", line 74, in _run
    cfs_states = self._get_cfs_components()
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/site-packages/bos/operators/status.py", line 100, in _get_cfs_components
    cfs_data = get_cfs_components()
               ^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/site-packages/bos/operators/utils/clients/cfs.py", line 45, in get_components
    response.raise_for_status()
  File "/usr/lib/python3.11/site-packages/requests/models.py", line 1021, in raise_for_status
    raise HTTPError(http_error_msg, response=self)
requests.exceptions.HTTPError: 400 Client Error: Bad Request for url: http://cray-cfs-api/v2/components
```

For more information on the BOS v2 operators (including the status operator), see
[BOS operators](../../operations/boot_orchestration/BOS_Services.md#bos-operators).

### SAT status CFS error

(`ncn-mw#`) To populate its CFS fields, SAT status makes a call which is impacted by this issue.

```bash
sat status --cfs-fields
```

If the beginning of the output includes an error resembling the following, then the system is impacted by this issue:

```text
WARNING: Could not retrieve status information from CFS; Failed to query CFS for component information: GET request to URL 'https://api-gw-service-nmn.local/apis/cfs/v2/components' failed with status code 400: Bad Request. The response size is too large Detail: The response size exceeds the default_page_size.  Use the v3 API to page through the results.
```

For more information on SAT, see [SAT in CSM](../../operations/sat/sat_in_csm.md).

## Workaround

This problem can be avoided by adjusting the CFS default page size to a larger value.

1. (`ncn-mw#`) Figure out how many CFS components exist on the system.

    ```bash
    NUM_CFS_COMPONENTS=$(cray cfs v3 components list --limit 10000000 --format json | jq '.components | length')
    echo $NUM_CFS_COMPONENTS
    ```

    Example output:

    ```text
    2600
    ```

1. (`ncn-mw#`) Optionally, increase this number, in case more hardware is added to the system.

    ```bash
    let NUM_CFS_COMPONENTS+=200
    echo $NUM_CFS_COMPONENTS
    ```

    Example output:

    ```text
    2800
    ```

1. (`ncn-mw#`) Set the CFS v3 default page size to this value.

    ```bash
    cray cfs v3 options update --default-page-size "${NUM_CFS_COMPONENTS}" --format json | jq -r '.default_page_size'
    ```

    The output should match the new desired value.

    ```text
    2800
    ```

Note that for large enough numbers of components, the `cray-cfs-api` Kubernetes pods (in the `services` namespace)
may encounter crashes because of memory use. In that case, the memory limits of the CFS pods can be increased to avoid that.
For information on how to do that, see [Increase Pod Resource Limits](../../operations/kubernetes/Increase_Pod_Resource_Limits.md).

## Fix

This problem will be fixed in BOS and `cmsdev` in CSM 1.5.1.
This problem will be fixed in SAT in CSM 1.6.0.
