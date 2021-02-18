# NCN Image Customization

The LiveCD is equipped for "re-squashing" an SquashFS images.

* [Boot Customization](#boot-customization)
    * [Set the Default Password](#set-the-default-password)
* [Image Layer Pipeline](#image-layer-pipeline)


<a name="boot-customization"></a>
### Boot Customization


<a name="set-the-default-password"></a>
#### Set the Default Password

_Using kubernetes as an example._

1. Open the image, ours is called `k8s-filesystem.squashfs`.
   ```bash
   pit:~ # cd /var/www/ephemeral/data/k8s
   pit:/var/www/ephemeral/data/k8s # unsquash k8s-filesystem.squashfs
   ```
2. Change into the image root
   ```bash
   chroot ./squashfs-root
   ```
3. Change the password
   ```bash
   ncn:~ # passwd
   ```
4. Create the new squashFS artifact
   ```bash
   ncn:~ # /srv/cray/scripts/common/create-kis-artifacts.sh
   ```
5. Exit the chroot
   ```bash
   /srv/cray/scripts/common/create-kis-artifacts.sh
   ```
6. Cleanup the squash creation
   ```bash
   umount /var/www/ephemeral/data/k8s/squasfs-root/squashfs
   ```
7. Set boot links
   ```bash
   pit:/var/www/ephemeral/data/k8s # set-sqfs-links.sh   
   ```

Now the next boot your images will have the new password for the next boot.

<a name="image-layer-pipeline"></a>
### Image Layer Pipeline

For more information on how the pipeline works, see the [node-image-docs](https://stash.us.cray.com/projects/CLOUD/repos/node-image-docs/browse).