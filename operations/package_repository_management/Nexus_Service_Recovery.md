# Nexus Service Recovery

The following covers redeploying the Nexus service and restoring the data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.
- The latest CSM documentation has been installed on the master nodes. See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation).

## Service recovery for Nexus

1. (`ncn-mw#`) Verify that an export of the Nexus PVC data exists.

   1. Verify that the `nexus-bak` PVC exists.

      ```bash
      kubectl get pvc -n nexus nexus-bak
      ```

      Example output:

      ```text
      NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
      nexus-bak    Bound    pvc-f058bf3b-97c0-4d7e-ab60-7294eaa18788   1000Gi     RWX            ceph-cephfs-external   6d
      ```

1. (`ncn-mw#`) Uninstall the chart and wait for the resources to terminate.

   1. Note the version of the chart that is currently deployed.

      ```bash
      helm history -n nexus cray-nexus
      ```

      Example output:

      ```text
      REVISION    UPDATED                     STATUS      CHART               APP VERSION DESCRIPTION
      1           Tue Aug  2 22:14:31 2022    deployed    cray-nexus-0.6.0    3.25.0      Install complete
      ```

   1. Uninstall the chart.

      ```bash
      helm uninstall -n nexus cray-nexus
      ```

      Example output:

      ```text
      release "cray-nexus" uninstalled
      ```

   1. Wait for the resources to terminate and delete the `nexus-data` PVC if it still exists. **Do not delete the `nexus-bak` PVC.**

      1. Verify that no Nexus pods are running.

         ```bash
         watch "kubectl get pods -n nexus -l app=nexus"
         ```

         Example output:

         ```text
         No resources found in nexus namespace.
         ```

      1. Delete the `nexus-data` PVC if it still exists.

         ```bash
         kubectl delete pvc nexus-data -n nexus 
         ```

         Example output:

         ```text
         persistentvolumeclaim "nexus-data" deleted
         ```

1. (`ncn-mw#`) Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

   - Name of chart to be redeployed: `cray-nexus`
   - Base name of manifest: `nexus`
   - Chart files are located in Nexus.
   - When reaching the step to update customizations, no edits need to be made to the customizations file.
   - When running the `loftsman ship` command, use the following command:

      ```bash
      loftsman ship --charts-repo https://csm-algol60.net/artifactory/csm-helm-charts/ --manifest-path "${CUSTOMIZED_CHART_FILE}"
      ```

   - When reaching the step to validate that the redeploy was successful, perform the following step:

      **Only follow this step as part of the previously linked chart redeploy procedure.**

      Wait for the resources to start.

      ```bash
      watch "kubectl get pods -n nexus -l app=nexus"
      ```

      Example output:

      ```text
      NAME                     READY   STATUS    RESTARTS   AGE
      nexus-7f79cd64c8-7j8tb   2/2     Running   0          30m
      ```

1. (`ncn-mw#`) Restore the critical data.

   See [Nexus Export and Restore](Nexus_Export_and_Restore.md).
