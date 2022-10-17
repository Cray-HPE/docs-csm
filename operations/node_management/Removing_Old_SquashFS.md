# Remove Old SquashFS

This page will guide a user through removing old squashFS (and overlayFS) that can reside on an 
NCN following upgrades or rebuilds.

> ***NOTE*** Historically speaking, CSM V1.3.0 upgrades (and newer) pull squashFS into a new directory
> and create a new overlayFS that corresponds to that squashFS directory. This facilitates rolling back
> to a previous image. This page helps a user clean up old images, freeing up space for new upgrades
> if space becomes too limited.

## Prerequisites

1. Deliver the cleanup script to the NCNs (this just provides the cleanup script to the NCNs).

   ```bash
   /usr/share/doc/csm/scripts/operations/node_management/copy-cleanup-live-images.sh
   ```

## Clean a single NCN

1. Login to the NCN to be cleaned.

1. Invoke the cleaning script on an NCN

    * Clean only old squashFS

      ```bash
      /srv/cray/metal/scripts/cleanup-live-images.sh
      ```

    * Clean all squashFS including the running squashFS

      > ***NOTE*** This does not clean the running overlayFS, or the system will crash.

      ```bash
      /srv/cray/metal/scripts/cleanup-live-images.sh -a
      ```

## Clean all NCNs

1. (`ncn-m001#`) Invoke the cleanup script on all NCNs

    * Clean only old squashFS

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/run-cleanup-live-images-on-all.sh
        ```

    * Clean all squashFS including the running squashFS
    
        > ***NOTE*** This does not clean the running overlayFS, or the system will crash.

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/copy-cleanup-live-images.sh -a
        ```
