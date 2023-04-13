# Vault Service Recovery

The following covers redeploying the Vault service and restoring the data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- A backup or export of the data already exists.
- The latest CSM documentation has been installed on the master nodes. See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation).

## Service recovery for Vault

1. (`ncn-mw#`) Verify that a backup of the Vault data exists.

   1. Verify a completed backup exists.

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

   1. Wait for the resources to terminate, delete PVCs and delete the `cray-vault-unseal-keys`.

      ```bash
      watch "kubectl get pods -n vault -l vault_cr=cray-vault"
      ```

      Example output:

      ```text
      No resources found in vault namespace.
      ```

      ```bash
      kubectl get pvc -n vault -l vault_cr=cray-vault --no-headers=true | awk '{print $1}' | xargs kubectl delete -n vault pvc
      ```

      Example output:

      ```text
      persistentvolumeclaim "vault-raft-cray-vault-0" deleted
      persistentvolumeclaim "vault-raft-cray-vault-1" deleted
      persistentvolumeclaim "vault-raft-cray-vault-2" deleted
      ```

      ```bash
      kubectl delete secret cray-vault-unseal-keys -n vault
      ```

      Example output:

      ```text
      secret "cray-vault-unseal-keys" deleted
      ```

1. (`ncn-mw#`) Redeploy the chart and wait for the resources to start.

   1. Create the manifest.

      ```bash
      kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
      kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}' > cray-vault.yaml
      for i in $(yq r cray-vault.yaml 'spec.charts[*].name' | grep -Ev '^cray-vault$'); do yq d -i cray-vault.yaml 'spec.charts(name=='"$i"')'; done
      yq w -i cray-vault.yaml metadata.name cray-vault
      yq d -i cray-vault.yaml spec.sources
      yq w -i cray-vault.yaml spec.sources.charts[0].location 'https://packages.local/repository/charts'
      yq w -i cray-vault.yaml spec.sources.charts[0].name csm-algol60
      yq w -i cray-vault.yaml spec.sources.charts[0].type repo
      manifestgen -c customizations.yaml -i cray-vault.yaml -o manifest.yaml
      ```

   1. Check that the chart version is correct based on the earlier `helm history`.

      ```bash
      grep "version:" manifest.yaml 
      ```

      Example output:

      ```text
            version: 1.3.1
      ```

   1. Redeploy the chart.

      ```bash
      loftsman ship --manifest-path ${PWD}/manifest.yaml
      ```

      Example output contains:

      ```text
      NAME: cray-vault
      ...
      STATUS: deployed
      ```

   1. Wait for the resources to start.

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

   See [Restore from a backup](../security_and_authentication/Backup_and_Restore_Vault_Clusters.md#restore-from-a-backup)
