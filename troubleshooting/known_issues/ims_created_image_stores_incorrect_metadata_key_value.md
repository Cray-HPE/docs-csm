# IMS Created Image Stores Incorrect Metadata Key Value

## Issue description

When an IMS image is created using command `cray ims images create` with metadata.
The metadata in the image details does not match the expected key value format.

Expected metadata:

```json
"metadata": {
    <metdata key>: <metadata value>
  }
```

Actual metadata:

```json
"metadata": {
    "key": <metdata key>,
    "value": <metadata value>
  }
```

This bug is fixed in CSM 1.7.0. In earlier CSM versions, the only option is to use the provided [Workaround](#workaround).

## Workaround

Work around the problem by manually correcting the metadata after the image is created.
This procedure shows how to work around the problem after creating an IMS image
specifying a metadata key and value. In this procedure, these are referred to as the
"desired" metadata key and value.

> In the commands in this procedure, be sure to perform the following substitutions:
>
> * Replace `<IMAGE_ID>` with actual IMS image ID.
> * Replace `<desired_metadata_key>` with the actual desired metadata key.
> * Replace `<desired_metadata_value>` with the actual desired metadata value.
>
> The following values are used in the example output shown in this procedure:
>
> * The IMS image ID is `a01eca53-4e1d-466f-9d87-7676c846c6b2`
> * The desired metadata key is `csmqe-metadata-key`
> * The desired metadata value is `csmqe-metadata-value`

1. (`ncn-mw#`) Update the image to properly set the desired metadata key/value pair.

    ```bash
    cray ims images update <IMAGE_ID> \
        --metadata-key "<desired_metadata_key>" \
        --metadata-value "<desired_metadata_value>" \
        --metadata-operation set --format json
    ```

    Example output:

    ```json
    {
      "name": "csmqe-metadatacheck",
      "link": null,
      "arch": "x86_64",
      "metadata": {
        "csmqe-metadata-key": "csmqe-metadata-value",
        "value": "csmqe-metadata-value"
      },
      "id": "a01eca53-4e1d-466f-9d87-7676c846c6b2",
      "created": "2025-07-10T12:54:29.588107"
    }
    ```

1. (`ncn-mw#`) Remove the `value` entry from the image metadata.

    ```bash
    cray ims images update <IMAGE_ID> --format json \
        --metadata-operation remove --metadata-key value
    ```

    Example output:

    ```json
    {
      "name": "csmqe-metadatacheck",
      "link": null,
      "arch": "x86_64",
      "metadata": {
        "csmqe-metadata-key": "csmqe-metadata-value"
      },
      "id": "a01eca53-4e1d-466f-9d87-7676c846c6b2",
      "created": "2025-07-10T12:54:29.588107"
    }
    ```

