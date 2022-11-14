# System Recovery

The following covers redeploying critical services and restoring the management service data - both from a per service perspective as well as from a fresh install perspective.

The following workflows are available:

* [Prerequisites](#prerequisites)
* [System recovery of critical service](#system-recovery-of-critical-service)
  * [Vault](#vault)
  * [Keycloak](#keycloak)
  * [Spire](#spire)
  * [Nexus](#nexus)
* [System recovery after fresh install](#system-recovery-after-fresh-install)

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

All activities required for site maintenance are complete.

A backup or export of the data already exists.

The latest CSM documentation has been installed on the master nodes. See [Check for Latest Documentation](../update_product_stream/index.md#check-for-latest-documentation).

## System recovery of critical service

### Vault

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

   See [Restore from a backup](security_and_authentication/Backup_and_Restore_Vault_Clusters.md#restore-from-a-backup)

### Keycloak

1. (`ncn-mw#`) Verify that a backup of the Keycloak Postgres data exists.

   1. Verify a completed backup exists.

      ```bash
      cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("keycloak"))'
      ```

      Example output:

      ```text
      keycloak-postgres-2022-09-14T02:10:05.manifest
      keycloak-postgres-2022-09-14T02:10:05.psql
      ```

1. (`ncn-mw#`) Uninstall the chart and wait for the resources to terminate.

   1. Note the version of the chart that is currently deployed.

      ```bash
      helm history -n services cray-keycloak
      ```

      Example output:

      ```text
      REVISION    UPDATED                     STATUS      CHART               APP VERSION DESCRIPTION
      1           Tue Aug  2 22:14:31 2022    deployed    cray-keycloak-3.3.1 3.1.1       Install complete
      ```

   1. Uninstall the chart.

      ```bash
      helm uninstall -n services cray-keycloak
      ```

      Example output:

      ```text
      release "cray-keycloak" uninstalled
      ```

   1. Wait for the resources to terminate

      ```bash
      watch "kubectl get pods -n services | grep keycloak | grep -v "keycloak-users-localize\|keycloak-vcs-user"
      ```

     Example output:

      ```text
      No resources found in services namespace.
      ```

1. (`ncn-mw#`) Redeploy the chart and wait for the resources to start.

   1. Create the manifest.

      ```bash
      kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
      kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}' > cray-keycloak.yaml
      for i in $(yq r cray-keycloak.yaml 'spec.charts[*].name' | grep -Ev '^cray-keycloak$'); do yq d -i cray-keycloak.yaml 'spec.charts(name=='"$i"')'; done
      yq w -i cray-keycloak.yaml metadata.name cray-keycloak
      yq d -i cray-keycloak.yaml spec.sources
      yq w -i cray-keycloak.yaml spec.sources.charts[0].location 'https://packages.local/repository/charts'
      yq w -i cray-keycloak.yaml spec.sources.charts[0].name csm-algol60
      yq w -i cray-keycloak.yaml spec.sources.charts[0].type repo
      manifestgen -c customizations.yaml -i cray-keycloak.yaml -o manifest.yaml
      ```

   1. Check that the chart version is correct based on the earlier `helm history`.

      ```bash
      grep "version:" manifest.yaml 
      ```

      Example output:

      ```text
            version: 3.3.1
      ```

   1. Redeploy the chart.

      ```bash
      loftsman ship --manifest-path ${PWD}/manifest.yaml
      ```

      Example output contains:

      ```text
      NAME: cray-keycloak
      ...
      STATUS: deployed
      ```

   1. Wait for the resources to start.

      ```bash
      watch "kubectl get pods -n services | grep keycloak"
      ```

      Example output:

      ```text
      cray-keycloak-0                                                   2/2     Running     0          32m
      cray-keycloak-1                                                   2/2     Running     0          32m
      cray-keycloak-2                                                   2/2     Running     0          32m
      keycloak-postgres-0                                               3/3     Running     0          32m
      keycloak-postgres-1                                               3/3     Running     0          31m
      keycloak-postgres-2                                               3/3     Running     0          30m
      keycloak-setup-1-9kdl2                                            0/2     Completed   0          32m
      keycloak-users-localize-1-jjb9b                                   2/2     Running     0          32m
      keycloak-vcs-user-1-gqftw                                         0/2     Completed   0          31m
      keycloak-wait-for-postgres-1-xt4nv                                0/2     Completed   0          32m
      ```

1. (`ncn-mw#`) Restore the critical data.

   See [Restore Postgres for Keycloak](kubernetes/Restore_Postgres.md#restore-postgres-for-keycloak)

### Spire

1. (`ncn-mw#`) Verify that a backup of the Spire Postgres data exists.

   1. Verify a completed backup exists.

      ```bash
      cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("spire"))'
      ```

      Example output:

      ```text
      spire-postgres-2022-09-14T03:10:04.manifest
      spire-postgres-2022-09-14T03:10:04.psql
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

   1. Wait for the resources to terminate, delete the PVCs and cleanup spire-agent before reinstalling the chart.

      ```bash
      watch "kubectl get pods -n spire"
      ```

      Example output:

      ```text
      No resources found in spire namespace.
      ```

      ```bash
      kubectl get pvc -n spire | grep spire-data-spire-server | awk '{print $1}' | xargs kubectl delete -n spire pvc
      ```

      Example output:

      ```text
      persistentvolumeclaim "spire-data-spire-server-0" deleted
      persistentvolumeclaim "spire-data-spire-server-1" deleted
      persistentvolumeclaim "spire-data-spire-server-2" deleted
      ```

      ```bash
      for ncn in $(kubectl get nodes -o name | cut -d'/' -f2); do ssh "${ncn}" systemctl stop spire-agent; \
          ssh "${ncn}" rm /root/spire/data/svid.key /root/spire/agent_svid.der /root/spire/bundle.der; done
      ```

1. (`ncn-mw#`) Redeploy the chart and wait for the resources to start.

   1. Create the manifest.

      ```bash
      kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
      kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}' > spire.yaml
      for i in $(yq r spire.yaml 'spec.charts[*].name' | grep -Ev '^spire$'); do yq d -i spire.yaml 'spec.charts(name=='"$i"')'; done
      yq w -i spire.yaml metadata.name spire
      yq d -i spire.yaml spec.sources
      yq w -i spire.yaml spec.sources.charts[0].location 'https://packages.local/repository/charts'
      yq w -i spire.yaml spec.sources.charts[0].name csm-algol60
      yq w -i spire.yaml spec.sources.charts[0].type repo
      manifestgen -c customizations.yaml -i spire.yaml -o manifest.yaml
      ```

   1. Check that the chart version is correct based on the earlier `helm history`.

      ```bash
      grep "version:" manifest.yaml 
      ```

      Example output:

      ```text
            version: 2.6.0
      ```

   1. Redeploy the chart.

      ```bash
      loftsman ship --manifest-path ${PWD}/manifest.yaml
      ```

      Example output contains:

      ```text
      NAME: spire
      ...
      STATUS: deployed
      ```

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

   1. Rejoin the storage nodes to spire and restart the spire-agent on all NCNs

      ```bash
      /opt/cray/platform-utils/spire/fix-spire-on-storage.sh
      for i in $(kubectl get nodes -o name | cut -d"/" -f2) $(ceph node ls | jq -r '.[] | keys[]' | sort -u); do ssh $i systemctl start spire-agent; done
      ```

1. (`ncn-mw#`) Restore the critical data.

   See [Restore Postgres for Spire](kubernetes/Restore_Postgres.md#restore-postgres-for-spire)

### Nexus

1. (`ncn-mw#`) Verify that an export of the Nexus PVC data exists.

   1. Verify the `nexus-bak` PVC exists.

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

      ```bash
      watch "kubectl get pods -n nexus -l app=nexus"
      ```

      Example output:

      ```text
      No resources found in nexus namespace.
      ```

      ```bash
      kubectl delete pvc nexus-data -n nexus 
      ```

      Example output:

      ```text
      persistentvolumeclaim "nexus-data" deleted
      ```

1. (`ncn-mw#`) Redeploy the chart and wait for the resources to start.

   1. Create the manifest.

      ```bash
      kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
      kubectl get cm -n loftsman loftsman-nexus -o jsonpath='{.data.manifest\.yaml}' > cray-nexus.yaml
      for i in $(yq r cray-nexus.yaml 'spec.charts[*].name' | grep -Ev '^cray-nexus$'); do yq d -i cray-nexus.yaml 'spec.charts(name=='"$i"')'; done
      yq w -i cray-nexus.yaml metadata.name cray-nexus
      yq d -i cray-nexus.yaml spec.sources
      yq w -i cray-nexus.yaml spec.sources.charts[0].location 'https://csm-algol60.net/artifactory/csm-helm-charts/'
      yq w -i cray-nexus.yaml spec.sources.charts[0].name csm-algol60
      yq w -i cray-nexus.yaml spec.sources.charts[0].type repo
      manifestgen -c customizations.yaml -i cray-nexus.yaml -o manifest.yaml
      ```

   1. Check that the chart version is correct based on the earlier `helm history`.

      ```bash
      grep "version:" manifest.yaml 
      ```

      Example output:

      ```text
            version: 0.6.0
      ```

   1. Redeploy the chart.

      ```bash
      loftsman ship --manifest-path ${PWD}/manifest.yaml
      ```

      Example output contains:

      ```text
      NAME: nexus
      ...
      STATUS: deployed
      ```

   1. Wait for the resources to start.

      ```bash
      watch "kubectl get pods -n nexus -l app=nexus"
      ```

      Example output:

      ```text
      NAME                     READY   STATUS    RESTARTS   AGE
      nexus-7f79cd64c8-7j8tb   2/2     Running   0          30m
      ```

1. (`ncn-mw#`) Restore the critical data.

   See [Nexus Export and Restore](package_repository_management/Nexus_Export_and_Restore.md)

## System recovery after fresh install
