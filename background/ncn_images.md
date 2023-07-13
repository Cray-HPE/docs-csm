# NCN Images

* [Overview of NCN images](#overview-of-ncn-images)
* [LiveCD server](#livecd-server)

## Overview of NCN images

The management non-compute nodes (NCNs) boot from images which are created from layers on top of a common base image.
The common image is customized with a `kubernetes` layer for the master nodes and worker nodes.
The common image is customized with a `storage-ceph` layer for the utility storage nodes.

When booting NCNs, an administrator will need to choose between stable (Release) and unstable (pre-release/development) images.

In short, each image (for instance, `kubernetes` and `storage-ceph`) inherit from the non-compute-common layer. Operationally, these are all
that matter; the common layer, Kubernetes layer, Ceph layer, and any other new images.

To boot an NCN, there are three required artifacts for each node-type (`kubernetes-master/worker`, `storage-ceph`):

1. The Kubernetes SquashFS (stable or unstable)

   * `initrd.img-[RELEASE]-[ARCH].xz`
   * `$version-[RELEASE]-[ARCH].kernel`
   * `kubernetes-[RELEASE]-[ARCH].squashfs`

1. The CEPH SquashFS (stable or unstable)

   * `initrd.img-[RELEASE].xz`
   * `$version-[RELEASE].kernel`
   * `storage-ceph-[RELEASE]-[ARCH].squashfs`

## LiveCD server

1. (`pit#`) View the current ephemeral data payload:

   ```bash
   ls -l /var/www
   ```

   Expected output (on a new PIT without any boot links created):

   ```text
   total 8
   drwxr-xr-x 1 dnsmasq tftp 4096 Dec 17 21:20 boot
   drwxr-xr-x 7 root    root 4096 Dec  2 04:45 ephemeral
   ```

   ```bash
   ls -l /var/www/ephemeral/data/*
   ```

   Expected output:

   ```text
   /var/www/ephemeral/data/ceph:
   total 4
   drwxr-xr-x 2 root root 4096 Dec 17 21:42 0.3.33

   /var/www/ephemeral/data/k8s:
   total 4
   drwxr-xr-x 2 root root 4096 Dec 17 21:26 0.3.33
   ```

1. (`pit#`) Setup the "booting repositories":

   ```bash
   /root/bin/set-sqfs-links.sh
   ```

   Expected output:

   ```text
   Resolving images to boot ...
   Images resolved
   Kubernetes Boot Selection:
   kernel: /var/www/ephemeral/data/k8s/fe775c6-1659395320990/5.3.18-150300.59.76-default-fe775c6-1659395320990-x86_64.kernel
   initrd: /var/www/ephemeral/data/k8s/fe775c6-1659395320990/initrd.img-fe775c6-1659395320990-x86_64.xz
   squash: /var/www/ephemeral/data/k8s/fe775c6-1659395320990/secure-kubernetes-fe775c6-1659395320990-x86_64.squashfs
   Storage Boot Selection:
   kernel: /var/www/ephemeral/data/ceph/fe775c6-1659395320990/5.3.18-150300.59.76-default-fe775c6-1659395320990-x86_64.kernel
   initrd: /var/www/ephemeral/data/ceph/fe775c6-1659395320990/initrd.img-fe775c6-1659395320990-x86_64.xz
   squash: /var/www/ephemeral/data/ceph/fe775c6-1659395320990/secure-storage-ceph-fe775c6-1659395320990-x86_64.squashfs
   Attempting to set all known BMCs (from /etc/conman.conf) to DHCP mode
   current BMC count: 0
   Waiting on 9 to request DHCP ...
   Waiting on 9 to request DHCP ...
   Waiting on 9 to request DHCP ...
   All [9] expected BMCs have requested DHCP.
   /root/bin/set-sqfs-links.sh is creating boot directories for each NCN with a BMC that has a lease in /var/lib/misc/dnsmasq.leases
   NOTE: Nodes without boot directories will still boot the non-destructive iPXE binary for bare-metal discovery usage.
   WARNING: CSM_RELEASE was not set, images will be stored in their default location on the node(s) at /run/initramfs/live/LiveOS/
   /var/www is ready.
   ```

1. (`pit#`) View the currently set links.

   ```bash
   ls -l /var/www/ncn-*
   ```

   Expected output:

   ```bash
   ncn-m001:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 rootfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8-x86_64.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8-x86_64.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8-x86_64.kernel

   ncn-m002:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 rootfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8-x86_64.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8-x86_64.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8-x86_64.kernel

   ncn-m003:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 rootfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8-x86_64.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8-x86_64.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8-x86_64.kernel

   ncn-s001:
   total 4
   lrwxrwxrwx 1 root root 56 Dec 26 06:11 rootfs -> ../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7-x86_64.squashfs
   lrwxrwxrwx 1 root root 48 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz
   lrwxrwxrwx 1 root root 62 Dec 26 06:11 kernel -> ../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel

   ncn-s002:
   total 4
   lrwxrwxrwx 1 root root 56 Dec 26 06:11 rootfs -> ../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7-x86_64.squashfs
   lrwxrwxrwx 1 root root 48 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz
   lrwxrwxrwx 1 root root 62 Dec 26 06:11 kernel -> ../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel

   ncn-s003:
   total 4
   lrwxrwxrwx 1 root root 56 Dec 26 06:11 rootfs -> ../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7-x86_64.squashfs
   lrwxrwxrwx 1 root root 48 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz
   lrwxrwxrwx 1 root root 62 Dec 26 06:11 kernel -> ../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel

   ncn-w002:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 rootfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8-x86_64.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8-x86_64.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8-x86_64.kernel

   ncn-w003:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 rootfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8-x86_64.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8-x86_64.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8-x86_64.kernel
   ```
