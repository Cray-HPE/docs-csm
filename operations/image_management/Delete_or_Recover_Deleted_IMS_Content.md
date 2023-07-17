# Delete or Recover Deleted IMS Content

The Image Management System \(IMS\) manages user supplied SSH public Keys, customizable image recipes,
images, and IMS jobs that are used to build or customize images. In previous versions of IMS, deleting
an IMS public key, recipe, or image resulted in that item being permanently deleted. Additionally, IMS
recipes and images store linked artifacts in the Simple Storage Service \(S3\) datastore. These artifacts
are referenced by the IMS recipe and image records. The default option when deleting an IMS recipe and
image record was to also delete these linked S3 artifacts.

```bash
cray ims recipes list
```

Example output:

```toml
[...]

[[results]]
id = "76ef564d-47d5-415a-bcef-d6022a416c3c"
name = "cray-sles15-barebones"
created = "2020-02-05T19:24:22.621448+00:00"

[results.link]
path = "s3://ims/recipes/76ef564d-47d5-415a-bcef-d6022a416c3c/cray-sles15-barebones.tgz"
etag = "28f3d78c8cceca2083d7d3090d96bbb7"
type = "s3"

[...]
```

```bash
cray ims images list
```

Example output:

```toml
[...]

[[results]]
created = "2018-12-04T17:25:52.482514+00:00"
id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
name = "sles_15_image.squashfs"

[results.link]
type = "s3"
path = "/4e78488d-4d92-4675-9d83-97adfc17cb19/sles_15_image.squashfs"
etag = ""

[...]
```

Deleting an IMS image can create a situation where boot artifacts referenced by a Boot Orchestration Service \(BOS\)
session template no longer exist, making that template unable to boot. Previously, to recover from this situation,
an admin would have had to rebuild the boot image using IMS and/or reinstall the prebuilt image from the installer,
reapply any Cray and site customizations, and recreate a new BOS template for the IMS image.

New functionality has been added to IMS to enable administrators to soft delete, recover \(undelete\), or hard delete
public-keys, recipes, and images. The added functionality provides a way to recover IMS items that were mistakenly
deleted. There is no undelete operation for IMS Jobs.

Soft deleting an IMS record effectively removes the record being deleted from the default collection, and moves it
to a new deleted collection. Recovering a deleted IMS record \(undelete operation\) moves the IMS record from the
deleted collection back to the collection of available items. Hard deleting an IMS record permanently deletes it from
the deleted collection.

## Delete an IMS Artifact

Use the `cray` CLI utility to delete either soft delete or hard delete an IMS public-key, recipe, or image.

Soft deleting an IMS public key, recipe, or image removes the record\(s\) from the collection of available items.
Hard deleting permanently removes the item from the deleted collection. Additionally, any linked artifacts are also
permanently removed.

Deleting an IMS public-key, recipe, or image record performs the following actions:

1. The IMS record\(s\) being deleted are moved from the collection of available items to a new deleted collection.
Any newly created records within the deleted collection will have the same IMS ID value as it did before being moved there.
2. Any Simple Storage Service \(S3\) artifacts that are associated with the record or records being deleted are renamed
within their S3 buckets so as to make them unavailable under their original key name.

### Delete Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system.
* System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the following deployments:
  * `cray-ims`, the Image Management Service \(IMS\)
  * `cray-nexus`, the Nexus repository manager service
* `kubectl` is installed locally and configured to point at the SMS Kubernetes cluster.

### Delete Procedure

