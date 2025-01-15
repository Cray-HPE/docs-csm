# Upgrade NCNs during CSM `1.5.3` Patch

* [Overview](#overview)
* [Steps](#steps)
* [Return to CSM `1.5.3` patch](#return-to-csm-153-patch)

This page provides guidance for systems that are performing an upgrade from a CSM `v1.5.X` release to the CSM `v1.5.3` release.

The [`v1.5.3` upgrade page](README.md) will refer to this page
during [NCN Upgrade](README.md#ncn-upgrade).

## Overview

The following steps upgrade NCNs into the node images created during the [Update NCN images](README.md#update-ncn-images)
step of the patch procedure. The node upgrades will not change the state of the node.

It is important to do this step so that nodes
are using the correct images. If NCNs are not upgraded into these images, then `cloudinit` will fail on the nodes the next
time the nodes are rebuilt. These images were set in BSS during [Update NCN images](README.md#update-ncn-images)
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

    1. After successfully upgrading the `CANARY_NODE`, continue upgrading the remaining storage nodes.

        1. Get a comma seperated list of storage nodes to be upgraded.

            ```bash
            STORAGE_NODES="$(ceph orch host ls | awk '/^ncn\-s/{if ($1 != "'"$CANARY_NODE"'") print $1}')"
            STORAGE_NODES="${STORAGE_NODES//$'\n'/,}"
            echo "$STORAGE_NODES"
            ```

        1. Upgrade remaining storage nodes.

            ```bash
            /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh "${STORAGE_NODES}" --upgrade
            ```

    For troubleshooting the storage node upgrades, see the notes in the [CSM storage node upgrade procedure](../Stage_2.md#storage-node-image-upgrade-and-ceph-upgrade).

1. (`ncn-m001#`) Export `CSM_ARTI_DIR` environment variable. (`CSM_RELEASE_VERSION` and `CSM_DISTDIR` is expected to already be set).

    ```bash
    CSM_REL_NAME="csm-${CSM_RELEASE_VERSION}"
    export CSM_ARTI_DIR="${CSM_DISTDIR}"
    echo "${CSM_ARTI_DIR}"
    ```

1. (`ncn-m001#`) Update the `/etc/cray/upgrade/csm/myenv` file with the correct `CSM_RELEASE`, `CSM_ARTI_DIR` and `CSM_REL_NAME` values.

    1. Backup the previous `myenv` file.

        ```bash
        mv /etc/cray/upgrade/csm/myenv /etc/cray/upgrade/csm/myenv.old
        ```

    1. Create the new `myenv` file.

        ```bash
        cat << EOF > /etc/cray/upgrade/csm/myenv
        export CSM_ARTI_DIR=${CSM_ARTI_DIR}
        export CSM_RELEASE=${CSM_RELEASE}
        export CSM_REL_NAME=${CSM_REL_NAME}
        EOF
        ```

    1. `cat` the `/etc/cray/upgrade/csm/myenv` file to make sure it is correct.

        ```bash
        cat /etc/cray/upgrade/csm/myenv
        ```

1. Upgrade master nodes and worker nodes using the following steps, these will walk through the [CSM Stage 3 Upgrade Kubernetes documentation](../Stage_3.md) steps.

    1. (`ncn-m001#`) Start with step [Stage 3.1 - Master node image upgrade](../Stage_3.md#stage-31---master-node-image-upgrade).

    1. (`ncn-m001#`) Perform [Stage 3.2 - Worker node image upgrade](../Stage_3.md#stage-32---worker-node-image-upgrade).

    1. (`ncn-m002#`) From `ncn-m002`, commence the upgrade for `ncn-m001`.

        1. Source the `/etc/cray/upgrade/csm/myenv` file to set environment variables. Also, set the `CSM_RELEASE_VERSION` environment variable.

            ```bash
            source /etc/cray/upgrade/csm/myenv
            export CSM_RELEASE_VERSION="${CSM_RELEASE}"
            ```

        1. Verify that the `CSM_ARTI_DIR`, `CSM_RELEASE`, `CSM_RELEASE_VERSION`, and `CSM_REL_NAME` variables are set correctly.

            ```bash
            echo -e "CSM_ARTI_DIR: $CSM_ARTI_DIR\nCSM_RELEASE: $CSM_RELEASE\nCSM_RELEASE_VERSION: $CSM_RELEASE_VERSION\nCSM_REL_NAME: $CSM_REL_NAME"
            ```

        1. Perform [Stage 3.3 - `ncn-m001` upgrade](../Stage_3.md#stage-33---ncn-m001-upgrade) and return to this document.

## Return to CSM `1.5.3` patch

Return to the next step of the CSM `1.5.3` patch procedure [Configure E1000 node and Redfish Exporter for SMART data](index.md#configure-e1000-node-and-redfish-exporter-for-smart-data).
