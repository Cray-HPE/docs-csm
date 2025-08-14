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

(`ncn-mw#`) Work around the problem by manually updating the `metadata` attribute `key` and `value` after the image is created.

> In the following command, replace `<IMAGE_ID>` with actual IMS image ID.

```bash
cray ims images update <IMAGE_ID> --metadata-operation set --metadata-key <original metdata key> --metadata-value <original metadata value> --format json
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

> After updating the `metadata` with original `metadata key` and `metadata value`, Remove the `value` key from the image's `metadata`.
In the following command, replace `<IMAGE_ID>` with actual IMS image ID.

```bash
cray ims images update <IMAGE_ID> --metadata-operation remove --metadata-key value --format json
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

