# IMS - Exporting and Importing for System Recovery or in the case of a fresh install

IMS recipe and image data, including associated artifacts stored in Ceph S3, can be exported and imported
either using an automated script, or manually one at a time.

- [Prerequisites](#prerequisites)
- [Exporting images and recipes](#exporting-images-and-recipes)
  - [Automated export procedure](#automated-export-procedure)
  - [Manual recipe export procedure](#manual-recipe-export-procedure)
  - [Manual image export procedure](#manual-image-export-procedure)
- [Importing images and recipes](#importing-images-and-recipes)
  - [Automated import procedure](#automated-import-procedure)
  - [Manual recipe import procedure](#manual-recipe-import-procedure)
  - [Manual image import procedure](#manual-image-import-procedure)

## Prerequisites

- Ensure that the `cray` command line interface (CLI) is authenticated and configured to talk to system management services.
  - See [Configure the Cray CLI](../configure_cray_cli.md).
- In order to use the automated procedures, the latest CSM documentation RPM must be installed on the node where the procedure is being performed.
  - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Exporting Images and Recipes

### Automated export procedure

1. (`ncn-mw`) The `ims-import-export.py`script will create a subdirectory of the current directory named `ims-import-export-data`
   containing information about the recipes and images that are registered with IMS.

   ```bash
   /usr/share/doc/csm/scripts/operations/system_recovery/ims-import-export.py --export --include-linked-artifacts
   ```

   Expected output:

   ```text
   INFO:__main__:Exporting recipes
   ...
   INFO:__main__:Exporting images
   ...
   INFO:__main__:DONE!!
   ```

### Manual recipe export procedure

1. (`ncn-mw`) Identify the recipes to be manually exported.

   ```bash
   cray ims recipes list --format json | jq
   ```

   The expected output is a list of IMS recipe entries. An example of one such entry is:

   ```json
       {
         "created": "2021-03-29T15:22:50.039151+00:00",
         "id": "1dd47f2f-aa37-4f17-9e9c-4e17a3675a92",
         "link": {
           "etag": "dd95e38bf328dd31d83d661877df8fcf",
           "path": "s3://ims/recipes/1dd47f2f-aa37-4f17-9e9c-4e17a3675a92/recipe.tar.gz",
           "type": "s3"
         },
         "linux_distribution": "sles15",
         "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4",
         "recipe_type": "kiwi-ng"
       }
   ```

   For each recipe to be exported, make note of the recipe details including:

   - Recipe ID
   - Recipe Type
   - Recipe Linux Distribution
   - Recipe Name
   - Recipe Link Path

1. (`ncn-mw`) For each recipe to be export, use the `cray artifacts` CLI to download the recipe archive from Ceph S3.

   ```bash
   RECIPE_ID=1dd47f2f-aa37-4f17-9e9c-4e17a3675a92
   mkdir -pv "recipes/${RECIPE_ID}"
   cray artifacts get ims "recipes/${RECIPE_ID}/recipe.tar.gz" "recipes/${RECIPE_ID}/recipe.tar.gz"
   ```

### Manual image export procedure

1. (`ncn-mw`) Identify the images to be manually exported.

   ```bash
   cray ims images list --format json | jq
   ```

   The expected output is a list of IMS image entries. An example of one such entry is:

   ```json
       {
         "created": "2021-04-28T20:48:44.007816+00:00",
         "id": "0f1acea4-2bf1-4931-ac19-ce3c484af540",
         "link": {
           "etag": "393ac6e2c56c56cf96398d7a31b87445",
           "path": "s3://boot-images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest.json",
           "type": "s3"
         },
         "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4"
       }
   ```

   For each image to be exported, make note of the image details including:

   - Image ID
   - Image Name
   - Image Link Path

1. (`ncn-mw`) For each image to be exported, use the `cray artifacts` CLI to download the image artifacts from Ceph S3.

   1. Download the image manifest from Ceph S3.

      ```bash
      IMAGE_ID=0f1acea4-2bf1-4931-ac19-ce3c484af540
      mkdir -pv "images/${IMAGE_ID}"
      cray artifacts get boot-images "${IMAGE_ID}/manifest.json" "images/${IMAGE_ID}/manifest.json"
      ```

   1. Review the image manifest.

      ```bash
      cat "images/${IMAGE_ID}/manifest.json" | jq
      ```

      Example output:

      ```json
      {
        "version": "1.0",
        "created": "2021-04-01 21:24:23.161422",
        "artifacts": [
          {
            "md5": "6e784dc8519baffc2177b0b70f3f8f89",
            "type": "application/vnd.cray.image.rootfs.squashfs",
            "link": {
              "etag": "f99dcad6c55a52904a8fee283b0dad22-204",
              "path": "s3://boot-images/0f1acea4-2bf1-4931-ac19-ce3c484af540/rootfs",
              "type": "s3"
            }
          },
          {
            "md5": "175f0c1363c9e3a4840b08570a923bc5",
            "type": "application/vnd.cray.image.kernel",
            "link": {
              "etag": "175f0c1363c9e3a4840b08570a923bc5",
              "path": "s3://boot-images/0f1acea4-2bf1-4931-ac19-ce3c484af540/kernel",
              "type": "s3"
            }
          },
          { 
            "md5": "2e8fadafab28081d6018ecfd479206d8",
            "type": "application/vnd.cray.image.initrd",
            "link": {
              "etag": "cad6c356f72e3dc65b6a28610629cba5-5",
              "path": "s3://boot-images/0f1acea4-2bf1-4931-ac19-ce3c484af540/initrd",
              "type": "s3"
            }
          }
        ]
      }
      ```

   1. Download each of the artifacts referenced in the manifest file.

      ```bash
      cray artifacts get boot-images "${IMAGE_ID}/rootfs" "images/${IMAGE_ID}/rootfs"
      cray artifacts get boot-images "${IMAGE_ID}/kernel" "images/${IMAGE_ID}/kernel"
      cray artifacts get boot-images "${IMAGE_ID}/initrd" "images/${IMAGE_ID}/initrd"
      ```

## Importing images and recipes

NOTE: Recipes and images imported using these procedures will have their IMS ID and S3 location of linked artifacts
changed during the import process. Any BOS Session templates, or other references to recipes, images, or their
artifacts will need to be updated to use the new identifiers.

### Automated import procedure

1. (`ncn-mw`) If IMS data was previously exported using the `ims-import-export.py` script, then the same script can be used to
   import IMS recipes and images that are missing after an upgrade.

   ```bash
   /usr/share/doc/csm/scripts/operations/system_recovery/ims-import-export.py --import
   ```

   Expected output:

   ```text
   INFO:__main__:Importing recipes
   ...
   INFO:__main__:Importing images
   ...
   INFO:__main__:DONE!!
   ```

### Manual recipe import procedure

Using the recipe information previously noted, for each recipe to be restored, perform the following steps:

1. (`ncn-mw#`) Record the old IMS ID of the recipe to be restored.

   This ID is obtained from the exported data. For example:

   ```bash
   OLD_RECIPE_ID=1dd47f2f-aa37-4f17-9e9c-4e17a3675a92
   ```

1. (`ncn-mw`) Create a new IMS recipe record.

   > Be sure to modify the example command to specify the appropriate recipe type and Linux distribution for the recipe being imported.

   ```bash
   cray ims recipes create --name <name> --recipe-type <type> --linux-distribution <linux-distribution> --format json
   ```

   Example output:

   ```json
   {
     "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4",
     "linux_distribution": "sles15",
     "link": null,
     "id": "e5b9a5f9-cd75-4cb2-870a-48c42c009d4b",
     "created": "2021-05-05T15:16:08.621668+00:00",
     "recipe_type": "kiwi-ng"
   }
   ```

1. (`ncn-mw`) Note the new IMS ID.

   This ID is found in the output of the command in the previous step.

   ```bash
   NEW_RECIPE_ID=e5b9a5f9-cd75-4cb2-870a-48c42c009d4b   
   ```

1. (`ncn-mw`) Upload the IMS recipe archive to Ceph S3.

   ```bash
   cray artifacts create ims "recipes/${NEW_RECIPE_ID}/recipe.tar.gz" "recipes/${OLD_RECIPE_ID}/recipe.tar.gz"
   ```

1. (`ncn-mw`) View the new S3 recipe archive.

   ```bash
   cray artifacts describe ims "recipes/${NEW_RECIPE_ID}/recipe.tar.gz" --format json
   ```

   Example output:

   ```json
   {
     "artifact": {
       "AcceptRanges": "bytes",
       "LastModified": "2021-03-29T15:22:50+00:00",
       "ContentLength": 11799,
       "ETag": "\"dd95e38bf328dd31d83d661877df8fcf\"",
       "ContentType": "binary/octet-stream",
       "Metadata": {
         "md5sum": "dd95e38bf328dd31d83d661877df8fcf"
       }
     }
   }
   ```

1. (`ncn-mw#`) Record the S3 etag of the new recipe archive.

   This value is found in the output of the command in the previous step.

   ```bash
   RECIPE_ETAG=dd95e38bf328dd31d83d661877df8fcf
   ```

1. (`ncn-mw`) Update the IMS recipe record with the Ceph S3 location of the recipe archive

   ```bash
   cray ims recipes update "${NEW_RECIPE_ID}" --link-type s3 --link-etag "${RECIPE_ETAG}" \
     --link-path "s3://ims/recipes/${NEW_RECIPE_ID}/recipe.tar.gz"
   ```

### Manual image import procedure

Using the image information previously noted, for each image to be restored, perform the following steps:

1. (`ncn-mw#`) Record the old IMS ID of the image to be restored.

   This ID is obtained from the exported data. For example:

   ```bash
   ${OLD_IMAGE_ID}=0f1acea4-2bf1-4931-ac19-ce3c484af540
   ```

1. (`ncn-mw`) Create a new IMS image record.

   > Be sure to modify the example command to specify the desired name for the image.

   ```bash
   cray ims images create --name <name> --format json
   ```

   Example output:

   ```json
   {
     "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4",
     "link": null,
     "id": "b5ac5d8a-0fac-470f-88a5-26c1276961e7",
     "created": "2021-05-05T15:16:08.621668+00:00",
   }
   ```

1. (`ncn-mw`) Note the new IMS ID.

   This ID is found in the output of the command in the previous step.

   ```bash
   NEW_IMAGE_ID=b5ac5d8a-0fac-470f-88a5-26c1276961e7
   ```

1. (`ncn-mw`) Upload each associated image artifact to Ceph S3.

   ```bash
   cray artifacts create boot-images "${NEW_IMAGE_ID}/rootfs" "images/${OLD_IMAGE_ID}/rootfs"
   cray artifacts create boot-images "${NEW_IMAGE_ID}/kernel" "images/${OLD_IMAGE_ID}/kernel"
   cray artifacts create boot-images "${NEW_IMAGE_ID}/initrd" "images/${OLD_IMAGE_ID}/initrd"
   ```

1. (`ncn-mw`) Collect the S3 etags of the new S3 image artifacts.

   1. View the new `rootfs` artifact in S3.

      ```bash
      cray artifacts describe boot-images "${NEW_IMAGE_ID}/rootfs" --format json
      ```

      Example output:

      ```json
      {
        "artifact": {
          "AcceptRanges": "bytes",
          "LastModified": "2021-03-29T15:22:50+00:00",
          "ContentLength": 11799,
          "ETag": "\"17574f7ce0d7b5e2b35913669347afca\"",
          "ContentType": "binary/octet-stream",
          "Metadata": {
            "md5sum": "dd95e38bf328dd31d83d661877df8fcf"
          }
        }
      }
      ```

   1. Record the S3 etag of the new `rootfs` artifact.

      This value is found in the output of the command in the previous step.

      ```bash
      ROOTFS_ETAG=17574f7ce0d7b5e2b35913669347afca
      ```

   1. View the new kernel artifact in S3.

      ```bash
      cray artifacts describe boot-images "${NEW_IMAGE_ID}/kernel" --format json
      ```

      Example output:

      ```json
      {
        "artifact": {
          "AcceptRanges": "bytes",
          "LastModified": "2021-03-29T15:22:50+00:00",
          "ContentLength": 11799,
          "ETag": "\"d2572e79e99bdf408bb2f65cd4b209f3\"",
          "ContentType": "binary/octet-stream",
          "Metadata": {
            "md5sum": "dd95e38bf328dd31d83d661877df8fcf"
          }
        }
      }
      ```

   1. Record the S3 etag of the new kernel artifact.

      This value is found in the output of the command in the previous step.

      ```bash
      KERNEL_ETAG=d2572e79e99bdf408bb2f65cd4b209f3
      ```

   1. View the new `initrd` artifact in S3.

      ```bash
      cray artifacts describe boot-images "${NEW_IMAGE_ID}/initrd" --format json
      ```

      Example output:

      ```json
      {
        "artifact": {
          "AcceptRanges": "bytes",
          "LastModified": "2021-03-29T15:22:50+00:00",
          "ContentLength": 11799,
          "ETag": "\"87adf3df69224d1b5f1449d21999ab52\"",
          "ContentType": "binary/octet-stream",
          "Metadata": {
            "md5sum": "dd95e38bf328dd31d83d661877df8fcf"
          }
        }
      }
      ```

   1. Record the S3 etag of the new `initrd` artifact.

      This value is found in the output of the command in the previous step.

      ```bash
      INITRD_ETAG=87adf3df69224d1b5f1449d21999ab52
      ```

1. (`ncn-mw`) Make a copy of the original IMS `manifest.json` and update with the new S3 link and etag values.

   ```bash
   cp -v "images/${OLD_IMAGE_ID}/manifest.json" "images/${OLD_IMAGE_ID}/manifest-new.json"
   vi "images/${OLD_IMAGE_ID}/manifest-new.json"
   ```

   Example file contents after editing:

   ```json
   {
     "version": "1.0",
     "created": "2021-04-01 21:24:23.161422",
     "artifacts": [
       {
         "md5": "6e784dc8519baffc2177b0b70f3f8f89",
         "type": "application/vnd.cray.image.rootfs.squashfs",
         "link": {
           "etag": "17574f7ce0d7b5e2b35913669347afca-204",
           "path": "s3://boot-images/e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/rootfs",
           "type": "s3"
         }
       },
       {
         "md5": "175f0c1363c9e3a4840b08570a923bc5",
         "type": "application/vnd.cray.image.kernel",
         "link": {
           "etag": "d2572e79e99bdf408bb2f65cd4b209f3",
           "path": "s3://boot-images/e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/kernel",
           "type": "s3"
         }
       },
       { 
         "md5": "2e8fadafab28081d6018ecfd479206d8",
         "type": "application/vnd.cray.image.initrd",
         "link": {
           "etag": "87adf3df69224d1b5f1449d21999ab52",
           "path": "s3://boot-images/e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/initrd",
           "type": "s3"
         }
       }
     ]
   }
   ```

1. (`ncn-mw`) Upload the IMS image manifest to Ceph S3.

   ```bash
   cray artifacts create boot-images "${NEW_IMAGE_ID}/manifest.json" "images/${OLD_IMAGE_ID}/manifest-new.json"
   ```

1. (`ncn-mw`) View the manifest in S3.

   ```bash
   cray artifacts describe boot-images ${NEW_IMAGE_ID}/manifest.json --format json
   ```

   Example output:

   ```json
   {
     "artifact": {
       "AcceptRanges": "bytes",
       "LastModified": "2021-03-29T15:22:50+00:00",
       "ContentLength": 11799,
       "ETag": "\"ab3ffecdd1299bbda6c373824c9d0870\"",
       "ContentType": "binary/octet-stream",
       "Metadata": {
         "md5sum": "dd95e38bf328dd31d83d661877df8fcf"
       }
     }
   }
   ```

1. (`ncn-mw#`) Record the new S3 etag of the manifest in S3.

   This value is found in the output of the command in the previous step.

   ```bash
   MANIFEST_ETAG=ab3ffecdd1299bbda6c373824c9d0870
   ```

1. (`ncn-mw`) Update the IMS image record with the Ceph S3 location of the manifest.

   ```bash
   cray ims images update "${NEW_IMAGE_ID}" --link-etag "${MANIFEST_ETAG}" \
     --link-type s3 --link-path "s3://boot-images/${NEW_IMAGE_ID}/manifest.json"
   ```
