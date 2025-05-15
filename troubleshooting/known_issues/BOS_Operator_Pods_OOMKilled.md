# BOS Operator Pods `OOMKilled`

* [Summary](#summary)
* [Details](#details)
* [Workaround](#workaround)
* [Fix](#fix)

## Summary

On large scale systems with thousands of nodes, if the [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos)
has debug logging enabled, then it is possible for some [BOS operator](../../operations/boot_orchestration/BOS_Services.md#bos-operators)
Kubernetes pods to be `OOMKilled` when trying to log particularly large API responses.

## Details

The BOS logging level is one of numerous [Options](../../operations/boot_orchestration/Options.md) that an administrator may customize.

## Workaround

(`ncn-mw#`) The only workaround in this case is to set the BOS logging level to `INFO` or higher.

```bash
cray bos v2 options update --logging-level INFO
```

## Fix

This problem is fixed in CSM 1.7, by changing how BOS performs its debug logging. The fix is not backported to earlier CSM versions.
Prior to CSM 1.7, the above [Workaround](#workaround) must be used if the issue is encountered.
