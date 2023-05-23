# Disaster Recovery for Postgres

In the event that the Postgres cluster has failed to the point that it must be recovered and there is no dump available to restore the data, a full service specific disaster recovery is needed.

Below are the service specific steps required to cleanup any existing resources, redeploy the resources, and repopulate the data.

Disaster recovery procedures by service:

- [Restore HSM (Hardware State Manger) Postgres without a Backup](../hardware_state_manager/Restore_HSM_Postgres_without_a_Backup.md)
- [Restore SLS (System Layout Service) Postgres without a Backup](../system_layout_service/Restore_SLS_Postgres_without_an_Existing_Backup.md)
- [Restore Spire Postgres without a Backup](../spire/Restore_Spire_Postgres_without_a_Backup.md)
- [Restore Keycloak Postgres without a Backup](#restore-keycloak-postgres-without-a-backup)
- [Restore console Postgres](#restore-console-postgres)

## Restore Keycloak Postgres without a backup

The following procedures are required to rebuild the automatically populated contents of Keycloak's PostgreSQL database if the database has been lost and
recreated.

1. (`ncn-mw#`) Re-run the `keycloak-setup` job.

   1. Fetch the current job definition.

      ```bash
      kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak -oyaml |\
        yq r - 'items[0]' | yq d - 'spec.selector' | \
        yq d - 'spec.template.metadata.labels' > keycloak-setup.yaml
      ```

      There should be no output.

   1. Restart the `keycloak-setup` job.

      ```bash
      kubectl replace --force -f keycloak-setup.yaml
      ```

      The output should be similar to the following:

      ```text
      job.batch "keycloak-setup-1" deleted
      job.batch/keycloak-setup-1 replaced
      ```

   1. Wait for the job to finish.

      ```bash
      kubectl wait --for=condition=complete -n services job -l app.kubernetes.io/name=cray-keycloak --timeout=-1s
      ```

      The output should be similar to the following:

      ```text
      job.batch/keycloak-setup-1 condition met
      ```

1. (`ncn-mw#`) Re-run the `keycloak-users-localize` job.

   1. Fetch the current job definition.

      ```bash
      kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize -oyaml |\
        yq r - 'items[0]' | yq d - 'spec.selector' | \
        yq d - 'spec.template.metadata.labels' > keycloak-users-localize.yaml
      ```

      There should be no output.

   1. Restart the `keycloak-users-localize` job.

      ```bash
      kubectl replace --force -f keycloak-users-localize.yaml
      ```

      The output should be similar to the following:

      ```text
      job.batch "keycloak-users-localize-1" deleted
      job.batch/keycloak-users-localize-1 replaced
      ```

   1. Wait for the job to finish.

      ```bash
      kubectl wait --for=condition=complete -n services job -l app.kubernetes.io/name=cray-keycloak-users-localize --timeout=-1s
      ```

      The output should be similar to the following:

      ```text
      job.batch/keycloak-users-localize-1 condition met
      ```

1. (`ncn-mw#`) Restart the ingress `oauth2-proxies`.

   1. Restart the deployments.

      ```bash
      kubectl rollout restart -n services deployment/cray-oauth2-proxies-customer-access-ingress && \
      kubectl rollout restart -n services deployment/cray-oauth2-proxies-customer-high-speed-ingress && \
      kubectl rollout restart -n services deployment/cray-oauth2-proxies-customer-management-ingress
      ```

     Expected output:

      ```text
      deployment.apps/cray-oauth2-proxies-customer-access-ingress restarted
      deployment.apps/cray-oauth2-proxies-customer-high-speed-ingress restarted
      deployment.apps/cray-oauth2-proxies-customer-management-ingress restarte
      ```

   1. Wait for the restart to complete.

      ```bash
      kubectl rollout status -n services deployment/cray-oauth2-proxies-customer-access-ingress && \
      kubectl rollout status -n services deployment/cray-oauth2-proxies-customer-high-speed-ingress && \
      kubectl rollout status -n services deployment/cray-oauth2-proxies-customer-management-ingress
      ```

     Expected output:

      ```text
      deployment "cray-oauth2-proxies-customer-access-ingress" successfully rolled out
      deployment "cray-oauth2-proxies-customer-high-speed-ingress" successfully rolled out
      deployment "cray-oauth2-proxies-customer-management-ingress" successfully rolled out
      ```

Any other changes made to Keycloak, such as local users that have been created, will have to be manually re-applied.

## Restore console Postgres

Many times the PostgreSQL database used for the console services may be restored to health using
the techniques described in the following documents:

- [Troubleshoot Postgres Database](Troubleshoot_Postgres_Database.md)
- [Recover from Postgres WAL Event](Recover_from_Postgres_WAL_Event.md)

If the database is not able to be restored to health, follow the directions below to recover.
There is nothing in the console services PostgreSQL database that needs to be backed up and restored.
Once the database is healthy it will get rebuilt and populated by the console services from the
current system. Recovery consists of uninstalling and reinstalling the Helm chart for the
`cray-console-data` service.

1. (`ncn-mw#`) Determine the version of `cray-console-data` that is deployed.

   ```bash
   helm history -n services cray-console-data
   ```

   Output similar to the following will be returned:

   ```text
   REVISION UPDATED                   STATUS     CHART                    APP VERSION  DESCRIPTION
   1        Thu Sep  2 19:56:24 2021  deployed   cray-console-data-1.0.8  1.0.8        Install complete
   ```

   Note the version of the helm chart that is deployed.

1. (`ncn-mw#`) Get the correct Helm chart package to reinstall.

   Copy the chart from the local Nexus repository into the current directory:

   > Replace the version in the following example with the version noted in the previous step.

   ```bash
   wget https://packages.local/repository/charts/cray-console-data-1.0.8.tgz
   ```

1. (`ncn-mw#`) Uninstall the current `cray-console-data` service.

   ```bash
   helm uninstall -n services cray-console-data
   ```

   Example output:

   ```text
   release "cray-console-data" uninstalled
   ```

1. (`ncn-mw#`) Wait for all resources to be removed.

   1. Watch the deployed pods terminate.

      Watch the services from the `cray-console-data` Helm chart as
      they are terminated and removed:

      ```bash
      watch -n .2 'kubectl -n services get pods | grep cray-console-data'
      ```

      Output similar to the following will be returned:

      ```text
      cray-console-data-764f9d46b5-vbs7w     2/2     Running      0          4d20h
      cray-console-data-postgres-0           3/3     Running      0          20d
      cray-console-data-postgres-1           3/3     Running      0          20d
      cray-console-data-postgres-2           3/3     Terminating  0          4d20h
      ```

      This may take several minutes to complete. When all of the services have terminated and nothing
      is displayed any longer, use `ctrl`-`C` to exit from the `watch` command.

   1. Check that the data PVC instances have been removed.

      ```bash
      kubectl -n services get pvc | grep console-data-postgres
      ```

      There should be no PVC instances returned by this command. If there are, delete them
      manually with the following command:

      Replace the name of the PVC in the following example with the PVC to be deleted.

      ```bash
      kubectl -n services delete pvc pgdata-cray-console-data-postgres-0
      ```

      Repeat until all of the `pgdata-cray-console-data-postgres-' instances are removed.

1. (`ncn-mw#`) Install the Helm chart.

   Install using the file downloaded previously:

   ```bash
   helm install -n services cray-console-data ./cray-console-data-1.0.8.tgz
   ```

   Example output:

   ```text
   NAME: cray-console-data
   LAST DEPLOYED: Mon Oct 25 22:44:49 2021
   NAMESPACE: services
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. (`ncn-mw#`) Verify that all services restart correctly.

   1. Watch the services come back up again.

      ```bash
      watch -n .2 'kubectl -n services get pods | grep cray-console-data'
      ```

      After a little time, expected output should look similar to:

      ```text
      cray-console-data-764f9d46b5-vbs7w     2/2     Running    0          5m
      cray-console-data-postgres-0           3/3     Running    0          4m
      cray-console-data-postgres-1           3/3     Running    0          3m
      cray-console-data-postgres-2           3/3     Running    0          2m
      ```

      It will take a few minutes after these services are back up and running for the
      console services to settle and rebuild the database.

   1. Query `cray-console-operator` for a node location.

      After a few minutes, query `cray-console-operator` to find the pod a particular node is connected to.

      In the following example, replace the `cray-console-operator` pod name with the actual name of the
      running pod, and replace the component name (xname) with an actual node xname on the system.

      ```bash
      kubectl -n services exec -it cray-console-operator-7fdc797f9f-xz8rt -- sh -c '/app/get-node x9000c3s3b0n1'
      ```

      Example output:

      ```json
      {"podname":"cray-console-node-0"}
      ```

      This confirms that the `cray-console-data` service is up and operational.
