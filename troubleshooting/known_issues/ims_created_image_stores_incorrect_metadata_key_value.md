# IMS Created Image Stores Incorrect Metadata

* [Issue description](#issue-description)
* [Workaround](#workaround)
    * [Image has not yet been created](#image-has-not-yet-been-created)
    * [Image was created without metadata](#image-was-created-without-metadata)
    * [Image was created with metadata](#image-was-created-with-metadata)

## Issue description

When an IMS image is created, if a metadata key and value (also known as an image label) are specified,
then the created image does not have the expected metadata.

This is the expected format after creating an image with a metadata key and value specified:

```json
"metadata": {
    "<metadata_key>": "<metadata_value>"
  }
```

Because of the issue described on this page, the actual format is:

```json
"metadata": {
    "key": "<metadata_key>",
    "value": "<metadata_value>"
  }
```

This bug is fixed in CSM 1.7.0. In earlier CSM versions, the only option is to use the provided [Workaround](#workaround).

For more information on managing IMS image metadata, see
[Manage image labels](../../operations/image_management/Image_Management_Workflows.md#manage-image-labels).

## Workaround

When desiring an IMS image to have a particular metadata key and value set,
there are three different scenarios an administrator may be in:

* [Image has not yet been created](#image-has-not-yet-been-created)
* [Image was created without metadata](#image-was-created-without-metadata)
* [Image was created with metadata](#image-was-created-with-metadata)

### Image has not yet been created

In this case, the issue can be avoided by not specifying the metadata when creating
the image, and instead setting it after the image has already been created.

1. Create the IMS image without specifying metadata.

1. Update the IMS image to set the desired metadata.

    See [Set image metadata](../../operations/image_management/Image_Management_Workflows.md#2-set-image-metadata).

### Image was created without metadata

In this case, the issue documented on this page does not apply, and no
workaround is necessary. Simply update the IMS image to set the desired
metadata.

See [Set image metadata](../../operations/image_management/Image_Management_Workflows.md#2-set-image-metadata).

### Image was created with metadata

In this case, work around the problem by removing the invalid metadata, and then
setting the correct metadata.

1. Remove the incorrect metadata from the image.

    Specifically, remove the metadata keys named `key` and `value`.
    This will require two separate image update calls.
    See [Remove image metadata](../../operations/image_management/Image_Management_Workflows.md#4-remove-image-metadata).

1. Update the IMS image to set the desired metadata.

    See [Set image metadata](../../operations/image_management/Image_Management_Workflows.md#2-set-image-metadata).
