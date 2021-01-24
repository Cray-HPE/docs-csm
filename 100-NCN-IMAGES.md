# Non-Compute Node Images

There are several flavors of NCN images, each share a common base image. When booting NCNs an admin or user will need to choose between
stable (Release) and unstable (pre-release/dev) images.

> For details on how these images behave and inherit from the base and common images, see [node-image-docs][1].

In short, each application image (i.e. kubernetes and storage-ceph) inherit from the non-compute-common layer. Operationally these are all
that matter; the common layer, kubernetes layer, ceph layer, and any other new application images.

To boot an NCN, you need 3 artifacts for each node-type (kubernetes-manager/worker, ceph):

1. The Kubernetes SquashFS ([stable][4] or [unstable][5])
    - `initrd-img-[RELEASE].xz`
    - `$version-[RELEASE].kernel`
    - `kubernetes-[RELEASE].squashfs`
2. The CEPH SquashFS ([stable][6] or [unstable][7])
    - `initrd-img-[RELEASE].xz`
    - `$version-[RELEASE].kernel`
    - `storage-ceph-[RELEASE].squashfs`

For information on pulling and swapping other NCN images, see [107-NCN-DEVEL](107-NCN-DEVEL.md).

### LiveCD Server

View the current ephemeral data payload:

```bash
pit:~ # ll /var/www
total 8
drwxr-xr-x 1 dnsmasq tftp 4096 Dec 17 21:20 boot
drwxr-xr-x 7 root    root 4096 Dec  2 04:45 ephemeral
pit:~ # ll /var/www/ephemeral/data/*
/var/www/ephemeral/data/ceph:
total 4
drwxr-xr-x 2 root root 4096 Dec 17 21:42 0.0.7

/var/www/ephemeral/data/k8s:
total 4
drwxr-xr-x 2 root root 4096 Dec 17 21:26 0.0.8
```

Setup the "booting repos":
```bash
pit:~ # set-sqfs-links.sh
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

Viewing the currently set links
```bash
-pit: # ll /var/www/ncn-*
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
