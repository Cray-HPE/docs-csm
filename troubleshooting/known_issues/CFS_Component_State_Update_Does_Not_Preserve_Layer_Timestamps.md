# CFS Component State Update Does Not Preserve Layer Timestamps

The [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
has issues in which updating the state of a
[CFS component](../../operations/configuration_management/Configuration_Management_of_System_Components.md)
updates the timestamps for layers that were not changed.

## Details

For this issue, it is important to understand that when patching component `state` in CFS,
the patch data is not allowed to specify the last updated timestamps for the `state` layers -- it
is a read-only field that CFS is responsible for maintaining.

When patching component `state` in CFS, there is no direct way to tell it to remove a layer.
Instead, one must perform a patch that includes all of the other layers, omitting the one
that is to be removed. This results in the layer being removed, but it also does not
preserve the last updated timestamps for all of the remaining layers, even though they were not
changed.

Component patching provides the `state_append` option mechanism for adding state layers
that does not run afoul of this. However, if one desired to insert a new state layer at any place
other than the end of the list, then this issue would still apply.

Even a patch operation with a `state` list that exactly matched the current `state` list would
encounter this issue, resulting in every timestamp being updated.

## Fix

None -- this issue exists in all versions of CSM.

## Workaround

Administrators can completely avoid this problem if they never perform CFS component patches
that have non-empty `state` lists. In the normal course of operations, it is not required to
perform such patches.

If such a patch is required, then this issue is unavoidable.
