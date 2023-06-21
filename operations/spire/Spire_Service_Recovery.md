# Spire Service Recovery

The following covers redeploying the Spire service and restoring the data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.
- The latest CSM documentation has been installed on the master nodes. See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation).
- The Cray CLI has been configured on the node where the procedure is being performed. See [Configure the Cray CLI](../configure_cray_cli.md).

## Service recovery for Spire

1. (`ncn-mw#`) Verify that a backup of the Spire Postgres data exists.

   1. List the Postgres logical backups by date.

      ```bash
      cray artifacts list postgres-backup --format json | jq -r '.artifacts[] | select(.Key | contains("spilo/spire")) | "\(.LastModified) \(.Key)"'
      ```

      Example output:

      ```text
      2023-03-23T16:00:10.360000+00:00 spilo/spire-postgres/f5d7952e-b049-4bcf-ba7f-6357898bd617/logical_backups/1679676609.sql.gz
      2023-03-24T16:00:11.010220+00:00 spilo/spire-postgres/f5d7952e-b049-4bcf-ba7f-6357898bd617/logical_backups/1679677088.sql.gz
      ```

1. (`ncn-mw#`) Uninstall the chart and wait for the resources to terminate.

   1. Note the version of the chart that is currently deployed.

      ```bash
      helm history -n spire spire
      ```

      Example output:

      ```text
      REVISION    UPDATED                     STATUS      CHART       APP VERSION DESCRIPTION
      1           Tue Aug  2 22:14:31 2022    deployed    spire-2.6.0 0.12.2      Install complete
      ```

   1. Uninstall the chart.

      ```bash
      helm uninstall -n spire spire
      ```

      Example output:

      ```text
      release "spire" uninstalled
      ```

   1. Wait for the resources to terminate, delete the PVCs, and clean up `spire-agent` before reinstalling the chart.

      1. Verify that no Spire pods are running.

         ```bash
         watch "kubectl get pods -n spire"
         ```

         Example output:

         ```text
         No resources found in spire namespace.
         ```

      1. Delete the Spire PVCs.

         ```bash
         kubectl get pvc -n spire | grep spire-data-spire-server | awk '{print $1}' | xargs kubectl delete -n spire pvc
         ```

         Example output:

         ```text
         persistentvolumeclaim "spire-data-spire-server-0" deleted
         persistentvolumeclaim "spire-data-spire-server-1" deleted
         persistentvolumeclaim "spire-data-spire-server-2" deleted
         ```

      1. Clean up `spire-agent`.

         ```bash
         for ncn in $(kubectl get nodes -o name | cut -d'/' -f2); do
             echo "Cleaning up NCN ${ncn}"
             ssh "${ncn}" systemctl stop spire-agent
             ssh "${ncn}" rm -v /root/spire/data/svid.key /root/spire/agent_svid.der /root/spire/bundle.der
         done
         ```

1. (`ncn-mw#`) Redeploy the chart and wait for the resources to start.

   Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

   - Name of chart to be redeployed: `spire`
   - Base name of manifest: `sysmgmt`
   - When reaching the step to update customizations, no edits need to be made to the customizations file.
   - When reaching the step to validate that the redeploy was successful, perform the following step:

      **Only follow this step as part of the previously linked chart redeploy procedure.**

      1. Wait for the resources to start.

         ```bash
         watch "kubectl get pods -n spire"
         ```

         Example output:

         ```text
         NAME                                     READY   STATUS      RESTARTS   AGE
         request-ncn-join-token-89hp7             2/2     Running     0          31m
         request-ncn-join-token-fvqdj             2/2     Running     0          31m
         request-ncn-join-token-h7qc2             2/2     Running     0          31m
         request-ncn-join-token-wv56n             2/2     Running     0          31m
         request-ncn-join-token-dnfhk             2/2     Running     0          31m
         request-ncn-join-token-hbvwc             2/2     Running     0          31m
         spire-agent-cmn9q                        1/1     Running     0          31m
         spire-agent-gzn2d                        1/1     Running     0          31m
         spire-agent-pl595                        1/1     Running     0          31m
         spire-create-pooler-schema-1-g6gr6       0/3     Completed   0          31m
         spire-jwks-6c97b5694f-d94rg              3/3     Running     0          31m
         spire-jwks-6c97b5694f-h89lb              3/3     Running     0          31m
         spire-jwks-6c97b5694f-kz9k4              3/3     Running     0          31m
         spire-postgres-0                         3/3     Running     0          31m
         spire-postgres-1                         3/3     Running     0          31m
         spire-postgres-2                         3/3     Running     0          30m
         spire-postgres-pooler-695d4cd48f-57p5s   2/2     Running     0          30m
         spire-postgres-pooler-695d4cd48f-bzm6n   2/2     Running     0          30m
         spire-postgres-pooler-695d4cd48f-mv57z   2/2     Running     0          30m
         spire-server-0                           2/2     Running     4          31m
         spire-server-1                           2/2     Running     0          28m
         spire-server-2                           2/2     Running     0          28m
         spire-update-bss-1-cfbxc                 0/2     Completed   0          31m
         ```

   1. Rejoin the storage nodes to Spire and restart the `spire-agent` on all NCNs.

      ```bash
      /opt/cray/platform-utils/spire/fix-spire-on-storage.sh
      for i in $(kubectl get nodes -o name | cut -d"/" -f2) $(ceph node ls | jq -r '.[] | keys[]' | sort -u); do ssh $i systemctl start spire-agent; done
      ```

1. (`ncn-mw#`) Restore the critical data.

   See [Restore Postgres for Spire](../kubernetes/Restore_Postgres.md#restore-postgres-for-spire).
