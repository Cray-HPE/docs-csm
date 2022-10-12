# IMS - Exporting and Importing for System Recovery or in the case of a fresh install

IMS recipe and image data, including associated artifacts stored in Ceph S3, can be exported and imported
either using an automated script, or manually one at a time.

## Exporting Images and Recipes

### Prerequisites

* Ensure that the `cray` command line interface (CLI) is authenticated and configured to talk to
system management services.

### Automated Exporting Procedure

1. (`ncn-mw`) Run the `ims-import-export.py` script located [here](../../scripts/operations/system_recovery). The `ims-import-export.py`
   script will create a directory named `ims-import-export-data` containing information about the recipes and images
   that are registered with IMS.

   ```bash
   ims-import-export.py --export --include-linked-artifacts
   ```

   Expected output:

   ```text
   INFO:__main__:Exporting recipes
   ...
   INFO:__main__:Exporting images
   ...
   INFO:__main__:DONE!!
   ```

### Manual Recipe Exporting Procedure

1. (`ncn-mw`) Identify the recipes that you wish to manually export.

   ```bash
   cray ims recipes list --format json | jq
   ```

   Expected output:

   ```text
     [
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
       },
       ...
     ]
   ```

   For each recipe that you wish to export, make note of the recipe details including:
   * Recipe ID
   * Recipe Type
   * Recipe Linux Distribution
   * Recipe Name
   * Recipe Link Path

1. (`ncn-mw`) For each recipe that you wish to export, use the `cray artifacts` CLI to download the recipe archive from Ceph S3.

   ```bash
   export RECIPE_ID=1dd47f2f-aa37-4f17-9e9c-4e17a3675a92
   mkdir -p recipes/$RECIPE_ID
   cray artifacts get ims recipes/$RECIPE_ID/recipe.tar.gz recipes/$RECIPE_ID/recipe.tar.gz
   ```

### Manual Image Exporting Procedure

1. (`ncn-mw`) Identify the images that you wish to manually export.

   ```bash
   cray ims images list --format json | jq
   ```

   Expected output:

   ```text
     [
       {
         "created": "2021-04-28T20:48:44.007816+00:00",
         "id": "0f1acea4-2bf1-4931-ac19-ce3c484af540",
         "link": {
           "etag": "393ac6e2c56c56cf96398d7a31b87445",
           "path": "s3://boot-images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest.json",
           "type": "s3"
         },
         "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4"
       },
       ...
     ]
   ```

   For each image that you wish to export, make note of the image details including:
   * Image ID
   * Image Name
   * Recipe Link Path

1. (`ncn-mw`) For each image that you wish to export, use the `cray artifacts` CLI to download the image manifest from Ceph S3.

   ```bash
   export IMAGE_ID=0f1acea4-2bf1-4931-ac19-ce3c484af540
   mkdir -p images/$IMAGE_ID
   cray artifacts get boot-images $IMAGE_ID/manifest.json images/$IMAGE_ID/manifest.json
   ```

   Review the image manifest and download any linked artifacts

   ```bash
   cat images/$IMAGE_ID/manifest.json | jq
   ```

   Expected output:

   ```text
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

   Export each of the images referenced in the manifest file:

   ```bash
   cray artifacts get boot-images $IMAGE_ID/rootfs images/$IMAGE_ID/rootfs
   cray artifacts get boot-images $IMAGE_ID/kernel images/$IMAGE_ID/kernel
   cray artifacts get boot-images $IMAGE_ID/initrd images/$IMAGE_ID/initrd
   ```

## Importing Images and Recipes

NOTE: recipes and images imported using these procedures will have their IMS ID and S3 location of linked artifacts
      changed during the import process. Any BOS Session templates, or other references to recipes, images or their
      artifacts will need to be updated to use the new identifiers.

### Importing Prerequisites

* Ensure that the `cray` command line interface (CLI) is authenticated and configured to talk to
system management services.

### Automated Importing Procedure

1. (`ncn-mw`) If IMS data was previously exported using the `ims-import-export.py` script, the same script can be used to
   import IMS recipes and images that are missing after an upgrade. To do so, run the `ims-import-export.py` script
   located [here](../../scripts/operations/system_recovery).

   ```bash
   ims-import-export.py --import
   ```

   Expected output:

   ```text
   INFO:__main__:Importing recipes
   ...
   INFO:__main__:Importing images
   ...
   INFO:__main__:DONE!!
   ```

### Manual Recipe Importing Procedure

Using the recipe information previously noted, for each recipe that you wish to restore, perform the following steps:

Note: In the example below, we are creating a new IMS recipe record for the recipe previously known as IMS recipe
      ID `1dd47f2f-aa37-4f17-9e9c-4e17a3675a92`.

1. (`ncn-mw`) Create a new IMS recipe record.

   ```bash
   cray ims recipes create --name <name> --recipe-type <type> --linux-distribution <linux-distribution> --format json
   ```

   Expected output:

   ```text
   {
     "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4",
     "linux_distribution": "sles15",
     "link": null,
     "id": "e5b9a5f9-cd75-4cb2-870a-48c42c009d4b",
     "created": "2021-05-05T15:16:08.621668+00:00",
     "recipe_type": "kiwi-ng"
   }
   ```

   Note the new and old recipe IDs:

   ```bash
   export NEW_RECIPE_ID=e5b9a5f9-cd75-4cb2-870a-48c42c009d4b
   export OLD_RECIPE_ID=1dd47f2f-aa37-4f17-9e9c-4e17a3675a92
   ```

1. (`ncn-mw`) Upload the IMS Recipe archive to Ceph S3

   ```bash
   cray artifacts create ims recipes/$NEW_RECIPE_ID/recipe.tar.gz recipes/$OLD_RECIPE_ID/recipe.tar.gz
   ```

1. (`ncn-mw`) Determine the S3 etag for the recipe archive

   ```bash
   cray artifacts describe ims recipes/$NEW_RECIPE_ID/recipe.tar.gz --format json
   ```

   Expected output:

   ```text
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

