# Boot Order Workaround

This directory includes the script and the library necessary for applying the workaround to all reachable NCNs.

## Usage

1. Run `run.sh`.

    ```bash
    ncn# /usr/share/doc/csm/scripts/workarounds/boot-order/run.sh
    ```

   Example output:

   ```text
   Failed to ping [ncn-w004]; skipping hotfix for [ncn-w004]
   Uploading new metal-lib.sh to ncn-m001:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-m002:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-m003:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-s001:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-s002:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-s003:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-w001:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-w002:/srv/cray/scripts/metal/ ... Done
   Uploading new metal-lib.sh to ncn-w003:/srv/cray/scripts/metal/ ... Done
   Refreshing the bootorder on [9] NCNs ... Done
   The following NCNs contain the boot-order patch:
   ncn-m001
   ncn-m002
   ncn-m003
   ncn-s001
   ncn-s002
   ncn-s003
   ncn-w001
   ncn-w002
   ncn-w003
   This workaround has completed.
   ```

## Origin

This script originated from the [metal-provision repository](https://github.com/Cray-HPE/metal-provision/tree/v1.3.4):

- [`metal-lib.sh`](https://github.com/Cray-HPE/metal-provision/blob/v1.3.4/roles/ncn-common/files/scripts/metal/metal-lib.sh)
