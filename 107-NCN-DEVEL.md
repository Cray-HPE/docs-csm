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

### Image Layer Pipeline

For more information on how the pipeline works, see the [node-image-docs](https://stash.us.cray.com/projects/CLOUD/repos/node-image-docs/browse).