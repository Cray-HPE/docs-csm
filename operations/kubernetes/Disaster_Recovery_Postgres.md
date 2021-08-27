## Disaster Recovery for Postgres

In the event that the Postgres cluster has failed to the point that it must be recovered and there is no dump available to restore the data, a full service specific disaster recovery is needed.

Below are the service specific steps required to cleanup any existing resources, redeploy the resources and repopulate the data.

Disaster Recovery Procedures by Service:S

-   [Restore HSM Postgres without a Backup](../hardware_state_manager/Restore_HSM_Postgres_without_a_Backup.md)
-   [Restore Spire Postgres without a Backup](../spire/Restore_Spire_Postgres_without_a_Backup.md)
