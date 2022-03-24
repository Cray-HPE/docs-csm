# Change NCN Image Root Password and SSH Keys

Customize the NCN images by changing the root password or adding different ssh keys for the root account.
This procedure shows this process being done any time after the first time installation of the CSM
software has been completed and the PIT node is booted as a regular master node. To change the NCN image
during an installation while the PIT node is booted as the PIT node,
see [Change_NCN_Image_Root_Password_and_SSH_Keys_PIT](#Change_NCN_Image_Root_Password_and_SSH_Keys_PIT.md).

There is some common preparation before making the Kubernetes image for master nodes and worker nodes, making the Ceph image for utility storage nodes, and then some common cleanup afterwards.

***Note:*** This procedure can only be done after the PIT node is rebuilt to become a normal master node.

### Common Preparation

1. Prepare new ssh keys for the root account in advance. The same key information will be added to both k8s-image and ceph-image.

   Either replace the root public and private ssh keys with your own previously generated keys or generate a new pair with `ssh-keygen(1)`. By default `ssh-keygen` will create an RSA key, but other types could be chosen and different filenames would need to be substituted in later steps.

   ```bash
   ncn-m# mkdir /root/.ssh
   ncn-m# ssh-keygen -f /root/.ssh/id_rsa -t rsa
   ncn-m# ls -l /root/.ssh/id_rsa*
   ncn-m# chmod 600 /root/.ssh/id_rsa
   ```

1. Change to a working directory with enough space to hold the images once they have been expanded.

   ```bash
   ncn-m# cd /run/initramfs/overlayfs
   ncn-m# mkdir workingarea
   ncn-m# cd workingarea
   ```

### Kubernetes Image

The Kubernetes image ```k8s-image``` is used by the master and worker nodes.

1. Decide which k8s-image is to be modified

   ```bash
   ncn-m# cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep k8s | grep squashfs
   "k8s-filesystem.squashfs"
   "k8s/0.1.107/filesystem.squashfs"
   "k8s/0.1.109/filesystem.squashfs"
   "k8s/0.1.48/filesystem.squashfs"
   ```

   This example uses k8s/0.1.109 for the current version and adds a suffix for the new version.

   ncn-m# export K8SVERSION=0.1.109
   ncn-m# export K8SNEW=0.1.109-2

1. Make a temporary directory for the k8s-image using the current version string.

   ```bash
   ncn-m# mkdir -p k8s/${K8SVERSION}
   ```

1. Get the image.

   ```bash
   ncn-m# cray artifacts get ncn-images k8s/${K8SVERSION}/filesystem.squashfs k8s/${K8SVERSION}/filesystem.squashfs.orig
   ```

1. Open the image.

   ```bash
   ncn-m# unsquashfs -d k8s/${K8SVERSION}/filesystem.squashfs k8s/${K8SVERSION}/filesystem.squashfs.orig
   ```

1. Copy the generated public and private ssh keys for the root account into the image.

   This example assumes that an RSA key was generated.

   ```bash
   ncn-m# cp -p /root/.ssh/id_rsa /root/.ssh/id_rsa.pub k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh
   ```

1. Add the public ssh key for the root account to `authorized_keys`.

   This example assumes that an RSA key was generated so it adds the id_rsa.pub file to authorized_keys.

   ```bash
   ncn-m# cat /root/.ssh/id_rsa.pub >> k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ncn-m# chmod 640 k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ```

1. Change into the image root.

   ```bash
   ncn-m# chroot k8s/${K8SVERSION}/filesystem.squashfs
   ```

1. Change the password.

   ```bash
   chroot-ncn-m# passwd
   ```

1. (Optional) If there are any other things to be changed in the image, they could also be done at this point.

   1. (Optional) Set default timezone on management nodes.

      1. Check whether TZ variable is already set in `/etc/environment`. The setting for NEWTZ must be a valid timezone from the set under `/usr/share/zoneinfo`.

         ```bash
         chroot-ncn-m# NEWTZ=US/Pacific
         chroot-ncn-m# grep TZ /etc/environment
         ```

         Add only if TZ is not present.

         ```bash
         chroot-ncn-m# echo TZ=${NEWTZ} >> /etc/environment
         ```

      1. Check for `utc` setting.

         ```bash
         chroot-ncn-m# grep -i utc /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

         Change only if the `grep` command shows these lines set to UTC.

         ```bash
         chroot-ncn-m# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/ntp-upgrade-config.sh
         chroot-ncn-m# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

1. Create the new SquashFS artifact.

   ```bash
   chroot-ncn-m# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the chroot environment.

   ```bash
   chroot-ncn-m# exit
   ```

1. Clean up the SquashFS creation.

   ```bash
   ncn-m# umount -v k8s/${K8SVERSION}/filesystem.squashfs/mnt/squashfs
   ```

1. Move new SquashFS image, kernel, and initrd into place.

   ```bash
   ncn-m# mkdir k8s/${K8SNEW}
   ncn-m# mv -v k8s/${K8SVERSION}/filesystem.squashfs/squashfs/* k8s/${K8SNEW}
   ```

1. Update file permissions on initrd.

   ```bash
   ncn-m# chmod -v 644 k8s/${K8SNEW}/initrd.img.xz
   ```

1. Put the new squashfs, kernel, and initrd into S3

   1. If not already available, get this sript which will put a file into S3 with public read setting.

   ```bash
   ncn-m# wget https://github.com/Cray-HPE/s3_examples/blob/main/no_STS/ceph-upload-file-public-read.py
   ncn-m# chmod +x ceph-upload-file-public-read.py
   ```

   1. Get info to add to credentials.json for the SDS user

      ```bash
      ncn-m# ssh ncn-s001 radosgw-admin user info --uid SDS | grep key
      "keys": [
              "access_key": "FKZWSIY92VBC4LPGXW9I",
              "secret_key": "mYcViYWwXDT7PAR5JOwzsT5vjkKhWHUb8MGJpjsm"
      "swift_keys": [],
      "temp_url_keys": [],
      ```

   1. Using the access_key and secret_key, construct a `credentials.json` file with contents similar to this.

      ```bash
      ncn-m# cat credentials.json
      {
          "access_key": "KJ1B22VP2MBKYPALP8VW",
          "secret_key": "EJbDkvoaHEcMfhkMeDSA3tEM6DwBSmuGzVYkuUOv",
          "endpoint_url": "http://10.252.1.11:8080"
      }
      ```

   1. Upload the boot artifacts to S3.

      ```bash
      ncn-m# cp -p credentials.json ceph-upload-file-public-read.py. k8s/${K8SNEW}
      cd k8s/${K8SNEW}
      ./ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'k8s/${K8SNEW}/filesystem.squashfs' --file-name filesystem.squashfs
      ./ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'k8s/${K8SNEW}/initrd' --file-name initrd.img.xz
      ./ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'k8s/${K8SNEW}/kernel' --file-name 5.3.18-24.75-default.kernel
      ```

1. The Kubernetes image now has the image changes.

1. Update BSS with the new image for the master nodes and worker nodes.

   **WARNING:** If doing a CSM software upgrade, skip this section to continue with Ceph Image.

   > If not doing a CSM software upgrade, this process will update the entries in BSS for the master nodes and worker nodes to use the new `k8s-image`.
   > 
   > 1. Set all master nodes and worker nodes to use newly created k8s-image.
   >
   >     This will use the K8SVERSION and K8SNEW variables defined earlier.
   >
   >     ```bash
   >     ncn-m# for node in $(grep -oP "(ncn-[mw]\w+)" /etc/hosts | sort -u) 
   >     do
   >       echo $node
   >       xname=$(ssh $node cat /etc/cray/xname)
   >       echo $xname
   >       cray bss bootparameters list --name $xname --format json > bss_$xname.json
   >       sed -i.old "s@k8s/${K8SVERSION}@k8s/${K8SNEW}@g" bss_$xname.json 
   >       kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
   >       initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
   >       params=$(cat bss_$xname.json | jq '.[]  .params')
   >       cray bss bootparameters update --initrd $initrd --kernel $kernel --params $params --name $xname --format json
   >     done
   >     ```

### Ceph Image

The Ceph image `ceph-image` is used by the utility storage nodes.

1. Decide which ceph-image is to be modified

   ```bash
   ncn-m# cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep ceph | grep squashfs
   "ceph-filesystem.squashfs"
   "ceph/0.1.107/filesystem.squashfs"
   "ceph/0.1.113/filesystem.squashfs"
   "ceph/0.1.48/filesystem.squashfs"
   ```

   This example uses ceph/0.1.113 for the current version and adds a suffix for the new version.

   ncn-m# export CEPHVERSION=0.1.113
   ncn-m# export CEPHNEW=0.1.113-2

1. Make a temporary directory for the ceph-image using the current version string.

   ```bash
   ncn-m# mkdir -p ceph/${CEPHVERSION}
   ```

1. Get the image.

   ```bash
   ncn-m# cray artifacts get ncn-images ceph/${CEPHVERSION}/filesystem.squashfs ceph/${CEPHVERSION}/filesystem.squashfs.orig
   ```

1. Open the image.

   ```bash
   ncn-m# unsquashfs -d ceph/${CEPHVERSION}/filesystem.squashfs ceph/${CEPHVERSION}/filesystem.squashfs.orig
   ```

1. Copy the generated public and private ssh keys for the root account into the image.

   This example assumes that an RSA key was generated.

   ```bash
   ncn-m# cp -p /root/.ssh/id_rsa /root/.ssh/id_rsa.pub ceph/${CEPHVERSION}/filesystem.squashfs/root/.ssh
   ```

1. Add the public ssh key for the root account to `authorized_keys`.

   This example assumes that an RSA key was generated so it adds the id_rsa.pub file to authorized_keys.

   ```bash
   ncn-m# cat /root/.ssh/id_rsa.pub >> ceph/${CEPHVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ncn-m# chmod 640 ceph/${CEPHVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ```

1. Change into the image root.

   ```bash
   ncn-m# chroot ceph/${CEPHVERSION}/filesystem.squashfs
   ```

1. Change the password.

   ```bash
   chroot-ncn-m# passwd
   ```

1. (Optional) If there are any other things to be changed in the image, they could also be done at this point.

   1. (Optional) Set default timezone on management nodes.

      1. Check whether TZ variable is already set in `/etc/environment`. The setting for NEWTZ must be a valid timezone from the set under `/usr/share/zoneinfo`.

         ```bash
         chroot-ncn-m# NEWTZ=US/Pacific
         chroot-ncn-m# grep TZ /etc/environment
         ```

         Add only if TZ is not present.

         ```bash
         chroot-ncn-m# echo TZ=${NEWTZ} >> /etc/environment
         ```

      1. Check for `utc` setting.

         ```bash
         chroot-ncn-m# grep -i utc /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

         Change only if the `grep` command shows these lines set to UTC.

         ```bash
         chroot-ncn-m# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/ntp-upgrade-config.sh
         chroot-ncn-m# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

1. Create the new SquashFS artifact.

   ```bash
   chroot-ncn-m# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the chroot environment.

   ```bash
   chroot-ncn-m# exit
   ```

1. Clean up the SquashFS creation.

   ```bash
   ncn-m# umount -v ceph/${CEPHVERSION}/filesystem.squashfs/mnt/squashfs
   ```

1. Update file permissions on initrd.

   ```bash
   ncn-m# chmod -v 644 ceph/${CEPHNEW}/initrd.img.xz
   ```

1. Put the new initrd.img.xz, kernel, and squashfs into S3

   1. If not already available, get this sript which will put a file into S3 with public read setting.

   ```bash
   ncn-m# wget https://github.com/Cray-HPE/s3_examples/blob/main/no_STS/ceph-upload-file-public-read.py
   ncn-m# chmod +x ceph-upload-file-public-read.py
   ```

   1. Get info to add to credentials.json for the SDS user

      ```bash
      ncn-m# ssh ncn-s001 radosgw-admin user info --uid SDS | grep key
      "keys": [
              "access_key": "FKZWSIY92VBC4LPGXW9I",
              "secret_key": "mYcViYWwXDT7PAR5JOwzsT5vjkKhWHUb8MGJpjsm"
      "swift_keys": [],
      "temp_url_keys": [],
      ```

   1. Using the `access_key` and `secret_key`, construct a `credentials.json` file with contents similar to this.

      ```bash
      ncn-m# cat credentials.json
      {
          "access_key": "KJ1B22VP2MBKYPALP8VW",
          "secret_key": "EJbDkvoaHEcMfhkMeDSA3tEM6DwBSmuGzVYkuUOv",
          "endpoint_url": "http://10.252.1.11:8080"
      }
      ```

   1. Upload the boot artifacts to S3.

      ***Note:*** The version string for the kernel file may be different.

      ```bash
      ncn-m# cp -p credentials.json ceph-upload-file-public-read.py. ceph/${CEPHNEW}
      cd ceph/${CEPHNEW}
      ./ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'ceph/${CEPHNEW}/filesystem.squashfs' --file-name filesystem.squashfs
      ./ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'ceph/${CEPHNEW}/initrd' --file-name initrd.img.xz
      ./ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'ceph/${CEPHNEW}/kernel' --file-name 5.3.18-24.75-default.kernel
      cd ../..
      ```

1. The Ceph image now has the image changes.

1. Update BSS with the new image for utility storage nodes.

   **WARNING:** If doing a CSM software upgrade, skip this section to continue with Common Cleanup.

   > If not doing a CSM software upgrade, this process will update the entries in BSS for the utiltity storage nodes to use the new `ceph-image`.
   > 
   > 1. Set all utility storage nodes to use newly created ceph-image.
   >
   >     This will use the CEPHVERSION and CEPHNEW variables defined earlier.
   >
   >     ```bash
   >     ncn-m# for node in $(grep -oP "(ncn-s\w+)" /etc/hosts | sort -u) 
   >     do
   >       echo $node
   >       xname=$(ssh $node cat /etc/cray/xname)
   >       echo $xname
   >       cray bss bootparameters list --name $xname --format json > bss_$xname.json
   >       sed -i.old "s@ceph/${CEPHVERSION}@ceph/${CEPHNEW}@g" bss_$xname.json 
   >       kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
   >       initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
   >       params=$(cat bss_$xname.json | jq '.[]  .params')
   >       cray bss bootparameters update --initrd $initrd --kernel $kernel --params $params --name $xname --format json
   >     done
   >     ```

### Common Cleanup

1. Remove the workarea so the space can be reused.

   ```bash
   ncn-m# rm -rf /run/initramfs/overlayfs/workingarea
   ```

1. Rebuild nodes.

   **WARNING:** If doing a CSM software upgrade, skip this step since the upgrade process does a rolling rebuild with some additional steps.

   > If not doing a CSM software upgrade, follow the procedure to do a [Rolling Rebuild](../operations/node_management/Rebuild_NCNs.md) of all management nodes.
