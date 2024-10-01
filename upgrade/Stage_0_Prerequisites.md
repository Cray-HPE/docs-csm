# Stage 0 - Prerequisites and Preflight Checks

> **Reminders:**
>
> - CSM 1.5.0 or higher is required in order to upgrade to CSM 1.6.
> - If any problems are encountered and the procedure or command output does not provide relevant guidance, see
>   [Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

Stage 0 has several critical procedures which prepare the environment and verify if the environment is ready for the upgrade.

- [Stage 0 - Prerequisites and Preflight Checks](#stage-0---prerequisites-and-preflight-checks)
    - [Start typescript](#start-typescript)
    - [Stage 0.1 - Prepare assets](#stage-01---prepare-assets)
        - [Direct download](#direct-download)
        - [Manual copy](#manual-copy)
    - [Stage 0.2 - Prerequisites](#stage-02---prerequisites)
    - [Stage 0.3 - Update management node CFS configuration and customize worker node image](#stage-03---update-management-node-cfs-configuration-and-customize-worker-node-image)
        - [Option 1: Upgrade of CSM manually and additional products with IUF](#option-1-upgrade-of-csm-manually-and-additional-products-with-iuf)
        - [Option 2: Upgrade of CSM on CSM-only system](#option-2-upgrade-of-csm-manually-on-csm-only-system)
    - [Stop typescript](#stop-typescript)
    - [Stage completed](#stage-completed)

## Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_0.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Stage 0.1 - Prepare assets

1. (`ncn-m001#`) Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   > If upgrading to a patch version of CSM, be sure to specify the correct patch version number when setting this variable.

   ```bash
   export CSM_RELEASE=1.6.0
   ```

1. (`ncn-m001#`) Install the latest `docs-csm` and `libcsm` RPMs. These should be for the target CSM version of the upgrade, not
   the currently installed CSM version. See the short procedure in
   [Check for latest documentation](../update_product_stream/README.md#check-for-latest-documentation).

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m001`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m001`.

### Direct download

1. (`ncn-m001#`) Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz`

   > ***NOTE*** This step is optional for Cray/HPE internal installs, if `ncn-m001` can reach the internet.

   ```bash
   ENDPOINT=https://put.the/url/here/
   ```

1. This step should ONLY be performed if an http proxy is required to access a public endpoint on the internet for the purpose of downloading artifacts.
CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
The http proxy variables must be `unset` after the desired artifacts are downloaded. Failure to unset the http proxy variables after downloading artifacts will cause many failures in subsequent steps.

    - Secured:

       ```bash
       export https_proxy=https://example.proxy.net:443
       ```

    - Unsecured:

       ```bash
       export http_proxy=http://example.proxy.net:80
       ```

1. (`ncn-m001#`) Run the script.
   **NOTE** For Cray/HPE internal installs, if `ncn-m001` can reach the internet, then the `--endpoint` argument may be omitted.

   > The `prepare-assets.sh` script will delete the CSM tarball (after expanding it) in order to free up space.
   > This behavior can be overridden by appending the `--no-delete-tarball-file` argument to the `prepare-assets.sh`
   > command below.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. This step must be performed if an http proxy was set previously.

   ```bash
   unset https_proxy
   ```

   ```bash
   unset http_proxy
   ```

1. Skip the `Manual copy` subsection and proceed to [Stage 0.2 - Prerequisites](#stage-02---prerequisites)

### Manual copy

1. Copy the CSM release `tar` file to `ncn-m001`.

   See [Update Product Stream](../update_product_stream/README.md).

1. (`ncn-m001#`) Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m001`.

   ```bash
   CSM_TAR_PATH=/path/to/csm-${CSM_RELEASE}.tar.gz
   ```

1. (`ncn-m001#`) Run the script.

   > The `prepare-assets.sh` script will delete the CSM tarball (after expanding it) in order to free up space.
   > This behavior can be overridden by appending the `--no-delete-tarball-file` argument to the `prepare-assets.sh`
   > command below.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --tarball-file "${CSM_TAR_PATH}"
   ```

## Stage 0.2 - Prerequisites

1. If it has not been done previously, record in Vault the `admin` user password for the management switches in the system.

   See [Adding switch admin password to Vault](../operations/network/management_network/README.md#adding-switch-admin-password-to-vault).

1. (`ncn-m001#`) Set the `NEXUS_PASSWORD` variable **only if needed**.

   > **IMPORTANT:** If the password for the local Nexus `admin` account has been
   > changed from the password set in the `nexus-admin-credential` secret (not typical),
   > then set the `NEXUS_PASSWORD` environment variable to the correct `admin` password
   > and export it, before running `prerequisites.sh`.
   >
   > For example:
   >
   > > `read -s` is used to prevent the password from being written to the screen or the shell history.
   >
   > ```bash
   > read -s NEXUS_PASSWORD
   > ```
   >
   > ```bash
   > export NEXUS_PASSWORD
   > ```
   >
   > Otherwise, the upgrade will try to use the password in the `nexus-admin-credential`
   > secret and fail to upgrade Nexus.

1. (`ncn-m001#`) Run the script.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prerequisites.sh --csm-version ${CSM_RELEASE}
   ```

   If the script ran correctly, it should end with the following output:

   ```text
   [OK] - Successfully completed
   ```

   If the script does not end with this output, then try rerunning it. If it still fails, see
   [Upgrade Troubleshooting](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).
   If the failure persists, then open a support ticket for guidance before proceeding.

1. (`ncn-m001#`) Unset the `NEXUS_PASSWORD` variable, if it was set in the earlier step.

   ```bash
   unset NEXUS_PASSWORD
   ```

1. (Optional) (`ncn-m001#`) Commit changes to `customizations.yaml`.

   `customizations.yaml` has been updated in this procedure. If using an external Git repository
   for managing customizations as recommended, then clone a local working tree and commit
   appropriate changes to `customizations.yaml`.

   For example:

   ```bash
   git clone <URL> site-init
   cd site-init
   kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
   git add customizations.yaml
   git commit -m 'CSM 1.3 upgrade - customizations.yaml'
   git push
   ```

1. Proceed to [Stage 0.3](#stage-03---update-management-node-cfs-configuration-and-customize-worker-node-image).

## Stage 0.3 - Update management node CFS configuration and customize worker node image

This stage updates a CFS configuration used to perform node personalization and image customization
of management nodes. It also applies that CFS configuration to the management nodes and customizes
the worker node image, if necessary.

Image customization is the process of using Ansible stored in VCS in conjunction with the CFS and
IMS microservices to customize an image before it is booted. Node personalization is the process of
using Ansible stored in VCS in conjunction with the CFS and IMS microservices to personalize a node
after it has booted.

There are several options for this stage. Use the option which applies to the current upgrade
scenario.

- [Option 1: Upgrade of CSM manually and additional products with IUF](#option-1-upgrade-of-csm-manually-and-additional-products-with-iuf)
- [Option 2: Upgrade of CSM on CSM-only system](#option-2-upgrade-of-csm-manually-on-csm-only-system)

### Option 1: Upgrade of CSM manually and additional products with IUF

This stage should not be performed when upgrading CSM manually and additional HPE Cray EX software products with IUF. Instead, refer to the [Upgrade CSM manually and additional products with IUF](../operations/iuf/workflows/upgrade_csm_manual_and_additional_products_with_iuf.md) procedure.

That procedure will perform the appropriate steps to create a CFS configuration for management nodes
and perform management node image customization during the
[Image Preparation](../operations/iuf/workflows/image_preparation.md) step.

### Option 2: Upgrade of CSM manually on CSM-only system

Use this alternative if performing an upgrade of CSM on a CSM-only system with no other HPE Cray EX
software products installed. This upgrade scenario is extremely uncommon in production environments.

1. (`ncn-m001#`) Set node images in BSS for all NCNs. These steps set the new CSM base NCN images in BSS so that NCNs will boot into them during the node upgrades.

    1. (`ncn-m001#`) Get CSM base images for NCNs. (These images were set in `/etc/cray/upgrade/csm/myenv` in the `prerequisites.sh` script.)

        ```bash
        source /etc/cray/upgrade/csm/myenv
        echo "K8s node image: $K8S_IMS_IMAGE_ID"
        echo "Storage node image: $STORAGE_IMS_IMAGE_ID"
        ```

    1. (`ncn-m001#`) Set the kubernetes node image on master nodes and worker nodes.

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -p $K8S_IMS_IMAGE_ID -mw
        ```

    1. (`ncn-m001#`) Set the storage node image on storage nodes.

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -p $STORAGE_IMS_IMAGE_ID -s
        ```

1. (`ncn-m001#`) Generate a new CFS configuration for the management nodes.

   This script creates a new CFS configuration that includes the CSM version in its name and
   applies it to the management nodes. This leaves the management node components in CFS disabled.
   They will be automatically enabled when they are rebooted at a later stage in the upgrade.

   ```bash
   /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
       --no-enable --config-name management-${CSM_RELEASE}
   ```

   Successful output should end with the following line:

   ```text
   All components updated successfully.
   ```

If performing an upgrade of CSM manually and additional HPE Cray EX software products using the IUF,
return to the [Upgrade CSM manually and additional products with IUF](../operations/iuf/workflows/upgrade_csm_manual_and_additional_products_with_iuf.md)
procedure. Otherwise, if performing an upgrade of only CSM, proceed to the next step.

## Stop typescript

For any typescripts that were started during this stage, stop them with the `exit` command.

## Stage completed

This stage is completed. Continue to [Stage 1 - CSM Service Upgrades](Stage_1.md).
