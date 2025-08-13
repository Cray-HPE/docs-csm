# Soft Deleted IMS Image Always Has `arch` Value Set To `x86_64`

## Issue description

When an IMS image is deleted and becomes a "deleted image", its `arch` attribute is set to `x86_64`,
regardless of its original value. This new value persists even if the image is later restored using
an `undelete` operation.

This bug is fixed in CSM 1.6.1. In earlier CSM versions, the only option is to use the provided [Workaround](#workaround).

For more information on deleting and restoring resources in IMS, see
[Delete or Recover Deleted IMS Content](../../operations/image_management/Delete_or_Recover_Deleted_IMS_Content.md).

## Workaround

(`ncn-mw#`) Work around the problem by manually updating the `arch` value after the deleted image has been restored.

> In the following command, replace `<IMAGE_ID>` with actual IMS image ID.

```bash
cray ims images update --arch <original value> <IMAGE_ID> --format json
```

Example output:

```json
{
    "arch": "aarch64",
    "created": "2024-07-18T19:47:09.498875",
    "id": "fdca156c-19b2-4453-983d-45f8ee96fbcb",
    "link": {
        "etag": "52b72aec88835e0663d7874c243cddbb",
        "path": "s3://boot-images/fdca156c-19b2-4453-983d-45f8ee96fbcb/manifest.json",
        "type": "s3"
    },
    "metadata": {},
    "name": "compute-csm-1.5-6.1.86-aarch64"
}
```
