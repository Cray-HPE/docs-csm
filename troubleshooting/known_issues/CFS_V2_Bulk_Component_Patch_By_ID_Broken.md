# CFS V2 Bulk Component Patch By ID Broken

A [CFS](../../glossary.md#configuration-framework-service-cfs) issue exists when trying to do a
[V2 bulk patch](../../api/cfs.md#patch_components_v2) of
[CFS Components](../../operations/configuration_management/CFS_Components.md).
This issue only happens when both of the following things are true:

* The patch body includes the `filters.ids` field
* At least one of the specified component IDs exists in CFS

If both things are true, then the patch operation will fail with an internal server error.

## Workaround

This issue can be avoided by using a [CFS V3 bulk patch](../../api/cfs.md#patch_components_v3).
It can also be avoided by omitting the `filters.ids` field.

## Fix

* This issue only exists in CSM 1.5.0.
* It does not exist prior to CSM 1.5.
* It is fixed in all CSM versions starting with CSM 1.5.1.
