# Set NCN Image Root Password and SSH Keys and optional modify the timezone

Customize the NCN images by setting the root password and adding SSH keys for the root account. Optionally,
change the the timezone (UTC is the default).

This procedure shows this process being done any time after the first time installation of the CSM
software has been completed and the PIT node is booted as a regular master node. To change the NCN image
during an installation while the PIT node is booted as the PIT node,
see [Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node](Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md).

There is some common preparation before making the Kubernetes image for master nodes and worker nodes, making the Ceph image for utility storage nodes, and then some common cleanup afterwards.

***Note:*** This procedure can only be done after the PIT node is rebuilt to become a normal master node.

## Common Preparation

1. Prepare new SSH keys for the root account in advance. The same key information will be added to both `k8s-image` and `ceph-image`.

   Either replace the root public and private SSH keys with your own previously generated keys or generate a new pair using the `ncn-image-modification.sh` script described below.

1. Change to a working directory with enough space to hold the images once they have been expanded.

   ```bash
   ncn-m# cd /run/initramfs/overlayfs
   ncn-m# mkdir workingarea
   ncn-m# cd workingarea
   ```

The Kubernetes image `k8s-image` is used by the master and worker nodes.

1. Decide which `k8s-image` is to be modified

   ```bash
   ncn-m# cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep k8s | grep squashfs
   "k8s-filesystem.squashfs"
   "k8s/0.1.107/filesystem.squashfs"
   "k8s/0.1.109/filesystem.squashfs"
   "k8s/0.1.48/filesystem.squashfs"
   ```

   This example uses k8s/0.1.109 for the current version and adds a suffix for the new version.

   ```bash
   ncn-m# export K8SVERSION=0.1.109
   ncn-m# export K8SNEW=0.1.109-2
   ```

1. Make a temporary directory for the k8s-image using the current version string.

   ```bash
   ncn-m# mkdir -p k8s/${K8SVERSION}
   ```

1. Get the image.

   ```bash
   ncn-m# cray artifacts get ncn-images k8s/${K8SVERSION}/filesystem.squashfs k8s/${K8SVERSION}/filesystem.squashfs
   ```

The Ceph image `ceph-image` is used by the utility storage nodes.

1. Decide which ceph-image is to be modified

   ```bash
   ncn-m# cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep ceph | grep squashfs
   "ceph-filesystem.squashfs"
   "ceph/0.1.107/filesystem.squashfs"
   "ceph/0.1.113/filesystem.squashfs"
   "ceph/0.1.48/filesystem.squashfs"
   ```

   This example uses `ceph/0.1.113` for the current version and adds a suffix for the new version.

   ```bash
   ncn-m# export CEPHVERSION=0.1.113
   ncn-m# export CEPHNEW=0.1.113-2
   ```

1. Make a temporary directory for the ceph-image using the current version string.

   ```bash
   ncn-m# mkdir -p ceph/${CEPHVERSION}
   ```

1. Get the image.

   ```bash
   ncn-m# cray artifacts get ncn-images ceph/${CEPHVERSION}/filesystem.squashfs ceph/${CEPHVERSION}/filesystem.squashfs
   ```

1. Execute the `ncn-image-modification.sh` script.

   The `ncn-image-modification.sh` script is included at the top-level of the unpacked CSM release tarball.

   See the `-h` output for usage information:

   ```bash
   ncn-m# ncn-image-modification.sh -h
   Usage: ncn-image-modification.sh [-p] [-d dir] [ -z timezone] [-k kubernetes-squashfs-file] [-s storage-squashfs-file] [ssh-keygen arguments]

          This script semi-automates the process of changing the timezone, root
          password, and adding new SSH keys for the root user to the NCN squashfs
          image(s).

          The script will immediately prompt for a new passphrase for ssh-keygen.
          The script will then proceed to unsquash the supplied squash files and
          then prompt for a password. Once the password of the last squash has been
          provided, the script will continue to completion without interruption.

          The process can be fully automated by using the SQUASHFS_ROOT_PW_HASH
          environment variable (see below) along with either -d or -N

          -a             Do *not* modify the authorized_keys file in the squashfs.
                         If modifying a previously modified image, or an
                         authorized_keys file that contains the public key is already
                         included in the directory used with the -d option, you may
                         want to use this option.

          -d dir         If provided, the contents will be copied into /root/.ssh/
                         in the squashfs image. Do not supply ssh-keygen arguments
                         when using -d. Assumes public keys have a .pub extension.

          -p             Change or set the password in the squashfs. By default, the
                         user prompted to enter the password after each squashfs file
                         is unsquashed. Use the SQUASHFS_ROOT_PW_HASH environment
                         variable (see below) to change or set the password without
                         being prompted.

          -z timezone    By default the timezone on NCNs is UTC. Use this option to
                         override.

   SUPPORTED SSH-KEYGEN ARGUMENTS

          The following ssh-keygen(1) arguments are supported by this script:
          [-b bits] [-t dsa | ecdsa | ecdsa-sk | ed25519 | ed25519-sk | rsa]
          [-N new_passphrase] [-C comment]

   ENVIRONMENT VARIABLES

          SQUASHFS_ROOT_PW_HASH    If set to the encrypted hash for a root password,
                                   this hash will be injected into /etc/shadow in the
                                   squashfs image and there will be no interactive prompt
                                   to set it. When setting this variable, be sure to use
                                   single quotes (') to ensure any '$' characters are not
                                   interpreted.

          DEBUG                    If set, the script will be run with 'set -x'
   ```

   Example:

   ```bash
   ncn-m# ncn-image-modification.sh -z Americas/Chicago \
                                    -k k8s/${K8SVERSION}/filesystem.squashfs \
                                    -s ceph/${CEPHVERSION}/filesystem.squashfs \
                                    -d ~/.ssh/
   ```

   In the above example, the timezone in the `squashfs` is being changed to `Americas/Chicago`.
   The root password will **not** be changed because `-p` was not provided on the command line.
   It will copy the existing keys in `~/.ssh/` into the image.

   Example:

   ```bash
   ncn-m# export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
   ncn-m# ncn-image-modification.sh -p -t rsa \
                                    -N "" \
                                    -k k8s/${K8SVERSION}/filesystem.squashfs \
                                    -s ceph/${CEPHVERSION}/filesystem.squashfs
   ```

   In this example the root password hash in `/etc/shadow` in the NCN image will be replaced with the contents
   of the `$SQUASHFS_ROOT_PW_HASH` variable. Ensure single quotes are used when setting the environment variable
   so that any `$` characters are not interpreted by Bash. In the example above, `SQUASHFS_ROOT_PW_HASH` is being
   set to match the root password hash that exists on the current node. This invocation also creates new SSH keys.

   The newly created images will have a `secure-` prefix. The original images are retained in an `./old` directory
   at the same level in the filesystem as the `squashfs` files.

