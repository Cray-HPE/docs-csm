# Known Issue: IMS Image Delete Loses `arch`

When an image is deleted in IMS the `deleted image` record will get its `arch` value set to `x86_64` no
matter what the original value was. This will cause an error if the image is subsequently undeleted and
used.

1. (`ncn-mw#`) Set an environment variable for the ID of the image:

  ```bash
  IMS_IMAGE_ID=YOUR_IMAGE_ID
  ```

1. (`ncn-mw#`) View the original image description:

  ```bash
  cray ims images describe $IMS_IMAGE_ID
  ```

  Expected output:

  ```text
  {
    "arch": "aarch64",
    "created": "2024-10-18T17:15:08.436814",
    "id": "e4523677-1ad8-4b2f-a352-69df23d3607d",
    "link": {
      "etag": "79232e07d78091f6dd1a13397158d53b",
      "path": "s3://boot-images/e4523677-1ad8-4b2f-a352-69df23d3607d/manifest.json",
      "type": "s3"
    },
    "metadata": {},
    "name": "compute-csm-1.5-6.1.86-aarch64"
  }
  ```

1. (`ncn-mw#`) Delete the image:

  ```bash
  cray ims images delete $IMS_IMAGE_ID
  ```

1. (`ncn-mw#`) Describe the deleted image record:

  ```bash
  cray ims deleted images describe $IMS_IMAGE_ID
  ```

  Expected output (note the `arch` value is now `x86_64`):

  ```text
  {
    "arch": "x86_64",
    "created": "2024-10-18T17:15:08.436814",
    "deleted": "2024-10-18T17:26:05.796157",
    "id": "e4523677-1ad8-4b2f-a352-69df23d3607d",
    "link": {
      "etag": "",
      "path": "s3://boot-images/deleted/e4523677-1ad8-4b2f-a352-69df23d3607d/deleted_manifest.json",
      "type": "s3"
    },
    "metadata": {},
    "name": "compute-csm-1.5-6.1.86-aarch64"
  }
  ```

## Fix

This is only an issue if the image is `undeleted`. To resolve this issue, `undelete` the image, then manually
correct the `arch` value.

1. (`ncn-mw#`) Undelete the image:

  ```bash
  cray ims deleted images update --operation undelete $IMS_IMAGE_ID
  ```

1. (`ncn-mw#`) Describe the image again:

  ```bash
  cray ims images describe $IMS_IMAGE_ID
  ```

  Expected output:

  ```text
  {
    "arch": "x86_64",
    "created": "2024-10-18T17:15:08.436814",
    "id": "e4523677-1ad8-4b2f-a352-69df23d3607d",
    "link": {
      "etag": "79232e07d78091f6dd1a13397158d53b",
      "path": "s3://boot-images/e4523677-1ad8-4b2f-a352-69df23d3607d/manifest.json",
      "type": "s3"
    },
    "metadata": {},
    "name": "compute-csm-1.5-6.1.86-aarch64"
  }
  ```

1. (`ncn-mw#`) Correct the value of `arch`:

  ```bash
  cray ims images update --arch aarch64 $IMS_IMAGE_ID
  ```

  Expected output:

  ```text
  {
    "arch": "aarch64",
    "created": "2024-10-18T17:15:08.436814",
    "id": "e4523677-1ad8-4b2f-a352-69df23d3607d",
    "link": {
      "etag": "79232e07d78091f6dd1a13397158d53b",
      "path": "s3://boot-images/e4523677-1ad8-4b2f-a352-69df23d3607d/manifest.json",
      "type": "s3"
    },
    "metadata": {},
    "name": "compute-csm-1.5-6.1.86-aarch64"
  }
  ```

Now the image may be used.
