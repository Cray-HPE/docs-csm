# Stage 0 - Prerequisites and Preflight Checks

> **`Note`:** CSM-1.0.1 or higher is required in order to upgrade to CSM-1.2.0

## Abstract

Stage 0 has several critical procedures which prepares and verify if the environment is ready for upgrade. First, the latest docs RPM is installed; it includes critical install scripts used in the upgrade procedure. Next, the current configuration of the System Layout Service (SLS) is updated to have necessary information for CSM 1.2. The management network configuration is also upgraded. Towards the end, prerequisite checks are performed to ensure that the upgrade is ready to proceed. Finally, a backup of Workload Manager configuration data and files is created. Once complete, the upgrade proceeds to Stage 1.

**Stages**
- [Stage 0.1 - Install latest docs RPM](#install-latest-docs)
- [Stage 0.2 - Update SLS](#update-sls)
- [Stage 0.3 - Upgrade Management Network](#update-management-network)
- [Stage 0.4 - Prerequisites Check](#prerequisites-check)
- [Stage 0.5 - Backup Workload Manager Data](#backup_workload_manager)
- [Stage Completed](#stage_completed)

<a name="install-latest-docs"></a>

## Stage 0.1 - Install latest documentation RPM

1. Install latest documentation RPM package and prepare assets:

   > The install scripts will look for the RPM in `/root`, so it is important that you copy it there.

   ```bash
    ncn-m001# CSM_RELEASE=csm-1.2.0
   ```

   - Internet Connected

      1. Set the ENDPOINT variable to the URL of the directory containing the CSM release tarball.

         In other words, the full URL to the CSM release tarball will be ${ENDPOINT}${CSM_RELEASE}.tar.gz

         **Note:** This step is optional for Cray/HPE internal installs.

         ```bash
         ncn-m001# ENDPOINT=https://put.the/url/here/
         ```

      1. Run the script

         ```bash
         ncn-m001# wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm -P /root &&
                   rpm -Uvh --force /root/docs-csm-latest.noarch.rpm

         ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
         ```

   - Air Gapped (replace the PATH_TO below with the location of the rpm)

      1. Copy the docs-csm RPM package and CSM release tarball to `ncn-m001`.

      1. Run the script

         ```bash
         ncn-m001# cp [PATH_TO_docs-csm-*.noarch.rpm] /root

         ncn-m001# rpm -Uvh --force /root/docs-csm-*.noarch.rpm

         ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
         ```

<a name="update-sls"></a>

## Stage 0.2 - Update SLS

### Abstract

CSM 1.2 introduces the bifurcated CAN as well as network configuration controlled by data in SLS. An offline upgrade of SLS data is performed. More details on the upgrade and its sequence of events can be found in the [README.SLS_upgrade.md](./scripts/sls/README.SLS_Upgrade.md).

The SLS data upgrade is a critical step in moving to CSM 1.2. Upgraded SLS data is used in DNS and management network configuration. Details of Bifurcated CAN can be found in the [BICAN document](../../operations/network/management_network/index.md) to aid in understanding and decision-making.

One detail which must not be overlooked is that the existing Customer Access Network (CAN) will be migrated or retrofitted into the new Customer Management Network (CMN) while minimizing changes. A new CAN, (or CHN) network is then created. Pivoting the existing CAN to the new CMN allows administrative traffic (already on the CAN) to remain as-is while moving standard user traffic to a new site-routable network.

> **`Important:`** If this is the first time performing the SLS update to CSM 1.2, you should review the [README.SLS_upgrade.md](./scripts/sls/README.SLS_Upgrade.md) to ensure you use all the correct options for your environment. Two examples are given below. To see all options from the update script run `./sls_updater_csm_1.2.py --help`

### Retrieve SLS data as JSON

1. Obtain a token:

   ```bash
   ncn-m001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. Create a working directory:

   ```bash
   ncn-m001# mkdir /root/sls_upgrade
   ncn-m001# cd /root/sls_upgrade
   ```

1. Extract SLS data to a file:

   ```bash
   ncn-m001# curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
   ```

### Migrate SLS data JSON to CSM 1.2

- Example 1: The CHN as the system default route (will by default output to `migrated_sls_file.json`).

   ```bash
   ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ncn-m001# ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CHN \
                         --customer-highspeed-network 5 10.103.11.192/26
   ```

- Example 2: The CAN as the system default route, keep the generated CHN (for testing), and preserve the existing `external-dns` entry.

   ```bash
   ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ncn-m001# ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CAN \
                         --customer-access-network 6 10.103.15.192/26 \
                         --preserve-existing-subnet-for-cmn external-dns
   ```

- **`Note:`**: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components (UAN, login nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure that subnet reservations are correct in order to prevent any data mismatches.

### Upload migrated SLS file to SLS service

   ```bash
   ncn-m001# curl -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
   ```

<a name="update-management-network"></a>

## Stage 0.3 - Upgrade Management Network

### Verify if switches have 1.2 configuration in place

1. Log in to each management switch
   ```bash
   linux# ssh admin@1.2.3.4
   ```

1. Examine the text displayed when logging in to the switch. Specifically, look for output similar to the following:

   ```
   ##################################################################################
   # CSM version:  1.2
   # CANU version: 1.3.2
   ##################################################################################
   ```

   - If you see text like the above, then it means that the switches have a CANU-generated configuration for CSM 1.2 in place. In this case, follow the steps in the [Management Network 1.0 (1.2 Preconfig) to 1.2](https://github.com/Cray-HPE/docs-csm/blob/release/1.2/operations/network/management_network/1.0_to_1.2_upgrade.md).

   - If the banner does NOT contain text like the above, then contact support in order to get the 1.2 preconfigs applied to the system.

   - See the [Management Network User Guide](../../operations/network/management_network/index.md) for more information on the management network.

<a name="prerequisites-check"></a>

## Stage 0.4 - Prerequisites Check

1. Set the `SW_ADMIN_PASSWORD` environment variable.

   Set it to the password for `admin` user on the switches. This is needed for preflight tests within the check script.

   ```bash
   ncn-m001# export SW_ADMIN_PASSWORD=changeme
   ```

1. Set the `NEXUS_PASSWORD` variable **only if needed**.

   > **`IMPORTANT:`** If the password for the local Nexus `admin` account has
   > been changed from the default `admin123` (not typical), then set the
   > `NEXUS_PASSWORD` environment variable to the correct `admin` password
   > before running `prerequisites.sh`!
   >
   > For example:
   >
   > ```bash
   > ncn-m001# export NEXUS_PASSWORD=changeme
   > ```
   >
   > Otherwise, a random 32-character base-64-encoded string will be generated
   > and updated as the default `admin` password when Nexus is upgraded.

1. Run the script.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE]
   ```

   **`IMPORTANT:`** If any errors are encountered, then potential fixes should be displayed where the error occurred. **IF** the upgrade `prerequisites.sh` script fails and does not provide guidance, then try rerunning it. If the failure persists, then open a support ticket for guidance before proceeding.

1. Unset the `NEXUS_PASSWORD` variable, if it was set in the earlier step.

   ```bash
   ncn-m001# unset NEXUS_PASSWORD
   ```

1. Commit changes to `customizations.yaml` (optional).

   `customizations.yaml` has been updated in this procedure. If [using an external Git repository for managing customizations](../../install/prepare_site_init.md#version-control-site-init-files) as recommended,
then clone a local working tree and commit appropriate changes to `customizations.yaml`.

   For example:

   ```bash
   ncn-m001# git clone <URL> site-init
   ncn-m001# cd site-init
   ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'CSM 1.2 upgrade - customizations.yaml'
   ncn-m001# git push
   ```

<a name="backup_workload_manager"></a>

## Stage 0.5 - Backup Workload Manager Data

To prevent any possibility of losing Workload Manager configuration data or files, a back-up is required. Please execute all Backup procedures (for the Workload Manager in use) located in the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the `HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting backup data should be stored in a safe location off of the system.

<a name="stage_completed"></a>

## Stage Completed

Continue to [Stage 1 - Ceph image upgrade](https://github.com/Cray-HPE/docs-csm/blob/release/1.2/upgrade/1.2/Stage_1.md).
