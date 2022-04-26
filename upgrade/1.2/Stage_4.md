# Stage 4 - Ceph Upgrade

## Addresses CVEs

1. CVE-2021-3531: Swift API denial of service.
1. CVE-2021-3524: HTTP header injects via CORS in RGW.
1. CVE-2021-3509: Dashboard XSS via token cookie.
1. CVE-2021-20288: Unauthorized global_id reuse in cephx.

**IMPORTANT:**

> * This upgrade is performed using the `ceph` orchestrator.
> * The upgrade includes all fixes from v15.2.9 through to v15.2.15 listed here [Ceph version index](https://docs.ceph.com/en/latest/releases/octopus/)

## Procedure

### Upgrade

1. Check to ensure the upgrade is possible.

   ```bash
   ncn-s# ceph orch upgrade check --image registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
   ```

1. Set the container image.

   ```bash
   ncn-s# ceph config set global container_image registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
   ```

   Verify the change has occurred:

   ```bash
   ncn-s# ceph config dump -f json-pretty|jq '.[]|select(.name=="container_image")|.value'
   ```

   Expected result:

   ```text
   "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15"
   ```

1. Start the upgrade.

   ```bash
   ncn-s# ceph orch upgrade start --image registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
   ```

1. Monitor the upgrade.

***NOTE***: You may want to split these commands into multiple windows depending on the size of your cluster.

   ```bash
   ncn-s# watch "ceph -s; ceph orch ps"
   ```

**IMPORTANT:** If the `ceph -s` has a warning with "UPGRADE_FAILED_PULL: Upgrade: failed to pull target image" as the description, then follow the below procedure.

**Perform the below steps from one of these nodes (ncn-s001/2/3):**
 1. check the upgrade status.

    ```bash
    ceph orch upgrade status
    ```
    ***Sample Output***
    ```bash
    {
       "target_image": "registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15",
       "in_progress": true,
       "services_complete": [],
       "message": "Error: UPGRADE_FAILED_PULL: Upgrade: failed to pull target image"
     }
     ```
 2. Pause and resume the upgrade.

    ```bash
    ceph orch upgrade pause
    ceph orch upgrade resume
    ```

1.  Watch cephadm

    ```bash
    ceph -W cephadm
    ```

    ***Note:*** This will watch the cephadm logs and if the occurence occurs again it will give you more detail as to which node may be having an issue.

2. If the issue occurs again then log into each of the storage nodes and perform a podman pull of the image.

    ```bash
    podman pull registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v15.2.15
    ```

    * If a node cannot pulled from any of the nodes then please contact support for further assistance.


Expected Warnings:

From `ceph -s`

```text
health: HEALTH_WARN
        clients are using insecure global_id reclaim
        mons are allowing insecure global_id reclaim
```

From `ceph health detail`

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

You will see the processes running the Ceph container image go through the upgrade process. This will involve stopping the old process running the v15.2.8 container and restarting the process with the new v15.2.15 container image.

**IMPORTANT:**
Only processes running the v15.2.8 image will be upgraded. This will include `MON`, `MGR`, `MDS`, `RGW`, and `OSD` processes only.

### Post Upgrade

1. Verify the upgrade

   `ceph health detail` should only show:

   ```text
   HEALTH_WARN mons are allowing insecure global_id reclaim
   [WRN] AUTH_INSECURE_GLOBAL_ID_RECLAIM_ALLOWED: mons are allowing insecure global_id reclaim
    mon.ncn-s001 has auth_allow_insecure_global_id_reclaim set to true
    mon.ncn-s002 has auth_allow_insecure_global_id_reclaim set to true
    mon.ncn-s003 has auth_allow_insecure_global_id_reclaim set to true
    ```

   `ceph -s` should show:

   ```text
       health: HEALTH_WARN
            mons are allowing insecure global_id reclaim
   ```

   `ceph orch ps` should show `MON`, `MGR`, `MDS`, `RGW`, and `OSD` processes running version `v15.2.15`. There should be **NO** processes running version `v15.2.8`.

   A handy command to verify you are not running any older versions of ceph:

   on ncn-m001/2/3 or ncn-s001/2/3:

   ```bash
   ceph orch ps -f json-pretty|jq -r '.[]|select(.version=="15.2.8")|.version'|wc -l
   ```

   > If the above command shows any number other than 0, then the upgrade is not complete. Refer to [Ceph_Orchestrator_Usage.md](../operation/../../operations/utility_storage/Ceph_Orchestrator_Usage.md) for additional usage and troubleshooting.

   Some addtional commands to run to check the ceph upgrade:

   on ncn-m00/1/2/3 or ncn-s001/2/3:

   ```bash
   ceph orch upgrade status
   ```

   > This will give you a summary and if the upgrade is failed or still in progress.

   ```bash
   ceph -W cephadm
   ```

   > This will watch the `cephadm` process. This is the most helpful, but can be slow as events will have to retry in order to see which part failed and why.

**IMPORTANT:** If you have any ceph mon/mgr/mds/osd/rgw processes still running 15.2.8 then do the following:

```bash
ceph orch upgrade stop
```

> DO NOT proceed past this point if the upgrade has not completed and been verified. Contact support for in-depth troubleshooting.

1. Disable `auth_allow_insecure_global_id_reclaim`

   ```bash
   ncn-s# ceph config set mon auth_allow_insecure_global_id_reclaim false
   ```

   Now the status of the cluster should show **`HEALTH_OK`**.

   Please ***NOTE*** that this may take up to 30 seconds to apply and the health to return to **`HEALTH_OK`**.

Once the above steps have been completed, proceed to [Stage 5](Stage_5.md).

