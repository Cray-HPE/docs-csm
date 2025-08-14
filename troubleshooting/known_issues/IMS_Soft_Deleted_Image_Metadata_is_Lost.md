# Soft Deleted IMS Image Metadata is Lost

## Issue description

When IMS image is deleted and becomes a "deleted image" its, `metadata` attribute is set to `{}`,
regardless of its original value. This new value persists even if the image is later restored using
`undelete` operation.

This bug is fixed in CSM 1.7.0. In earlier CSM versions, the only option is to use the provided [Workaround](#workaround).

* For more information on deleting and restoring resources in IMS, see
  [Delete or Recover Deleted IMS Content](../../operations/image_management/Delete_or_Recover_Deleted_IMS_Content.md).
* For more information on managing IMS image metadata, see
  [Manage image labels](../../operations/image_management/Image_Management_Workflows.md#manage-image-labels).

## Workaround

Work around the problem by manually updating the metadata after the deleted image has been restored.

See [Set image metadata](../../operations/image_management/Image_Management_Workflows.md#2-set-image-metadata).