1. Put the new `squashfs`, `kernel`, and `initrd` into S3

   ***Note:*** The version string for the kernel file may be different.

   ```bash
   ncn-m# cd k8s/${K8SNEW}
   /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'k8s/${K8SNEW}/filesystem.squashfs' --file-name filesystem.squashfs
   /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'k8s/${K8SNEW}/initrd' --file-name initrd.img.xz
   /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'k8s/${K8SNEW}/kernel' --file-name 5.3.18-24.75-default.kernel
   ```

   ```bash
   ncn-m# cd ceph/${CEPHNEW}
   /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'ceph/${CEPHNEW}/filesystem.squashfs' --file-name filesystem.squashfs
   /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'ceph/${CEPHNEW}/initrd' --file-name initrd.img.xz
   /usr/share/doc/csm/scripts/ceph-upload-file-public-read.py --bucket-name ncn-images --key-name 'ceph/${CEPHNEW}/kernel' --file-name 5.3.18-24.75-default.kernel
   cd ../..
   ```

1. The Kubernetes and Storage images now have the image changes.

1. Update BSS with the new image for the master nodes and worker nodes.

   **WARNING:** If doing a CSM software upgrade, skip this section to continue with Ceph Image.

   > If not doing a CSM software upgrade, this process will update the entries in BSS for the master nodes and worker nodes to use the new `k8s-image`.
   >
   > 1. Set all master nodes and worker nodes to use newly created k8s-image.
   >
   >     This will use the K8SVERSION and K8SNEW variables defined earlier.
   >
   >     ```bash
   >     ncn-m# for node in $(grep -oP "(ncn-[mw]\w+)" /etc/hosts | sort -u)
   >     do
   >       echo $node
   >       xname=$(ssh $node cat /etc/cray/xname)
   >       echo $xname
   >       cray bss bootparameters list --name $xname --format json > bss_$xname.json
   >       sed -i.old "s@k8s/${K8SVERSION}@k8s/${K8SNEW}@g" bss_$xname.json
   >       kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
   >       initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
   >       params=$(cat bss_$xname.json | jq '.[]  .params')
   >       cray bss bootparameters update --initrd $initrd --kernel $kernel --params $params --name $xname --format json
   >     done
   >     ```

1. Update BSS with the new image for utility storage nodes.

   **WARNING:** If doing a CSM software upgrade, skip this section to continue with Cleanup.

   > If not doing a CSM software upgrade, this process will update the entries in BSS for the utility storage nodes to use the new `ceph-image`.
   >
   > 1. Set all utility storage nodes to use newly created ceph-image.
   >
   >     This will use the CEPHVERSION and CEPHNEW variables defined earlier.
   >
   >     ```bash
   >     ncn-m# for node in $(grep -oP "(ncn-s\w+)" /etc/hosts | sort -u)
   >     do
   >       echo $node
   >       xname=$(ssh $node cat /etc/cray/xname)
   >       echo $xname
   >       cray bss bootparameters list --name $xname --format json > bss_$xname.json
   >       sed -i.old "s@ceph/${CEPHVERSION}@ceph/${CEPHNEW}@g" bss_$xname.json
   >       kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
   >       initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
   >       params=$(cat bss_$xname.json | jq '.[]  .params')
   >       cray bss bootparameters update --initrd $initrd --kernel $kernel --params $params --name $xname --format json
   >     done
   >     ```

## Cleanup

1. Remove the workarea so the space can be reused.

   ```bash
   ncn-m# rm -rf /run/initramfs/overlayfs/workingarea
   ```

1. Rebuild nodes.

   **WARNING:** If doing a CSM software upgrade, skip this step since the upgrade process does a rolling rebuild with some additional steps.

   > If not doing a CSM software upgrade, follow the procedure to do a [Rolling Rebuild](../node_management/Rebuild_NCNs/Rebuild_NCNs.md) of all management nodes.
