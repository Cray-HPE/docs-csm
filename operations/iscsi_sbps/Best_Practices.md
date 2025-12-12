# Best practices to follow to avoid issues with iSCSI SBPS

This document presents recommended best practices to avoid issues with
iSCSI SBPS.

Scenario #1: As roots/PE images will be placed in `s3` storage/IMS, there could be unused
images which user/admin would like to delete. The following are steps to delete unused
`rootfs/PE` images safely.

## Steps to remove unused `rootfs/PE` images projected by iSCSI SBPS

1. Identify the unused `PE` and `rootfs` images from `targetcli ls` command output from
   one of the iSCSI target node (worker node) and list them in a file.

   Example command:

   ```bash
   (`ncn-w#`) targetcli ls
   ```

   Example command output snippet:

    ```text
    ...

    |     | o- lun0  [fileio/a50dd52157e1636 (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-23.12.squashfs) (default_tg_pt_gp)]
    ...
    |     | o- lun5  [fileio/c1d98cf92b0647f (/var/lib/cps-local/boot-images/PE/CPE-aocc.x86_64-23.12.squashfs) (default_tg_pt_gp)]
    ...
    |     | o- lun28  [fileio/84c5b467e892c6b (/var/lib/cps-local/boot-images/d114469b-06c6-42ed-b151-05a7f555b3a1/rootfs) (default_tg_pt_gp)]
    ...

    ```

1. Provide a list of images in a file that are identified for deletion.

   Example:

   ```bash
   (`ncn-w#`) cat img_list
   ```

   ```text
   CPE-amd.x86_64-23.12.squashfs
   CPE-aocc.x86_64-23.12.squashfs
   d114469b-06c6-42ed-b151-05a7f555b3a1
   ```

1. Run the script [`get_img_str.sh`](../../scripts/operations/iscsi_sbps/get_img_str.sh) on one of the worker node (For example, iSCSI target) which takes above file having list of images as an argument.

   Example command:

   ```bash
   (`ncn-w#`) sh get_img_str.sh img_list
   ```

   This script will create a output file named `img_str.txt` having list of image identifier
   strings for which corresponding iSCSI `LUNs` on the iSCSI initiator are to be deleted.

   Example `img_str.txt` file output:

   ```bash
   (`ncn-w#`) cat img_str.txt
   ```

   ```text
   a50dd52157e1636
   c1d98cf92b0647f
   84c5b467e892c6b
   ```

   The first image identifier string above corresponds to the image `CPE-amd.x86_64-23.12.squashfs` in the list
   and corresponds to `lun0` in the `targetcli ls` output as below:

  ```text
  |     | o- lun0  [fileio/a50dd52157e1636 (/var/lib/cps-local/boot-images/PE/CPE-amd.x86_64-23.12.squashfs) (default_tg_t_gp)]
  ```

   Similarly, second (`c1d98cf92b0647f`) and third (`84c5b467e892c6b`) image strings correspond to `lun5` and `lun28` respectively.

1. Login to iSCSI initiator node (compute/UAN) and check the `luns` corresponding to the image
   identifiers in `img_str.txt`.

   Example command and their outputs:

   (`nid00000#`) or (`uan0#`)

   ```bash
   (`nid00000#`) lsscsi | grep a50dd52157e1636
   ```

   ```text
   [14:0:0:0]   disk    LIO-ORG  a50dd52157e1636  4.0   /dev/sdg
   [15:0:0:0]   disk    LIO-ORG  a50dd52157e1636  4.0   /dev/sdao
   [16:0:0:0]   disk    LIO-ORG  a50dd52157e1636  4.0   /dev/sdbw
   [17:0:0:0]   disk    LIO-ORG  a50dd52157e1636  4.0   /dev/sdde
   ```

   ```bash
   (`nid00000#`) lsscsi | grep c1d98cf92b0647f
   ```

   ```text
   [14:0:0:5]   disk    LIO-ORG  c1d98cf92b0647f  4.0   /dev/sdl
   [15:0:0:5]   disk    LIO-ORG  c1d98cf92b0647f  4.0   /dev/sdat
   [16:0:0:5]   disk    LIO-ORG  c1d98cf92b0647f  4.0   /dev/sdcz
   [17:0:0:5]   disk    LIO-ORG  c1d98cf92b0647f  4.0   /dev/sddj
   ```

   ```bash
   (`nid00000#`) lsscsi | grep 84c5b467e892c6b
   ```

   ```text
   [14:0:0:28]  disk    LIO-ORG  84c5b467e892c6b  4.0   /dev/sdai
   [15:0:0:28]  disk    LIO-ORG  84c5b467e892c6b  4.0   /dev/sdbp
   [16:0:0:28]  disk    LIO-ORG  84c5b467e892c6b  4.0   /dev/sdcc
   [17:0:0:28]  disk    LIO-ORG  84c5b467e892c6b  4.0   /dev/sdeg
   ```

1. Copy `img_str.txt` and `rm_iscsi_luns.sh` onto all iSCSI initiator nodes (compute/UAN nodes)
   and run the `rm_iscsi_lun.sh` script on compute and UAN nodes with `img_str.txt` as an
   argument.

   ```bash
   (`nid00000#`) sh rm_iscsi_luns.sh img_str.txt
   ```

   This can also be run on multiple iSCSI initiator nodes using `pdsh` command as follows.

   Example:

   ```bash
   (`ncn-m#`):~ # pdsh -w nid00000[1-4]-nmn "sh rm_iscsi_luns.sh img_str.txt"
   ```

   Above command runs the script on four compute nodes `nid000001`, `nid000002`, `nid000003`
   and `nid000004`

1. Verify that the `luns` corresponding to the image identifiers are deleted from iSCSI
   initiator nodes (compute/UAN).

   (`nid00000#`) or (`uan0#`)

   ```bash
   lsscsi | grep a50dd52157e1636
   ```

   ```bash
   lsscsi | grep c1d98cf92b0647f
   ```

   ```bash
   lsscsi | grep 84c5b467e892c6b
   ```

1. Login to master node and delete the images listed in `img_list` file using `craycli`.

   Example command:

   ```bash
   cray artifacts delete boot-images PE/CPE-amd.x86_64-23.12.squashfs
   ```

1. Wait for 180 seconds and verify the iSCSI `luns` corresponding to the images are deleted by  
   checking the `targetcli ls` output.

   ```bash
   targetcli ls | grep a50dd52157e1636
   ```

   This should not list any iSCSI `luns` and `fileio` backing store corresponding to the image
   identifier string(s).
