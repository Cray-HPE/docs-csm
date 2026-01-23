# BOS Operator Pods `OOMKilled`

* [Summary](#summary)
* [Details](#details)
* [Workaround](#workaround)
* [Fix](#fix)

## Summary

On large scale systems with thousands of nodes, if the [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos)
has debug logging enabled, then it is possible for some [BOS operator](../../operations/boot_orchestration/Operators.md)
Kubernetes pods to be `OOMKilled` when trying to log particularly large API responses.

On large enough systems, it is possible for this to happen even without debug logging enabled.

## Details

The BOS logging level is one of numerous [Options](../../operations/boot_orchestration/Options.md) that an administrator may customize.

## Workaround

(`ncn-mw#`) Use the following procedure to work around the problem.

Check if debug logging is enabled.

```bash
cray bos v2 options list --format json
```

* If debug logging is enabled, then the easiest workaround is to set the BOS logging level to `INFO` or higher.

    ```bash
    cray bos v2 options update --logging-level INFO
    ```

* If debug logging is not enabled, or if the problem persists after disabling it, then the only other option is to increase the
  memory limits for the pods experiencing this problem. See [Increase Pod Resource Limits](../../operations/kubernetes/Increase_Pod_Resource_Limits.md).

## Fix

This problem is fixed in CSM 1.7, by changing how BOS performs its debug logging. The fix is not backported to earlier CSM versions.
Prior to CSM 1.7, the above [Workaround](#workaround) must be used if the issue is encountered.
