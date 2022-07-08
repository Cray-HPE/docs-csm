# Kernel Dump Hotfix

This directory includes the script and the library necessary for applying the hotfix to all reachable NCNs.

## Usage

1. Run `hotfix.sh`.

    ```bash
    ncn# /usr/share/doc/csm/scripts/hotfixes/kdump/hotfix.sh
    ```

   Example output:

   ```text
   Uploading hotfix files to ncn-m001:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-m002:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-m003:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-s001:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-s002:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-s003:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-s004:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-w001:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-w002:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-w003:/srv/cray/scripts/common/ ... Done
   Uploading hotfix files to ncn-w004:/srv/cray/scripts/common/ ... Done
   Running updated create-kdump-artifacts.sh script on [11] NCNs ... Done
   The following NCNs contain the kdump patch:
   ncn-m001
   ncn-m002
   ncn-m003
   ncn-s001
   ncn-s002
   ncn-s003
   ncn-s004
   ncn-w001
   ncn-w002
   ncn-w003
   ncn-w004
   This hotfix has completed.
   ```

## Origin

The original script and library used live in [metal-provision](https://github.com/Cray-HPE/metal-provision/tree/v1.0.6):

- [`create-kdump-artifacts.sh`](https://github.com/Cray-HPE/metal-provision/blob/v1.0.6/roles/ncn-common-setup/files/srv/cray/scripts/common/create-kdump-artifacts.sh)
- [`dracut-lib.sh`](https://github.com/Cray-HPE/metal-provision/blob/v1.0.6/roles/ncn-common-setup/files/srv/cray/scripts/common/dracut-lib.sh)
