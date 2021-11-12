## Change NCN Image Root Password and SSH Keys

Customize the NCN image by changing the root password or adding different ssh keys for the root account.
This procedure shows this process being done on the PIT node during a first time installation of the CSM
software.

This process should be done for the "Kubernetes" image used by master and worker nodes and then repeated for the "ceph" image used by the utility storage nodes.

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

1. Chroot into the image root

   ```bash
   pit# chroot ./squashfs-root
   ```

1. Change the password

   ```bash
   chroot-pit# passwd
   ```

1. Replace the ssh keys

   ```bash
   chroot-pit# cd root
   ```

1. Replace the default root public and private ssh keys with your own or generate a new pair with `ssh-keygen(1)`

   ```bash
   chroot-pit# mknod /dev/urandom c 1 9
   chroot-pit# ssh-keygen <options>
   chroot-pit# rm /dev/urandom
   ```

1. Create the new SquashFS artifact

   ```bash
   chroot-pit# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the chroot

   ```bash
   chroot-pit# exit
   ```

1. Clean up the SquashFS creation

   The Kubernetes image directory is /var/www/ephemeral/data/k8s.

   ```bash
   pit# umount -v /var/www/ephemeral/data/k8s/squashfs-root/mnt/squashfs
   ```

1. Move new SquashFS image, kernel, and initrd into place.

   ```bash
   pit# mv -v squashfs-root/squashfs/* .
   ```

1. Update file permissions on initrd

   ```bash
   pit# chmod -v 644 initrd.img.xz
   ```

1. Rename the new squashfs, kernel, and initrd to include a new version string.

   If the old name of the squashfs was kubernetes-0.1.69.squashfs, then its version was '0.1.69', so the newly created version should be renamed to include a version of '0.1.69-1' with an additional dash and a build iteration number of 1. This will help to track what base version was used.

   ```bash
   pit# ls -l old/*squashfs
   -rw-r--r--  1 root root 5135859712 Aug 19 19:10 kubernetes-0.1.69.squashfs
   ```

   Set the VERSION variable based on the version string displayed by the above command.

   ```bash
   pit# VERSION=0.1.69-1
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

The Kubernetes image will have the new password for the next boot.

### Ceph Image

The Ceph image is used by the utility storage nodes.

1. Change to the working directory for the Kubernetes image.

   ```bash
   pit# cd /var/www/ephemeral/data/k8s
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

1. Change into the image root

   ```bash
   pit# chroot ./squashfs-root
   ```

1. Change the password

   ```bash
   chroot-pit# passwd
   ```

1. Replace the ssh keys

   ```bash
   chroot-pit# cd root
   ```

1. Replace the default root public and private ssh keys with your own or generate a new pair with `ssh-keygen(1)`

1. Create the new SquashFS artifact

   ```bash
   chroot-pit# /srv/cray/scripts/common/create-kis-artifacts.sh
   ```

1. Exit the chroot

   ```bash
   chroot-pit# exit
   ```

1. Clean up the SquashFS creation

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

1. Update file permissions on initrd

   ```bash
   pit# chmod -v 644 initrd.img.xz
   ```

1. Rename the new squashfs, kernel, and initrd to include a new version string.

   If the old name of the squashfs was storage-ceph-0.1.69.squashfs, then its version was '0.1.69', so the newly created version should be renamed to include a version of '0.1.69-1' with an additional dash and a build iteration number of 1. This will help to track what base version was used.

   ```bash
   pit# ls -l old/*squashfs
   -rw-r--r--  1 root root 5135859712 Aug 19 19:10 storage-ceph-0.1.69.squashfs
   ```

   Set the VERSION variable based on the version string displayed by above command.

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

The Ceph image will have the new password for the next boot.
