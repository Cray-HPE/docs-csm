# CFS Component State Updates Allow Invalid Values

The [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
has issues in which updating the state of a
[CFS component](../../operations/configuration_management/CFS_Components.md)
can leave the component with invalid state data. This in turn can cause problems, such as
a complete failure of [CFS Batcher](../../operations/configuration_management/CFS_Batcher.md).

## Details

The issue is caused by a few problems:

* CFS does not enforce any required fields for configuration status layers.
* CFS does very little validation of values in these fields.
* There is a bug in how CFS converts a v2 configuration status layer into v3 format.

For some aspects of this issue, it is important to be aware that
[Component configuration state layers](../../operations/configuration_management/Differences_Between_the_V2_and_V3_CFS_APIs.md#component-configuration-state-layers)
changed between CFS v2 and v3. For this issue, the important change is that the layer `status` changes from
being embedded in the `commit` field (CFS v2) to having its own dedicated `status` field (CFS v3).
However, when a configuration state layer is converted from v2 format to v3 format, CFS ignores this;
it leaves the `commit` field unchanged, and the v3 layer is missing the `status` field. This conversion
takes place any time component `state` is patched using the CFS v2 endpoint (provided that the patch
includes a non-empty `state` list).

The end result of all of this is that it is possible to patch components so that their
`state` fields contain configuration state layers that are missing fields and/or have
fields with invalid values.

The problems that will result from this vary based on the nature of the invalid data.
If this issue causes a component to have configuration state layers that are missing the `status` field,
then this will break CFS batcher. The symptom in the `cfs-batcher` Kubernetes pod logs resembles the following:

```text
2026-02-24 17:35:54,843 - ERROR   - __main__ - Unexpected error occurred: 'status'
```

## Fix

None -- this issue exists in all versions of CSM.

## Workaround

This issue is only seen by user patch operations -- no CSM services perform any CFS patch
operations that encounter this. Administrators can completely avoid this problem if they
never perform CFS component patches that have non-empty `state` lists. In the normal course
of operations, it is not required to perform such patches. If such a patch is required, then
administrators should use the CFS v3 endpoint to do the patching, and should take care that
the `state` value in the patch is complete and valid.

## Remediation

Perform a CFS v3 component patch to set the `state` field to a valid list.
A simple option is to set the `state` to an empty list.
