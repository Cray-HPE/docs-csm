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

During this stage there will be a brief (approximately 5 minutes) window where pods with Persistent Volumes (`PV`s) will not be able to migrate between nodes.
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

1. Verify that the Keycloak Users Localize job has completed as expected.

   This step can be skipped if user localization is not required.

   After an upgrade, it is possible that all expected Keycloak users were not localized. Check to see if the Keycloak users localize job has completed. You should see output containing `condition met`.

   ```bash
   ncn# kubectl -n services wait --for=condition=complete --timeout=10s job/`kubectl -n services get jobs | grep users-localize | awk '{print $1}'`
   ```

   If the job completed, check that the count of localized users matches the expected count from your Keycloak server. This can be done by looking at the count of users reported from the command below.

   ```bash
   ncn# cray artifacts get wlm etc/passwd /dev/stdout | wc -l
   ```

   If that count looks correct, then no further action is needed.  If not, rerun the localize job by following the steps below:

   ```bash
   ncn# kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize \
        -ojson | jq '.items[0]' > keycloak-users-localize-job.json
   ncn# kubectl delete job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize
   ncn# cat keycloak-users-localize-job.json | jq 'del(.spec.selector)' | \
        jq 'del(.spec.template.metadata.labels)' | kubectl apply -f -
   ```

   Expected output looks similar to:

   ```bash
   job.batch "keycloak-users-localize-1" deleted
   job.batch/keycloak-users-localize-1 created
   ```

   Confirm that the job completed. You should see output containing `condition met`.

   ```bash
   ncn# kubectl -n services wait --for=condition=complete --timeout=10s job/`kubectl -n services get jobs | grep users-localize | awk '{print $1}'`
   ```

   Confirm that the user count looks correct by running the command below again:

   ```bash
   ncn# cray artifacts get wlm etc/passwd /dev/stdout | wc -l
   ```

## Stage completed

This stage is completed. Continue to [Stage 4](Stage_4.md).
