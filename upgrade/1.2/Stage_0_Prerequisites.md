# Stage 0 - Prerequisites and Preflight Checks

> **Reminders:**
>
> - CSM 1.0.1 or higher is required in order to upgrade to CSM 1.2.x.
> - If any problems are encountered and the procedure or command output does not provide relevant guidance, see
>   [Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Abstract (Stage 0)

Stage 0 has several critical procedures which prepares and verify if the environment is ready for upgrade. First, the latest documentation RPM is installed; it includes
critical install scripts used in the upgrade procedure. Next, the current configuration of the System Layout Service (SLS) is updated to have necessary information for CSM 1.2.x.
The management network configuration is also upgraded. Towards the end, prerequisite checks are performed to ensure that the upgrade is ready to proceed. Finally, a
backup of Workload Manager configuration data and files is created. Once complete, the upgrade proceeds to Stage 1.

### Stages

- [Stage 0.1 - Prepare assets](#prepare-assets)
- [Stage 0.2 - Update SLS](#update-sls)
- [Stage 0.3 - Upgrade Management Network](#update-management-network)
- [Stage 0.4 - Prerequisites Check](#prerequisites-check)
- [Stage 0.5 - Backup Workload Manager Data](#backup_workload_manager)
- [Stage completed](#stage_completed)

## Stage 0.1 - Prepare assets

1. Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade. The command below is just an example.  Be sure you are setting the appropriate `CSM_RELEASE` version for your upgrade.

   ```bash
   ncn-m001# CSM_RELEASE=csm-1.2.2
   ```

1. If there are space concerns on the node, then add an `rbd` device on the node for the CSM tarball.

    1. [Create a storage pool](../../operations/utility_storage/Alternate_Storage_Pools.md#create-a-storage-pool).

    1. [Create and map an `rbd` device](../../operations/utility_storage/Alternate_Storage_Pools.md#create-and-map-an-rbd-device).

    1. [Mount an `rbd` device](../../operations/utility_storage/Alternate_Storage_Pools.md#mount-an-rbd-device).

    **Note:** This same `rbd` device can be remapped to `ncn-m002` later in the upgrade procedure, when the CSM tarball is needed on that node.
    However, the `prepare-assets.sh` script will delete the CSM tarball in order to free space on the node.
    If using an `rbd` device, this is not necessary or desirable, as it will require the CSM tarball to be downloaded again later in the
    procedure. Therefore, **if using an `rbd` device to store the CSM tarball**, then copy the tarball to a different location and point to that location
    when running the `prepare-assets.sh` script.

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m001`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m001`.

### Direct download

1. Download and install the latest documentation RPM.

   > **Important:** The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why this command copies it there.

   ```bash
   ncn-m001# wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.2/noarch/docs-csm-latest.noarch.rpm \
                -O /root/docs-csm-latest.noarch.rpm &&
             rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}${CSM_RELEASE}.tar.gz`

   **NOTE** This step is optional for Cray/HPE internal installs, if `ncn-m001` can reach the internet.

   ```bash
   ncn-m001# ENDPOINT=https://put.the/url/here/
   ```

1. Run the script.

   **NOTE** For Cray/HPE internal installs, if `ncn-m001` can reach the internet, then the `--endpoint` argument may be omitted.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. Skip the `Manual copy` subsection and proceed to [Stage 0.2 - Update SLS](#stage-0.2-update-sls).

### Manual copy

1. Copy the `docs-csm` RPM package and CSM release `tar` file to `ncn-m001`.

   See [Update Product Stream](../../update_product_stream/index.md).

1. Copy the documentation RPM to `/root` and install it.

   > **Important:**
   >
   > - Replace the `PATH_TO_DOCS_RPM` below with the location of the RPM on `ncn-m001`.
   > - The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why this command copies it there.

   ```bash
   ncn-m001# cp PATH_TO_DOCS_RPM /root/docs-csm-latest.noarch.rpm &&
             rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m001`.

   > The `prepare-assets.sh` script will delete the CSM tarball in order to free space on the node.
   > If using an `rbd` device to store the CSM tarball (or if not wanting the tarball file deleted for other reasons), then be sure to
   > copy the tarball file to a different location, and set the `CSM_TAR_PATH` to point to this new location.

   ```bash
   ncn-m001# CSM_TAR_PATH=/path/to/${CSM_RELEASE}.tar.gz
   ```

1. Run the script.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --tarball-file "${CSM_TAR_PATH}"
   ```

## Stage 0.2 - Update SLS

### Abstract (Stage 0.2)

CSM 1.2.x introduces the bifurcated CAN (BICAN) as well as network configuration controlled by data in SLS. An offline upgrade of SLS data is performed. For more details on the
upgrade and its sequence of events, see the [SLS upgrade `README`](scripts/sls/README.SLS_Upgrade.md).

The SLS data upgrade is a critical step in moving to CSM 1.2.x. Upgraded SLS data is used in DNS and management network configuration. For details to aid in understanding and
decision making, see the [Management Network User Guide](../../operations/network/management_network/index.md).

One detail which must not be overlooked is that the existing Customer Access Network (CAN) will be migrated or retrofitted into the new Customer Management Network (CMN) while
minimizing changes. A new CAN (or CHN) network is then created. Pivoting the existing CAN to the new CMN allows administrative traffic (already on the CAN) to remain as-is while
moving standard user traffic to a new site-routable network. You can read more about this, as well as steps to ensure undisrupted access to UANs during upgrade, in
[Plan and coordinate network upgrade](plan_and_coordinate_network_upgrade.md).

> **Important:** If this is the first time performing the SLS update to CSM 1.2.x, review the [SLS upgrade `README`](scripts/sls/README.SLS_Upgrade.md) in order to ensure
the correct options for the specific environment are used. Two examples are given below. To see all options from the update script, run `./sls_updater_csm_1.2.py --help`.

### Retrieve SLS data as JSON

1. Obtain a token.

   ```bash
   ncn-m001# export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client \
                                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. Create a working directory.

   ```bash
   ncn-m001# mkdir /root/sls_upgrade && cd /root/sls_upgrade
   ```

1. Extract SLS data to a file.

   ```bash
   ncn-m001# curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -S . > sls_input_file.json
   ```

### Migrate SLS data JSON to CSM 1.2.x

- Example 1: The CHN as the system default route (will by default output to `migrated_sls_file.json`).

   ```bash
   ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ncn-m001# ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CHN \
                         --customer-highspeed-network REPLACE_CHN_VLAN REPLACE_CHN_IPV4_SUBNET
   ```

- Example 2: The CAN as the system default route, keep the generated CHN (for testing), and preserve the existing `external-dns` entry.

   ```bash
   ncn-m001# export DOCDIR=/usr/share/doc/csm/upgrade/1.2/scripts/sls
   ncn-m001# ${DOCDIR}/sls_updater_csm_1.2.py --sls-input-file sls_input_file.json \
                         --bican-user-network-name CAN \
                         --customer-access-network REPLACE_CHN_VLAN REPLACE_CHN_IPV4_SUBNET \
                         --preserve-existing-subnet-for-cmn external-dns
   ```

- **Note:**: A detailed review of the migrated/upgraded data (using `vimdiff` or otherwise) for production systems and for systems which have many add-on components (UANs, login
  nodes, storage integration points, etc.) is strongly recommended. Particularly, ensure that subnet reservations are correct in order to prevent any data mismatches.

### Upload migrated SLS file to SLS service

If the following command does not complete successfully, check if the `TOKEN` environment variable is set correctly.

   ```bash
   ncn-m001# curl --fail -H "Authorization: Bearer ${TOKEN}" -k -L -X POST 'https://api-gw-service-nmn.local/apis/sls/v1/loadstate' -F 'sls_dump=@migrated_sls_file.json'
   ```

## Stage 0.3 - Upgrade management network

### Verify that switches have 1.2 configuration in place

1. Log in to each management switch.

   ```bash
   linux# ssh admin@1.2.3.4
   ```

1. Examine the text displayed when logging in to the switch.

   Specifically, look for output similar to the following:

   ```text
   ##################################################################################
   # CSM version:  1.2
   # CANU version: 1.3.2
   ##################################################################################
   ```

   - Output like the above text means that the switches have a CANU-generated configuration for CSM 1.2 in place. In this case, follow the steps in
     [Management Network 1.0 (`1.2 Preconfig`) to 1.2](../../operations/network/management_network/1.0_to_1.2_upgrade.md).
   - If the banner does NOT contain text like the above, then contact support in order to get the `1.2 Preconfig` applied to the system.
   - See the [Management Network User Guide](../../operations/network/management_network/index.md) for more information on the management network.
   - With the 1.2 switch configuration in place, users will only be able to SSH into the switches over the HMN.  

## Stage 0.4 - Prerequisites check

1. Set the `SW_ADMIN_PASSWORD` environment variable.

   Set it to the password for `admin` user on the switches. This is needed for preflight tests within the check script.

   > **NOTE:** `read -s` is used to prevent the password from being written to the screen or the shell history.

   ```bash
   ncn-m001# read -s SW_ADMIN_PASSWORD
   ncn-m001# export SW_ADMIN_PASSWORD
   ```

1. Prevent the use of the `rpcrdma` module.

   This step is required. The `rpcrdma` kernel module needs to be ignored so that it does not interfere
   with Slingshot Host Software.

   Run the following script to add the necessary parameters to the kernel command line on the worker nodes.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/blacklist-kernel-modules.sh
   ```

1. Set the `NEXUS_PASSWORD` variable **only if needed**.

   > **IMPORTANT:** If the password for the local Nexus `admin` account has
   > been changed from the default `admin123` (not typical), then set the
   > `NEXUS_PASSWORD` environment variable to the correct `admin` password
   > and export it, before running `prerequisites.sh`.
   >
   > For example:
   >
   > > `read -s` is used to prevent the password from being written to the screen or the shell history.
   >
   > ```bash
   > ncn-m001# read -s NEXUS_PASSWORD
   > ncn-m001# export NEXUS_PASSWORD
   > ```
   >
   > Otherwise, a random 32-character base-64-encoded string will be generated
   > and updated as the default `admin` password when Nexus is upgraded.

1. Run the script.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version ${CSM_RELEASE}
   ```

   If the script ran correctly, it should end with the following output:

   ```text
   [OK] - Successfully completed
   ```

   If the script does not end with this output, then try rerunning it. If it still fails, see
   [Upgrade Troubleshooting](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).
   If the failure persists, then open a support ticket for guidance before proceeding.

   `prerequisites.sh` clears the existing CFS configuration for each Management node. As each
   worker node is upgraded, the documentation will refer to the CFS configuration that should be
   assigned to the node at that time. If any worker node is unexpectedly rebooted prior to this, or if any other
   type of Management node is unexpectedly rebooted prior to the end of the CSM upgrade, then
   CFS will not automatically personalize the node after it has booted.

1. Unset the `NEXUS_PASSWORD` variable, if it was set in the earlier step.

   ```bash
   ncn-m001# unset NEXUS_PASSWORD
   ```

1. (Optional) Commit changes to `customizations.yaml`.

   `customizations.yaml` has been updated in this procedure. If
   [using an external Git repository for managing customizations](../../install/prepare_site_init.md#version-control-site-init-files) as recommended,
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

1. Check available space in Nexus, and free up space if needed.

   See [Nexus Space Cleanup](../../operations/package_repository_management/Nexus_Space_Cleanup.md).

## Stage 0.5 - Backup workload manager data

To prevent any possibility of losing workload manager configuration data or files, a backup is required. Execute all backup procedures (for the workload manager in use) located in
the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the
`HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting backup data should be stored in a safe location off of the system.

## Stage completed

This stage is completed. Continue to [Stage 1 - Ceph image upgrade](Stage_1.md).
