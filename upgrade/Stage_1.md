# Stage 1 - Ceph image upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Stage 1 - Ceph image upgrade](#stage-1---ceph-image-upgrade)
  - [Start typescript](#start-typescript)
  - [Run Ceph Latency Repair Script](#run-ceph-latency-repair-script)
  - [Apply boot order workaround](#apply-boot-order-workaround)
  - [Argo workflows](#argo-workflows)
  - [CSM Upgrade requirement for upgrades staying within a CSM release version](#csm-upgrade-requirement-for-upgrades-staying-within-a-csm-release-version)
  - [Storage node image upgrade](#storage-node-image-upgrade)
  - [Ensure that `rbd` stats monitoring is enabled](#ensure-that-rbd-stats-monitoring-is-enabled)
  - [Stop typescript](#stop-typescript)
  - [Stage completed](#stage-completed)

## Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_1.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

### Run Ceph Latency Repair Script

Ceph can begin to exhibit latency over time when upgrading the cluster from previous versions. It is recommended to run the `/usr/share/doc/csm/scripts/repair-ceph-latency.sh` script at [Known Issue: Ceph OSD latency](../troubleshooting/known_issues/ceph_osd_latency.md).

## Apply boot order workaround

(`ncn-m001#`) Apply a workaround for the boot order:

```bash
/usr/share/doc/csm/scripts/workarounds/boot-order/run.sh
```

## Argo workflows

Before starting [Storage node image upgrade](#storage-node-image-upgrade), access the Argo UI to view the progress of this stage.
Note that the progress for the current stage will not show up in Argo before the storage node image upgrade script has been started.

For more information, see [Using the Argo UI](../operations/argo/Using_the_Argo_UI.md) and [Using Argo Workflows](../operations/argo/Using_Argo_Workflows.md).

## CSM Upgrade requirement for upgrades staying within a CSM release version

**IMPORTANT:**

> If the upgrade is staying within a CSM release, e.g. `CSM-1.3.0-rc1` to `CSM-1.3.0-rc2`, then you will need to run the following to point the Ceph cluster to use the Ceph container image stored in Nexus.
> The issue stems from slightly different `sha` values for the Ceph containers for in-family CSM storage node images which will prevent the Ceph containers from starting.
> This script uploads local Ceph container images to nexus and restarts all Ceph daemons so they are using the image in Nexus.

(`ncn-s00[1/2/3]#`) Copy `upload_ceph_images_to_nexus.sh` from `ncn-m001` and execute it.

   ```bash
   scp ncn-m001:/usr/share/doc/csm/scripts/upload_ceph_images_to_nexus.sh /srv/cray/scripts/common/upload_ceph_images_to_nexus.sh
   /srv/cray/scripts/common/upload_ceph_images_to_nexus.sh
   ```

### Troubleshooting `upload_ceph_images_to_nexus.sh`

If the script is stuck 'Sleeping for five seconds waiting for Ceph to be healthy...' for more than 10 minutes at a time, try manually redeploying Ceph daemons with an 'error' state.

1. (`ncn-s00[1/2/3]#`) Find daemons with an 'error' state.

    ```bash
    ceph orch ps | grep error
    ```

2. (`ncn-s00[1/2/3]#`) Redeploy each daemon in an error state. For example, the `daemon_name` could be `mon.ncn-s002`.

    ```bash
    ceph orch daemon redeploy <daemon_name>
    ```

## Storage node image upgrade

(`ncn-m001#`) Run `ncn-upgrade-worker-storage-nodes.sh` for all storage nodes to be upgraded. Provide the storage nodes in a comma-separated list, such as `ncn-s001,ncn-s002,ncn-s003`. This upgrades the storage nodes sequentially.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001,ncn-s002,ncn-s003
```

**`NOTE`**
It is possible to upgrade a single storage node at a time using the following command.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001
```

>**Storage node image upgrade troubleshooting**
>
> - If the storage node upgrade is looping on the `wait-for-ncn-s00X-health` stage and Ceph is in a `HEALTH_WARN` state, this is likely **not** a problem.
Ceph needs time to recover after a node upgrade. Run `ceph -s` and observe that the percentage by `Degraded data redundancy` is decreasing.
If the percentage is not decreasing, then continue to the following troubleshooting statements.
> - The best troubleshooting tool for this stage is the Argo UI. Information about accessing this UI and about using Argo Workflows is above.
> - If the upgrade is `waiting for ceph HEALTH_OK`, the output from commands `ceph -s` and `ceph health detail` should provide information.
> - If a crash has occurred, [dumping the `ceph` crash data](../operations/utility_storage/Dump_Ceph_Crash_Data.md) will return Ceph to healthy state and allow the upgrade to continue.
>   The crash should be evaluated to determine if there is an issue that should be addressed.
> - If the following error occurs during the `check-ceph-ro-key` phase, `Can't open input file /etc/ceph/ceph.client.ro.keyring: [Errno 2] No such file or directory: '/etc/ceph/ceph.client.ro.keyring'`,
>then export the keyring in a separate terminal. The workflow will continue on its own.
>
>   (`ncn-m001#`) Export keyring.
>
>   ```bash
>   ceph auth get client.ro -o /etc/ceph/ceph.client.ro.keyring
>   ```
>
> - Refer to [storage troubleshooting documentation](../operations/utility_storage/Utility_Storage.md#storage-troubleshooting-references) for Ceph related issues.

## Ensure that `rbd` stats monitoring is enabled

(`ncn-m001#`) Run the following commands to enable the `rbd` stats collection on the pools.

```bash
ceph config set mgr mgr/prometheus/rbd_stats_pools "kube,smf"
ceph config set mgr mgr/prometheus/rbd_stats_pools_refresh_interval 600
```

## Stop typescript

For any typescripts that were started during this stage, stop them with the `exit` command.

## Stage completed

All the Ceph nodes have been rebooted into the new image.

This stage is completed. Continue to [Stage 2](Stage_2.md).
