# Stage 4 - Ceph Upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Addresses CVEs

* `CVE-2021-3531`: Swift API denial of service.
* `CVE-2021-3524`: HTTP header injects via `CORS` in `RGW.`.
* `CVE-2021-3509`: Dashboard `XSS` via token cookie.
* `CVE-2021-20288`: Unauthorized `global_id` reuse in `cephx`.

The upgrade includes all fixes from `v15.2.9` through `v15.2.15`. See the [Ceph version index](https://docs.ceph.com/en/latest/releases/octopus/) for details.

## Procedure

This upgrade is performed using the `ceph` orchestrator. Unless otherwise noted, all `ceph` commands in this stage may be run on any master node or any
of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`).

### Initiate upgrade

1. Check to ensure that the upgrade is possible.

   ```bash
   ncn-ms# ceph orch upgrade check --image registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
   ```

   Example output:

   ```json
   {
       "needs_update": {
           "alertmanager.ncn-s001": {
               "current_id": "6ec9fa439af31102c9e6581cbb3d12ee2ab258dada41d40d0f8ad987e8ff266f",
               "current_name": "registry.local/quay.io/prometheus/alertmanager:v0.21.0",
               "current_version": "0.21.0"
           },
           "crash.ncn-s001": {
               "current_id": "6a777b4f888c24feec6e12eeeff4ab485f2c043b415bc2213815d5fb791f2597",
               "current_name": "registry.local/ceph/ceph:v15.2.8",
               "current_version": "15.2.8"
           },
           "crash.ncn-s002": {
               "current_id": "6a777b4f888c24feec6e12eeeff4ab485f2c043b415bc2213815d5fb791f2597",
               "current_name": "registry.local/ceph/ceph:v15.2.8",
               "current_version": "15.2.8"
           },
           "[ ... lines omitted for readability ... ]",
           "rgw.site1.zone1.ncn-s003.adrubu": {
               "current_id": "6a777b4f888c24feec6e12eeeff4ab485f2c043b415bc2213815d5fb791f2597",
               "current_name": "registry.local/ceph/ceph:v15.2.8",
               "current_version": "15.2.8"
           }
       },
       "target_id": "cba763a65a95e8849d578e05b111123f55a78ab096e67e8ecf7fdc98e67aea71",
       "target_name": "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15",
       "target_version": "ceph version 15.2.15 (2dfb18841cfecc2f7eb7eb2afd65986ca4d95985) octopus (stable)",
       "up_to_date": []
   }
   ```

   **Notes:**

   * This upgrade is targeting the Ceph processes running `15.2.8` only.
   * The monitoring services may be listed but those are patched internally and will not be upgraded with this upgrade.
     * This includes `alertmanager`, `prometheus`, `node-exporter`, and `grafana`.
   * The main goals of this check are to see the listed `15.2.8` services and to see the output at the bottom that confirms the presence of the `15.2.15` target image.
   * If the output does not match what is expected, then this can indicate that a previous step has failed.
     Review output from [Stage 1](Stage_1.md) for errors or contact support.

1. Set the container image.

   ```bash
   ncn-ms# ceph config set global container_image registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
   ```

1. Verify that the change has occurred.

   ```bash
   ncn-ms# ceph config dump -f json-pretty|jq '.[]|select(.name=="container_image")|.value'
   ```

   Expected result:

   ```text
   "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15"
   ```

1. Start the upgrade.

   ```bash
   ncn-ms# ceph orch upgrade start --image registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
   ```

1. Monitor the upgrade.

   > If upgrading a larger cluster, consider splitting this into two different `watch` commands in separate windows.

   ```bash
   ncn-ms# watch "ceph -s; ceph orch ps"
   ```

### Monitor upgrade

The processes running the Ceph container image will go through the upgrade process. This involves stopping the old process running the version `15.2.8`
container and restarting the process with the new version `15.2.15` container image.

**IMPORTANT:** Only processes running the `15.2.8` image will be upgraded. This includes `crash`, `mds`, `mgr`, `mon`, `osd`, and `rgw` processes only.

#### `UPGRADE_FAILED_PULL: Upgrade: failed to pull target image`

If `ceph -s` shows a warning with `UPGRADE_FAILED_PULL: Upgrade: failed to pull target image` as the description, then perform the following procedure
on any of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`).

1. Check the upgrade status.

    ```bash
    ncn-s# ceph orch upgrade status
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
    ncn-s# ceph orch upgrade pause
    ncn-s# ceph orch upgrade resume
    ```

1. Watch `cephadm`.

    This command watches the `cephadm` logs. If the issue occurs again, it will give more details about which node may be having an issue.

    ```bash
    ncn-s# ceph -W cephadm
    ```

1. If the issue occurs again, then log into each of the storage nodes and perform a `podman` pull of the image.

    ```bash
    ncn-s# podman pull registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
    ```

If these steps do not resolve the issue, then contact support for further assistance.

#### Expected warnings

* From `ceph -s`:

    ```text
    health: HEALTH_WARN
            clients are using insecure global_id reclaim
            mons are allowing insecure global_id reclaim
    ```

