# CFS Component State Updates Allow Invalid Values

The [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
has issues in which updating the state of a
[CFS component](../../operations/configuration_management/Configuration_Management_of_System_Components.md)
can leave the component with invalid state data.

## Details

The issue is caused by multiple problems:

* CFS does not enforce any required fields for configuration status layers.
* CFS does very little validation of values in these fields.

The end result of all of this is that it is possible to patch components so that their
`state` fields contain configuration state layers that are missing fields and/or have
fields with invalid values.

The problems that will result from this vary based on the nature of the invalid data.

## Fix

This issue is fixed in CSM 1.7.1-patch.2; the issue exists in all earlier versions of CSM.

## Workaround

This issue is only seen by user patch operations -- no CSM services perform any CFS patch
operations that encounter this. Administrators can completely avoid this problem if they
never perform CFS component patches that have non-empty `state` lists. In the normal course
of operations, it is not required to perform such patches. If such a patch is required, then
administrators should take care that the `state` value in the patch is complete and valid.

## Remediation

Perform a CFS component patch to set the `state` field to a valid list.
A simple option is to set the `state` to an empty list.
