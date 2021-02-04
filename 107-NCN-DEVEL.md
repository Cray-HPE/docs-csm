# NCN Development

This page will help you if you're trying to test new images on a metal system. Here you can
find a basic flow for iterative boots.

> We assume you are internally developing, these scripts are for internal use only.

1. Get your Image ID
    > `-k` for kubernetes, `-s` for storage/ceph

    ```bash
   pit:~ # /root/bin/get-sqfs.sh -k 9683117-1609280754169
   pit:~ # /root/bin/get-sqfs.sh -s c46624e-1609524120402
   ```

2. Set your Image IDs
    > This finds the newest pair, so it'll find the last downloaded set (i.e. your set of images). 
    ```bash
   pit:~ # /root/bin/set-sqfs-links.sh
   ```

3. (Re)boot the node(s) you want to test.

4. You can easily follow along using conman, run `conman -q` to see available consoles.


### Repacking Images

The LiveCD is equipped for resquashing the SquashFS images.

### Boot Customization

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

### Image Layer Pipeline

For more information on how the pipeline works, see the [node-image-docs](https://stash.us.cray.com/projects/CLOUD/repos/node-image-docs/browse).