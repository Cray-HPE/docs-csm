# Stage 4 - Ceph Upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Addresses Bugs and CVEs

The upgrade includes all fixes from `v15.2.15` through `v16.2.9`. See the [Ceph version index](https://docs.ceph.com/en/latest/releases/pacific/) for details.

## Procedure

* This upgrade is performed using the `cubs_tool`.
* The `cubs_tool.py` can be found on `ncn-s00[1-3]` in `/srv/cray/script/common/`
* Unless otherwise noted, all `ceph` commands that may need to be used in this stage may be run on any master node or any of the first three storage nodes (`ncn-s00[1-3]`).

### Initiate upgrade

1. Check to ensure that the upgrade is possible.

   On `ncn-s001`:

   ```bash
   /srv/cray/scripts/common/cubs_tool.py --version 16.2.9 --registry localhost
   ```

   Example output:

   ```text
   Upgrade Available!!  The specified version v16.2.9 has been found in the registry
   ```

   **Notes:**

   * This upgrade is targeting the Ceph processes running `15.2.15` only.
   * The monitoring services may be listed but those are patched internally and may not be upgraded with this upgrade.
     * This includes `alertmanager`, `prometheus`, `node-exporter`, and `grafana`.
   * If the output does not match what is expected, then this can indicate that a previous step has failed.
     Review output from [Stage 1](Stage_1.md) for errors or contact support.

1. Start the upgrade.

   ```bash
   /srv/cray/scripts/common/cubs_tool.py --version v16.2.9 --registry localhost --upgrade
   ```

   Example output:

   ```text
   Upgrade Available!!  The specified version v16.2.9 has been found in the registry
   Initiating Ceph upgrade from v16.2.7 to v16.2.9
   ```

1. Monitor the upgrade.

   The `cubs_tool` will automatically watch the upgrade.  As services are upgraded they will move from the ***Current*** column to the ***Upgraded*** column.

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

   This will progress to the end result of:

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

1. Verify completed upgrade

   On `ncn-s001`:

   ```bash
   /srv/cray/scripts/common/cubs_tool.py --report
   ```

   Expected output:

   ```bash
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
   ```

   **NOTE:** This is an example only and is showing only the core Ceph components.  

### Diagnose a stalled upgrade

The processes running the Ceph container image will go through the upgrade process. This involves stopping the old process running the version `15.2.15`
container and restarting the process with the new version `16.2.9` container image.

**IMPORTANT:** Only processes running the `15.2.15` image will be upgraded. This includes `crash`, `mds`, `mgr`, `mon`, `osd`, and `rgw` processes only.

#### `UPGRADE_FAILED_PULL: Upgrade: failed to pull target image`

If `ceph -s` shows a warning with `UPGRADE_FAILED_PULL: Upgrade: failed to pull target image` as the description, then perform the following procedure
on any of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`).

1. Check the upgrade status.

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

1. Pause and resume the upgrade.

    ```bash
    ceph orch upgrade pause
    ceph orch upgrade resume
    ```

1. Watch `cephadm`.

    This command watches the `cephadm` logs. If the issue occurs again, it will give more details about which node may be having an issue.

    ```bash
    ceph -W cephadm
    ```

1. If the issue occurs again, then log into each of the storage nodes and perform a `podman` pull of the image.

    ```bash
    podman pull localhost/quay.io/ceph/ceph:v16.2.9
    ```

If these steps do not resolve the issue, then contact support for further assistance.

   1. Troubleshoot the failed upgrade.

      The upgrade is not complete. See
      See [Ceph Orchestrator Usage](../operations/utility_storage/Ceph_Orchestrator_Usage.md) for additional usage and troubleshooting.

   1. Verify that no processes are running the old version `15.2.15`.

   The following command will count the number of processes which are running version `15.2.15`.

   ```bash
   ceph orch ps -f json-pretty|jq -r '[.[]|select(.version=="15.2.15")] | length'
   ```

   If the command outputs any number other than zero, then this means there are processes still running `15.2.15`. In that case, do the following:

   1. List the processes which are not at the expected version.

      ```bash
      ceph orch ps -f json-pretty|jq -r '[.[]|select(.version=="15.2.15")]'
      ```

   2. Make sure the upgrade has stopped.

      ```bash
      ceph orch upgrade stop
      ```

   3. Troubleshoot the failed upgrade.

      The upgrade is not complete. See
      [Ceph Orchestrator Usage](../operations/utility_storage/Ceph_Orchestrator_Usage.md) for additional usage and troubleshooting.

**DO NOT** proceed past this point if the upgrade has not completed and been verified. Contact support for in-depth troubleshooting.

## Stage completed

This stage is completed. Continue to [Stage 5](Stage_5.md).
