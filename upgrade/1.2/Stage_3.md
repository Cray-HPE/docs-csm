# Stage 3 - CSM Service Upgrades

## Prepare assets on `ncn-m002`

1. Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   ```bash
    ncn-m002# CSM_RELEASE=csm-1.2.0
   ```

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m002`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m002`.

<a name="direct-download">

### Direct download

1. Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}${CSM_RELEASE}.tar.gz`

   **NOTE** This step is optional for Cray/HPE internal installs, if `ncn-m002` can reach the internet.

   ```bash
   ncn-m002# ENDPOINT=https://put.the/url/here/
   ```

1. Run the script.

   **NOTE** For Cray/HPE internal installs, if `ncn-m002` can reach the internet, then the `--endpoint` argument may be omitted.

   ```bash
   ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. Skip the `Manual copy` subsection.

<a name="manual-copy">

### Manual copy

1. Copy the CSM release `tar` file to `ncn-m002`.

   See [Update Product Stream](../../update_product_stream/index.md).

1. Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m002`.

   ```bash
   ncn-m002# CSM_TAR_PATH=/path/to/${CSM_RELEASE}.tar.gz
   ```

1. Run the script.

   ```bash
   ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --tarball-file "${CSM_TAR_PATH}"
   ```

## Perform upgrade

During this stage there will be a brief (approximately five minutes) window where pods with Persistent Volumes (`PV`s) will not be able to migrate between nodes.
This is due to a redeployment of the Ceph `csi` provisioners into namespaces, in order to accommodate the newer charts and a better upgrade strategy.

1. Set the `SW_ADMIN_PASSWORD` environment variable.

   Set it to the `admin` user password for the switches. This is required for post-upgrade tests.

   > `read -s` is used to prevent the password from being written to the screen or the shell history.

   ```bash
   ncn-m002# read -s SW_ADMIN_PASSWORD
   ncn-m002# export SW_ADMIN_PASSWORD
   ```

1. Perform the upgrade.

   Run `csm-upgrade.sh` to deploy upgraded CSM applications and services.

   ```bash
   ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/csm-upgrade.sh
   ```

## Validate `cray-shared-kafka` was updated properly

Occasionally the `cray-shared-kafka-kafka` pods will be restarted before the
`cray-shared-kafka-zookeeper` pods are ready. Check to make sure that all
`cray-shared-kafka-kafka` and `cray-shared-kafka-zookeeper` pods have a Ready status
of 1/1. If any of them have a 2/2 then rerun the `kafka-restart.sh` script.

```bash
ncn# kubectl get pods -n services -l app.kubernetes.io/instance=cray-shared-kafka
NAME                                                 READY   STATUS    RESTARTS   AGE
cray-shared-kafka-entity-operator-7f9895897d-zjgkm   3/3     Running   0          12m
cray-shared-kafka-kafka-0                            2/2     Running   0          10m
cray-shared-kafka-kafka-1                            2/2     Running   0          10m
cray-shared-kafka-kafka-2                            2/2     Running   0          10m
cray-shared-kafka-zookeeper-0                        1/1     Running   0          8m
cray-shared-kafka-zookeeper-1                        1/1     Running   0          8m
cray-shared-kafka-zookeeper-2                        1/1     Running   0          8m

ncn# /usr/share/doc/csm/upgrade/1.2/scripts/strimzi/kafka-restart.sh
```

## Verify Keycloak users

Verify that the Keycloak users localize job has completed as expected.

> This section can be skipped if user localization is not required.

After an upgrade, it is possible that all expected Keycloak users were not localized.
See [Verification procedure](../../operations/security_and_authentication/Keycloak_User_Localization.md#Verification-procedure) to confirm that Keycloak localization has completed as expected.

## Stage completed

This stage is completed. Continue to [Stage 4](Stage_4.md).
