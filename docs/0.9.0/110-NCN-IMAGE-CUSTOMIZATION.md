# NCN Image Customization

The LiveCD is equipped for "re-squashing" an SquashFS images.

* [Boot Customization](#boot-customization)
    * [Set the Default Password](#set-the-default-password)
* [Image Layer Pipeline](#image-layer-pipeline)


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
