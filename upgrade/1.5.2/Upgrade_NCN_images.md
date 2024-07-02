# Upgrade NCNs during CSM `1.5.2` Patch

This page provides guidance for systems that are performing an upgrade from a CSM `v1.5.X` release to the CSM `v1.5.2` release.

The [`v1.5.2` upgrade page](../1.5.2/README.md) will refer to this page
during [NCN Upgrade](../1.5.2/README.md#ncn-upgrade).

## Overview

This steps upgrade NCNs into the node images created during the [Update NCN images](../1.5.2/README.md#update-ncn-images)
step of the patch procedure. The node upgrades will not change the state of the node.

It is important to do this step so that nodes
are using the correct images. If NCN are not upgraded into these images, then `cloudinit` would fail on the nodes the next
time the nodes are rebuilt. These images were set in BSS during [Update NCN images](../1.5.2/README.md#update-ncn-images)
and if the NCN nodes are not upgraded, then on any node reboot will cause the node to be booted into this new image which is not following the proper
upgrade procedure which could cause problems.

## Steps

1. (`ncn-m001#`) Upgrade storage nodes.

    1. Pick one storage node to test the first storage node upgrade on. This will be referred to as the `CANARY_NODE`.

        ```bash
        CANARY_NODE="ncn-s001"
        ```

    1. Perform the storage node upgrade on the `CANARY_NODE`.

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ${CANARY_NODE} --upgrade
        ```

    1. If the `CANARY_NODE` upgrade succeeded, upgrade the remaining storage nodes.

        1. Get a comma sperated list of storage nodes to be upgraded.

            ```bash
            STORAGE_NODES="$(ceph orch host ls | grep ncn-s | grep -v "$CANARY_NODE" | awk '{print $1}' | tr '\n' ',' | head -c -1)"
            echo "$STORAGE_NODES"
            ```

        1. Upgrade remaining storage nodes.

            ```bash
            /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ${STORAGE_NODES} --upgrade
            ```

    For troubleshooting the storage node upgrades, please see the notes in the [CSM storage node upgrade procedure](../Stage_2.md#storage-node-image-upgrade-and-ceph-upgrade).

1. (`ncn-m001#`) Export `CSM_ARTI_DIR` environment variable. (`CSM_RELEASE_VERSION` and `CSM_DISTDIR` is expected to already be set).

    ```bash
    CSM_REL_NAME="csm-${CSM_RELEASE_VERSION}"
    export CSM_ARTI_DIR="${CSM_DISTDIR}"
    echo "${CSM_ARTI_DIR}"
    ```

1. (`ncn-m001#`) Upgrade master nodes and worker nodes.

    Follow steps `3.1`, `3.2`, and `3.3` in the [CSM Stage 3 Upgrade Kubernetes documentation](../Stage_3.md) to upgrade master nodes and worker nodes.

    Start with step [Stage 3.1 - Master node image upgrade](../Stage_3.md#stage-31---master-node-image-upgrade). Then perform the worker node upgrades.
    Stop after completing [Stage 3.3 - `ncn-m001` upgrade](../Stage_3.md#stage-33---ncn-m001-upgrade) and return to this document.

## Return to CSM `1.5.2` patch

Return to the next step of the CSM `1.5.2` patch procedure [Configure E1000 node and Redfish Exporter for SMART data](./index.md#configure-e1000-node-and-redfish-exporter-for-smart-data).
