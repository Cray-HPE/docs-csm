## Change NCN Image Root Password and SSH Keys on PIT Node

Customize the NCN images by changing the root password or adding different ssh keys for the root account.
This procedure shows this process being done on the PIT node during a first time installation of the CSM
software.

There is some common preparation before making the Kubernetes image for master nodes and worker nodes, making the Ceph image for utility storage nodes, and then some common cleanup afterwards.

***Note:*** This procedure can only be done before the PIT node is rebuilt to become a normal master node.

### Common Preparation

1. Prepare new ssh keys on the PIT node for the root account in advance. The same key information will be added to both k8s-image and ceph-image.

   Either replace the root public and private ssh keys with your own previously generated keys or generate a new pair with `ssh-keygen(1)`. By default `ssh-keygen` will create an RSA key, but other types could be chosen and different filenames would need to be substituted in later steps.

   ```bash
   pit# mkdir /root/.ssh
   pit# ssh-keygen -f /root/.ssh/id_rsa -t rsa
   pit# ls -l /root/.ssh/id_rsa*
   pit# chmod 600 /root/.ssh/id_rsa
   ```

### Kubernetes Image

The Kubernetes image is used by the master and worker nodes.

1. Change to the working directory for the Kubernetes image.

   ```bash
   pit# cd /var/www/ephemeral/data/k8s
   ```

1. Open the image.

   The Kubernetes image will be of the form "kubernetes-0.1.69.squashfs" in /var/www/ephemeral/data/k8s, but the version number may be different.

   ```bash
   pit# unsquashfs kubernetes-0.1.69.squashfs
   ```

1. Save the old SquashFS image, kernel, and initrd.

   ```bash
   pit# mkdir -v old
   pit# mv -v *squashfs *kernel initrd* old
   ```

1. Copy the generated public and private ssh keys for the root account into the image.

   This example assumes that an RSA key was generated.

   ```bash
   pit# cp -p /root/.ssh/id_rsa /root/.ssh/id_rsa.pub squashfs-root/root/.ssh
   ```

1. Add the public ssh key for the root account to `authorized_keys`.

   This example assumes that an RSA key was generated so it adds the id_rsa.pub file to authorized_keys.

   ```bash
   pit# cat /root/.ssh/id_rsa.pub >> squashfs-root/root/.ssh/authorized_keys
   pit# chmod 640 squashfs-root/root/.ssh/authorized_keys
   ```

1. Change into the image root.

   ```bash
   pit# chroot ./squashfs-root
   ```

1. Change the password.

   ```bash
   chroot-pit# passwd
   ```

1. (Optional) If there are any other things to be changed in the image, they could also be done at this point.

   1. (Optional) Set default timezone on management nodes.

      1. Check whether TZ variable is already set in `/etc/environment`. The setting for NEWTZ must be a valid timezone from the set under `/usr/share/zoneinfo`.

         ```bash
         chroot-pit# NEWTZ=US/Pacific
         chroot-pit# grep TZ /etc/environment
         ```

         Add only if TZ is not present.

         ```bash
         chroot-pit# echo TZ=${NEWTZ} >> /etc/environment
         ```

      1. Check for `utc` setting.

         ```bash
         chroot-pit# grep -i utc /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

         Change only if the `grep` command shows these lines set to UTC.

         ```bash
         chroot-pit# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/ntp-upgrade-config.sh
         chroot-pit# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

