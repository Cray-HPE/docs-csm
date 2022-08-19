# Stage 1 - Ceph image upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

Before starting Stage 1, access the Argo UI to view the progress of this stage. For more information, see [Using the Argo UI](../operations/argo/Using_the_Argo_UI.md).

***

## Procedure

### Storage node image upgrade

1. (`ncn-m001#`) Run `ncn-upgrade-worker-storage-nodes.sh` for all storage nodes to be upgraded. Provide the storage nodes in a comma-separated list, such as `ncn-s001,ncn-s002,ncn-s003`. This upgrades the storage nodes sequentially.

    ```bash
    /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001,ncn-s002,ncn-s003
    ```

> **`NOTE`**
> It is possible to upgrade a single storage node at a time using the following command.
>
>```bash
> /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001
>```

***

### Ensure `rbd` stats monitoring is enabled

1. (`ncn-m001#`) Run the below commands to enable the `rbd` stats collection on the pools.

```bash
ceph config set mgr mgr/prometheus/rbd_stats_pools "kube,smf"
ceph config set mgr mgr/prometheus/rbd_stats_pools_refresh_interval 600
```

***

## Stage completed

All the Ceph nodes have been rebooted into the new image.

This stage is completed. Continue to [Stage 2](Stage_2.md).
