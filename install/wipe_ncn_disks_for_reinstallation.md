# Wipe NCN Disks for Reinstallation

This page will detail how disks to wipe NCN disks.

> **Everything in this section should be considered DESTRUCTIVE**.

After following these procedures an NCN can be rebooted and redeployed.

All types of disk wipe can be run from Linux or an initramFS/initrd emergency shell.

The following are potential use cases for wiping disks:

<a name="use-cases"></a>
   * Adding a node that is not bare.
   * Adopting new disks that are not bare.
   * Doing a fresh install.

## Topics:
   1. [Basic Wipe](#basic-wipe)
   1. [Advanced Wipe](#advanced-wipe)
   1. [Full Wipe](#full-wipe)

<a name="basic-wipe"></a>
## 1. Basic Wipe

A basic wipe includes wiping the disks and all of the RAIDs. These basic wipe instructions can be
executed on **any management nodes** (master, worker, and storage).

1. List the disks for verification.

    ```bash
    ncn# ls -1 /dev/sd* /dev/disk/by-label/*
    ```

1. Wipe the disks and the RAIDs.

    ```bash
    ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
    ```

    If any disks had labels present, output looks similar to the following:

    ```
    /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdb: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
    /dev/sdb: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
    /dev/sdc: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdc: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdc: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    ```

    Verify there are no error messages in the output.

    The `wipefs` command may fail if no labeled disks are found, which is an indication of a larger problem.

<a name="advanced-wipe"></a>
## 2. Advanced Wipe

This section is specific to utility storage nodes. An advanced wipe includes deleting the Ceph volumes and then
wiping the disks and RAIDs.

1. Delete Ceph volumes.

    ```bash
    ncn-s# systemctl stop ceph-osd.target
    ```

    Make sure the OSDs (if any) are not running after running the first command.

    ```bash
    ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
    ncn-s# vgremove -f -v --select 'vg_name=~ceph*'
    ```

1. List the disks for verification.

    ```bash
    ncn# ls -1 /dev/sd* /dev/disk/by-label/*
    ```

1. Wipe the disks and RAIDs.

    ```bash
    ncn-s# wipefs --all --force /dev/sd* /dev/disk/by-label/*
    ```

    See [Basic Wipe](#basic-wipe) section for expected output from the `wipefs` command.

<a name="full-wipe"></a>
### 3. Full-Wipe

This section is the preferred method for all nodes. A full wipe includes deleting the Ceph volumes (where applicable), stopping the
RAIDs, zeroing the disks, and then wiping the disks and RAIDs.

**IMPORTANT:** Pay attention to whether the command is to be run on a worker node, master node, or storage node.
If a node type is not specified, the step should be run regardless of node type.

1. Reset Kubernetes **on worker nodes ONLY**.

   This will stop kubelet, underlying containers, and remove the contents of `/var/lib/kubelet`.

   1. Reset Kubernetes.
        ```bash
        ncn-w# kubeadm reset --force
        ```

   1. List any containers running in `containerd`.

        ```bash
        ncn-w# crictl ps
        CONTAINER           IMAGE               CREATED              STATE               NAME                                                ATTEMPT             POD ID
        66a78adf6b4c2       18b6035f5a9ce       About a minute ago   Running             spire-bundle                                        1212                6d89f7dee8ab6
        7680e4050386d       c8344c866fa55       24 hours ago         Running             speaker                                             0                   5460d2bffb4d7
        b6467c907f063       8e6730a2b718c       3 days ago           Running             request-ncn-join-token                              0                   a3a9ca9e1ca78
        e8ce2d1a8379f       64d4c06dc3fb4       3 days ago           Running             istio-proxy                                         0                   6d89f7dee8ab6
        c3d4811fc3cd0       0215a709bdd9b       3 days ago           Running             weave-npc                                    0                   f5e25c12e617e
        ```

    1. If there are any running containers from the output of the `crictl ps` command, stop them.

        ```bash
        ncn-w# crictl stop <container id from the CONTAINER column>
        ```

1. Reset Kubernetes **on master nodes ONLY**.

    This will stop kubelet, underlying containers, and remove the contents of `/var/lib/kubelet`.

    1.  Reset Kubernetes.

        ```bash
        ncn-m# kubeadm reset --force
        ```

   1. List any containers running in `containerd`.

       ```bash
       ncn-m# crictl ps
       CONTAINER           IMAGE               CREATED              STATE               NAME                                                ATTEMPT             POD ID
       66a78adf6b4c2       18b6035f5a9ce       About a minute ago   Running             spire-bundle                                        1212                6d89f7dee8ab6
       7680e4050386d       c8344c866fa55       24 hours ago         Running             speaker                                             0                   5460d2bffb4d7
       b6467c907f063       8e6730a2b718c       3 days ago           Running             request-ncn-join-token                              0                   a3a9ca9e1ca78
       e8ce2d1a8379f       64d4c06dc3fb4       3 days ago           Running             istio-proxy                                         0                   6d89f7dee8ab6
       c3d4811fc3cd0       0215a709bdd9b       3 days ago           Running             weave-npc                                    0                   f5e25c12e617e
       ```

   1. If there are any running containers from the output of the `crictl ps` command, stop them.

       ```bash
       ncn-m# crictl stop <container id from the CONTAINER column>
       ```

1. Delete Ceph Volumes **on utility storage nodes ONLY**.

    1. For each storage node:

       1. Stop Ceph.

           * ***1.4 or earlier***

               ```bash
               ncn-s# systemctl stop ceph-osd.target
               ```

           * ***1.5 or later***

               ```bash
               ncn-s# cephadm rm-cluster --fsid $(cephadm ls|jq -r '.[0].fsid') --force
               ```

       1. Make sure the OSDs (if any) are not running.

           * ***1.4 or earlier***

               ```bash
               ncn-s# ps -ef|grep ceph-osd
               ```

           * ***1.5 or later***

               ```bash
               ncn-s# podman ps
               ```

           Examine the output. There should be no running `ceph-osd` processes or containers.

       1. Remove the VGs.

           ```bash
           ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
           ncn-s# vgremove -f -v --select 'vg_name=~ceph*'
           ```

1. Unmount volumes.

    > **NOTE:** Some of the following `umount` commands may fail or have warnings depending on the state of the NCN. Failures in this section can be ignored and will not inhibit the wipe process.

    > **NOTE:** There is an edge case where the overlay may keep the drive from being unmounted. If this is a rebuild, ignore this.

    * Master nodes

        Stop the etcd service on the master node before unmounting /var/lib/etcd

        ```bash
        ncn-m# systemctl stop etcd.service
        ncn-m# umount -v /run/lib-etcd /var/lib/etcd /var/lib/sdu /var/opt/cray/sdu/collection-mount /var/lib/admin-tools /var/lib/s3fs_cache /var/lib/containerd
        ```

    * Worker nodes

        ```bash
        ncn-w# umount -v /var/lib/kubelet /var/lib/sdu /run/containerd /var/lib/containerd /run/lib-containerd /var/opt/cray/sdu/collection-mount /var/lib/admin-tools /var/lib/s3fs_cache /var/lib/containerd
        ```

    * Storage nodes

        ```bash
        ncn-s# umount -vf /var/lib/ceph /var/lib/containers /etc/ceph /var/opt/cray/sdu/collection-mount /var/lib/admin-tools /var/lib/s3fs_cache /var/lib/containerd
        ```

        If the `umount` command is responding with `target is busy` on the storage node, then try the following:

        ```bash
        ncn-s# mount | grep "containers"
        /dev/mapper/metalvg0-CONTAIN on /var/lib/containers type xfs (rw,noatime,swalloc,attr2,largeio,inode64,allocsize=131072k,logbufs=8,logbsize=32k,noquota)
        /dev/mapper/metalvg0-CONTAIN on /var/lib/containers/storage/overlay type xfs (rw,noatime,swalloc,attr2,largeio,inode64,allocsize=131072k,logbufs=8,logbsize=32k,noquota)

        ncn-s# umount -v /var/lib/containers/storage/overlay
        umount: /var/lib/containers/storage/overlay unmounted

        ncn-s# umount -v /var/lib/containers
        umount: /var/lib/containers unmounted
        ```

1. Stop `cray-sdu-rda`.

    1. Stop `cray-sdu-rda` container if necessary.

        ```bash
        ncn# podman ps
        CONTAINER ID  IMAGE                                                      COMMAND               CREATED      STATUS          PORTS   NAMES
        7741d5096625  registry.local/sdu-docker-stable-local/cray-sdu-rda:1.1.1  /bin/sh -c /usr/s...  6 weeks ago  Up 6 weeks ago          cray-sdu-rda
        ```

    1. If there is a running `cray-sdu-rda` container in the above output, stop it using the container ID:

        ```bash
        ncn# podman stop 7741d5096625
        7741d50966259410298bb4c3210e6665cdbd57a82e34e467d239f519ae3f17d4
        ```

1. Remove etcd device **on master nodes ONLY**.

    1. This `dmsetup` command will determine whether an etcd volume is present.

        ```bash
        ncn-m# dmsetup ls
        ```

        Expected output when the etcd volume is present will show `ETCDLVM`, but the numbers might be different.

        ```bash
        ETCDLVM (254:1)
        ```

    1. This `dmsetup` command will remove the etcd device mapper.

        ```bash
        ncn-m# dmsetup remove $(dmsetup ls | grep -i etcd | awk '{print $1}')
        ```

        > **NOTE:** The following output means the etcd volume mapper is not present.
        ```bash
        No device specified.
        Command failed.
        ```

1. Remove etcd volumes **on master nodes ONLY**.

    ```bash
    ncn-m# vgremove etcdvg0
    ```

1. Remove metal LVM.

    ```bash
    ncn# vgremove -f -v --select 'vg_name=~metal*'
    ```

    > **NOTE:** Optionally, run the `pvs` command. If any drives are still listed, remove them with `pvremove`, but this is rarely needed. Also, if the above command fails or returns a warning about the filesystem being in use, ignore the error and proceed to the next step, as this will not inhibit the wipe process.

1. Group these commands together for each node.

    This group of commands should be done in succession on one node before moving to do the same set of commands on the next node. The nodes would be addressed in descending order for each type of node. Start with the utility storage nodes, then the worker nodes, then `ncn-m003`, then `ncn-m002`.

    > **WARNING:** Do not run these commands on `ncn-m001`
    1. List the disks for verification.

        ```bash
        ncn# ls -1 /dev/sd* /dev/disk/by-label/*
        ```

    1. Wipe the disks and RAIDs.

        ```bash
        ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
        ```

        If any disks had labels present, output from `wipefs` looks similar to the following:

        ```
        /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
        /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
        /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
        /dev/sdb: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
        /dev/sdb: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
        /dev/sdc: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
        /dev/sdc: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
        /dev/sdc: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
        ```

        Verify there are no error messages in the output.

        The `wipefs` command may fail if no labeled disks are found, which is an indication of a larger problem.

        See [Basic Wipe](#basic-wipe) section for expected output from the `wipefs` command.

