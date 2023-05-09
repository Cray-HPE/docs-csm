# Stage 1 - Ceph image upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Stage 1 - Ceph image upgrade](#stage-1---ceph-image-upgrade)
  - [Start typescript](#start-typescript)
  - [Run Ceph Latency Repair Script](#run-ceph-latency-repair-script)
  - [Apply boot order workaround](#apply-boot-order-workaround)
  - [Upload Ceph container images to Nexus](#upload-ceph-container-images-to-nexus)
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

## CSM Upgrade requirement for upgrades to a new CSM release version

**IMPORTANT:**

> If the upgrade is to a new CSM release, e.g. `CSM-1.2.0` to `CSM-1.3.0`, then you will need to run the following to upgrade Ceph. This will upgrade Ceph from `v15.2.15` to `v16.2.9`.

1. (`ncn-m001#`) Check that Ceph version `16.2.9` is in Nexus.

    ```bash
    ceph orch upgrade check registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v16.2.9
    ```
  
    Expected output for a successful check should contain `target_digest`, `target_id`, `target_name`. The following is an example :

    ```bash
    "target_digest": "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:a960130143d4feb952d6afc205ffcc0d7d033f78839a38339e46c122646910d5",
    "target_id": "87b249bff032ea26a91e455c43b7b2feb07e03c1b10bc32885ca9d583fc08236",
    "target_name": "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v16.2.9"
    ```

    A failed check will provide the following error:

    ```bash
    Error EINVAL: host ncn-s001 `cephadm pull` failed: cephadm exited with an error code: 1, stderr:Pulling container image registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v16.2.9...
    ```

    This failure means that the Ceph image with version `16.2.9` is not in Nexus. Verify that the upgrade `prerequisites.sh` script completed successfully. This script uploads images to Nexus.

1. (`ncn-m001#`) Upgrade Ceph to `16.2.9`.

   ```bash
   ceph orch upgrade start registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v16.2.9
   ```

1. (`ncn-m001, ncn-s00[1/2/3]#`) Monitor the upgrade.

    ```bash
    watch ceph orch upgrade status
    ```

    Other helpful commands for monitoring the status of the upgrade are below.

    ```bash
    watch ceph orch ps
    ceph -W cephadm
    ```

1. Wait for the upgrade to complete. Expected output after a successful upgrade:

    ```bash
    ncn-s001:~ # ceph orch upgrade status
    {
        "target_image": null,
        "in_progress": false,
        "services_complete": [],
        "progress": null,
        "message": ""
    }
    ```

## CSM Upgrade requirement for upgrades staying within a CSM release version

**IMPORTANT:**

> If the upgrade is staying with a CSM release, e.g. `CSM-1.3.0-rc1` to `CSM-1.3.0-rc2`, then you will need to run the following to point the Ceph cluster to use the Ceph container image stored in Nexus.
> The issue stems from slightly different `sha` values for the Ceph containers for in-family CSM storage node images which will prevent the Ceph containers from starting.

(`ncn-s001#`) Upload Ceph container images into Nexus and restart daemons so that they use the image in Nexus.

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