1. Create the new SquashFS artifact.

   ```bash
   chroot-pit# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the chroot environment.

   ```bash
   chroot-pit# exit
   ```

1. Clean up the SquashFS creation.

   The Kubernetes image directory is /var/www/ephemeral/data/k8s.

   ```bash
   pit# umount -v /var/www/ephemeral/data/k8s/squashfs-root/mnt/squashfs
   ```

1. Move new SquashFS image, kernel, and initrd into place.

   ```bash
   pit# mv -v squashfs-root/squashfs/* .
   ```

1. Update file permissions on initrd.

   ```bash
   pit# chmod -v 644 initrd.img.xz
   ```

1. Rename the new squashfs, kernel, and initrd to include a new version string.

   If the old name of the squashfs was kubernetes-0.1.69.squashfs, then its version was '0.1.69', so the newly created version should be renamed to include a version of '0.1.69-1' with an additional dash and a build iteration number of 1. This will help to track what base version was used.

   ```bash
   pit# ls -l old/*squashfs
   -rw-r--r--  1 root root 5135859712 Aug 19 19:10 kubernetes-0.1.69.squashfs
   ```

   Set the VERSION variable based on the version string displayed by the above command with an incremented suffix added to show a build iteration.

   ```bash
   pit# export VERSION=0.1.69-1
   pit# mv filesystem.squashfs kubernetes-${VERSION}.squashfs
   pit# mv initrd.img.xz initrd.img-${VERSION}.xz
   ```

   The kernel file will have a name with the kernel version but not this new $VERSION.

   ```bash
   pit# ls -l *kernel
   -rw-r--r--  1 root root    8552768 Aug 19 19:09 5.3.18-24.75-default.kernel
   ```

   Rename it to include the version string.

   ```bash
   pit# mv 5.3.18-24.75-default.kernel 5.3.18-24.75-default-${VERSION}.kernel
   ```

1. Set the boot links.

   ```bash
   pit# cd
   pit# set-sqfs-links.sh
   ```

The Kubernetes image will have the image changes for the next boot.

### Ceph Image

The Ceph image is used by the utility storage nodes.

1. Change to the working directory for the Ceph image.

   ```bash
   pit# cd /var/www/ephemeral/data/ceph
   ```

1. Open the image.

   The Ceph image will be of the form "storage-ceph-0.1.69.squashfs" in /var/www/ephemeral/data/ceph, but the version number may be different.

   ```bash
   pit# unsquashfs storage-ceph-0.1.69.squashfs
   ```

1. Save the old SquashFS image, kernel, and initrd.

   ```bash
   pit# mkdir -v old
   pit# mv -v *squashfs *kernel initrd* old
   ```

1. Copy the generated public and private ssh keys for the root account into the image.

   This example assumes that an RSA key was generated.

   ```bash
   pit# cp -p /root/.ssh/id_rsa /root/.ssh/id_rsa.pub squashfs-root/root/.ssh
   ```

1. Add the public ssh key for the root account to `authorized_keys`.

   This example assumes that an RSA key was generated so it adds the id_rsa.pub file to authorized_keys.

   ```bash
   pit# cat /root/.ssh/id_rsa.pub >> squashfs-root/root/.ssh/authorized_keys
   pit# chmod 640 squashfs-root/root/.ssh/authorized_keys
   ```

1. Change into the image root.

   ```bash
   pit# chroot ./squashfs-root
   ```

1. Change the password.

   ```bash
   chroot-pit# passwd
   ```

1. (Optional) If there are any other things to be changed in the image, they could also be done at this point.

   1. (Optional) Set default timezone on management nodes.

      1. Check whether TZ variable is already set in `/etc/environment`. The setting for NEWTZ must be a valid timezone from the set under `/usr/share/zoneinfo`.

         ```bash
         chroot-pit# NEWTZ=US/Pacific
         chroot-pit# grep TZ /etc/environment
         ```

         Add only if TZ is not present.

         ```bash
         chroot-pit# echo TZ=${NEWTZ} >> /etc/environment
         ```

      1. Check for `utc` setting.

         ```bash
         chroot-pit# grep -i utc /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

         Change only if the `grep` command shows these lines set to UTC.

         ```bash
         chroot-pit# sed -i "s#^timedatectl set-timezone UTC#timedatectl set-timezone $NEWTZ#" /srv/cray/scripts/metal/ntp-upgrade-config.sh
         chroot-pit# sed -i 's/--utc/--localtime/' /srv/cray/scripts/metal/ntp-upgrade-config.sh
         ```

1. Create the new SquashFS artifact.

   ```bash
   chroot-pit# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the chroot environment.

   ```bash
   chroot-pit# exit
   ```

1. Clean up the SquashFS creation.

   The Ceph image directory is /var/www/ephemeral/data/ceph.

   ```bash
   pit# umount -v /var/www/ephemeral/data/ceph/squashfs-root/mnt/squashfs
   ```

1. Save old SquashFS image.

   ```bash
   pit# mkdir -v old
   pit# mv -v *squashfs old
   ```

1. Move new SquashFS image, kernel, and initrd into place.

   ```bash
   pit# mv -v squashfs-root/squashfs/* .
   ```

1. Update file permissions on initrd.

   ```bash
   pit# chmod -v 644 initrd.img.xz
   ```

1. Rename the new squashfs, kernel, and initrd to include a new version string.

   If the old name of the squashfs was storage-ceph-0.1.69.squashfs, then its version was '0.1.69', so the newly created version should be renamed to include a version of '0.1.69-1' with an additional dash and a build iteration number of 1. This will help to track what base version was used.

   ```bash
   pit# ls -l old/*squashfs
   -rw-r--r--  1 root root 5135859712 Aug 19 19:10 storage-ceph-0.1.69.squashfs
   ```

   Set the VERSION variable based on the version string displayed by the above command with an incremented suffix added to show a build iteration.

   ```bash
   pit# VERSION=0.1.69-1
   pit# mv filesystem.squashfs storage-ceph-${VERSION}.squashfs
   pit# mv initrd.img.xz initrd.img-${VERSION}.xz
   ```

   The kernel file will have a name with the kernel version but not this new $VERSION.

   ```bash
   pit# ls -l *kernel
   -rw-r--r--  1 root root    8552768 Aug 19 19:09 5.3.18-24.75-default.kernel
   ```

   Rename it to include the version string.

   ```bash
   pit# mv 5.3.18-24.75-default.kernel 5.3.18-24.75-default-${VERSION}.kernel
   ```

1. Set the boot links.

   ```bash
   pit# cd
   pit# set-sqfs-links.sh
   ```

The Ceph image will have the image changes for the next boot.

### Common Cleanup

1. Clean up temporary storage used to prepare images.

   These could be removed now or after verification that the nodes are able to boot successfully with the new images.

   ```bash
   pit# cd /var/www/ephemeral/data
   pit# rm -rf ceph/old k8s/old
   ```
