# CSM RBD Tool Usage

## Introduction

## Usage

```bash
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

1. Check the status of the `rbd` device.

   (`ncn-m#`)

   ```bash
    /usr/share/doc/csm/scripts/csm_rbd_tool.py --status
   ```

   Output:

   ```text
    [{"id":"0","pool":"csm_admin_pool","namespace":"","name":"csm_scratch_img","snap":"-","device":"/dev/rbd0"}]
    Pool csm_admin_pool exists: True
    RBD device exists True
    RBD device mounted at - ncn-m001.nmn:/etc/cray/upgrade/csm
    ```

2. Move the `rbd` device.

   (`ncn-s001`)

   ```bash
   /usr/share/doc/csm/scripts/csm_rbd_tool.py --rbd_action move --target_host ncn-m002
   ```

   Output:

   ```text
   [{"id":"0","pool":"csm_admin_pool","namespace":"","name":"csm_scratch_img","snap":"-","device":"/dev/rbd0"}]
   /dev/rbd0
   RBD device mounted at - ncn-m002.nmn:/etc/cray/upgrade/csm
   ```
