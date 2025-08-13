# Soft Deleted IMS Recipe Always Has `require_dkms=true`

## Issue description

When an IMS recipe is deleted and becomes a "deleted recipe", its `require_dkms` attribute is set to `true`,
regardless of its original value. This new value persists even if the recipe is later restored using an `undelete`
operation.

This bug is fixed in CSM 1.7.0. In earlier CSM versions, the only option is to use the provided [Workaround](#workaround).

For more information on deleting and restoring resources in IMS, see
[Delete or Recover Deleted IMS Content](../../operations/image_management/Delete_or_Recover_Deleted_IMS_Content.md).

## Workaround

(`ncn-mw#`) The problem can be worked around by manually updating the `require_dkms` value after the deleted recipe
has been restored.

> In the following command, replace `<RECIPE_ID>` with actual IMS recipe ID.

```bash
cray ims recipes update --require-dkms <original value> <RECIPE_ID> --format json
```

Example output:

```json
{
    "arch": "aarch64",
    "created": "2024-07-18T19:47:03.600611",
    "id": "b89827ea-d929-461f-95b6-14cba7983311",
    "link": {
    "etag": "e07f7f535d886fb9a61130a753a2467b",
    "path": "s3://ims/recipes/b89827ea-d929-461f-95b6-14cba7983311/recipe.tar.gz",
    "type": "s3"
    },
    "linux_distribution": "sles15",
    "name": "cray-shasta-csm-sles15sp5-barebones-csm-1.5-aarch64",
    "recipe_type": "kiwi-ng",
    "require_dkms": false,
    "template_dictionary": []
}
```