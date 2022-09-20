# Change NCN Image Root Password and SSH Keys

The default SSH keys in the NCN image must be removed. The default password for the root user must be changed.
Customize the NCN images by changing the root password or adding different SSH keys for the root account.
This procedure shows this process being done any time after the first time installation of the CSM
software has been completed and the PIT node is booted as a regular master node. To change the NCN image
during an installation while the PIT node is booted as the PIT node,
see [Change NCN Image Root Password and SSH Keys PIT](#Change_NCN_Image_Root_Password_and_SSH_Keys_PIT.md).

There is some common preparation before making the Kubernetes image for master nodes and worker nodes, making the Ceph image for utility storage nodes, and then some common cleanup afterwards.

***Note:*** This procedure can only be done after the PIT node is rebuilt to become a normal master node.
***Note:*** The NCNs must be rebuilt for the changes to take effect. This is covered in the last step.

- [Common preparation](#common-preparation)
- [Kubernetes image](#kubernetes-image)
- [Ceph image](#ceph-image)
- [Common cleanup](#common-cleanup)
- [Deploy changes](#deploy-changes)

## Common preparation

1. Prepare new SSH keys for the root account in advance. The same key information will be added to both `k8s-image` and Ceph image.

   Either replace the root public and private SSH keys with your own previously generated keys or generate a new
   pair with `ssh-keygen(1)`. By default `ssh-keygen` will create an RSA key, but other types could be chosen and
   different filenames would need to be substituted in later steps.

   ***Note:*** CSM only supports key pairs with empty passphrases (`ssh-keygen -N""`, or enter an empty passphrase when prompted).

   ```bash
   ncn-mw# mkdir /root/.ssh
   ncn-mw# ssh-keygen -f /root/.ssh/id_rsa -t rsa
   ncn-mw# ls -l /root/.ssh/id_rsa*
   ncn-mw# chmod 600 /root/.ssh/id_rsa
   ```

1. Change to a working directory with enough space to hold the images once they have been expanded.

   ```bash
   ncn-mw# cd /run/initramfs/overlayfs
   ncn-mw# mkdir workingarea
   ncn-mw# cd workingarea
   ```

## Kubernetes image

The Kubernetes image `k8s-image` is used by the master and worker nodes.

1. Decide which `k8s-image` to modify.

   ```bash
   ncn-mw# cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep k8s | grep squashfs
   ```

   Example output:

   ```text
   "k8s-filesystem.squashfs"
   "k8s/0.1.107/filesystem.squashfs"
   "k8s/0.1.109/filesystem.squashfs"
   "k8s/0.1.48/filesystem.squashfs"
   ```

   This example uses `k8s/0.1.109` for the current version and adds a suffix for the new version.

   ```bash
   ncn-mw# export K8SVERSION=0.1.109
   ncn-mw# export K8SNEW=0.1.109-2
   ```

1. Make a temporary directory for the `k8s-image` using the current version string.

   ```bash
   ncn-mw# mkdir -p k8s/${K8SVERSION}
   ```

1. Get the image.

   ```bash
   ncn-mw# cray artifacts get ncn-images k8s/${K8SVERSION}/filesystem.squashfs k8s/${K8SVERSION}/filesystem.squashfs.orig
   ```

1. Open the image.

   ```bash
   ncn-mw# unsquashfs -d k8s/${K8SVERSION}/filesystem.squashfs k8s/${K8SVERSION}/filesystem.squashfs.orig
   ```

1. If the image being modified contains the default SSH keys for the `root` user and/or the default
   SSH host keys, remove them now. If the defaults were removed during initial system install or in
   a subsequent rotation, then this step can be safely skipped.

   ```bash
   ncn-mw# rm -rf k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh
   ncn-mw# rm -f k8s/${K8SVERSION}/filesystem.squashfs/etc/ssh/*key*
   ```

1. Copy the generated public and private SSH keys for the `root` account into the image.

   This example assumes that an RSA key was generated.

   ```bash
   ncn-mw# mkdir -m 0700 k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh
   ncn-mw# cp -p /root/.ssh/id_rsa /root/.ssh/id_rsa.pub k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh
   ```

1. Replace the public SSH key for the `root` account in `authorized_keys`.

   This example assumes that an RSA key was generated so it adds the `id_rsa.pub` file to `authorized_keys`. It also removes any previously authorized keys. Feel free to manage this differently to retain additional keys if desired.

   ```bash
   ncn-mw# cat /root/.ssh/id_rsa.pub > k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ncn-mw# chmod 640 k8s/${K8SVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ```

1. Change into the image root.

   ```bash
   ncn-mw# chroot k8s/${K8SVERSION}/filesystem.squashfs
   ```

1. Change the password.

   ```bash
   chroot-ncn-mw# passwd
   ```

1. (Optional) If there are any other things to be changed in the image, then they could also be done at this point.

   1. (Optional) Set default timezone on management nodes.

      1. Check whether `TZ` variable is already set in `/etc/environment`. The setting for `NEWTZ` must be a valid timezone from the set under `/usr/share/zoneinfo`.

         ```bash
         chroot-ncn-mw# NEWTZ=US/Pacific
         chroot-ncn-mw# grep TZ /etc/environment
         ```

         Add only if `TZ` is not present.

         ```bash
         chroot-ncn-mw# echo TZ=${NEWTZ} >> /etc/environment
         ```

      1. Check for `utc` setting.

         ```bash
         chroot-ncn-mw# grep -i utc /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

         Change only if the `grep` command shows these lines set to UTC.

         ```bash
         chroot-ncn-mw# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/ntp-upgrade-config.sh
         chroot-ncn-mw# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

1. Create the new SquashFS artifact.

   ```bash
   chroot-ncn-mw# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the `chroot` environment.

   ```bash
   chroot-ncn-mw# exit
   ```

1. Clean up the SquashFS creation.

   ```bash
   ncn-mw# umount -v k8s/${K8SVERSION}/filesystem.squashfs/mnt/squashfs
   ```

1. Move new SquashFS image, kernel, and `initrd` into place.

   ```bash
   ncn-mw# mkdir k8s/${K8SNEW}
   ncn-mw# mv -v k8s/${K8SVERSION}/filesystem.squashfs/squashfs/* k8s/${K8SNEW}
   ```

1. Update file permissions on `initrd`.

   ```bash
   ncn-mw# chmod -v 644 k8s/${K8SNEW}/initrd.img.xz
   ```

1. Put the new `squashfs`, `kernel`, and `initrd` into S3.

   ```bash
   ncn-mw# cd k8s/${K8SNEW}
   ncn-mw# /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name k8s/${K8SNEW}/filesystem.squashfs --file-name filesystem.squashfs
   ncn-mw# /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name k8s/${K8SNEW}/initrd --file-name initrd.img.xz
   ncn-mw# /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name k8s/${K8SNEW}/kernel --file-name 5.3.18-24.75-default.kernel
   ncn-mw# cd ../..
   ```

1. The Kubernetes image now has the image changes.

1. Update BSS with the new image for the master nodes and worker nodes.

   **WARNING:** If doing a CSM software upgrade, then skip this section and proceed to [Ceph image](#ceph-image).

   > If not doing a CSM software upgrade, this process will update the entries in BSS for the master nodes and worker nodes to use the new `k8s-image`.
   >
   > 1. Set all master nodes and worker nodes to use newly created `k8s-image`.
   >
   >     This will use the `K8SVERSION` and `K8SNEW` variables defined earlier.
   >
   >     ```bash
   >     ncn-mw# for node in $(grep -oP "(ncn-[mw]\w+)" /etc/hosts | sort -u)
   >             do
   >                 echo $node
   >                 xname=$(ssh $node cat /etc/cray/xname)
   >                 echo $xname
   >                 cray bss bootparameters list --name $xname --format json > bss_$xname.json
   >                 sed -i.$(date +%Y%m%d_%H%M%S%N).orig "s@/k8s/${K8SVERSION}\([\"/[:space:]]\)@/k8s/${K8SNEW}\1@g" bss_$xname.json
   >                 kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
   >                 initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
   >                 params=$(cat bss_$xname.json | jq '.[]  .params')
   >                cray bss bootparameters update --initrd $initrd --kernel $kernel --params "$params" --hosts $xname --format json
   >             done
   >     ```
   >
   > BSS will be updated to use the new versions when `/etc/cray/upgrade/csm/myenv` is manually updated.
   > See [Stage 0.9 - Modify NCN Images](../../upgrade/1.0.11/Stage_0_Prerequisites.md#stage-09---modify-ncn-images)for more information.

## Ceph image

The Ceph image is used by the utility storage nodes.

1. Decide which Ceph image to modify.

   ```bash
   ncn-mw# cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep ceph | grep squashfs
   ```

   Example output:

   ```text
   "ceph-filesystem.squashfs"
   "ceph/0.1.107/filesystem.squashfs"
   "ceph/0.1.113/filesystem.squashfs"
   "ceph/0.1.48/filesystem.squashfs"
   ```

   This example uses `ceph/0.1.113` for the current version and adds a suffix for the new version.

   ```bash
   ncn-mw# export CEPHVERSION=0.1.113
   ncn-mw# export CEPHNEW=0.1.113-2
   ```

1. Make a temporary directory for the Ceph image using the current version string.

   ```bash
   ncn-mw# mkdir -p ceph/${CEPHVERSION}
   ```

1. Get the image.

   ```bash
   ncn-mw# cray artifacts get ncn-images ceph/${CEPHVERSION}/filesystem.squashfs ceph/${CEPHVERSION}/filesystem.squashfs.orig
   ```

1. Open the image.

   ```bash
   ncn-mw# unsquashfs -d ceph/${CEPHVERSION}/filesystem.squashfs ceph/${CEPHVERSION}/filesystem.squashfs.orig
   ```

1. Copy the generated public and private SSH keys for the `root` account into the image.

   This example assumes that an RSA key was generated.

   ```bash
   ncn-mw# cp -p /root/.ssh/id_rsa /root/.ssh/id_rsa.pub ceph/${CEPHVERSION}/filesystem.squashfs/root/.ssh
   ```

1. Replace the public SSH key for the `root` account in `authorized_keys`.

   This example assumes that an RSA key was generated so it adds the `id_rsa.pub` file to `authorized_keys`. It also removes any previously authorized keys. Feel free to manage this differently to retain additional keys if desired.

   ```bash
   ncn-mw# cat /root/.ssh/id_rsa.pub > ceph/${CEPHVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ncn-mw# chmod 640 ceph/${CEPHVERSION}/filesystem.squashfs/root/.ssh/authorized_keys
   ```

1. Change into the image root.

   ```bash
   ncn-mw# chroot ceph/${CEPHVERSION}/filesystem.squashfs
   ```

1. Change the password.

   ```bash
   chroot-ncn-mw# passwd
   ```

1. (Optional) If there are any other things to be changed in the image, then they could also be done at this point.

   1. (Optional) Set default timezone on management nodes.

      1. Check whether `TZ` variable is already set in `/etc/environment`. The setting for `NEWTZ` must be a valid timezone from the set under `/usr/share/zoneinfo`.

         ```bash
         chroot-ncn-mw# NEWTZ=US/Pacific
         chroot-ncn-mw# grep TZ /etc/environment
         ```

         Add only if `TZ` is not present.

         ```bash
         chroot-ncn-mw# echo TZ=${NEWTZ} >> /etc/environment
         ```

      2. Check for `utc` setting.

         ```bash
         chroot-ncn-mw# grep -i utc /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

         Change only if the `grep` command shows these lines set to UTC.

         ```bash
         chroot-ncn-mw# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/ntp-upgrade-config.sh
         chroot-ncn-mw# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

1. Create the new SquashFS artifact.

   ```bash
   chroot-ncn-mw# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the `chroot` environment.

   ```bash
   chroot-ncn-mw# exit
   ```

1. Clean up the SquashFS creation.

   ```bash
   ncn-mw# umount -v ceph/${CEPHVERSION}/filesystem.squashfs/mnt/squashfs
   ```

1. Move the new SquashFS image, kernel, and initrd into place.

   ```bash
   ncn-mw# mkdir ceph/$CEPHNEW
   ncn-mw# mv -v ceph/$CEPHVERSION/filesystem.squashfs/squashfs/* ceph/$CEPHNEW
   ```

1. Update file permissions on `initrd`.

   ```bash
   ncn-mw# chmod -v 644 ceph/${CEPHNEW}/initrd.img.xz
   ```

1. Put the new `initrd.img.xz`, `kernel`, and SquashFS into S3.

   ***Note:*** The version string for the kernel file may be different.

   ```bash
   ncn-mw# cd ceph/${CEPHNEW}
   ncn-mw# /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name ceph/${CEPHNEW}/filesystem.squashfs --file-name filesystem.squashfs
   ncn-mw# /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name ceph/${CEPHNEW}/initrd --file-name initrd.img.xz
   ncn-mw# /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name ceph/${CEPHNEW}/kernel --file-name 5.3.18-24.75-default.kernel
   ncn-mw# cd ../..
   ```

1. The Ceph image now has the image changes.

1. Update BSS with the new image for utility storage nodes.

   **WARNING:** If doing a CSM software upgrade, then skip this section and proceed to [Common cleanup](#common-cleanup).

   > If not doing a CSM software upgrade, this process will update the entries in BSS for the utility storage nodes to use the new Ceph image.
   >
   > 1. Set all utility storage nodes to use newly created Ceph image.
   >
   >     This will use the `CEPHVERSION` and `CEPHNEW` variables defined earlier.
   >
   >     ```bash
   >     ncn-mw# for node in $(grep -oP "(ncn-s\w+)" /etc/hosts | sort -u)
   >             do
   >                 echo $node
   >                 xname=$(ssh $node cat /etc/cray/xname)
   >                 echo $xname
   >                 cray bss bootparameters list --name $xname --format json > bss_$xname.json
   >                 sed -i.$(date +%Y%m%d_%H%M%S%N).orig "s@/ceph/${CEPHVERSION}\([\"/[:space:]]\)@/ceph/${CEPHNEW}\1@g" bss_$xname.json
   >                 kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
   >                 initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
   >                 params=$(cat bss_$xname.json | jq '.[]  .params')
   >                 cray bss bootparameters update --initrd $initrd --kernel $kernel --params "$params" --hosts $xname --format json
   >             done
   >     ```

## Common cleanup

1. Remove the work area so the space can be reused.

   ```bash
   ncn-mw# rm -rf /run/initramfs/overlayfs/workingarea
   ```

## Deploy changes

1. Rebuild nodes.

   **WARNING:** If doing a CSM software upgrade, then skip this step because the upgrade process does a rolling rebuild with some additional steps.

   > If not doing a CSM software upgrade, then follow the procedure to do a [Rolling Rebuild](../node_management/Rebuild_NCNs.md) of all management nodes.
