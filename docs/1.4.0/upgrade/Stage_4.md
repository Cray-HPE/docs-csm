# Stage 4 - Ceph Upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, then see
[Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Ceph upgrade contents](#ceph-upgrade-contents)
- [Start typescript](#start-typescript)
- [Procedure](#procedure)
  - [Perform upgrade](#perform-upgrade)
  - [Diagnose a stalled upgrade](#diagnose-a-stalled-upgrade)
    - [`UPGRADE_FAILED_PULL: Upgrade: failed to pull target image`](#upgrade_failed_pull-upgrade-failed-to-pull-target-image)
  - [Troubleshoot a failed upgrade](#troubleshoot-a-failed-upgrade)
- [Stop typescript](#stop-typescript)
- [Stage completed](#stage-completed)

## Ceph upgrade contents

The upgrade includes all fixes from `v15.2.15` through `v16.2.9`. See the [Ceph version index](https://docs.ceph.com/en/latest/releases/pacific/) for details.

## Start typescript

1. (`ncn-m002#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m002#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_4.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Procedure

- This upgrade is performed using the `cubs_tool`.
- The `cubs_tool.py` can be found on `ncn-s00[1-3]` in `/srv/cray/script/common/`
- Unless otherwise noted, all `ceph` commands that may need to be used in this stage may be run on any master node or any of the first three storage
  nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`).

### Perform upgrade

1. (`ncn-s001#`) Initiate the upgrade.

   ```bash
   /srv/cray/scripts/common/cubs_tool.py --version 16.2.9 --registry localhost --upgrade
   ```

   Example output:

   ```text
   Upgrade Available!!  The specified version v16.2.9 has been found in the registry
   Initiating Ceph upgrade from v16.2.7 to v16.2.9
   ```

   **Note:** The source version in the output may vary, but the target version should match what is shown above. If the output does not match what is expected, then this can indicate that a previous step has failed.
   Review the output from [Stage 1](Stage_1.md) for errors or contact support.

   If this is an in family upgrade and the Ceph upgrade was completed during [Stage 1](Stage_1.md), then the upgrade will not run again. The expected output is stated below.

   ```text
   Your current version is the same as the proposed version 16.2.9
   ```

1. Monitor the upgrade.

   The `cubs_tool` will automatically watch the upgrade.
   As services are upgraded, they will move from the `Total Current` column to the `Total Upgraded` column.

   ```text
   +---------+---------------+----------------+
   | Service | Total Current | Total Upgraded |
   +---------+---------------+----------------+
   |   MGR   |       0       |       2        |
   |   MON   |       3       |       0        |
   |  Crash  |       3       |       0        |
   |   OSD   |       9       |       0        |
   |   MDS   |       3       |       0        |
   |   RGW   |       3       |       0        |
   +---------+---------------+----------------+
   ```

   The final result should have `0` for every service in the `Total Current` column.

   ```text
   +---------+---------------+----------------+
   | Service | Total Current | Total Upgraded |
   +---------+---------------+----------------+
   |   MGR   |       0       |       3        |
   |   MON   |       0       |       3        |
   |  Crash  |       0       |       3        |
   |   OSD   |       0       |       9        |
   |   MDS   |       0       |       3        |
   |   RGW   |       0       |       3        |
   +---------+---------------+----------------+
   ```

1. If the upgrade has completed successfully, then a report will automatically be printed and the output will state successful completion. If the upgrade is unsuccessful, then the output will state the error.

   Expected output:

   ```text
   +----------+-------------+-----------------+---------+---------+
   |   Host   | Daemon Type |        ID       | Version |  Status |
   +----------+-------------+-----------------+---------+---------+
   | ncn-s001 |     mgr     | ncn-s001.antgnu |  16.2.9 | running |
   | ncn-s002 |     mgr     | ncn-s002.jhwgup |  16.2.9 | running |
   | ncn-s003 |     mgr     | ncn-s003.wzoivk |  16.2.9 | running |
   +----------+-------------+-----------------+---------+---------+
   +----------+-------------+----------+---------+---------+
   |   Host   | Daemon Type |    ID    | Version |  Status |
   +----------+-------------+----------+---------+---------+
   | ncn-s001 |     mon     | ncn-s001 |  16.2.9 | running |
   | ncn-s002 |     mon     | ncn-s002 |  16.2.9 | running |
   | ncn-s003 |     mon     | ncn-s003 |  16.2.9 | running |
   +----------+-------------+----------+---------+---------+
   +----------+-------------+----------+---------+---------+
   |   Host   | Daemon Type |    ID    | Version |  Status |
   +----------+-------------+----------+---------+---------+
   | ncn-s001 |    crash    | ncn-s001 |  16.2.9 | running |
   | ncn-s002 |    crash    | ncn-s002 |  16.2.9 | running |
   | ncn-s003 |    crash    | ncn-s003 |  16.2.9 | running |
   +----------+-------------+----------+---------+---------+
   +----------+-------------+----+---------+---------+
   |   Host   | Daemon Type | ID | Version |  Status |
   +----------+-------------+----+---------+---------+
   | ncn-s001 |     osd     | 0  |  16.2.9 | running |
   | ncn-s001 |     osd     | 3  |  16.2.9 | running |
   | ncn-s001 |     osd     | 7  |  16.2.9 | running |
   | ncn-s002 |     osd     | 1  |  16.2.9 | running |
   | ncn-s002 |     osd     | 5  |  16.2.9 | running |
   | ncn-s002 |     osd     | 8  |  16.2.9 | running |
   | ncn-s003 |     osd     | 2  |  16.2.9 | running |
   | ncn-s003 |     osd     | 4  |  16.2.9 | running |
   | ncn-s003 |     osd     | 6  |  16.2.9 | running |
   +----------+-------------+----+---------+---------+
   +----------+-------------+------------------------+---------+---------+
   |   Host   | Daemon Type |           ID           | Version |  Status |
   +----------+-------------+------------------------+---------+---------+
   | ncn-s001 |     mds     | cephfs.ncn-s001.sbtjip |  16.2.9 | running |
   | ncn-s002 |     mds     | cephfs.ncn-s002.gywfal |  16.2.9 | running |
   | ncn-s003 |     mds     | cephfs.ncn-s003.emebxe |  16.2.9 | running |
   +----------+-------------+------------------------+---------+---------+
   +----------+-------------+-----------------------+---------+---------+
   |   Host   | Daemon Type |           ID          | Version |  Status |
   +----------+-------------+-----------------------+---------+---------+
   | ncn-s001 |     rgw     | site1.ncn-s001.rrfbvo |  16.2.9 | running |
   | ncn-s002 |     rgw     | site1.ncn-s002.axqnca |  16.2.9 | running |
   | ncn-s003 |     rgw     | site1.ncn-s003.pxhahp |  16.2.9 | running |
   +----------+-------------+-----------------------+---------+---------+

   The upgrade has completed successfully.
   ```

   **NOTE:** This is an example only and is showing only the core Ceph components. This report can be printed manually with the following command.

   (`ncn-s001#`) Get a report of Ceph components.

   ```bash
   /srv/cray/scripts/common/cubs_tool.py --report
   ```

### Diagnose a stalled upgrade

The processes running the Ceph container image will go through the upgrade process. This involves stopping the old process
and restarting the process with the new version `16.2.9` container image.

**IMPORTANT:** Only processes running the `15.2.15` image will be upgraded. This includes `crash`, `mds`, `mgr`, `mon`, `osd`, and `rgw` processes only.

#### `UPGRADE_FAILED_PULL: Upgrade: failed to pull target image`

If `ceph -s` shows a warning with `UPGRADE_FAILED_PULL: Upgrade: failed to pull target image` as the description, then perform the following procedure
on any of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`).

1. (`ncn-s#`) Check the upgrade status.

    ```bash
    ceph orch upgrade status
    ```

    Example output:

    ```json
    {
       "target_image": "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15",
       "in_progress": true,
       "services_complete": [],
       "message": "Error: UPGRADE_FAILED_PULL: Upgrade: failed to pull target image"
     }
     ```

1. (`ncn-s#`) Pause and resume the upgrade.

    ```bash
    ceph orch upgrade pause
    ceph orch upgrade resume
    ```

1. (`ncn-s#`) Watch `cephadm`.

    This command watches the `cephadm` logs. If the issue occurs again, then it will give more details about which node may be having an issue.

    ```bash
    ceph -W cephadm
    ```

1. (`ncn-s#`) If the issue occurs again, then log into each of the storage nodes and perform a `podman` pull of the image.

    ```bash
    podman pull localhost/quay.io/ceph/ceph:v16.2.9
    ```

If these steps do not resolve the issue, then contact support for further assistance.

### Troubleshoot a failed upgrade

See [Ceph Orchestrator Usage](../operations/utility_storage/Ceph_Orchestrator_Usage.md) for additional usage and troubleshooting.

## Stop typescript

For any typescripts that were started during this stage, stop them with the `exit` command.

## Stage completed

**DO NOT** proceed past this point if the upgrade has not completed and been verified. Contact support for in-depth troubleshooting.

This stage is completed. Proceed to [Validate CSM health](README.md#4-validate-csm-health) on the main upgrade page.
