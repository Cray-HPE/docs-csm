# CSM RBD Tool Usage

- [Prerequisites](#prerequisites)
  - [Preparing the Python environment](#preparing-the-python-environment)
  - [Restoring the Python environment](#restoring-the-python-environment)
- [Usage](#usage)
- [Examples](#examples)
  - [Checking device status](#checking-device-status)
  - [Moving device to different node](#moving-device-to-different-node)
- [Troubleshooting](#troubleshooting)
  - [mount system call fails when moving `rbd` device](#mount-system-call-fails-when-moving-rbd-device)

## Prerequisites

- The tool must be run on a Kubernetes master NCN or one of the Ceph storage NCNs.
  - The Ceph storage NCNs are typically the first three storage NCNs: `ncn-s001`, `ncn-s002`, and `ncn-s003`.
- The latest CSM documentation RPM is installed on the node where the script is being run.
  - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).
- Before running the tool, the Python environment must be prepared.
  - See [Preparing the Python environment](#preparing-the-python-environment).

### Preparing the Python environment

Before running the tool, the Python environment must be prepared using the following procedure on the node where the tool is going to be run.

1. Verify that the latest CSM documentation RPM is installed.

    See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

1. (`ncn-ms#`) Extract the necessary files.

    > This only needs to be done once after the latest documentation RPM is installed on the node, but there is no harm in running it multiple times.

    ```bash
    tar xvf /usr/share/doc/csm/scripts/csm_rbd_tool.tar.gz -C /opt/cray/csm/scripts/
    ```

1. (`ncn-ms#`) Initialize the Python environment.

    ```bash
    source /opt/cray/csm/scripts/csm_rbd_tool/bin/activate
    ```

After the tool has been run, restore the original Python environment in the shell. See [Restoring the Python environment](#restoring-the-python-environment).

### Restoring the Python environment

(`ncn-ms#`) After the tool has been run, restore the original Python environment in the shell by running the following command:

```bash
deactivate
```

## Usage

```text
usage: csm_rbd_tool.py [-h] [--status] [--rbd_action RBD_ACTION]
                       [--pool_action POOL_ACTION] [--target_host TARGET_HOST]
                       [--csm_version CSM_VERSION]

A Helper tool to utilize an rbd device so additional upgrade space.

optional arguments:
  -h, --help            show this help message and exit
  --status              Provides the status of an rbd device managed by this
                        script
  --rbd_action RBD_ACTION
                        "create/delete/move" an rbd device to store and
                        decompress the csm tarball
  --pool_action POOL_ACTION
                        Use with "--pool_action delete" to delete a predefined
                        pool and rbd device used with the csm tarball.
  --target_host TARGET_HOST
                        Destination node to map the device to. Must be a k8s
                        master host
  --csm_version CSM_VERSION
                        The CSM version being installed or upgraded to. This
                        is used for the rbd device mount point. [Future Placeholder]
```

## Examples

- [Checking device status](#checking-device-status)
- [Moving device to different node](#moving-device-to-different-node)

### Checking device status

(`ncn-ms#`) Check the status of the `rbd` device.

```bash
/usr/share/doc/csm/scripts/csm_rbd_tool.py --status
```

Example output:

```text
[{"id":"0","pool":"csm_admin_pool","namespace":"","name":"csm_scratch_img","snap":"-","device":"/dev/rbd0"}]
Pool csm_admin_pool exists: True
RBD device exists True
RBD device mounted at - ncn-m001.nmn:/etc/cray/upgrade/csm
```

### Moving device to different node

(`ncn-ms#`) Move the `rbd` device.

```bash
/usr/share/doc/csm/scripts/csm_rbd_tool.py --rbd_action move --target_host ncn-m002
```

Example output:

```text
[{"id":"0","pool":"csm_admin_pool","namespace":"","name":"csm_scratch_img","snap":"-","device":"/dev/rbd0"}]
/dev/rbd0
RBD device mounted at - ncn-m002.nmn:/etc/cray/upgrade/csm
```

## Troubleshooting

### mount system call fails when moving `rbd` device

The symptom of this issue is that moving the `rbd` device fails with the error message:

 `mount: /etc/cray/upgrade/csm: mount(2) system call failed: Structure needs cleaning.`

The fix for this issue is to clean the device using the following procedure.

1. Get the `rbd` device name and location.

    1. Check the device status.

        See [Checking device status](#checking-device-status).

    1. Examine the output of the status check for the device name and location.

        The device name is likely `/dev/rbd0` or similar and it usually is located on `ncn-m001` or `ncn-m002`.

1. (`ncn-m#`) Clean the device.

    Run the following command on the node that the device is located on. Modify the command to use the
    device name identified in the previous step.

    This command may have multiple prompts.

    ```bash
    fsck.ext4 <device_name>
    ```

    - Example output of a successful clean:

        ```text
        e2fsck 1.43.8 (1-Jan-2018)
        One or more block group descriptor checksums are invalid.  Fix<y>?

        Group descriptor 7999 checksum is 0x6f65, should be 0x6971.  FIXED.
        Pass 1: Checking inodes, blocks, and sizes

        Pass 2: Checking directory structure
        Pass 3: Checking directory connectivity
        Pass 4: Checking reference counts
        Pass 5: Checking group summary information
        Block bitmap differences:  +(32768--33917) +(98304--99453) + ...
        Fix<y>? yes
        Free blocks count wrong (246632145, counted=257747999).
        Fix<y>? yes
        Free inodes count wrong (65529942, counted=65535989).
        Fix<y>? yes
        Padding at end of inode bitmap is not set. Fix<y>? yes

        /dev/rbd0: ***** FILE SYSTEM WAS MODIFIED *****
        /dev/rbd0: 11/65536000 files (0.0% non-contiguous), 4396001/262144000 blocks
        ```

    - Example output if the `rbd` device is already clean:

        ```text
        e2fsck 1.43.8 (1-Jan-2018)
        /dev/rbd0: clean, 11/65536000 files, 4396001/262144000 blocks
        ```

1. Retry the original attempt to move the device.
