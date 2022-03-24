## Disaster Recovery for Postgres

In the event that the Postgres cluster has failed to the point that it must be recovered and there is no dump available to restore the data, a full service specific disaster recovery is needed.

Below are the service specific steps required to cleanup any existing resources, redeploy the resources and repopulate the data.

Disaster Recovery Procedures by Service:

- [Restore HSM (Hardware State Manger) Postgres without a Backup](../hardware_state_manager/Restore_HSM_Postgres_without_a_Backup.md)
- [Restore SLS (System Layout Service) Postgres without a Backup](../system_layout_service/Restore_SLS_Postgres_without_an_Existing_Backup.md)
- [Restore Spire Postgres without a Backup](../spire/Restore_Spire_Postgres_without_a_Backup.md)
- [Restore Keycloak Postgres without a Backup](#restore-keycloak-postgres)
- [Restore Console Postgres without a Backup](#restore-console-postgres)

<a name="restore-keycloak-postgres"> </a>
### Keycloak

The following procedures are required to rebuild the automatically populated
contents of Keycloak's PostgreSQL database if the database has been lost and
recreated.

1. Re-run the keycloak-setup Job by running the following commands on a Kubernetes NCN:
   
   1. Run the following command to fetch the current Job definition:
      
      ```
      kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak -oyaml |\
       yq r - 'items[0]' | yq d - 'spec.selector' | \
       yq d - 'spec.template.metadata.labels' > keycloak-setup.yaml
      ```
      There should be no output.
   
   1. Run the following command to restart the keycloak-setup Job:
      
      ```
      kubectl replace --force -f keycloak-setup.yaml
      ```
      
      The output should be similar to the following:
      
      ```
      job.batch "keycloak-setup-1" deleted
      job.batch/keycloak-setup-1 replaced
      ```
   
   1. Wait for the Job to finish by running the following command:
      
      ```
      kubectl wait --for=condition=complete -n services job -l app.kubernetes.io/name=cray-keycloak --timeout=-1s
      ```
      
      The output should be similar to the following:
      
      ```
      job.batch/keycloak-setup-1 condition met
      ```
1. Re-run the keycloak-users-localize Job by running the following commands on a Kubernetes NCN:
   
   1. Run the following command to fetch the current Job definition:
      
      ```
      kubectl get job -n services -l app.kubernetes.io/name=cray-keycloak-users-localize -oyaml |\
       yq r - 'items[0]' | yq d - 'spec.selector' | \
       yq d - 'spec.template.metadata.labels' > keycloak-users-localize.yaml
      ```
      There should be no output.
   
   1. Run the following command to restart the keycloak-users-localize Job:
      
      ```
      kubectl replace --force -f keycloak-users-localize.yaml
      ```
      
      The output should be similar to the following:
      
      ```
      job.batch "keycloak-users-localize-1" deleted
      job.batch/keycloak-users-localize-1 replaced
      ```
   
   1. Wait for the Job to finish by running the following command:
      
      ```
      kubectl wait --for=condition=complete -n services job -l app.kubernetes.io/name=cray-keycloak-users-localize --timeout=-1s
      ```
      
      The output should be similar to the following:
      
      ```
      job.batch/keycloak-users-localize-1 condition met
      ```
1. Restart keycloak-gatekeeper to pick up the newly generated client ID by running the following commands on a Kubernetes NCN:
   
   1. Run the following command to restart the keycloak-gatekeeper Pod(s):
      
      ```
      kubectl rollout restart deployment -n services cray-keycloak-gatekeeper-ingress
      ```
   
   1. The output should match the following:
      
      ```
      deployment.apps/cray-keycloak-gatekeeper-ingress restarted
      ```

Any other changes made to Keycloak, such as local users that have been created,
will have to be manually re-applied.

<a name="#restore-console-postgres"> </a>
### Restore Console Postgres without a Backup

Many times the PostgreSQL database used for the console services may be restored to health using
the techniques described in these documents:
- [Troubleshoot Postgres Database](./Troubleshoot_Postgres_Database.md)
- [Recover from Postgres WAL Event](./Recover_from_Postgres_WAL_Event.md)

If the database is not able to be restored to health, follow the directions below to recover.
There is nothing in the console services PostgreSQL database that needs to be backed up and restored.
Once the database is healthy it will get rebuilt and populated by the console services from the
current system. Recovery consists of uninstalling and reinstalling the helm chart for the
cray-console-data service.

1. Determine the version of cray-console-data deployed.
   1. Run the following command to find the version of cray-console-data deployed on the system:
      
      ```
      ncn-m# helm history -n services cray-console-data
      ```
      
      Output similar to the following will be returned:
      
      ```
      REVISION	UPDATED                   STATUS     CHART                    APP VERSION  DESCRIPTION
      1        Thu Sep  2 19:56:24 2021  deployed   cray-console-data-1.0.8  1.0.8        Install complete
      ```
      
      Note the version of the helm chart that is deployed.

1. Get the correct helm chart package to reinstall.
   
   1. Retrieve the helm chart with the correct version.
      
      The chart may be copied from the local Nexus repository using:
      
      ```
      wget https://packages.local/repository/charts/cray-console-data-1.0.8.tgz
      ```
      
      That will place the helm chart file in your current directory.

1. Uninstall the current cray-console-data service.
   
   1. Uninstall the current cray-console-data helm chart:
      
      ```
      ncn-m# helm uninstall -n services cray-console-data
      release "cray-console-data" uninstalled
      ```

1. Wait for all resources to be removed.
   
   1. Watch the deployed pods terminate.
      
      Use the following command to watch the services from the cray-console-data helm chart as
      they are terminated and removed:
      
      ```
      ncn-m# watch -n .2 'kubectl -n services get pods | grep cray-console-data'
      ```
      
      Output similar to the following will be returned:
      
      ```
      cray-console-data-764f9d46b5-vbs7w     2/2     Running      0          4d20h
      cray-console-data-postgres-0           3/3     Running      0          20d
      cray-console-data-postgres-1           3/3     Running      0          20d
      cray-console-data-postgres-2           3/3     Terminating  0          4d20h
      ```
      
      This may take several minutes to complete. When all of the services have terminated and nothing
      is displayed any longer, use **ctl-C** to exit from the watch command.
   
   1. Check that the data PVC instances have been removed using the command:
      
      ```
      ncn-m# kubectl -n services get pvc | grep console-data-postgres
      ```
      
      There should be no PVC instances returned by this command. If there are, delete them
      manually with the following command:
      
      ```
      ncn-m# kubectl -n services delete pvc pgdata-cray-console-data-postgres-0
      ```
      
      Change the name of the PVC and repeat until all of the `pgdata-cray-console-data-postgres-'
      instances are removed.

1. Install the helm chart.
   
   1. Install the helm chart from the file downloaded previously:
      
      ```
      ncn-m# helm install -n services cray-console-data ./cray-console-data-1.0.8.tgz
      ```

      Example output:

      ``` 
      NAME: cray-console-data
      LAST DEPLOYED: Mon Oct 25 22:44:49 2021
      NAMESPACE: services
      STATUS: deployed
      REVISION: 1
      TEST SUITE: None
      ```

1. Verify all services restart correctly.
   
   1. Watch the services come back up again:
      
      ```
      ncn-m# watch -n .2 'kubectl -n services get pods | grep cray-console-data'
      ```
      
      After a little time you will see something similar to:
      
      ```
      cray-console-data-764f9d46b5-vbs7w     2/2     Running    0          5m
      cray-console-data-postgres-0           3/3     Running    0          4m
      cray-console-data-postgres-1           3/3     Running    0          3m
      cray-console-data-postgres-2           3/3     Running    0          2m
      ```
      
      It will take a few minutes after these services are back up and running for the
      console services to settle and rebuild the database.
   
   1. Query cray-console-operator for a node location.
      
      After a few minutes you should be able to again query cray-console-operator to
      find the pod a particular node is connected to. Using the cray-console-operator
      pod on your system and node that is up on your system call:
      
      ```
      ncn-m# kubectl -n services exec -it cray-console-operator-7fdc797f9f-xz8rt -- sh -c '/app/get-node x9000c3s3b0n1'
      {"podname":"cray-console-node-0"}
      ```
      
      This confirms that the cray-console-data service is up and operational.
