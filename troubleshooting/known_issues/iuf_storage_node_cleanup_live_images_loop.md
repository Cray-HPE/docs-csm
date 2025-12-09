# Known Issue: IUF Storage Node Upgrade Stuck in Loop During `cleanup-live-images`

During an upgrade from CSM 1.6 using IUF, the management nodes rollout may get stuck in a loop when processing storage nodes. The workflow repeatedly fails at the `cleanup-live-images` step with warnings about the workflow being in a failed state.

## Symptoms

When running the IUF management-nodes-rollout command:

```bash
iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_CANARY}
```

The output shows repeated failure and retry messages:

```text
WARN [storage-node-upgrade                                     ]       - Workflow in Failed state, Retry ...
INFO [storage-node-upgrade                                     ]       - Succeeded:
INFO [storage-node-upgrade                                     ]       before-each-ncn-s001 -  set-bss-image-and-cfs-config
INFO [storage-node-upgrade                                     ]       - Running:
INFO [storage-node-upgrade                                     ]       reboot-ncn-s001 -  cleanup-live-images
```

## Root Cause

The issue occurs when the `/run/initramfs/live/` directory on a storage node is empty or missing the expected CSM version subdirectory.
The `cleanup-live-images.sh` script (called by IUF via `/usr/share/doc/csm/workflows/templates/storage.reboot.yaml`) returns an exit
status of 1 when there are no directories to remove, causing the workflow to fail.

On affected nodes, the directory structure appears as:

```bash
# ls -al /run/initramfs/live/
total 0
drwxr-xr-x 2 root root   6 Mar 12 12:46 .
drwxr-xr-x 7 root root 180 Oct 24 14:22 ..
```

While on healthy nodes, it contains version subdirectories:

```bash
# ls -al /run/initramfs/live/
total 0
drwxr-xr-x 6 root root  58 Jun 11 10:33 .
drwxr-xr-x 7 root root 180 Oct 24 14:22 ..
drwxr-xr-x 2 root root  66 Jan 15  2024 1.5.1
drwxr-xr-x 2 root root  66 Mar 20  2024 1.6.0
drwxr-xr-x 2 root root  66 May 10  2024 1.6.1
drwxr-xr-x 2 root root  66 Jun 11  2024 1.6.2
```

## Workaround

Create the missing directory structure on the affected storage node with the current CSM version:

1. (`ncn-m#`) SSH to the affected storage node:

    ```bash
    ssh ncn-s001
    ```

1. (`ncn-s#`) Verify the directory is empty:

    ```bash
    ls -al /run/initramfs/live/
    ```

1. (`ncn-s#`) Create the directory for the current CSM version (adjust the version number as needed):

    ```bash
    mkdir /run/initramfs/live/1.6.2
    ```

1. Return to the management node and retry the IUF step.

## Prevention

Before running the IUF management-nodes-rollout, verify that all storage nodes have the expected directory structure:

```bash
pdsh -w ncn-s00[1-3] ls -al /run/initramfs/live/
```

If any nodes show an empty directory, apply the workaround.