1. (`ncn-mw`) Update the IMS recipe record with the Ceph S3 location of the recipe archive

   ```bash
   cray ims recipes update $NEW_RECIPE_ID \
     --link-type s3 --link-path s3://ims/recipes/$NEW_RECIPE_ID/recipe.tar.gz \
     --link-etag dd95e38bf328dd31d83d661877df8fcf
   ```

### Manual Image Importing Procedure

Using the image information previously noted, for each image that you wish to restore, perform the following steps:

Note: In the example below, we are creating a new IMS image record for the image previously known as IMS image
      ID `0f1acea4-2bf1-4931-ac19-ce3c484af540`.

1. (`ncn-mw`) Create a new IMS image record.

   ```bash
   cray ims images create --name <name> --format json
   ```

   Expected output:

   ```text
   {
     "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4",
     "link": null,
     "id": "b5ac5d8a-0fac-470f-88a5-26c1276961e7",
     "created": "2021-05-05T15:16:08.621668+00:00",
   }
   ```

   Note the old and new image ID:

   ```bash
   export OLD_IMAGE_ID=0f1acea4-2bf1-4931-ac19-ce3c484af540
   export NEW_IMAGE_ID=b5ac5d8a-0fac-470f-88a5-26c1276961e7
   ```

1. (`ncn-mw`) Upload each associated image artifact to Ceph S3

   ```bash
   cray artifacts create boot-images $NEW_IMAGE_ID/rootfs images/$OLD_IMAGE_ID/rootfs
   cray artifacts create boot-images $NEW_IMAGE_ID/kernel images/$OLD_IMAGE_ID/kernel
   cray artifacts create boot-images $NEW_IMAGE_ID/initrd images/$OLD_IMAGE_ID/initrd
   ```

1. (`ncn-mw`) Determine the S3 etag for each associated image artifact

   ```bash
   cray artifacts describe boot-images $NEW_IMAGE_ID/rootfs --format json
   ```

   Expected output:

   ```text
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

   ```bash
   cray artifacts describe boot-images $NEW_IMAGE_ID/kernel --format json
   ```

   Expected output:

   ```text
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

   ```bash
   cray artifacts describe boot-images $NEW_IMAGE_ID/initrd --format json
   ```

   Expected output:

   ```text
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

1. (`ncn-mw`) Make a copy of the original IMS `manifest.json` and update with the new S3 link and etag values.

   ```bash
   cp images/$OLD_IMAGE_ID/manifest.json images/$OLD_IMAGE_ID/manifest-new.json
   vi images/$OLD_IMAGE_ID/manifest-new.json
   ```

   Expected file contents:

   ```text
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

1. (`ncn-mw`) Upload the IMS image manifest to Ceph S3

   ```bash
   cray artifacts create boot-images $NEW_IMAGE_ID/manifest.json images/$OLD_IMAGE_ID/manifest-new.json
   ```

1. (`ncn-mw`) Determine the S3 etag for the `manifest.json`

   ```bash
   cray artifacts describe ims $NEW_IMAGE_ID/manifest.json --format json
   ```

   Expected output:

   ```text
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

1. (`ncn-mw`) Update the IMS image record with the Ceph S3 location of the `manifest.json`

   ```bash
   cray ims images update $NEW_IMAGE_ID \
     --link-type s3 --link-path s3://ims/$NEW_IMAGE_ID/manifest.json \
     --link-etag ab3ffecdd1299bbda6c373824c9d0870
   ```
