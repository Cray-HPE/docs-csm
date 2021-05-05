# PLEASE DO NOT EXECUTE THIS PAGE OF INSTRUCTIONS AT THIS TIME.  IT IS EXPERIMENTAL AND MUST GO THROUGH INTERNAL TESTING.

# Upgrade Recovery and Troubleshooting

This document has recommendations for recovering from a failed upgrade.  The ability to recover from failures may be impacted by the stage in which the failure occurred.  There may be known issues and/or work-arounds that are already documented in other locations (which this document may reference).  Non-recoverable upgrade failures are more likely with irreversible data loss encountered in the Ceph/Storage upgrade steps.  Should this occur, the recommended recovery method will be to ensure that data exported in the 'Prereq' steps has been safely stored external to the shasta system, execute a Shasta 1.4 Fresh install, and follow steps documented below to "import" critical data back on top of the fresh install.  At that point, an upgrade attempt can be re-tried.

## Determine If Your Upgrade Failure if Recoverable

<Steps TBD to determine what consititues an Unrecoverable Upgrade failure.>

### Procedure for Restoring Nexus PVC

<Enter procedure here or link to script>


## Recovering from Unrecoverable Upgrade Failures

### Ensure Exported Data is Externally Saved
Ensure that the data that you collected to [export critical site data] (../prereqs/export-critical-data.md) has been safely stored in a location external to the system.


### Fresh Install Shasta 1.4 and Patches
Follow the steps in the [14 Fresh Install Documentation](../../../docs-csm-install) to fresh install your shasta system.

<Open Question:  In this process will we also require that all 14 patches are installed before upgrading - particularly if the data export was done from a particular version of shasta.  It may be advisable to ensure that the same version that data was exported from, be restored, in order to procedure with getting exported data configured on the fresh installed system.


### Copy or Mount Saved Data Back Onto System

Get exported data back onto the freshly installed 1.4 Shasta System. This may be done by restoring a mount or transferring files back onto the system.


### Get Saved Data Reconfigured On System

Use the following procedures to get critical data re-configured on the running 14 system.

TO DO:  Determine if the ordering if the below items matters and re-order accordingly!!!

#### Reconfigure Saved Hardware State Manager Group Info

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import Gitea-vcs Config Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import IMS Recipe & Image Data

IMS recipe and image data, including associated artifacts stored in Ceph S3, can be imported using one of
two procedures documented below.

NOTE: recipes and images imported using these procedures will have their IMS ID and S3 location of linked artifacts
      changed during the import process. Any BOS Session templates, or other references to recipes, images or their
      artifacts will need to be updated to use the new identifiers. 

### Automated Procedure
#### Prerequisites
* Ensure that the `cray` commandline cli is authenticated and configured to talk to Shasta services.

#### Procedure

1. If IMS data was previously exported using the `ims-import-export.py` script, the same script can be used to
   import IMS recipes and images that are missing after an upgrade. To do so, run the `ims-import-export.py` script 
   located [here](../../scripts/ims-import-export).
   
   ```bash
   # ims-import-export.py --import
   INFO:__main__:Importing recipes
   ...
   INFO:__main__:Importing images
   ...
   INFO:__main__:DONE!!
   ```

### Manual Procedure
#### Prerequisites
* Ensure that the `cray` commandline cli is authenticated and configured to talk to Shasta services.

#### Procedure

Using the recipe information previously noted, for each recipe that you wish to restore, perform the following steps:

Note: In the example below, we are creating a new IMS recipe record for the recipe previously known as IMS recipe 
      ID 1dd47f2f-aa37-4f17-9e9c-4e17a3675a92.

1. Create a new IMS recipe record. 
     
   ```bash
   # cray ims recipes create --name <name> --recipe-type <type> --linux-distribution <linux-distribution> --format json
   {
     "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4",
     "linux_distribution": "sles15",
     "link": null,
     "id": "e5b9a5f9-cd75-4cb2-870a-48c42c009d4b",
     "created": "2021-05-05T15:16:08.621668+00:00",
     "recipe_type": "kiwi-ng"
   }
   ```
   
1. Upload the IMS Recipe archive to Ceph S3

   ```bash
   # cray artifacts create ims recipes/e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/recipe.tar.gz recipes/1dd47f2f-aa37-4f17-9e9c-4e17a3675a92/recipe.tar.gz
   ```

1. Determine the S3 etag for the recipe archive
   
   ```bash
   # cray artifacts describe ims recipes/e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/recipe.tar.gz --format json
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
   
1. Update the IMS recipe record with the Ceph S3 location of the recipe archive

   ```bash
   # cray ims recipes update e5b9a5f9-cd75-4cb2-870a-48c42c009d4b \
     --link-type s3 --link-path s3://ims/recipes/e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/recipe.tar.gz \
     --link-etag dd95e38bf328dd31d83d661877df8fcf
   ```    
   
Using the image information previously noted, for each image that you wish to restore, perform the following steps:

Note: In the example below, we are creating a new IMS image record for the image previously known as IMS image 
      ID 0f1acea4-2bf1-4931-ac19-ce3c484af540.

1. Create a new IMS image record. 
     
   ```bash
   # cray ims images create --name <name> --format json
   {
     "name": "cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4",
     "link": null,
     "id": "e5b9a5f9-cd75-4cb2-870a-48c42c009d4b",
     "created": "2021-05-05T15:16:08.621668+00:00",
   }
   ```

1. Upload each associated image artifact to Ceph S3

   ```bash
   # cray artifacts create boot-images e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/rootfs images/0f1acea4-2bf1-4931-ac19-ce3c484af540/rootfs
   # cray artifacts create boot-images e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/kernel images/0f1acea4-2bf1-4931-ac19-ce3c484af540/kernel
   # cray artifacts create boot-images e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/initrd images/0f1acea4-2bf1-4931-ac19-ce3c484af540/initrd   
   ```
   
1. Determine the S3 etag for each associated image artifact
   
   ```bash
   # cray artifacts describe boot-images e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/rootfs --format json
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

   # cray artifacts describe boot-images e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/kernel --format json
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
   
   # cray artifacts describe boot-images e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/initrd --format json
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

1. Make a copy of the original IMS manifest.json and update with the new S3 link and etag values.
   
   ```bash
   # cp images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest.json images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest-new.json
   # vi images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest-new.json
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
1. Upload the IMS image manifest to Ceph S3

   ```bash
   # cray artifacts create boot-images e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/manifest.json images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest-new.json
   ```

1. Determine the S3 etag for the manifest.json
   
   ```bash
   # cray artifacts describe ims e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/manifest.json --format json
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
   
1. Update the IMS image record with the Ceph S3 location of the manifest.json

   ```bash
   # cray ims images update e5b9a5f9-cd75-4cb2-870a-48c42c009d4b \
     --link-type s3 --link-path s3://ims/e5b9a5f9-cd75-4cb2-870a-48c42c009d4b/manifest.json \
     --link-etag ab3ffecdd1299bbda6c373824c9d0870
   ```    

#### Import BOS Session Template Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import SLS Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import Vault Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import Keycloak Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >



[Back to Main Page](../../README.md)
