# Wipe NCN Disks for Reinstallation

This page will detail how disks are wiped and includes workarounds for wedged disks.
Any process covered on this page will be covered by the installer.

> **Everything in this section should be considered DESTRUCTIVE**.

After following these procedures an NCN can be rebooted and redeployed.

Ideally the Basic Wipe is enough, and should be tried first. All types of disk wipe can be run from Linux or an initramFS/initrd emergency shell. 

The following are potential use cases for wiping disks:

<a name="use-cases"></a>
   * Adding a node that is not bare.
   * Adopting new disks that are not bare.
   * Doing a fresh install.


### Topics:
   1. [Basic Wipe](#basic-wipe)
   1. [Advanced Wipe](#advanced-wipe)
   1. [Full Wipe](#full-wipe)

## Details

<a name="basic-wipe"></a>
### 1. Basic Wipe

A basic wipe includes wiping the disks and all of the RAIDs. These basic wipe instructions can be
executed on **any management nodes** (master, worker and storage).

1. List the disks for verification:

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
### 2. Advanced Wipe

This section is specific to utility storage nodes. An advanced wipe includes deleting the Ceph volumes and then
wiping the disks and RAIDs.

1. Delete CEPH Volumes

   ```bash
   ncn-s# systemctl stop ceph-osd.target
   ```

   Make sure the OSDs (if any) are not running after running the first command.

   ```bash
   ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
   ncn-s# vgremove -f --select 'vg_name=~ceph*'
   ```

1. Wipe the disks and RAIDs.

   ```bash
   ncn-s# wipefs --all --force /dev/sd* /dev/disk/by-label/*
   ```

See [Basic Wipe](#basic-wipe) section for expected output from the wipefs command.

<a name="full-wipe"></a>
### 3. Full-Wipe

This section is the preferred method for all nodes. A full wipe includes deleting the Ceph volumes (where applicable), stopping the
RAIDs, zeroing the disks, and then wiping the disks and RAIDs.

**IMPORTANT:** Step 2 is to wipe the Ceph OSD drives. ***Steps 1, 3, 4, and 5 are for all node types.***

1. Reset Kubernetes on each master and worker node

   ***NOTE:*** Our recommended order is to do this on the workers then the master nodes

   1. For each worker node, log in and run:

       ```bash
       ncn-m/w# kubeadm reset --force
       ```

   1. Verify that no containers are running in containerd

       ```bash
       ncn-m/w # crictl ps
       CONTAINER           IMAGE               CREATED              STATE               NAME                                                ATTEMPT             POD ID
       66a78adf6b4c2       18b6035f5a9ce       About a minute ago   Running             spire-bundle                                        1212                6d89f7dee8ab6
       7680e4050386d       c8344c866fa55       24 hours ago         Running             speaker                                             0                   5460d2bffb4d7
       b6467c907f063       8e6730a2b718c       3 days ago           Running             request-ncn-join-token                              0                   a3a9ca9e1ca78
       e8ce2d1a8379f       64d4c06dc3fb4       3 days ago           Running             istio-proxy                                         0                   6d89f7dee8ab6
       c3d4811fc3cd0       0215a709bdd9b       3 days ago           Running             weave-npc                                    0                   f5e25c12e617e
      ```

   1. Stop any running containers from the output of our `crictl ps` command

      ***NOTE:*** There should be no containers.

      ```bash
      ncn-m/w #crictl stop <container id from the CONTAINER column>
      ```

   This will stop kubelet, underlying containers, and remove the contents of `/var/lib/kubelet`

1. Delete CEPH Volumes ***on Utility Storage Nodes ONLY***

   For Each Storage node:

    1. Stop CEPH

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

        Examine the output. There should be no running ceph-osd processes or containers.

    1. Remove the VGs.

        ```bash
        ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
        ncn-s# vgremove -f --select 'vg_name=~ceph*'
        ```

1. Unmount volumes

   > **`NOTE`** Some of the following umount commands may fail or have warnings depending on the state of the NCN. Failures in this section can be ignored and will not inhibit the wipe process.
   >
   > **`NOTE:`** There is an edge case where the overlay may keep you from unmounting the drive. If this is a rebuild you ignore this or go here.

   1. Storage nodes

       ```bash
       ncn-s# umount -vf /var/lib/ceph /var/lib/containers /etc/ceph
       ```

   1. Master nodes

       ```bash
       ncn-m# umount -v /var/lib/etcd /var/lib/sdu
       ```

   1. Worker nodes

      ```bash
      ncn-w# umount -v /var/lib/containerd /var/lib/kubelet /var/lib/sdu
      ```

   Troubleshooting Unmount on a Storage node

   1. If the umount command is responding with `target is busy` then try the following

      ```bash
      ncn-s:~ # mount | grep "containers"

      /dev/mapper/metalvg0-CONTAIN on /var/lib/containers type xfs (rw,noatime,swalloc,attr2,largeio,inode64,allocsize|
      32k,noquota)
      /dev/mapper/metalvg0-CONTAIN on /var/lib/containers/storage/overlay type xfs (rw,noatime,swalloc,attr2,largeio,i|
      bufs=8,logbsize=32k,noquota)

      ncn-s001:~ # umount -v /var/lib/containers/storage/overlay
      umount: /var/lib/containers/storage/overlay unmounted

      ncn-s001:~ # umount -v /var/lib/containers
      umount: /var/lib/containers unmounted

1. Remove auxiliary LVMs

   1. Stop sdu container if necessary

      ```bash
      ncn# podman ps
      CONTAINER ID  IMAGE                                                      COMMAND               CREATED      STATUS          PORTS   NAMES
      7741d5096625  registry.local/sdu-docker-stable-local/cray-sdu-rda:1.1.1  /bin/sh -c /usr/s...  6 weeks ago  Up 6 weeks ago          cray-sdu-rda
      ```

      If there is a running `cray-sdu-rda` container in the above output, stop it using the container id:

      ```bash
      ncn# podman stop 7741d5096625
      7741d50966259410298bb4c3210e6665cdbd57a82e34e467d239f519ae3f17d4
      ```

   1. Remove metal LVM

      ```bash
      ncn# vgremove -f --select 'vg_name=~metal*'
      ```

      > **`NOTE`** Optionally you can run the `pvs` command and if any drives are still listed, you can remove them with `pvremove`, but this is rarely needed. Also, if the above command fails or returns a warning about the filesystem being in use, you should ignore the error and proceed to the next step, as this will not inhibit the wipe process.

1. Stop the RAIDs.

   ```bash
   ncn# for md in /dev/md/*; do mdadm -S $md || echo nope ; done
   ```

1. Wipe the disks and RAIDs.

   ```bash
   ncn# sgdisk --zap-all /dev/sd*
   ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
   ```

   **Note**: On worker nodes, it is a known issue that the sgdisk command sometimes encounters a hard hang. If you see no output from the command for 90 seconds, close the terminal session to the worker node, open a new terminal session to it, and complete the disk wipe procedure by running the above wipefs command.

   See [Basic Wipe](#basic-wipe) section for expected output from the wipefs command.

