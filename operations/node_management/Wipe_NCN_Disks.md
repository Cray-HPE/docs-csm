# Manual Wipe Procedures

This page details how to wipe disks on NCNs installed with the current version of CSM.

**Everything in this section should be considered DESTRUCTIVE**.

> ***NOTE*** All types of disk wipe can be run from Linux or from an emergency shell.

## Topics

- [Manual Wipe Procedures](#manual-wipe-procedures)
  - [Topics](#topics)
  - [Basic wipe](#basic-wipe)
  - [Advanced wipe](#advanced-wipe)
  - [Full wipe](#full-wipe)

## Basic wipe

This wipe erases the magic bits on the disk to prevent them from being recognized, as well as removing the common volume groups.

1. (`ncn#`) List the disks for verification.

    1. Set a variable by loading a helper library.

        - From the Linux command line, run the following command:

            ```bash
            source /usr/lib/dracut/modules.d/90metalmdsquash/metal-lib.sh
            ```

        - From the emergency shell, run the following command:

            ```bash
            . /lib/metal-lib.sh
            ```

    1. List the disks.

        ```bash
        disks_to_wipe=$(lsblk -l -o NAME,TYPE,TRAN | grep -E "[[:space:]].*(raid|${metal_transports})" |
                        awk '{ print "/dev/"$1 }' | sort -u | tr '\n' ' ')
        echo "${disks_to_wipe}"
        ```

1. (`ncn#`) Wipe the disks and the RAIDs.

    ```bash
    for disk in $disks_to_wipe; do
        wipefs --all --force ${disk}* 2> /dev/null
    done
    ```

    If any disks had labels present, then the output looks similar to the following:

    ```text
    /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdb: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
    /dev/sdb: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
    /dev/sdc: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdc: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdc: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    ```

    Verify that there are no error messages in the output.

    The `wipefs` command may fail if no labeled disks are found, which is an indication of a larger problem.

1. (`ncn#`) Remove the volume groups on all NCNs.

   > ***NOTE*** The Ceph volume group will only exist on storage nodes, but this code snippet will work on all NCNs.

    ```bash
    ceph_vgs='vg_name=~ceph*'
    metal_vgs='vg_name=~metal*'
    for volume_group in ${ceph_vgs} ${metal_vgs}; do
        vgremove -f -v --select "${volume_group}" -y >/dev/null 2>&1
    done
    ```

## Advanced wipe

An advanced wipe includes handling storage node specific items before running the [Basic wipe](#basic-wipe).

1. (`ncn-s#`) Stop Ceph on all of the storage nodes.

    - ***CSM 0.9 or earlier***

        ```bash
        systemctl stop ceph-osd.target
        ```

    - ***CSM 1.0 or later***

        ```bash
        cephadm rm-cluster --fsid $(cephadm ls|jq -r '.[0].fsid') --force
        ```

1. (`ncn-s#`) Make sure the OSDs (if any) are not running on the storage nodes.

    - ***CSM 0.9 or earlier***

        ```bash
        ps -ef|grep ceph-osd
        ```

    - ***CSM 1.0 or later***

        ```bash
        podman ps
        ```

    Examine the output. There should be no running `ceph-osd` processes or containers.

1. Perform the [Basic wipe](#basic-wipe) procedure.

## Full wipe

A full wipe cleanly stops all running services that require partitions, as well as
removing the node from the Ceph or Kubernetes cluster (as appropriate for the node type).

This does not zero disks; this will ensure that all disks look raw on the next reboot.

***IMPORTANT*** For each step, pay attention to whether the command is to be run on a master node, storage node, or worker node. If
wiping a different type of node than what a step specifies, then skip that step.

1. (`ncn-w#`) Reset Kubernetes **on worker nodes ONLY**.

   This will stop `kubelet`, stop underlying containers, and remove the contents of `/var/lib/kubelet`.

   1. Reset Kubernetes.

        ```bash
        kubeadm reset --force
        ```

   1. List any containers running in `containerd`.

        ```bash
        crictl ps
        ```

        Example output:

        ```text
        CONTAINER           IMAGE               CREATED              STATE               NAME                                                ATTEMPT             POD ID
        66a78adf6b4c2       18b6035f5a9ce       About a minute ago   Running             spire-bundle                                        1212                6d89f7dee8ab6
        7680e4050386d       c8344c866fa55       24 hours ago         Running             speaker                                             0                   5460d2bffb4d7
        b6467c907f063       8e6730a2b718c       3 days ago           Running             request-ncn-join-token                              0                   a3a9ca9e1ca78
        e8ce2d1a8379f       64d4c06dc3fb4       3 days ago           Running             istio-proxy                                         0                   6d89f7dee8ab6
        c3d4811fc3cd0       0215a709bdd9b       3 days ago           Running             weave-npc                                    0                   f5e25c12e617e
        ```

   1. If there are any running containers from the output of the `crictl ps` command, then stop them.

        ```bash
        crictl stop <container id from the CONTAINER column>
        ```

1. (`ncn-m#`) Reset Kubernetes **on master nodes ONLY**.

    This will stop `kubelet`, stop underlying containers, and remove the contents of `/var/lib/kubelet`.

    1. Reset Kubernetes.

        ```bash
        kubeadm reset --force
        ```

    1. List any containers running in `containerd`.

        ```bash
        crictl ps
        ```

        Example output:

        ```text
        CONTAINER           IMAGE               CREATED              STATE               NAME                                                ATTEMPT             POD ID
        66a78adf6b4c2       18b6035f5a9ce       About a minute ago   Running             spire-bundle                                        1212                6d89f7dee8ab6
        7680e4050386d       c8344c866fa55       24 hours ago         Running             speaker                                             0                   5460d2bffb4d7
        b6467c907f063       8e6730a2b718c       3 days ago           Running             request-ncn-join-token                              0                   a3a9ca9e1ca78
        e8ce2d1a8379f       64d4c06dc3fb4       3 days ago           Running             istio-proxy                                         0                   6d89f7dee8ab6
        c3d4811fc3cd0       0215a709bdd9b       3 days ago           Running             weave-npc                                    0                   f5e25c12e617e
        ```

    1. If there are any running containers from the output of the `crictl ps` command, then stop them.

       ```bash
       crictl stop <container id from the CONTAINER column>
       ```

1. (`ncn-s#`) Run the [Advanced wipe](#advanced-wipe), but stop when it mentions the "basic wipe". Then return here.

1. Unmount volumes.

    > **`NOTE`** Some of the following `umount` commands may fail or have warnings depending on the state of the NCN. Failures in this
    > section can be ignored and will not inhibit the wipe process.
    >
    > **`NOTE`** There is an edge case where the overlay may keep the drive from being unmounted. If this is a rebuild, ignore this.

    The exact commands used depends on the node type:

    - **Master nodes**

        Stop the `etcd` service on the master node before unmounting `/var/lib/etcd` and other mounts.

        ```bash
        systemctl stop etcd.service
        umount -v /run/lib-etcd /var/lib/etcd /var/lib/sdu /var/opt/cray/sdu/collection-mount /var/lib/admin-tools /var/lib/s3fs_cache /var/lib/containerd
        ```

    - **Storage nodes**

        ```bash
        umount -vf /var/lib/ceph /var/lib/containers /etc/ceph /var/opt/cray/sdu/collection-mount /var/lib/admin-tools /var/lib/s3fs_cache /var/lib/containerd
        ```

        If the `umount` command outputs `target is busy` on the storage node, then try the following:

        1. Look for `containers` mounts:

            ```bash
            mount | grep containers
            ```

            Example output:

            ```text
            /dev/mapper/metalvg0-CONTAIN on /var/lib/containers type xfs (rw,attr2,logbufs=8,logbsize=32k,noquota)
            /dev/mapper/metalvg0-CONTAIN on /var/lib/containers/storage/overlay type xfs (rw,attr2,logbufs=8,logbsize=32k,noquota)
            ```

        1. Unmount `/var/lib/containers/storage/overlay`.

            ```bash
            umount -v /var/lib/containers/storage/overlay
            ```

            Example output:

            ```text
            umount: /var/lib/containers/storage/overlay unmounted
            ```

        1. Unmount `/var/lib/containers`.

            ```bash
            umount -v /var/lib/containers
            ```

            Example output:

            ```text
            umount: /var/lib/containers unmounted
            ```

    - **Worker nodes**

        ```bash
        umount -v /var/lib/kubelet /var/lib/sdu /run/containerd /var/lib/containerd /run/lib-containerd /var/opt/cray/sdu/collection-mount /var/lib/admin-tools /var/lib/s3fs_cache /var/lib/containerd
        ```

1. (`ncn#`) Stop `cray-sdu-rda` on **all node types** (master, storage, or worker).

    1. See if any `cray-sdu-rda` containers are running.

        ```bash
        podman ps
        ```

        Example output:

        ```text
        CONTAINER ID  IMAGE                                                      COMMAND               CREATED      STATUS          PORTS   NAMES
        7741d5096625  registry.local/sdu-docker-stable-local/cray-sdu-rda:1.1.1  /bin/sh -c /usr/s...  6 weeks ago  Up 6 weeks ago          cray-sdu-rda
        ```

    1. If there is a running `cray-sdu-rda` container in the above output, then stop it using the container ID:

        ```bash
        podman stop 7741d5096625
        ```

        Example output:

        ```text
        7741d50966259410298bb4c3210e6665cdbd57a82e34e467d239f519ae3f17d4
        ```

1. (`ncn-m#`) Remove `etcd` device **on master nodes ONLY**.

    1. Determine whether or not an `etcd` volume is present.

        ```bash
        dmsetup ls
        ```

        Expected output when the `etcd` volume is present will show `ETCDLVM`, but the numbers might be different.

        ```text
        ETCDLVM (254:1)
        ```

    1. Remove the `etcd` device mapper.

        ```bash
        dmsetup remove $(dmsetup ls | grep -i etcd | awk '{print $1}')
        ```

        > **`NOTE`** The following output means that the `etcd` volume mapper is not present. This is okay.

        ```text
        No device specified.
        Command failed.
        ```

1. (`ncn-m#`) Remove `etcd` volumes **on master nodes ONLY**.

    ```bash
    vgremove etcdvg0
    ```

1. Perform the [Basic wipe](#basic-wipe) procedure.
