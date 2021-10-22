## Disaster Recovery for Postgres

In the event that the Postgres cluster has failed to the point that it must be recovered and there is no dump available to restore the data, a full service specific disaster recovery is needed.

Below are the service specific steps required to cleanup any existing resources, redeploy the resources and repopulate the data.

Disaster Recovery Procedures by Service:

- [Restore HSM (Hardware State Manger) Postgres without a Backup](../hardware_state_manager/Restore_HSM_Postgres_without_a_Backup.md)
- [Restore SLS (System Layout Service) Postgres without a Backup](../system_layout_service/Restore_SLS_Postgres_without_an_Existing_Backup.md)
- [Restore Spire Postgres without a Backup](../spire/Restore_Spire_Postgres_without_a_Backup.md)
- [Restore Keycloak Postgres without a Backup](#restore-keycloak-postgres)

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

