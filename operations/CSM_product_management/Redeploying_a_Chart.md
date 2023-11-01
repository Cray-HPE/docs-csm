# Redeploying a Chart

Administrators are able to customize many aspects of the system in order to address problems or tailor it to better suit their requirements.
Often this requires redeploying one or more Helm charts. This page outlines the procedure for doing this in CSM. Other parts of the CSM
documentation will reference this page if you are instructed to redeploy a chart. In those cases, the source page that links to this one should
specify which charts should be redeployed and what customizations (if any) should be made to them.

* [Prerequisites](#prerequisites)
* [Procedure](#procedure)
  1. [Preparation](#1-preparation)
  1. [Obtain and optionally update customizations](#2-obtain-and-optionally-update-customizations)
  1. [Redeploy charts](#3-redeploy-charts)
  1. [Save updated customizations](#4-save-updated-customizations)
  1. [Cleanup](#5-cleanup)

## Prerequisites

* CSM is fully installed and operational.
* The latest CSM documentation RPMs are installed on the node where this procedure is being performed. See
  [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).
* If this procedure was linked from another page, the administrator must have the following information from that other page:
  * The name of the charts to be redeployed (for example, `cray-hms-bss`, `cray-sysmgmt-health`, or `spire`).
  * The base name of the manifest for each of these charts (for example, `sysmgmt`, `platform`, or `storage`).
  * The customization changes to make, if any.
  * The steps to validate that the chart deployment was successful.

## Procedure

### 1. Preparation

1. (`ncn-mw#`) Create a temporary directory to use during this procedure.

    ```bash
    TEMPDIR=$(mktemp -d) ; echo "${TEMPDIR}"
    ```

1. (`ncn-mw#`) Change the current working directory to the new directory.

    ```bash
    cd "${TEMPDIR}"
    ```

### 2. Obtain and optionally update customizations

1. (`ncn-mw#`) Save the current set of chart customizations to a file.

    ```bash
    CUSTOMIZATIONS="${TEMPDIR}/customizations.yaml"
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > "${CUSTOMIZATIONS}"
    ```

1. Edit the `${CUSTOMIZATIONS}` file, if appropriate.

    The step involves updating the system customizations. In cases where a chart is being redeployed with no changes, or only changes to the chart version,
    then this step should be skipped.

    **If this procedure was linked from another page, that page should provide instructions on what edits to make, if any.**

### 3. Redeploy charts

If redeploying more than one chart at once, perform the steps in this section for each chart being redeployed.

1. (`ncn-mw#`) Set helper variables.

    1. Set variable with the name of the chart.

        **If this procedure was linked from another page, that page should provide the chart name.**
        Examples of chart names are `cray-hms-bss`, `cray-sysmgmt-health`, or `spire`.

        ```bash
        CHART_NAME=<put actual name here>
        echo "${CHART_NAME}"
        ```

    1. Set variable with the base manifest name for this chart.

        **If this procedure was linked from another page, that page should provide the base manifest name.**
        Examples of base manifest names are `sysmgmt`, `platform`, or `storage`.

        ```bash
        BASE_MANIFEST_NAME=<put actual name here>
        echo "${BASE_MANIFEST_NAME}"
        ```

    1. Set convenience variables for files that will be created during this procedure.

        ```bash
        BASE_MANIFEST_FILE="${TEMPDIR}/${BASE_MANIFEST_NAME}.yaml" ; echo "${BASE_MANIFEST_FILE}"
        BASE_CHART_FILE="${TEMPDIR}/${CHART_NAME}.yaml" ; echo "${BASE_CHART_FILE}"
        CUSTOMIZED_CHART_FILE="${TEMPDIR}/${CHART_NAME}-customized.yaml" ; echo "${CUSTOMIZED_CHART_FILE}"
        ```

1. (`ncn-mw#`) Save the base manifest to a file.

    If redeploying multiple charts, this step does not need to be repeated for additional charts that use the same base manifest name.

    ```bash
    kubectl get cm -n loftsman "loftsman-${BASE_MANIFEST_NAME}" -o jsonpath='{.data.manifest\.yaml}'  > "${BASE_MANIFEST_FILE}"
    ```

1. (`ncn-mw#`) Make a copy of this file to use for redeploying the chart.

    ```bash
    cp -v "${BASE_MANIFEST_FILE}" "${BASE_CHART_FILE}"
    ```

1. (`ncn-mw#`) Edit the name of the manifest in the new file.

    This is to prevent it from overwriting the original manifest when it is redeployed.

    ```bash
    NEW_MANIFEST_NAME="${CHART_NAME}-$(date +%Y%m%d%H%M%S)"
    yq w -i "${BASE_CHART_FILE}" 'metadata.name' "${NEW_MANIFEST_NAME}"
    ```

1. Edit the `spec.charts` list in the `${BASE_CHART_FILE}` file so that it only contains the stanza for the chart to be redeployed.

    For example, if the chart being redeployed was `cray-cfs-api`, then the `charts` list would resemble the following example after editing.
    Note that the exact form and values may differ, because this is an example.

    ```yaml
          charts:
            - name: cray-cfs-api
              namespace: services
              source: csm-algol60
              version: 1.12.1
    ```

1. (`ncn-mw#`) Remove chart source fields from the `${BASE_CHART_FILE}` file.

    Remove the `spec.sources` stanza and remove the `source` field from each chart listing.

    > These commands will work even if the stanzas and fields are not present in the file.

    ```bash
    yq d -i "${BASE_CHART_FILE}" spec.sources && yq d -i "${BASE_CHART_FILE}" spec.charts[\*].source
    ```

1. (`ncn-mw#`) Update the version numbers in `${BASE_CHART_FILE}` if necessary.

    The information in the chart stanza is from the time the chart was deploying during the most recent install or upgrade of the CSM software. However,
    it is possible that the chart has been redeployed more recently, using a newer chart version. This may happen when a hotfix is installed, or when
    the procedure on this page was previously followed.

    1. Show most recently deployed chart versions.

        A record is saved in Kubernetes of every Loftsman chart deploy that has happened. This step uses a helper script to find and display the most recent
        successful deployment of this chart, in order for the administrator to check the version numbers it used.

        ```bash
        /usr/share/doc/csm/scripts/operations/kubernetes/latest_chart_manifest.sh "${CHART_NAME}"
        ```

        Example output for the `cray-cfs-api` chart may resemble the following:

        ```text
        Displaying chart manifest for 'cray-cfs-api' from loftsman-sysmgmt

        name: cray-cfs-api
        namespace: services
        source: csm-algol60
        swagger:
          - name: cfs
            url: https://raw.githubusercontent.com/Cray-HPE/config-framework-service/v1.12.2/api/openapi.yaml
            version: v1
        version: 1.12.1
        ```

    1. Edit the version numbers in `${BASE_CHART_FILE}` if necessary.

        In the example output from the previous step, the version numbers matches what we saw previously, so no updates are required.
        If the output shows different version numbers, then edit the version numbers in the chart stanza of `${BASE_CHART_FILE}` to match them.

1. (`ncn-mw#`) Apply customizations to the manifest.

    **This must be done whether or not any changes were made to the customizations in the previous section.**

    ```bash
    manifestgen -c "${CUSTOMIZATIONS}" -i "${BASE_CHART_FILE}" -o "${CUSTOMIZED_CHART_FILE}"    
    ```

1. (`ncn-mw#`) Review the customized manifest file to verify that it contains the expected version numbers and customizations.

    ```bash
    cat "${CUSTOMIZED_CHART_FILE}"
    ```

1. (`ncn-mw#`) Redeploy the chart.

    * In most cases, the Helm chart to be used is already in Nexus. Unless this procedure was linked from another page which specified an alternative location
      for the Helm chart, then run the following command:

        ```bash
        loftsman ship --charts-repo https://packages.local/repository/charts --manifest-path "${CUSTOMIZED_CHART_FILE}"
        ```

    * If this procedure was linked from another page, and that page specified a directory location for the Helm chart, then run the following command,
      substituting the directory name provided by the linking page.

        ```bash
        loftsman ship --charts-path <helm_chart_path> --manifest-path "${CUSTOMIZED_CHART_FILE}"
        ```

1. Validate that the redeploy was successful.

    How to do this will vary based on what was redeployed. **If this procedure was linked from another page, that page should provide details on how to do this validation.**

1. If additional charts are being redeployed, then repeat the previous steps in this section for each such chart.

### 4. Save updated customizations

If no changes were made to customizations, then skip this section. **If changes were made to customizations, then this step is critical.**

(`ncn-mw#`) Update the copy of the customizations in Kubernetes. If this is not done, then the customization changes will not persist after the next CSM upgrade,
the next hotfix that is applied, or the next time that this procedure is followed.

```bash
kubectl delete secret -n loftsman site-init
kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
```

### 5. Cleanup

The temporary directory created at the beginning of the procedure may be deleted if desired.