* From `ceph health detail`:

    ```text
    HEALTH_WARN clients are using insecure global_id reclaim; mons are allowing insecure global_id reclaim; 1 osds down
    [WRN] AUTH_INSECURE_GLOBAL_ID_RECLAIM: clients are using insecure global_id reclaim
        osd.4 at [REDACTED] is using insecure global_id reclaim
        mds.cephfs.ncn-s001.qcalye at [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s001.lgfngf at [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s001.lgfngf at [REDACTED] is using insecure global_id reclaim
        osd.0 at [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s003.wllbbx at [REDACTED] is using insecure global_id reclaim
        osd.5 at [REDACTED] is using insecure global_id reclaim
        osd.7 at [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s002.aanqmw at [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s002.aanqmw at [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s002.aanqmw a [REDACTED] is using insecure global_id reclaim
        osd.3 at [REDACTED]] is using insecure global_id reclaim
        mds.cephfs.ncn-s002.tdrohq at [REDACTED]] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s003.wllbbx a [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s001.lgfngf a [REDACTED] is using insecure global_id reclaim
        client.rgw.site1.zone1.ncn-s003.wllbbx a [REDACTED] is using insecure global_id reclaim
        mds.cephfs.ncn-s003.ddbgzt at [REDACTED]] is using insecure global_id reclaim
        osd.8 at [REDACTED]] is using insecure global_id reclaim
        osd.1 at [REDACTED]] is using insecure global_id reclaim
    [WRN] AUTH_INSECURE_GLOBAL_ID_RECLAIM_ALLOWED: mons are allowing insecure global_id reclaim
        mon.ncn-s001 has auth_allow_insecure_global_id_reclaim set to true
        mon.ncn-s002 has auth_allow_insecure_global_id_reclaim set to true
        mon.ncn-s003 has auth_allow_insecure_global_id_reclaim set to true
    ```

### Verify completed upgrade

Verify that the upgrade has completed using the following procedure.

1. Verify that the upgrade is no longer in progress.

   ```bash
   ncn-ms# ceph orch upgrade status
   ```

   In the output of this command, validate that the `in_progress` field is `false`. If it is `true`, then
   the upgrade is still underway. In that case, retry this step after waiting for a few minutes.

   If the upgrade encountered any problems, there may be indications of this in the `messages` field of the
   command output.

   In the case of a completed upgrade without errors, the output will resemble the following:

   ```json
   {
       "target_image": null,
       "in_progress": false,
       "services_complete": [],
       "message": ""
   }
   ```

1. Verify that `ceph health detail` only shows the following:

   ```text
   HEALTH_WARN mons are allowing insecure global_id reclaim
   [WRN] AUTH_INSECURE_GLOBAL_ID_RECLAIM_ALLOWED: mons are allowing insecure global_id reclaim
    mon.ncn-s001 has auth_allow_insecure_global_id_reclaim set to true
    mon.ncn-s002 has auth_allow_insecure_global_id_reclaim set to true
    mon.ncn-s003 has auth_allow_insecure_global_id_reclaim set to true
   ```

1. Verify that `ceph -s` shows the following for its `health`:

   ```text
       health: HEALTH_WARN
            mons are allowing insecure global_id reclaim
   ```

1. Verify that all Ceph `crash`, `mds`, `mgr`, `mon`, `osd`, and `rgw` processes are running version `15.2.15`.

   The following command will count the number of `crash`, `mds`, `mgr`, `mon`, `osd`, and `rgw` processes which are not running version `15.2.15`.

   ```bash
   ncn-ms# ceph orch ps -f json-pretty|jq -r '[.[]|select(.version!="15.2.15")|select(.daemon_type as $d | [ "crash", "mds", "mgr", "mon", "osd", "rgw" ] | index($d))] | length'
   ```

   If the command outputs any number other than zero, then this means that not all expected processes are running `15.2.15`. In that case, do the following:

   1. List the processes which are not at the expected version.

      ```bash
      ncn-ms# ceph orch ps -f json-pretty|jq -r '[.[]|select(.version!="15.2.15")|select(.daemon_type as $d | [ "crash", "mds", "mgr", "mon", "osd", "rgw" ] | index($d))]'
      ```

   1. Make sure the upgrade has stopped.

      ```bash
      ncn-ms# ceph orch upgrade stop
      ```

   1. Troubleshoot the failed upgrade.

      The upgrade is not complete. See
      [`Ceph_Orchestrator_Usage.md`](../operation/../../operations/utility_storage/Ceph_Orchestrator_Usage.md) for additional usage and troubleshooting.

1. Verify that no processes are running version `15.2.8`.

   The following command will count the number of processes which are running version `15.2.8`.

   ```bash
   ncn-ms# ceph orch ps -f json-pretty|jq -r '[.[]|select(.version=="15.2.8")] | length'
   ```

   If the command outputs any number other than zero, then this means there are processes still running `15.2.8`. In that case, do the following:

   1. List the processes which are not at the expected version.

      ```bash
      ncn-ms# ceph orch ps -f json-pretty|jq -r '[.[]|select(.version=="15.2.8")]'
      ```

   1. Make sure the upgrade has stopped.

      ```bash
      ncn-ms# ceph orch upgrade stop
      ```

   1. Troubleshoot the failed upgrade.

      The upgrade is not complete. See
      [`Ceph_Orchestrator_Usage.md`](../operation/../../operations/utility_storage/Ceph_Orchestrator_Usage.md) for additional usage and troubleshooting.

**DO NOT** proceed past this point if the upgrade has not completed and been verified. Contact support for in-depth troubleshooting.

### Post-upgrade

1. Disable `auth_allow_insecure_global_id_reclaim`:

   ```bash
   ncn-ms# ceph config set mon auth_allow_insecure_global_id_reclaim false
   ```

1. Wait until the Ceph cluster health is `HEALTH_OK`.

    It may take up to 30 seconds for the health to return to `HEALTH_OK`.

    ```bash
    ncn-ms# ceph health detail
    ```

    Successful output is:

    ```text
    HEALTH_OK
    ```

<a name="stage_completed"></a>

## Stage completed

This stage is completed. Continue to [Stage 5](Stage_5.md).
