# Set NCN Image Root Password, SSH Keys, and Timezone on PIT Node

Modify the NCN images by setting the root password and adding SSH keys for the root account.
Optionally, changing the timezone for the NCNs can also be done at this time. This procedure shows this process being
done on the PIT node during a first time installation of the CSM software.

***Note:*** This procedure **is required** to be done during an initial CSM software installation
**before management nodes are first deployed**.

## Set the root password and add SSH keys to the NCN images

This step is required. **There is no default root password and no default SSH keys in the NCN images.**

1. Add SSH keys and set the password in the SquashFS. Optionally, set the timezone.

   If desired, create new SSH keys on the PIT node. These will be copied into the NCN SquashFS images in the next step. Alternatively,
   copy an existing set of keys and `authorized_hosts` file into a directory for reference in the following step. It is assumed
   that public keys have a `.pub` extension.

   Execute the `ncn-image-modification.sh` script located at the top level of the CSM release tarball in order to add SSH keys and
   set the root password. Optionally, set a local timezone (UTC is the default). If you choose to create new SSH keys, then specify
   the directory where these keys are located with the `-d` argument to the script, in addition to the other required options.

   ```console
   pit# ncn-image-modification.sh -h
   Usage: ncn-image-modification.sh [-p] [-d dir] [ -z timezone] [-k kubernetes-squashfs-file] [-s storage-squashfs-file] [ssh-keygen arguments]

          This script semi-automates the process of changing the timezone, root
          password, and adding new SSH keys for the root user to the NCN squashfs
          image(s).

          The script will immediately prompt for a new passphrase for ssh-keygen.
          The script will then proceed to unsquash the supplied squash files and
          then prompt for a password. Once the password of the last squash has been
          provided, the script will continue to completion without interruption.

          The process can be fully automated by using the SQUASHFS_ROOT_PW_HASH
          environment variable (see below) along with either -d or -N.

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

   The following example references a directory with existing keys and setting the timezone to
   `America/Chicago`. This example will prompt the administrator to enter a root password after
   each squashed image is unsquashed.

   ```bash
   pit# cd /var/www/ephemeral/data/
   pit# ${CSM_PATH}/ncn-image-modification.sh -p -z America/Chicago \
                                              -d /my/pre-existing/keys \
                                              -k ./k8s/kubernetes-<version>.squashfs \
                                              -s ./ceph/storage-ceph-<version>.squashfs
   ```

   The following example generates new keys with an empty passphrase, and the
   `$SQUASHFS_ROOT_PW_HASH` variable set. This variable will be set to reuse the same root
   password hash that exists on the PIT node. This example will not prompt the administrator for
   any input after it is invoked.

   ```bash
   pit# cd /var/www/ephemeral/data/
   pit# export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
   pit# ${CSM_PATH}/ncn-image-modification.sh -p \
                                              -t rsa \
                                              -N "" \
                                              -k ./k8s/kubernetes-<version>.squashfs \
                                              -s ./ceph/storage-ceph-<version>.squashfs
   ```

   The script will save the original SquashFS images in `./{k8s,ceph}/old`. The new image filenames will
   have a `secure-` prefix. The initrd and kernel will retain their original filenames.

1. Set the boot links.

   ```bash
   pit# cd
   pit# set-sqfs-links.sh
   ```

## Cleanup

1. Clean up temporary storage used to prepare images.

   These may be removed now, or after verifying that the nodes are able to boot successfully with the new images.

   ```bash
   pit# cd /var/www/ephemeral/data && rm -rf ceph/old k8s/old
   ```
