# Stage 2 - Ceph image upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Stage 2 - Ceph image upgrade](#stage-2---ceph-image-upgrade)
  - [Start typescript](#start-typescript)
  - [Argo workflows](#argo-workflows)
  - [Storage node image upgrade and Ceph upgrade](#storage-node-image-upgrade-and-ceph-upgrade)
  - [Stop typescript](#stop-typescript)
  - [Stage completed](#stage-completed)

## Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_2.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Argo workflows

Before starting the [Storage node image upgrade and Ceph upgrade](#storage-node-image-upgrade-and-ceph-upgrade), access the Argo UI to view the progress of this stage.
Note that the progress for the current stage will not show up in Argo before the storage node image upgrade script has been started.

For more information, see [Using the Argo UI](../operations/argo/Using_the_Argo_UI.md) and [Using Argo Workflows](../operations/argo/Using_Argo_Workflows.md).

## Storage node image upgrade and Ceph upgrade

(`ncn-m001#`) Run `ncn-upgrade-worker-storage-nodes.sh` with the `--upgrade` flag for all storage nodes to be upgraded. Provide the storage nodes in a comma-separated list, such as `ncn-s001,ncn-s002,ncn-s003`.
This upgrades the storage nodes sequentially. Once all storage nodes have been upgraded, this workflow will upgrade Ceph to `v17.2.6`.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001,ncn-s002,ncn-s003 --upgrade
```

**`NOTE`**
It is possible to upgrade a single storage node at a time using the following command.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001 --upgrade
```

>**Storage node image upgrade troubleshooting**
>
> - The best troubleshooting tool for this stage is the Argo UI. Information about accessing this UI and about using Argo Workflows is above.
> - If the upgrade is 'waiting for Ceph `HEALTH_OK`', the output from commands `ceph -s` and `ceph health detail` should provide information.
> - If a crash has occurred, [dumping the Ceph crash data](../operations/utility_storage/Dump_Ceph_Crash_Data.md) will return Ceph to healthy state and allow the upgrade to continue.
>   The crash should be evaluated to determine if there is an issue that should be addressed.
> - Refer to [storage troubleshooting documentation](../operations/utility_storage/Utility_Storage.md#storage-troubleshooting-references) for Ceph related issues.
> - Refer to [troubleshoot Ceph image with tag:'\<none\>'](../operations/utility_storage/Troubleshoot_ceph_image_with_none_tag.md) if running `podman images` on a storage node shows an image with tag:\<none\>.

## Stop typescript

For any typescripts that were started during this stage, stop them with the `exit` command.

## Stage completed

All the Ceph nodes have been rebooted into the new image.

This stage is completed. Continue to [Stage 3](Stage_3.md).
