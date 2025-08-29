# Reboot NCNs with IUF

- [1. Reboot NCNs with IUF](#1-reboot-ncns-with-iuf)
    - [1.1 Utility storage nodes](#11-utility-storage-nodes-ceph)
    - [1.2 NCN worker nodes](#12-ncn-worker-nodes)

**`NOTE`** Rebooting master nodes is not supported with IUF and must be performed manually as mentioned [here](Reboot_NCNs_manual.md#ncn-master-nodes).

## 1. Reboot NCNs with IUF

**`NOTE`** Additional arguments are available to control the behavior of the `management-nodes-rollout` stage, for example `--limit-management-rollout` and `-cmrp`. See the
[`management-nodes-rollout` stage documentation](../iuf/stages/management_nodes_rollout.md) for details and adjust the examples below if necessary.

### 1.1 Utility storage nodes (Ceph)

Follow the steps below to reboot storage nodes:

1. Perform the NCN storage node reboot. This reboots a single storage node first and then reboots the remaining storage nodes.

    1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN storage node.

        ```bash
        STORAGE_CANARY=ncn-s001
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_CANARY} --management-rollout-strategy reboot
        ```

    1. (`ncn-m001#`) Reboot the remaining NCN storage nodes once the first has rebooted successfully. This reboots NCN storage nodes serially.
    Get the number of storage nodes based on the cluster and verify that it is correct. The storage canary node should not be in the list since it has already been rebooted.
    The list of storage nodes can be manually entered as list of storage
    node names separated by spaces if it is not desired to reboot all of the remaining storage nodes.

        ```bash
        STORAGE_NODES="$(ceph orch host ls | grep ncn-s | grep -v "$STORAGE_CANARY" | awk '{print $1}' | xargs echo)"
        echo "$STORAGE_NODES"
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_NODES} --management-rollout-strategy reboot
        ```

### 1.2 NCN worker nodes

**`NOTE`** When using the option `--limit-management-rollout` to pass the list of nodes for `management-nodes-rollout`, ensure that the label `iuf-prevent-reboot=true` is not set on any of the nodes passed in the list.

1. (`ncn-m001#`) Verify if any nodes are labeled with `iuf-prevent-reboot=true`.

    ```bash
    kubectl get nodes --show-labels | grep iuf-prevent-reboot
    ```

1. (`ncn-m001#`) Use `kubectl` to remove the `iuf-prevent-reboot=true` label from the node.

    ```bash
    kubectl label nodes "${NODE}" --overwrite iuf-prevent-reboot-
    ```

Follow the steps below to reboot worker nodes:

1. Perform the NCN worker node reboot. This reboots a single worker node first and then reboots the remaining worker nodes.

    1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN worker node.
    This will reboot the canary node.
    The worker canary node can be any worker node and does not have to be `ncn-w001`.

        ```bash
        WORKER_CANARY=ncn-w001
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${WORKER_CANARY} --management-rollout-strategy reboot
        ```

    1. (`ncn-m001#`) Use `kubectl` to apply the `iuf-prevent-reboot=true` label to the canary node to prevent it from unnecessarily rebooting again.

        ```bash
        kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-reboot=true
        ```

    1. (`ncn-m001#`) Verify the IUF node labels are present on the desired node.

        ```bash
        kubectl get nodes --show-labels | grep iuf-prevent-reboot
        ```

    1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage on all remaining worker nodes.

        **`NOTE`** For this step, the argument to `--limit-management-rollout` can be `Management_Worker` or a list of worker
        node names separated by spaces. If `Management_Worker` is supplied, all worker nodes that are not labeled
        with `iuf-prevent-reboot=true` will be reboot. If a list of worker node names is supplied, then those worker nodes will be reboot.

        **Choose one** of the following two options. The difference between the options is the `limit-management-rollout` argument, but the two options do the same thing.

        1. (`ncn-m001#`) Execute `management-nodes-rollout` on all `Management_Worker` nodes.

            ```bash
            iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout Management_Worker --management-rollout-strategy reboot
            ```

        1. (`ncn-m001#`) Execute `management-nodes-rollout` on a group of worker nodes. The list of worker nodes can be manually edited if it is undesirable to reboot all of the workers with one execution.

            ```bash
            WORKER_NODES=$(kubectl get node | grep -P 'ncn-w\d+' | grep -v $WORKER_CANARY |  awk '{print $1}' | xargs)
            echo $WORKER_NODES
            ```

            ```bash
            iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout $WORKER_NODES --management-rollout-strategy reboot
            ```

    1. (`ncn-m001#`) Use `kubectl` to remove the `iuf-prevent-rollout=true` label from the canary node.

        ```bash
        kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-reboot-
        ```

**`NOTE`** To complete reboot of master nodes manually, refer to the procedure mentioned [here](Reboot_NCNs_manual.md#ncn-master-nodes).

[operations/node_management/Reboot_NCNs_iuf.md](#ncn-worker-nodes)