1. (`ncn-mw#`) Soft delete the desired IMS artifact.

    The following substeps assume that an image is being deleted. The same process can be followed if deleting a public-key or recipe.

    1. List the existing images in IMS.

        ```bash
        cray ims images list
        ```

        Example output:

        ```toml
        [...]

        [[results]]
        created = "2018-12-04T17:25:52.482514+00:00"
        id = "4e78488d-4d92-4675-9d83-97adfc17cb19" <<-- Note this ID
        name = "sles_15_image.squashfs"

        [results.link]
        type = "s3"
        path = "/4e78488d-4d92-4675-9d83-97adfc17cb19/sles_15_image.squashfs"
        etag = ""

        [...]
        ```

    1. Delete the image.

        ```bash
        cray ims images delete IMS_IMAGE_ID
        ```

    1. Verify the image was successfully deleted.

        ```bash
        cray ims images list
        ```

    1. View the recently deleted item in the deleted images list.

        ```bash
        cray ims deleted images list
        ```

        Example output:

        ```toml
        [...]

        [[results]]
        created = "2018-12-04T17:25:52.482514+00:00"  <<-- Date the record was originally created
        deleted = "2020-11-03T09:57:31.746521+00:00"  <<-- Date the record was deleted
        id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
        name = "sles_15_image.squashfs"

        [results.link]
        type = "s3"
        path = "/deleted/4e78488d-4d92-4675-9d83-97adfc17cb19/sles_15_image.squashfs" <<-- S3 path to linked artifact was renamed
        etag = ""

        [...]
        ```

        If the administrator desires the public-key, recipe, or image to be permanently deleted, proceed to the next step. If the
        deleted image might need to be recovered in the future, no more work is needed.

1. (`ncn-mw#`) Hard delete the desired IMS artifact.

    Do not proceed with this step if the IMS artifact might be needed in the future. The following substeps assume that an image
    is being deleted. The same process can be followed if deleting a public-key or recipe.

    1. List the deleted images.

        ```bash
        cray ims deleted images list
        ```

        Example output:

        ```toml
        [...]

        [[results]]
        created = "2018-12-04T17:25:52.482514+00:00"
        deleted = "2020-11-03T09:57:31.746521+00:00"
        id = "4e78488d-4d92-4675-9d83-97adfc17cb19" <<-- Note this ID
        name = "sles_15_image.squashfs"

        [results.link]
        type = "s3"
        path = "/deleted/4e78488d-4d92-4675-9d83-97adfc17cb19/sles_15_image.squashfs"
        etag = ""

        [...]
        ```

    1. Permanently delete the desired image from the deleted images list.

        ```bash
        cray ims deleted images delete IMS_IMAGE_ID
        ```

## Recover Deleted IMS Artifacts

Use the IMS undelete command to update the record\(s\) within the deleted collection for an IMS public-key, recipe, or image.

Recovering a deleted IMS public-key, recipe, or image record uses the following workflow:

1. The record\(s\) being undeleted are moved to from the deleted collection to the collection of available items. Any
restored records will have the same IMS ID value as it did before being undeleted.
2. Any Simple Storage Service \(S3\) artifacts that are associated with the record\(s\) being undeleted are renamed within
their S3 buckets so as to make them available under their original key name.

### Recover Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system.
* System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the following deployments:
  * `cray-ims`, the Image Management Service \(IMS\)
  * `cray-nexus`, the Nexus repository manager service
* `kubectl` is installed locally and configured to point at the SMS Kubernetes cluster.

### Recover Procedure

The steps in this procedure assume that a deleted image is being recovered. The same process can be followed if recovering a deleted public-key or recipe.

1. (`ncn-mw#`) List the deleted image.

    ```bash
    cray ims deleted images list
    ```

    Example output:

    ```toml
    [...]

    [[results]]
    created = "2018-12-04T17:25:52.482514+00:00"
    deleted = "2020-11-03T09:57:31.746521+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19" <<-- Note this ID
    name = "sles_15_image.squashfs"

    [results.link]
    type = "s3"
    path = "/deleted/4e78488d-4d92-4675-9d83-97adfc17cb19/sles_15_image.squashfs"
    etag = ""

    [...]
    ```

1. (`ncn-mw#`) Use the `undelete` operation to recover the image.

    ```bash
    cray ims deleted images update IMS_IMAGE_ID --operation undelete
    ```

1. (`ncn-mw#`) List the deleted images to verify the recovered image is no longer in the collection of deleted items.

    ```bash
    cray ims deleted images list
    ```

1. (`ncn-mw#`) List the IMS images to verify the image was recovered.

    ```bash
    cray ims images list
    ```

    Example output:

    ```toml
    [...]

    [[results]]
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"

    [results.link]
    type = "s3"
    path = "/4e78488d-4d92-4675-9d83-97adfc17cb19/sles_15_image.squashfs"  <<-- The restored artifact path
    etag = ""

    [...]
    ```
