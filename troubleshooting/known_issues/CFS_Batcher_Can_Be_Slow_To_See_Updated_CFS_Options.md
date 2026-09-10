# CFS Batcher Can Be Slow To See Updated CFS Options

The [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
has an issue in which the [CFS Batcher](../../operations/configuration_management/CFS_Batcher.md)
takes a long time to read updated [CFS Global Option](../../operations/configuration_management/CFS_Global_Options.md)
values.

Batcher only checks the CFS global option values in two cases:

* When it first starts up
* When it scans and processes batches

The [batcher check interval](../../operations/configuration_management/CFS_Global_Options.md#batcher-check-interval)
option controls how often the batcher scans and processes batches.

Because of this, if the check interval is set to a large value, then CFS batcher will not check
the CFS global option values very often.

## Fix

This issue is fixed in [CSM 1.7.1-patch.2](../../RELEASE_NOTES_1.7.1-patch.2.md); the issue exists in all earlier versions of CSM.

## Workaround

An administrator can force batcher to get updated CFS options values by
restarting the `cray-cfs-batcher` Kubernetes deployment in the `services` namespace.
This should not be done while batcher is scanning and processing batches.
