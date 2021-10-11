# NCN Image Customization

## From the Live CD

The LiveCD is equipped for "re-squashing" an SquashFS images.

* [Boot Customization](#boot-customization)
    * [Set the Default Password](#set-the-default-password)
* [Image Layer Pipeline](#image-layer-pipeline)
* [Image Customization after System Bring Up](#customization-after-system-up)


<a name="boot-customization"></a>
### Boot Customization


<a name="set-the-default-password"></a>
#### Set the Default Password

Customize the NCN images by changing the root password or adding different SSH keys for the root account.

This process should be done for the "Kubernetes" image used by master and worker nodes and then repeated for the Ceph image used by the utility storage nodes.


1. Open the image.

   The Kubernetes image will be of the form "kubernetes-0.0.53.squashfs" in /var/www/ephemeral/data/k8s.
   ```bash
   pit# cd /var/www/ephemeral/data/k8s
   pit# unsquashfs kubernetes-0.0.53.squashfs
   ```
   The Ceph image will be of the form "ceph-0.0.44.squashfs" in /var/www/ephemeral/data/ceph.
   ```bash
   pit# cd /var/www/ephemeral/data/ceph
   pit# unsquashfs ceph-0.0.44.squashfs
   ```
2. Change into the image root
   ```bash
   pit# chroot ./squashfs-root
   ```
3. Change the password
   ```bash
   chroot-pit# passwd
   ```
4. Replace the SSH keys
   ```bash
   chroot-pit# cd root
   ```
   Replace the default root public and private SSH keys with your own or generate a new pair with `ssh-keygen(1)`

5. Create the new SquashFS artifact
   ```bash
   chroot-pit# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```
6. Exit the chroot
   ```bash
   chroot-pit# exit
   ```
7. Cleanup the SquashFS creation

   The Kubernetes image directory is /var/www/ephemeral/data/k8s.
   ```bash
   pit# umount /var/www/ephemeral/data/k8s/squashfs-root/mnt/squashfs
   ```
   The Ceph image directory is /var/www/ephemeral/data/ceph.
   ```bash
   pit# umount /var/www/ephemeral/data/ceph/squashfs-root/mnt/squashfs
   ```
8. Save old SquashFS image.
   ```bash
   pit# mkdir old
   pit# mv *squashfs old
   ```
9. Move new SquashFS image, kernel, and initrd into place.
   ```bash
   pit# mv squashfs-root/squashfs/* .
   ```
10. Update file permissions on initrd
   ```bash
   pit# chmod 644 initrd.img.xz

11. Repeat the preceding steps for the other image type.

12. Set the boot links.
   ```bash
   pit# cd
   pit# set-sqfs-links.sh   
   ```

The images will have the new password for the next boot.

<a name="image-layer-pipeline"></a>
### Image Layer Pipeline

For more information on how the pipeline works, see the [node-image-docs](https://stash.us.cray.com/projects/CLOUD/repos/node-image-docs/browse).

<a name="customization-after-system-up"></a>
## Customization after System Up

After the pit node has been rebooted and joined into the Kubernetes cluster, the
NCN images can still be customized using the Image Management Service (IMS) and
the Configuration Framework Service (CFS).

The following procedure shows how to find existing images used by the NCNs,
register them with IMS, configure them with user-supplied Ansible plays using
CFS, and re-register them with the Boot Script Service (BSS) for booting.

### Locate the NCN SquashFS Images Currently in Use

1. Find the existing NCN images in use as configured in BSS. Define the following
function in a shell on an NCN:

   ```bash
   ncn# export CRAY_FORMAT=json
   ncn# get-ncn-image() { echo $(cray bss bootparameters list --hosts $1 | jq -r .[].params | egrep -o "metal.server=(\S+)" | cut -d"=" -f2-)/$(cray bss bootparameters list --hosts $1 | jq -r .[].params | egrep -o "rd.live.squashimg=(\S+)" | cut -d"=" -f2-);  }
   ```

1. Use the following loop to list all of the images in use on the management nodes
(masters, workers, and storage nodes):

   ```bash
   ncn# for xname in $(cray hsm state components list --role Management --format json | jq -r .Components[].ID); do get-ncn-image $xname | sed 's|http://rgw-vip.nmn/|s3://|g'; done | sort -u

   s3://ncn-images/ceph-filesystem.squashfs
   s3://ncn-images/k8s-filesystem.squashfs
   ```

The default images that were used during initial system bring up are listed
above assuming no other customizations have been made. The output may be
different if the node images are the not the defaults.

*NOTE*: Repeat the following sections for each image that customizations should
be applied to. The `k8s-filesystem.squashfs` file is used in the examples.

### Register the Image in IMS

1. Define variables for the image location in S3 as shown in the previous
   section's output. The S3 bucket is the first part of the `s3://` url, and
   the image filename is the last part. For example:
   ```bash
   ncn# export S3_IMAGE=s3://ncn-images/k8s-filesystem.squashfs
   ncn# export S3_BUCKET=ncn-images
   ncn# export S3_IMAGE_NAME=k8s-filesystem.squashfs
   ```

1. Download the image and compute its md5sum.
   ```bash
   ncn# export IMAGE_MD5SUM=`cray artifacts get $S3_BUCKET $S3_IMAGE_NAME $(basename "$S3_IMAGE_NAME") | md5sum | awk '{ print $1 }'`
   ```

1. Create a new IMS image record for the image.
   ```bash
   ncn# export IMS_IMAGE_ID=`cray ims images create --name $S3_IMAGE_NAME --format json | jq -r .id`
   ```

1. Upload the image to the `boot-images` bucket.
   ```bash
   ncn# cray artifacts create boot-images $IMS_IMAGE_ID/$S3_IMAGE_NAME $(basename "$S3_IMAGE_NAME")
   ```

1. Create an image manifest file.
   ```bash
   ncn# cat <<EOF> manifest.json
   {
      "created": "`date '+%Y-%m-%d %H:%M:%S'`",
      "version": "1.0",
      "artifacts": [
         {
            "link": {
               "path": "s3://boot-images/$IMS_IMAGE_ID/$S3_IMAGE_NAME",
               "type": "s3"
            },
            "md5": "$IMAGE_MD5SUM",
            "type": "application/vnd.cray.image.rootfs.squashfs"
         }
      ]
   }
   EOF
   ```

1. Upload the manifest to S3.
   ```bash
   ncn# cray artifacts create boot-images $IMS_IMAGE_ID/manifest.json manifest.json
   ```

1. Update the IMS image record with the manifest information.
   ```bash
   ncn# cray ims images update $IMS_IMAGE_ID \
      --link-type s3 \
      --link-path s3://boot-images/$IMS_IMAGE_ID/manifest.json
   ```

1. Verify the image is registered with IMS.
   ```bash
   ncn# cray ims images describe $IMS_IMAGE_ID --format json
   {
      "created": "2021-07-28T03:26:00.581774+00:00",
      "id": "3b2fff9f-6325-4286-8024-fd1bf29f211c",
      "link": {
         "etag": "",
         "path": "s3://boot-images/3b2fff9f-6325-4286-8024-fd1bf29f211c/manifest.json",
         "type": "s3"
      },
      "name": "k8s-filesystem.squashfs"
   }
   ```

### Customize the NCN Image

NCN images are customized in a similar manner as other images available on the
system. Refer to "Create an Image Customization CFS Session" in the
_HPE Cray EX System Administration Guide S-8001_. After creating a CFS configuration
with one or more layers, create a CFS session meant for image customization.

The following procedure uses a CFS configuration named `ncn-image-customization`
which specifies the Ansible playbook.

1. Create the CFS session
   ```bash
   ncn# cray cfs sessions create --name ncn-image-customization \
       --configuration-name ncn-image-customization \
       --target-definition image \
       --target-group Management $IMS_IMAGE_ID
   {
      "ansible": {
         "config": "cfs-default-ansible-cfg",
         "limit": null,
         "verbosity": 0
      },
      "configuration": {
         "limit": "",
         "name": "ncn-image-customization"
      },
      "name": "ncn-image-customization",
      "status": {
         "artifacts": [],
         "session": {
            "completionTime": null,
            "job": null,
            "startTime": null,
            "status": "pending",
            "succeeded": "none"
         }
      },
      "tags": {},
      "target": {
         "definition": "image",
         "groups": [
            {
            "members": [
               "3b2fff9f-6325-4286-8024-fd1bf29f211c"
            ],
            "name": "Management"
            }
         ]
      }
   }
   ```