# Soft Deleted IMS Recipe Always Has `arch=x86_64`

## Issue description

When an IMS recipe is deleted and becomes a "deleted recipe", its `arch` attribute is set to `x86_64`,
regardless of its original value. This new value persists even if the recipe is later restored using
an `undelete` operation.

This bug is fixed in CSM 1.7.0. In earlier CSM versions, the only option is to use the provided [Workaround](#workaround).

For more information on deleting and restoring resources in IMS, see
[Delete or Recover Deleted IMS Content](../../operations/image_management/Delete_or_Recover_Deleted_IMS_Content.md).

## Workaround

(`ncn-mw#`) Work around the problem by manually updating the `arch` value after the deleted recipe has been restored..

> In the following command, replace `<RECIPE_ID>` with actual IMS recipe ID.

```bash
cray ims recipes update --arch <original value> <RECIPE_ID> --format json
```

Example output:

```json
{
    "arch": "x86_64",
    "created": "2025-04-18T17:07:03.236506",
    "id": "d2be2cc0-0294-4e4c-adc3-22796f61816e",
    "link": null,
    "linux_distribution": "sles15",
    "name": "recipe_wqbyjsvcon",
    "recipe_type": "kiwi-ng",
    "require_dkms": true,
    "template_dictionary": []
}
```
