# Soft deleted IMS Image always has `arch` value set to `x86_64`

## Issue description

When IMS image is deleted and becomes a `deleted image` its `arch` attribute is set to `x86_64`,
regardless of its original value. This new value persists even if the image is later restored using
`undelete` operation.

This bug is fixed in CSM 1.7.0. In earlier CSM versions, the only option is to use the provided [Workaround](#workaround).

For more information on deleting and restoring resources in IMS, see [Delete or Recover Deleted IMS Content](../../operations/image_management/Delete_or_Recover_Deleted_IMS_Content.md)


## Workaround

1. (`ncn-mw#`) The problem can be worked around by manually updating the `arch` value after the image deleted has been restored..

    > In the following command, replace `<IMAGE_ID>` with actual IMS image ID.

    ```bash
    cray ims images update --arch aarch64 <IMAGE_ID>
    ```

