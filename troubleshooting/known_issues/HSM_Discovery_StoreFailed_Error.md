# HSM Discovery `StoreFailed` Error

This problem occurs when hardware exists in a system across multiple BMCs that have bogus non-empty values for serial numbers and those BMCs are being discovered at the same time. This causes the same non-unique FRUID to be generated for that hardware.
Concurrent discovery of theses BMCs causes database deadlocks to occur and causes HSM discovery for most of those BMCs to fail with `StoreFailed`.

## Known Causes

One of the known types of hardware to cause this is Castle nodes with HBM.
In this case, a non-unique FRUID is generated because the empty DIMM slots do not include the redfish `Status` field showing it is `Absent` and the `SerialNumber` field shows up as a non-empty string, "NO DIMM".
Because it isn't reporting `Absent`, HSM thinks it is populated and creates a FRU entry for it.
Because the `SerialNumber` redfish field is non-empty, HSM creates a FRUID for the FRU entry where HSM would have otherwise just created a unique bogus FRUID.
The FRUID that gets created for all empty DIMM slots end up being the same, `Memory.Unknown.NODIMM.NODIMM`.

## Workarounds

### Wait For it to Clear Up

This issue will clear itself up after a while if left alone if the `hms-discovery` cron job is enabled.

The discovery cron job will periodically run and restart HMS discovery on any BMCs that previously failed.
When running concurrent discoveries on the problem BMCs, some of them will succeed while the others will experience a database deadlock and fail again with `StoreFailed`. So eventually, all BMCs will get successfully discovered.

The amount of time it will take to clear itself up is very difficult to estimate and depends heavily on the number of BMCs with the same troublesome hardware.
It also depends on the varying speeds of discovery calls to the hardware and if HSM will reach the storage stage of discovery for multiple BMCs at around the same time. It could take anywhere from 5 mins to 20+ hours to fully clear itself up.

### Manually Re-discover

To potentially speed up the process, you can manually re-discover the BMCs. To do this:

1. Suspend the `hms-discovery` cron job to prevent it from automatically rediscovering.

    ```bash
    kubectl -n services patch cronjobs hms-discovery \
    -p '{"spec" : {"suspend" : true }}'
    ```

2. Verify that the `hms-discovery` cron job has stopped (ACTIVE column = 0).

    ```bash
    kubectl get cronjobs -n services hms-discovery
    ```

    Example output:

    ```text
    NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE^M
    hms-discovery */3 * * * * True 0 117s 15d
    ```

3. Get a list of BMCs that failed discovery with `StoreFailed`.

    ```bash
    export CRAY_FORMAT=json
    BMCLIST=$(cray hsm inventory redfishEndpoints list --laststatus StoreFailed | jq .RedfishEndpoints[].ID -r | tr '\n' ',' | sed 's/.$//')
    ```

4. Kick off re-discovery.

    ```bash
    cray hsm inventory discover create --xnames $BMCLIST
    ```

5. Wait for discovery to finish. The following command will return 0 when discovery is finished.

    ```bash
    cray hsm inventory redfishEndpoints list --laststatus DiscoveryStarted | grep -c LastDiscoveryStatus
    ```

6. Check to see if there are still BMCs that failed discovery with `StoreFailed`. There should be fewer than before.

    ```bash
    cray hsm inventory redfishEndpoints list --laststatus StoreFailed | grep -c LastDiscoveryStatus
    ```

7. If there are still some BMCs with `StoreFailed`, repeat steps 3-6 until there are none.

8. Restart the `hms-discovery` cron job

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

9. Verify that the `hms-discovery` cron job has restarted (ACTIVE column = 1).

    ```bash
    kubectl get cronjobs.batch -n services hms-discovery
    ```

    Example output:

    ```text
    NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE
    hms-discovery */3 * * * * False 1 41s 33d
    ```

### Patch SMD

This patch is only for cases involving Castle nodes with HBM.

There is a patched SMD container image available in `artifactory` for CSM releases 1.3.2 and on. For CSM 1.3 it is `cray-smd:1.58.3`. For later CSM versions, `cray-smd:2.7.0`. For this example, we will use `cray-smd:1.58.3`.
This example assumes you have the patched container image in tarball form in at `/tmp/cray-smd_1.58.3.tar`.

1. Get Nexus credentials.

    ```bash
    export NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.username}} | base64 -d)"
    export NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.password}} | base64 -d)"
    ```

2. Load the tarball image.

    ```bash
    podman load -i /tmp/cray-smd_1.58.3.tar
    ```

3. Push the image to Nexus.

    ```bash
    podman push --creds $NEXUS_USERNAME:$NEXUS_PASSWORD localhost/cray-smd:1.58.3 docker://registry.local/artifactory.algol60.net/csm-docker/stable/cray-smd:1.58.3
    ```

4. Modify the image being used by the `cray-smd` deployment.

    ```bash
    kubectl edit deployments -n services cray-smd
    ```

    Change the image to:

    ```text
    image: registry.local/artifactory.algol60.net/csm-docker/stable/cray-smd:1.58.3
    ```

5. Wait for the SMD pods to restart.

    ```bash
    watch "kubectl get pods -n services | grep smd"
    ```

6. Re-discover the failed BMCs.

    ```bash
    export CRAY_FORMAT=json
    BMCLIST=$(cray hsm inventory redfishEndpoints list --laststatus StoreFailed | jq .RedfishEndpoints[].ID -r | tr '\n' ',' | sed 's/.$//')
    cray hsm inventory discover create --xnames $BMCLIST
    ```

7. Wait for discovery to finish. The following command will return 0 when discovery is finished.

    ```bash
    cray hsm inventory redfishEndpoints list --laststatus DiscoveryStarted | grep -c LastDiscoveryStatus
    ```

8. Verify discovery completed without BMCs failing with `StoreFailed`. The following command should return 0.

    ```bash
    cray hsm inventory redfishEndpoints list --laststatus StoreFailed | grep -c LastDiscoveryStatus
    ```
