# NCN Images

* [Overview of NCN images](#overview-of-ncn-images)
* [LiveCD server](#livecd-server)

<a name="overview_ncn_images"></a>

## Overview of NCN images

The management non-compute nodes (NCNs) boot from images which are created from layers on top of a common base image.
The common image is customized with a `kubernetes` layer for the master nodes and worker nodes.
The common image is customized with a `storage-ceph` layer for the utility storage nodes.

When booting NCNs, an administrator will need to choose between stable (Release) and unstable (pre-release/development) images.

In short, each image (i.e. Kubernetes and `storage-ceph`) inherit from the non-compute-common layer. Operationally these are all
that matter; the common layer, Kubernetes layer, Ceph layer, and any other new images.

To boot an NCN, there are three required artifacts for each node-type (`kubernetes-master/worker`, `storage-ceph`):

1. The Kubernetes SquashFS (stable or unstable)

   * `initrd.img-[RELEASE].xz`
   * `$version-[RELEASE].kernel`
   * `kubernetes-[RELEASE].squashfs`

1. The CEPH SquashFS (stable or unstable)

   * `initrd.img-[RELEASE].xz`
   * `$version-[RELEASE].kernel`
   * `storage-ceph-[RELEASE].squashfs`

<a name="livecd_server"></a>

## LiveCD Server

1. View the current ephemeral data payload:

   ```bash
   pit# ls -l /var/www
   ```

   Example output:

   ```text
   total 8
   drwxr-xr-x 1 dnsmasq tftp 4096 Dec 17 21:20 boot
   drwxr-xr-x 7 root    root 4096 Dec  2 04:45 ephemeral
   ```

   ```bash
   pit# ls -l /var/www/ephemeral/data/*
   ```

   Example output:

   ```text
   /var/www/ephemeral/data/ceph:
   total 4
   drwxr-xr-x 2 root root 4096 Dec 17 21:42 0.0.7

   /var/www/ephemeral/data/k8s:
   total 4
   drwxr-xr-x 2 root root 4096 Dec 17 21:26 0.0.8
   ```

1. Setup the "booting repositories":

   ```bash
   pit# set-sqfs-links.sh
   ```

   Example output:

   ```text
   Mismatching kernels! The discovered artifacts will deploy an undesirable stack.
   mkdir: created directory 'ncn-m001'
   /var/www/ncn-m001 /var/www
   'kernel' -> '../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel'
   'initrd.img.xz' -> '../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz'
   'filesystem.squashfs' -> '../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs'
   /var/www
   mkdir: created directory 'ncn-m002'
   /var/www/ncn-m002 /var/www
   'kernel' -> '../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel'
   'initrd.img.xz' -> '../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz'
   'filesystem.squashfs' -> '../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs'
   /var/www
   mkdir: created directory 'ncn-m003'
   /var/www/ncn-m003 /var/www
   'kernel' -> '../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel'
   'initrd.img.xz' -> '../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz'
   'filesystem.squashfs' -> '../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs'
   /var/www
   mkdir: created directory 'ncn-w002'
   /var/www/ncn-w002 /var/www
   'kernel' -> '../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel'
   'initrd.img.xz' -> '../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz'
   'filesystem.squashfs' -> '../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs'
   /var/www
   mkdir: created directory 'ncn-w003'
   /var/www/ncn-w003 /var/www
   'kernel' -> '../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel'
   'initrd.img.xz' -> '../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz'
   'filesystem.squashfs' -> '../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs'
   /var/www
   mkdir: created directory 'ncn-s001'
   /var/www/ncn-s001 /var/www
   'kernel' -> '../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel'
   'initrd.img.xz' -> '../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz'
   'filesystem.squashfs' -> '../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7.squashfs'
   /var/www
   mkdir: created directory 'ncn-s002'
   /var/www/ncn-s002 /var/www
   'kernel' -> '../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel'
   'initrd.img.xz' -> '../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz'
   'filesystem.squashfs' -> '../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7.squashfs'
   /var/www
   mkdir: created directory 'ncn-s003'
   /var/www/ncn-s003 /var/www
   'kernel' -> '../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel'
   'initrd.img.xz' -> '../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz'
   'filesystem.squashfs' -> '../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7.squashfs'
   /var/www
   ```

1. View the currently set links.

   ```bash
   pit# ls -l /var/www/ncn-*
   ```

   Example output:

   ```text
   boot:
   total 1552
   -rw-r--r-- 1 root    root 166634 Dec 17 13:21 graffiti.png
   -rw-r--r-- 1 dnsmasq tftp 700480 Dec 17 13:25 ipxe.efi
   -rw-r--r-- 1 dnsmasq tftp 700352 Dec 15 09:35 ipxe.efi.stable
   -rw-r--r-- 1 root    root   6157 Dec 15 05:12 script.ipxe
   -rw-r--r-- 1 root    root   6284 Dec 17 13:21 script.ipxe.rpmnew

   ephemeral:
   total 32
   drwxr-xr-x 2 root root  4096 Dec  6 22:18 configs
   drwxr-xr-x 4 root root  4096 Dec  7 04:29 data
   drwx------ 2 root root 16384 Dec  2 04:25 lost+found
   drwxr-xr-x 4 root root  4096 Dec  3 02:31 prep
   drwxr-xr-x 2 root root  4096 Dec  2 04:45 static

   ncn-m001:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel

   ncn-m002:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel

   ncn-m003:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel

   ncn-s001:
   total 4
   lrwxrwxrwx 1 root root 56 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7.squashfs
   lrwxrwxrwx 1 root root 48 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz
   lrwxrwxrwx 1 root root 62 Dec 26 06:11 kernel -> ../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel

   ncn-s002:
   total 4
   lrwxrwxrwx 1 root root 56 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7.squashfs
   lrwxrwxrwx 1 root root 48 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz
   lrwxrwxrwx 1 root root 62 Dec 26 06:11 kernel -> ../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel

   ncn-s003:
   total 4
   lrwxrwxrwx 1 root root 56 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/ceph/0.0.7/storage-ceph-0.0.7.squashfs
   lrwxrwxrwx 1 root root 48 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/ceph/0.0.7/initrd.img-0.0.7.xz
   lrwxrwxrwx 1 root root 62 Dec 26 06:11 kernel -> ../ephemeral/data/ceph/0.0.7/5.3.18-24.37-default-0.0.7.kernel

   ncn-w002:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel

   ncn-w003:
   total 4
   lrwxrwxrwx 1 root root 53 Dec 26 06:11 filesystem.squashfs -> ../ephemeral/data/k8s/0.0.8/kubernetes-0.0.8.squashfs
   lrwxrwxrwx 1 root root 47 Dec 26 06:11 initrd.img.xz -> ../ephemeral/data/k8s/0.0.8/initrd.img-0.0.8.xz
   lrwxrwxrwx 1 root root 61 Dec 26 06:11 kernel -> ../ephemeral/data/k8s/0.0.8/5.3.18-24.37-default-0.0.8.kernel
   ```
