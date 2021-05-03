<h2 id="download-csi">Download hot new version of csi</h2>

1. Install the rpm:

   ```
   % rpm -Uhv http://car.dev.cray.com/artifactory/csm/MTL/sle15_sp2_ncn/x86_64/feature/1.5-upgrade/metal-team/cray-site-init-1.5.26-20210407180816_c508729.x86_64.rpm
   ```

<h2 id="upload-new-images-to-s3">Upload new NCN images to S3</h2>

1. Create some directories on the same node we've installed the new csi binary.

   ```
   % export CSM_RELEASE=csm-1.0.0
   % export artdir=/var/www/ephemeral/${CSM_RELEASE}/images
   % mkdir -p $artdir/kubernetes
   % mkdir -p $artdir/storage-ceph
   ```

2. `wget` the new images:

   ```
   % cd $artdir/kubernetes

   % wget https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/kubernetes/bc49327-1617059196409/5.3.18-24.52-default-bc49327-1617059196409.kernel https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/kubernetes/bc49327-1617059196409/initrd.img-bc49327-1617059196409.xz https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/kubernetes/bc49327-1617059196409/kubernetes-bc49327-1617059196409.squashfs

   % cd $artdir/storage-ceph

   % wget https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/storage-ceph/3ffdbeb-1617285108240/initrd.img-3ffdbeb-1617285108240.xz https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/storage-ceph/3ffdbeb-1617285108240/5.3.18-24.52-default-3ffdbeb-1617285108240.kernel https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/storage-ceph/3ffdbeb-1617285108240/storage-ceph-3ffdbeb-1617285108240.squashfs
   ```

3. Upload the images to S3 using csi:

   ```
   % csi handoff ncn-images \
      --kubeconfig /etc/kubernetes/admin.conf \
      --k8s-kernel-path $artdir/kubernetes/*.kernel \
      --k8s-initrd-path $artdir/kubernetes/initrd.img*.xz \
      --k8s-squashfs-path $artdir/kubernetes/kubernetes*.squashfs \
      --ceph-kernel-path $artdir/storage-ceph/*.kernel \
      --ceph-initrd-path $artdir/storage-ceph/initrd.img*.xz \
      --ceph-squashfs-path $artdir/storage-ceph/storage-ceph*.squashfs
   ```

<h2 id="add-new-ceph-docker-image-to-nexus">Add new ceph docker image to nexus</h2>

1. Ensure we can resolve dtr.dev.cray.com.  Might need to add this entry to `/etc/hosts` if unable to ping dtr.dev.cray.com.

   ```
   172.29.30.54  dtr.dev.cray.com
   ```
2. Define a shell `sync` function:

   ```
   sync() { skopeo copy --dest-tls-verify=false  docker://dtr.dev.cray.com/$1 docker://registry.local/$1 ; }
   ```
3. Install skopeo (TEMPORARY -- NEED A SOLUTION THAT WORKS IN AIRGAP)

   ```
   zypper --no-gpg-checks --non-interactive in skopeo
   ```
4. Sync the new ceph image to nexus:

   ```
   sync ceph/ceph:v15.2.8
   ```

[Back to Main Page](../../README.md)
