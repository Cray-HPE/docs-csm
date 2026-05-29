# CSM 1.7.1-Patch1 Installation Instructions

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Steps](#steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.7.1-patch1`
from CSM `v1.7.1` onwards only.

## Bug fixes and improvements

* Fixes for `USS 1.5.1-1's` `blancapeak` boot failure
* `CVE-2026-31431` - CVE Copy Fail
* `CVE-2026-46333` - Fixed CVE `ptrace`

## Steps

1. [Preparation](#preparation)
1. [Prepare for the patch Upgrade](#prepare-for-the-patch-upgrade)
1. [Create `product_vars.yaml`](#create-product_varsyaml)
1. [IUF Stage: process-media and pre-install-check stages](#iuf-stage-process-media-and-pre-install-check)
1. [IUF Stage: deliver-product](#iuf-stage-deliver-product)
1. [IUF Stage: management-nodes-rollout](#iuf-stage-management-nodes-rollout)
1. [Update test suite packages](#update-test-suite-packages)
1. [Verification](#verification)
1. [Complete upgrade](#complete-upgrade)

### Preparation

1. Validate CSM health.

   See [Validate CSM Health](../../operations/validate_csm_health.md).

   Run the CSM health checks to ensure that everything is working properly before the upgrade starts.
   After the upgrade is completed, another health check is performed.
   It is important to know if any problems observed at that time existed prior to the upgrade.

1. (`ncn-m001#`) Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   script -af csm-update.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM `v1.7.1-patch1` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract-csm-product-release).

1. (`ncn-m001#`) Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: Modify the command as necessary to match the actual location of the extracted files.

   ```bash
   export CSM_DISTDIR="$(pwd)/csm-1.7.1-patch1"
   echo "${CSM_DISTDIR}"
   ```

1. (`ncn-m001#`) Set `CSM_RELEASE_VERSION` to the CSM release version.

   ```bash
   export CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   echo "${CSM_RELEASE_VERSION}"
   ```

1. Download and install/upgrade the **latest** CSM documentation on `ncn-m001`.

   See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Prepare for the patch Upgrade

Follow steps 1 - 4 of the [Prepare for the Install or Upgrade](../../operations/iuf/workflows/preparation.md)

The CSM product distribution file should be available in the media directory now.

## Create `product_vars.yaml`

In the `MEDIA_DIR` directory configured in [preparation step](#prepare-for-the-patch-upgrade), create a new `product_vars.yaml` file with the following content:

   ```yaml
   # Copyright 2022-2026 Hewlett Packard Enterprise Development LP
   ---
   # override product specific branch values with product specific
   # entries in site_vars.yaml

   csm:
   version: 1.7.1-patch1
   ```

Save the file and proceed to next step.

## IUF Stage: process-media and pre-install-check

1. Using the IUF activity configured in the [previous step](#prepare-for-the-patch-upgrade), run the process-media
   stage as mentioned in the [Execute the IUF process-media and pre-install-check stages](../../operations/iuf/workflows/product_delivery.md#2-execute-the-iuf-process-media-and-pre-install-check-stages)

1. This should ensure that the CSM product distribution file is unpacked and available in
   the media directory.

## IUF Stage: deliver-product

1. Run the deliver-product stage of IUF with the below command:

   ```bash
   iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run \
      -rv "${MEDIA_DIR}"/product_vars.yaml -r deliver-product
   ```

1. At the end of this stage, check the file `/etc/cray/upgrade/csm/myenv`.
It should have the content similar to example below:

   ```bash
   export CSM_ARTI_DIR=/etc/cray/upgrade/csm/patch-install/csm-1.7.1-patch1
   export CSM_RELEASE=1.7.1-patch1
   export CSM_REL_NAME=csm-1.7.1-patch1
   export SECURE_STORAGE_IMAGE_ID=10bb9f73-0ca0-46dc-bb0f-d5e15dbeef36
   export SECURE_K8S_IMAGE_ID=04e06407-4b12-4401-8168-cd7683e1fa4d
   export MASTER_CONFIG=management-25.9.0-rc.4-prodinst
   export WORKER_CONFIG=management-25.9.0-rc.4-prodinst
   export STORAGE_CONFIG=storage-25.9.0-rc.4-prodinst    
   export FINAL_MASTER_IMAGE_ID=97d5a71e-0c50-4ad2-bcce-5fff8f130f5d
   export FINAL_WORKER_IMAGE_ID=ccc2cce7-2fee-4d2a-8115-69e6a76fca28
   export FINAL_STORAGE_IMAGE_ID=0bb6a504-cc96-4684-80bc-57da92104be0
   ```

1. This stage creates the new image based on the base images provided by the
   patch with the CFS configuration currently used by the master, worker and
   storage nodes.

1. The `myenv` file shown above has the image IDs and CFS configurations
   to be used for the next step.

## IUF Stage: management-nodes-rollout

1. Run the management-nodes-rollout stage of IUF to rollout the image and
   configuration for master, worker and storage nodes.

1. (`ncn-m001#`) Set upgrade variables.

   ```bash
   source /etc/cray/upgrade/csm/myenv
   ```

1. Follow the order mentioned [here](../../operations/iuf/workflows/management_rollout.md#21-management-nodes-rollout-with-csm-upgrade).

1. Use the command below by replacing the node names from the order mentioned in above step:

   For Storage Nodes:

   (`ncn-m001#`)

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run \
      --set-management-config "${STORAGE_CONFIG}" \
      --set-management-image "${FINAL_STORAGE_IMAGE_ID}" \
      -r management-nodes-rollout --limit-management-rollout ${NODE_NAME}
   ```

   For Master Nodes: `ncn-m002`,`ncn-m003`

   (`ncn-m001#`)

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run \
      --set-management-config "${MASTER_CONFIG}" \
      --set-management-image "${FINAL_MASTER_IMAGE_ID}" \
      -r management-nodes-rollout --limit-management-rollout ${NODE_NAME}
   ```

   For Worker Nodes:

   (`ncn-m001#`)

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run \
      --set-management-config "${WORKER_CONFIG}" \
      --set-management-image "${FINAL_WORKER_IMAGE_ID}" \
      -r management-nodes-rollout --limit-management-rollout ${NODE_NAME}
   ```

   For Master Nodes: `ncn-m001`

   (`ncn-m002#`)

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run \
      --set-management-config "${MASTER_CONFIG}" \
      --set-management-image "${FINAL_MASTER_IMAGE_ID}" \
      -r management-nodes-rollout --limit-management-rollout ${NODE_NAME}
   ```

> **NOTE:** More than one node can be rolled out at a time using the above command.

1. Use IUF CLI output and ARGO UI to trace the success of the rollout.

### Update test suite packages

(`ncn-m001#`) Update select RPMs on the NCNs.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/util/upgrade-test-rpms.sh
```

On success, the output should end with the following:

```text
Enabling and restarting goss-servers
SUCCESS
```

### Verification

1. Verify that the new CSM version is in the product catalog.

   (`ncn-m001#`) Verify that the new CSM version is listed in the output of the following command:

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.7.1-patch1`):

   ```text
   0.9.2
   0.9.3
   0.9.4
   0.9.5
   0.9.6
   1.0.1
   1.0.10
   1.2.0
   1.2.1
   1.2.2
   1.3.0
   1.3.1
   1.4.0
   1.4.1
   1.4.2
   1.4.3
   1.4.4
   1.5.0
   1.5.1
   1.5.2
   1.5.3
   1.7.0
   1.7.1
   1.7.1-patch1
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   (`ncn-m001#`) Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.7.1-patch1".configuration.import_date'
   ```

### Complete upgrade

(`ncn-m001#`) Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

It is recommended to save the typescript file for later reference.
