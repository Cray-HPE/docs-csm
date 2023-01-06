# Set NCN Image Root Password, SSH Keys, and Timezone on PIT Node

> **NOTE:** This procedure is **required** during initial CSM installs **before management nodes are first deployed**.

Modify the NCN images by setting the `root` user password and adding SSH keys for the `root` user account.
If desired, also change the timezone for the NCNs.

This page describes this procedure being performed on the PIT node during a first time installation of the CSM software.
All commands in this procedure should be run on the PIT node.
If wanting to perform this operation after the initial CSM install, then
see [Set NCN Image Root Password, SSH Keys, and Timezone](Change_NCN_Image_Root_Password_and_SSH_Keys.md).

- [Overview](#overview)
- [SSH keys](#ssh-keys)
  - [Script-generated keys](#script-generated-keys)
  - [Administrator-provided keys](#administrator-provided-keys)
- [Password](#password)
  - [Use PIT node password](#use-pit-node-password)
  - [Enter password and generate hash](#enter-password-and-generate-hash)
- [Timezone](#timezone)
- [Examples](#examples)
  - [Example 1: New keys, copy PIT password, keep UTC](#example-1--new-keys-copy-pit-password-keep-utc)
  - [Example 2: Provide keys, prompt for password, change timezone](#example-2--provide-keys-prompt-for-password-change-timezone)
  - [Example 3: New keys, copy PIT password, keep UTC, no prompting](#example-3--new-keys-copy-pit-password-keep-utc-no-prompting)
- [Cleanup](#cleanup)

## Overview

Add SSH keys and the `root` password to the NCN SquashFS images. Optionally set their timezone, if a timezone other than UTC
(the default) is desired. This is all done by running the `ncn-image-modification.sh` script, which is located in the `scripts/operations/node_management` directory of the CSM documentation. Set the path to the script:

```bash
NCN_MOD_SCRIPT=$(rpm -ql docs-csm | grep ncn-image-modification[.]sh) ; echo "${NCN_MOD_SCRIPT}"
```

This document provides common ways of using the script to accomplish this. However, specific environments may require
deviations from these examples. In those cases, it may be helpful to view the complete script usage statement by running
it with only the `-h` argument.

The Kubernetes NCN image location is specified with the `-k` argument to the script, and the storage NCN image location is
specified with the `-s` argument to the script. Both images should be customized with a single call to the script to ensure that
they receive matching customizations.

The new customized images are created in their original image's directory. They have the same name as the original image, except
with the `secure-` prefix added. The original image is moved into a subdirectory named `old`, for backup purposes.

There are several choices to be made during this process:

- SSH key files can be provided to the script, or the script can generate them itself.
- The hashed `root` password can be provided to the script, or the script can prompt for password entry when it is running.
- To use a non-default timezone, that must be passed into the script.

## SSH keys

### Script-generated keys

To have the script generate the SSH keys automatically, it must be provided with the `ssh-keygen` options to use.

- To view the complete list of supported `ssh-keygen` options, view the script usage statement by running it with the `-h` argument.
- If the `-N` option is not used to specify the passphrase, then the script will prompt for the passphrase when it generates the keys.
  - Even specifying an empty passphrase will prevent being prompted to enter the passphrase during script execution.
    See [Example 3](#example-3--new-keys-copy-pit-password-keep-utc-no-prompting).

### Administrator-provided keys

To provide SSH keys to the script, specify the directory containing them with the `-d` argument.

- The script assumes that public keys in that directory have the `.pub` file extension.
- The entire contents of this directory will be copied into the `/root/.ssh` directory in the images.
- After copying the directory contents, the script updates the `/root/.ssh/authorized_keys` file in the images
  with the new public keys.
  - This is usually the desired behavior, but it can be overridden by specifying the `-a` argument. In that
    case, the script will **not** update the `authorized_keys` file after copying the directory contents.

## Password

In order for the script to set `root` passwords in the images, the `-p` argument must be included when calling it. **This is
required for initial CSM installs.**

If the `SQUASHFS_ROOT_PW_HASH` environment variable is exported, the script will use that as the new `root` password hash for the images.
Otherwise, the script will prompt for the password to be entered during its execution.

### Use PIT node password

If wanting to use the same `root` user password that is being used on the PIT node where this procedure is being run, then
the following command can be used to set the `SQUASHFS_ROOT_PW_HASH` variable.

```bash
export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
```

### Enter password and generate hash

The following script can be used to manually enter a new password, and then generate its hash.

> This script uses `read -s` to prevent the password from being echoed to the screen or saved
> in the shell history. It unsets the plaintext password variables at the end, so that only
> the hash is preserved.

```bash
read -r -s -p "Enter root password for NCN images: " PW1 ; echo ; if [[ -z ${PW1} ]]; then
    echo "ERROR: Password cannot be blank"
else
    read -r -s -p "Enter again: " PW2
    echo
    if [[ ${PW1} != ${PW2} ]]; then
        echo "ERROR: Passwords do not match"
    else
        export SQUASHFS_ROOT_PW_HASH=$(echo -n "${PW1}" | openssl passwd -6 -salt $(< /dev/urandom tr -dc ./A-Za-z0-9 | head -c4) --stdin)
        [[ -n ${SQUASHFS_ROOT_PW_HASH} ]] && echo "Password hash set and exported" || echo "ERROR: Problem generating hash"
    fi
fi ; unset PW1 PW2
```

## Timezone

The default timezone in the NCN images is UTC. This can optionally be changed by passing the `-z` argument to the
script. Valid timezone options can be listed by running `timedatectl list-timezones`.

## Examples

### Example 1: New keys, copy PIT password, keep UTC

This example has the script generate new SSH keys (prompting the administrator for the SSH key passphrase) and
copies the `root` user password from the PIT node. It does not change the timezone from the UTC default.

```bash
export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
KUBERNETES_VERSION="$(find ${CSM_PATH}/images/kubernetes -name '*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')"
CEPH_VERSION="$(find ${CSM_PATH}/images/storage-ceph -name '*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')"
   
$NCN_MOD_SCRIPT -p \
                -t rsa \
                -k "${PITDATA}/data/k8s/${KUBERNETES_VERSION}/kubernetes-${KUBERNETES_VERSION}-$(uname -i).squashfs" \
                -s "${PITDATA}/data/ceph/${CEPH_VERSION}/storage-ceph-${CEPH_VERSION}-$(uname -i).squashfs"
```

### Example 2: Provide keys, prompt for password, change timezone

This example uses existing SSH keys located in the `/my/pre-existing/keys` directory. The script prompts the
administrator for the `root` user password during execution. It changes the timezone to `America/Chicago`.

```bash
$NCN_MOD_SCRIPT -p \
                -d /my/pre-existing/keys \
                -z America/Chicago \
                -k "${PITDATA}/data/k8s/${KUBERNETES_VERSION}/kubernetes-${KUBERNETES_VERSION}-$(uname -i).squashfs" \
                -s "${PITDATA}/data/ceph/${CEPH_VERSION}/storage-ceph-${CEPH_VERSION}-$(uname -i).squashfs"
```

### Example 3: New keys, copy PIT password, keep UTC, no prompting

This example has the script generate new SSH keys and copies the `root` user password from the PIT node. It does
not change the timezone from the UTC default. It is identical to the first example except that a blank passphrase
is provided, so that the script requires no input from the administrator while it is running.

```bash
export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
$NCN_MOD_SCRIPT -p \
                -t rsa \
                -N "" \
                -k "${PITDATA}/data/k8s/${KUBERNETES_VERSION}/kubernetes-${KUBERNETES_VERSION}-$(uname -i).squashfs" \
                -s "${PITDATA}/data/ceph/${CEPH_VERSION}/storage-ceph-${CEPH_VERSION}-$(uname -i).squashfs"
```

## Cleanup

Remove backups of NCN images, if desired. These may be removed now, or after verifying that the nodes are able to boot
successfully with the new images.

```bash
cd "${PITDATA}"/data && rm -rvf ceph/old k8s/old
```
