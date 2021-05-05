# PLEASE DO NOT EXECUTE THIS PAGE OF INSTRUCTIONS AT THIS TIME.  IT IS EXPERIMENTAL AND MUST GO THROUGH INTERNAL TESTING.

# Determine Data Export Location (External to Shasta System)

Configure a mount point or select a location external to the Shasta system where critical data can be exported.  

For example, on ncn-m001, create a local directory for the mount point and run `mount -t nfs <external-host>:/<mount_point> /local/directory`.  Other mechanisms can be used to ensure that the data collected is stored external to the system in the event that it is needed in a later stage. 

# Collect Data

Follow the instructions, below, to collect data for the specified components.  If unexpected errors are encountered during the upgrade procedure, the exported data can aid in system recovery or re-configuration if a reinstall becomes necessary.

## General System Information

The following will collect general credential, switch, firmware, and node status information:

Either execute a script here

   ```bash
   ncn-m001# /usr/share/doc/metal/upgrade/1.0/resource_material/prereqs/data_export/<script_name.sh>
   ```

or

See Steps 1- 19 in the `Collect Data From Healthy Shasta System for EX Installation` section of the `HPE Cray EX System Installation and Configuration Guide`.


## Export Nexus PVC Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Hardware State Manager Group Info

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Critical Gitea-vcs Config Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export IMS Recipe & Image Data

IMS recipe and image data, including associated artifacts stored in Ceph S3, can be exported using one of
two procedures documented below.

### Automated Procedure
#### Prerequisites
* Ensure that the `cray` commandline cli is authenticated and configured to talk to Shasta services.

#### Procedure

1. Run the `ims-import-export.py` script located [here](../../scripts/ims-import-export). The `ims-import-export.py`
   script will create a directory named `ims-import-export-data` containing information about the recipes and images
   that are registered with IMS. 

   ```bash
   # ims-import-export.py --export --include-linked-artifacts
   INFO:__main__:Exporting recipes
   ...
   INFO:__main__:Exporting images
   ...
   INFO:__main__:DONE!!
   ```

### Manual Procedure
#### Prerequisites
* Ensure that the `cray` commandline cli is authenticated and configured to talk to Shasta services.

#### Procedure

1. Identify the recipes that you wish to manually export. 
   
   ```bash
   # cray ims recipes list --format json | jq
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
    
1. For each recipe that you wish to export, use the `cray artifacts` cli to download the recipe archive from Ceph S3.

   ```bash
   # mkdir -p recipes/1dd47f2f-aa37-4f17-9e9c-4e17a3675a92
   # cray artifacts get ims recipes/1dd47f2f-aa37-4f17-9e9c-4e17a3675a92/recipe.tar.gz recipes/1dd47f2f-aa37-4f17-9e9c-4e17a3675a92/recipe.tar.gz 
   ```
   
1. Identify the images that you wish to manually export. 
   
   ```bash
   # cray ims images list --format json | jq
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
    
1. For each image that you wish to export, use the `cray artifacts` cli to download the image manifest from Ceph S3.

   ```bash
   # mkdir -p images/0f1acea4-2bf1-4931-ac19-ce3c484af540
   # cray artifacts get boot-images 0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest.json images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest.json 
   ```
   
   Review the image manifest and download any linked artifacts

   ```bash
   # cat images/0f1acea4-2bf1-4931-ac19-ce3c484af540/manifest.json | jq
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
   
   # cray artifacts get boot-images 0f1acea4-2bf1-4931-ac19-ce3c484af540/rootfs images/0f1acea4-2bf1-4931-ac19-ce3c484af540/rootfs
   # cray artifacts get boot-images 0f1acea4-2bf1-4931-ac19-ce3c484af540/kernel images/0f1acea4-2bf1-4931-ac19-ce3c484af540/kernel
   # cray artifacts get boot-images 0f1acea4-2bf1-4931-ac19-ce3c484af540/initrd images/0f1acea4-2bf1-4931-ac19-ce3c484af540/initrd
   ```

## Export BOS Session Template Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export SLS Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Vault Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Keyloak Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >




[Back to Main Page](../../README.md)
