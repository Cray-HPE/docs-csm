# Vault Service Recovery

The following covers redeploying the Vault service and restoring the data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.
- The latest CSM documentation has been installed on the master nodes. See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation).

## Service recovery for Vault

1. (`ncn-mw#`) Verify that a backup of the Vault data exists.

   1. Verify that a completed backup exists.

      ```bash
      velero get backup | grep vault-daily-backup | grep -i completed
      ```

      Example output:

      ```text
      vault-daily-backup-20221018020016        Completed         0        0          2022-10-18 02:00:16 +0000 UTC   2d        default            vault_cr=cray-vault
      vault-daily-backup-20221017020015        Completed         0        0          2022-10-17 02:00:15 +0000 UTC   1d        default            vault_cr=cray-vault
      vault-daily-backup-20221016020015        Completed         0        0          2022-10-16 02:00:15 +0000 UTC   11h       default            vault_cr=cray-vault
      ```

1. (`ncn-mw#`) Uninstall the chart and wait for the resources to terminate.

   1. Note the version of the chart that is currently deployed.

      ```bash
      helm history -n vault cray-vault
      ```

      Example output:

      ```text
      REVISION    UPDATED                     STATUS      CHART               APP VERSION DESCRIPTION
      1           Tue Aug  2 22:14:31 2022    deployed    cray-vault-1.3.1    1.5.5       Install complete
      ```

   1. Uninstall the chart.

      ```bash
      helm uninstall -n vault cray-vault
      ```

      Example output:

      ```text
      release "cray-vault" uninstalled
      ```

   1. Wait for the resources to terminate, delete the PVCs, and delete the `cray-vault-unseal-keys` Kubernetes secret.

      1. Verify that no Vault pods are running.

         ```bash
         watch "kubectl get pods -n vault -l vault_cr=cray-vault"
         ```

         Example output:

         ```text
         No resources found in vault namespace.
         ```

      1. Delete the Vault PVCs.

         ```bash
         kubectl get pvc -n vault -l vault_cr=cray-vault --no-headers=true | awk '{print $1}' | xargs kubectl delete -n vault pvc
         ```

         Example output:

         ```text
         persistentvolumeclaim "vault-raft-cray-vault-0" deleted
         persistentvolumeclaim "vault-raft-cray-vault-1" deleted
         persistentvolumeclaim "vault-raft-cray-vault-2" deleted
         ```

      1. Delete the `cray-vault-unseal-keys` Kubernetes secret.

         ```bash
         kubectl delete secret cray-vault-unseal-keys -n vault
         ```

         Example output:

         ```text
         secret "cray-vault-unseal-keys" deleted
         ```

1. (`ncn-mw#`) Redeploy the chart and wait for the resources to start.

   Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

   - Name of chart to be redeployed: `cray-vault`
   - Base name of manifest: `platform`
   - Chart files are located in Nexus.
   - When reaching the step to update customizations, no edits need to be made to the customizations file.
   - When reaching the step to validate that the redeploy was successful, perform the following step:

      **Only follow this step as part of the previously linked chart redeploy procedure.**

      Wait for the resources to start.

      ```bash
      watch "kubectl get pods -n vault -l vault_cr=cray-vault"
      ```

      Example output:

      ```text
      NAME                                     READY   STATUS    RESTARTS   AGE
      cray-vault-0                             5/5     Running   0          4m9s
      cray-vault-1                             5/5     Running   0          3m22s
      cray-vault-2                             5/5     Running   0          2m59s
      cray-vault-configurer-7c7dcdb958-cq2gw   2/2     Running   0          3m26s
      ```

1. (`ncn-mw#`) Restore the critical data.

   See [Restore from a backup](Backup_and_Restore_Vault_Clusters.md#restore-from-a-backup).
