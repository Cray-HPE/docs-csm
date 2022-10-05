# Set NCN Image Root Password, SSH Keys, and Timezone

Modify the NCN images by setting the `root` user password and adding SSH keys for the `root` user account.
If desired, also change the timezone for the NCNs.

This procedure shows this process being done any time after the first time installation of the CSM
software has been completed and the PIT node is booted as a regular master node. To change the NCN images
from the PIT node during CSM installation, see
[Set NCN Image Root Password, SSH Keys, and Timezone on PIT Node](Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md).

All of the commands in this procedure are intended to be run on a single master or worker node.

## Prerequisites

- This procedure can only be done after the PIT node is rebuilt to become a normal master node.
- The Cray CLI must be configured on the node where the procedure is being done. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).
- The CSM documentation RPM must be installed on the node where the procedure is being run. See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

1. [Preparation](#1-preparation)
1. [Get NCN artifacts](#2-get-ncn-artifacts)
1. [Customize the images](#3-customize-the-images)

    - [SSH keys](#ssh-keys)
      - [Script-generated keys](#script-generated-keys)
      - [Administrator-provided keys](#administrator-provided-keys)
    - [Password](#password)
      - [Use node password](#use-node-password)
      - [Enter password and generate hash](#enter-password-and-generate-hash)
    - [Timezone](#timezone)
    - [Examples](#examples)
      - [Example 1: New keys, copy password, keep UTC](#example-1-new-keys-copy-password-keep-utc)
      - [Example 2: Provide keys, prompt for password, change timezone](#example-2-provide-keys-prompt-for-password-change-timezone)
      - [Example 3: New keys, no password change, keep UTC, no prompting](#example-3-new-keys-no-password-change-keep-utc-no-prompting)

1. [Upload artifacts into S3](#4-upload-artifacts-into-s3)
1. [Update BSS](#5-update-bss)
1. [Cleanup](#6-cleanup)
1. [Rebuild NCNs](#7-rebuild-ncns)

### 1. Preparation

(`ncn-mw#`) Change to a working directory with enough space to hold the images once they have been expanded.

```bash
mkdir -pv /run/initramfs/overlayfs/workingarea && cd /run/initramfs/overlayfs/workingarea
```

### 2. Get NCN artifacts

1. (`ncn-mw#`) List available Kubernetes NCN images.

    The Kubernetes image is used by the master and worker nodes.

    ```bash
    cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep k8s | grep squashfs
    ```

    Example output:

    ```text
    "k8s-filesystem.squashfs"
    "k8s/0.1.107/filesystem.squashfs"
    "k8s/0.1.109/filesystem.squashfs"
    "k8s/0.1.48/filesystem.squashfs"
    ```

1. (`ncn-mw#`) Set Kubernetes image version variables.

    - Set `K8SVERSION` to the version of the image to be modified.
    - Set `K8SNEW` to the version label to use for the modified image.

    This example uses `k8s/0.1.109` for the current version and adds a suffix for the new version.

    ```bash
    K8SVERSION=0.1.109
    K8SNEW=${K8SVERSION}-2
    ```

1. (`ncn-mw#`) Make a temporary directory for the Kubernetes artifacts using the current version string.

    ```bash
    mkdir -pv k8s/${K8SVERSION}
    ```

1. (`ncn-mw#`) Download the Kubernetes NCN artifacts.

    ```bash
    for art in filesystem.squashfs initrd kernel ; do
        cray artifacts get ncn-images k8s/${K8SVERSION}/${art} k8s/${K8SVERSION}/${art}
    done
    ```

1. (`ncn-mw#`) List available Ceph images.

    The Ceph image is used by the utility storage nodes.

    ```bash
    cray artifacts list ncn-images --format json | jq '.artifacts[] .Key' | grep ceph | grep squashfs
    ```

    Example output:

    ```text
    "ceph-filesystem.squashfs"
    "ceph/0.1.107/filesystem.squashfs"
    "ceph/0.1.113/filesystem.squashfs"
    "ceph/0.1.48/filesystem.squashfs"
    ```

1. (`ncn-mw#`) Set Ceph image version variables.

    - Set `CEPHVERSION` to the version of the image to be modified.
    - Set `CEPHNEW` to the version label to use for the modified image.

    This example uses `ceph/0.1.113` for the current version and adds a suffix for the new version.

    ```bash
    CEPHVERSION=0.1.113
    CEPHNEW=${CEPHVERSION}-2
    ```

1. (`ncn-mw#`) Make a temporary directory for the Ceph artifacts using the current version string.

    ```bash
    mkdir -pv ceph/${CEPHVERSION}
    ```

1. (`ncn-mw#`) Download the storage NCN artifacts.

    ```bash
    for art in filesystem.squashfs initrd kernel ; do
        cray artifacts get ncn-images ceph/${CEPHVERSION}/${art} ceph/${CEPHVERSION}/${art}
    done
    ```

### 3. Customize the images

Add SSH keys and the `root` password to the NCN SquashFS images. Optionally set their timezone, if a timezone other than UTC
(the default) is desired. This is all done by running the `ncn-image-modification.sh` script.

(`ncn-mw#`) Set the path to the script:

```bash
NCN_MOD_SCRIPT=$(rpm -ql docs-csm | grep ncn-image-modification[.]sh)
```

This document provides common ways of using the script to accomplish this. However, specific environments may require
deviations from these examples. In those cases, it may be helpful to view the complete script usage statement by running
it with only the `-h` argument.

The Kubernetes NCN image location is specified with the `-k` argument to the script, and the storage NCN image location is
specified with the `-s` argument to the script. Both images should be customized with a single call to the script to ensure that
they receive matching customizations, unless specifically desiring otherwise.

The new customized images are created in their original image's directory. They have the same name as the original image, except
with the `secure-` prefix added. The original image is moved into a subdirectory named `old`, for backup purposes.

There are several choices to be made during this process:

- SSH key files can be provided to the script, or the script can generate them itself.
- The hashed `root` password can be provided to the script, or the script can prompt for password entry when it is running.
- To use a non-default timezone, that must be passed into the script.

#### SSH keys

##### Script-generated keys

To have the script generate the SSH keys automatically, it must be provided with the `ssh-keygen` options to use.

- To view the complete list of supported `ssh-keygen` options, view the script usage statement by running it with the `-h` argument.
- If the `-N` option is not used to specify the passphrase, then the script will prompt for the passphrase when it generates the keys.
  - Even specifying an empty passphrase will prevent being prompted to enter the passphrase during script execution.
    See [Example 3](#example-3-new-keys-no-password-change-keep-utc-no-prompting).

##### Administrator-provided keys

To provide SSH keys to the script, specify the directory containing them with the `-d` argument.

- The script assumes that public keys in that directory have the `.pub` file extension.
- The entire contents of this directory will be copied into the `/root/.ssh` directory in the images.
- After copying the directory contents, the script updates the `/root/.ssh/authorized_keys` file in the images
  with the new public keys.
  - This is usually the desired behavior, but it can be overridden by specifying the `-a` argument. In that
    case, the script will **not** update the `authorized_keys` file after copying the directory contents.

#### Password

In order for the script to set `root` passwords in the images, the `-p` argument must be included when calling it.

If the `SQUASHFS_ROOT_PW_HASH` environment variable is exported, the script will use that as the new `root` password hash for the images.
Otherwise, the script will prompt for the password to be entered during its execution.

##### Use node password

(`ncn-mw#`) If wanting to use the same `root` user password that is being used on the node where this procedure is being run, then
the following command can be used to set the `SQUASHFS_ROOT_PW_HASH` variable.

```bash
export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
```

##### Enter password and generate hash

(`ncn-mw#`) The following script can be used to manually enter a new password, and then generate its hash.

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

#### Timezone

The default timezone in the NCN images is UTC. This can optionally be changed by passing the `-z` argument to the
script. Valid timezone options can be listed by running `timedatectl list-timezones`.

#### Examples

##### Example 1: New keys, copy password, keep UTC

(`ncn-mw#`) This example has the script generate new SSH keys (prompting the administrator for the SSH key passphrase) and
copies the `root` user password from the current node. It does not change the timezone from the UTC default.

```bash
export SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
$NCN_MOD_SCRIPT -p \
                -t rsa \
                -k k8s/${K8SVERSION}/filesystem.squashfs \
                -s ceph/${CEPHVERSION}/filesystem.squashfs
```

##### Example 2: Provide keys, prompt for password, change timezone

(`ncn-mw#`) This example uses existing SSH keys located in the `/my/pre-existing/keys` directory. The script prompts the
administrator for the `root` user password during execution. It changes the timezone to `America/Chicago`.

```bash
$NCN_MOD_SCRIPT -p \
                -d /my/pre-existing/keys \
                -z America/Chicago \
                -k k8s/${K8SVERSION}/filesystem.squashfs \
                -s ceph/${CEPHVERSION}/filesystem.squashfs
```

##### Example 3: New keys, no password change, keep UTC, no prompting

(`ncn-mw#`) This example has the script generate new SSH keys. It does not change the `root` password, nor does it
change the timezone from the UTC default. A blank passphrase is provided, so that the script requires
no input from the administrator while it is running.

```bash
$NCN_MOD_SCRIPT -t rsa \
                -N "" \
                -k k8s/${K8SVERSION}/filesystem.squashfs \
                -s ceph/${CEPHVERSION}/filesystem.squashfs
```

### 4. Upload artifacts into S3

1. (`ncn-mw#`) Upload the new Kubernetes image into S3.

    ```bash
    cray artifacts create boot-images k8s/${K8SNEW}/filesystem.squashfs k8s/${K8SVERSION}/secure-filesystem.squashfs
    ```

1. (`ncn-mw#`) Upload the Kubernetes kernel and `initrd` into S3 under the new version string.

    ```bash
    for art in initrd kernel ; do
        cray artifacts create boot-images k8s/${K8SNEW}/${art} k8s/${K8SVERSION}/${art}
    done
    ```

1. (`ncn-mw#`) Upload the new Ceph image into S3.

    ```bash
    cray artifacts create boot-images ceph/${CEPHNEW}/filesystem.squashfs ceph/${CEPHVERSION}/secure-filesystem.squashfs
    ```

1. (`ncn-mw#`) Upload the Ceph kernel and `initrd` into S3 under the new version string.

    ```bash
    for art in initrd kernel ; do
        cray artifacts create boot-images ceph/${CEPHNEW}/${art} ceph/${CEPHVERSION}/${art}
    done
    ```

The Kubernetes and storage images now have the image changes.

### 5. Update BSS

**WARNING:** If doing a CSM software upgrade, then skip this section and proceed to [Cleanup](#6-cleanup).

This step updates the entries in BSS for the NCNs to use the new images.

1. (`ncn-mw#`) Update BSS for master and worker nodes.

    > This uses the `K8SVERSION` and `K8SNEW` variables defined earlier.

    ```bash
    for node in $(grep -oP "(ncn-[mw]\w+)" /etc/hosts | sort -u); do
        echo $node
        xname=$(ssh $node cat /etc/cray/xname)
        echo $xname
        cray bss bootparameters list --name $xname --format json > bss_$xname.json
        sed -i.$(date +%Y%m%d_%H%M%S%N).orig "s@/k8s/${K8SVERSION}\([\"/[:space:]]\)@/k8s/${K8SNEW}\1@g" bss_$xname.json
        kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
        initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
        params=$(cat bss_$xname.json | jq '.[]  .params')
        cray bss bootparameters update --initrd $initrd --kernel $kernel --params "$params" --hosts $xname --format json
    done
    ```

1. (`ncn-mw#`) Update BSS for utility storage nodes.

    > This uses the `CEPHVERSION` and `CEPHNEW` variables defined earlier.

    ```bash
    for node in $(grep -oP "(ncn-s\w+)" /etc/hosts | sort -u); do
        echo $node
        xname=$(ssh $node cat /etc/cray/xname)
        echo $xname
        cray bss bootparameters list --name $xname --format json > bss_$xname.json
        sed -i.$(date +%Y%m%d_%H%M%S%N).orig "s@/ceph/${CEPHVERSION}\([\"/[:space:]]\)@/ceph/${CEPHNEW}\1@g" bss_$xname.json
        kernel=$(cat bss_$xname.json | jq '.[]  .kernel')
        initrd=$(cat bss_$xname.json | jq '.[]  .initrd')
        params=$(cat bss_$xname.json | jq '.[]  .params')
        cray bss bootparameters update --initrd $initrd --kernel $kernel --params "$params" --hosts $xname --format json
    done
    ```

### 6. Cleanup

(`ncn-mw#`) Remove the temporary working area in order to reclaim the space.

```bash
rm -rvf /run/initramfs/overlayfs/workingarea
```

### 7. Rebuild NCNs

**WARNING:** If doing a CSM software upgrade, then skip this step because the upgrade process does a rolling rebuild with some additional steps.

Do a rolling rebuild of all NCNs. See [Rebuild NCNs](../node_management/Rebuild_NCNs/Rebuild_NCNs.md).
