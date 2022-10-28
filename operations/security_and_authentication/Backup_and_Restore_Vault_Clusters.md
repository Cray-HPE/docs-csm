# Backup and Restore Vault Clusters

View the existing Vault backups on the system and use a completed backup to perform a restore operation.

Velero is used to perform a nightly backup of Vault. The backup includes Kubernetes object state, in addition to pod volume data for the Vault `statefulset`.
For more information on Velero, refer to the [external Velero documentation](https://velero.io/).

**CAUTION:** A restore operation should only be performed in extreme situations. Performing a restore from a backup may cause secrets stored in Vault to change to an earlier state or get out of sync.

- [Prerequisites](#prerequisites)
- [View backup schedules and completed backups](#view-backup-schedules-and-completed-backups)
- [Restore from a backup](#restore-from a-backup)

## Prerequisites

- All of the steps listed in this section should be performed from a Kubernetes master or worker node.
- Ceph must be healthy to maximize the chance of a successful restore.

## View backup schedules and completed backups

1. (`ncn-mw#`) View the backup schedules.

    ```bash
    velero get schedule
    ```

    Example output:

    ```text
    NAME                 STATUS    CREATED                         SCHEDULE    BACKUP TTL   LAST BACKUP   SELECTOR
    vault-daily-backup   Enabled   2021-01-26 14:14:04 +0000 UTC   0 2 * * *   0s           19h ago       vault_cr=cray-vault
    ```

1. (`ncn-mw#`) View the completed backups.

    ```bash
    velero get backup
    ```

    Example output:

    ```text
    NAME                                STATUS      ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
    vault-daily-backup-20210217020038   Completed   0        0          2021-02-17 02:00:38 +0000 UTC   29d       default            vault_cr=cray-vault
    vault-daily-backup-20210216020035   Completed   0        0          2021-02-16 02:00:35 +0000 UTC   28d       default            vault_cr=cray-vault
    vault-daily-backup-20210215020035   Completed   0        0          2021-02-15 02:00:35 +0000 UTC   27d       default            vault_cr=cray-vault
    ```

1. (`ncn-mw#`) View the details of a completed backup.

    Replace the `BACKUP_NAME` value with the name of a backup returned in the previous step.

    ```bash
    velero describe backup BACKUP_NAME --details
    ```

    Example output:

    ```text
    Name:         vault-daily-backup-20210217020038
    Namespace:    velero
    Labels:       app.kubernetes.io/managed-by=Helm
                  velero.io/schedule-name=vault-daily-backup
                  velero.io/storage-location=default
    Annotations:  velero.io/source-cluster-k8s-gitversion=v1.18.6
                  velero.io/source-cluster-k8s-major-version=1
                  velero.io/source-cluster-k8s-minor-version=18

    Phase:  Completed

    Errors:    0
    Warnings:  0

    Namespaces:
      Included:  vault
      Excluded:  <none>

    Resources:
      Included:        pv, pvc, secret, sealedsecret, vault, configmap, deployment, service, statefulset, pod, ingress, replicaset
      Excluded:        <none>
      Cluster-scoped:  included

    Label selector:  vault_cr=cray-vault

    Storage Location:  default

    Velero-Native Snapshot PVs:  auto

    TTL:  720h0m0s

    Hooks:  <none>

    Backup Format Version:  1.1.0

    Started:    2021-02-17 02:00:38 +0000 UTC
    Completed:  2021-02-17 02:00:52 +0000 UTC

    Expiration:  2021-03-19 02:00:38 +0000 UTC

    Total items to be backed up:  21
    Items backed up:              21

    Resource List:
      apps/v1/Deployment:
        - vault/cray-vault-configurer
      apps/v1/ReplicaSet:
        - vault/cray-vault-configurer-56df7f768d
      apps/v1/StatefulSet:
        - vault/cray-vault
      v1/ConfigMap:
        - vault/cray-vault-configurer
        - vault/cray-vault-statsd-mapping
      v1/PersistentVolume:
        - pvc-0ea5065b-d5e1-45f9-8b54-b8f56281b81b
        - pvc-34d11110-1ff3-4267-8e66-696045f35af4
        - pvc-e3d07b75-1b27-4a55-b8d5-8e57857ad619
      v1/PersistentVolumeClaim:
        - vault/vault-raft-cray-vault-0
        - vault/vault-raft-cray-vault-1
        - vault/vault-raft-cray-vault-2
      v1/Pod:
        - vault/cray-vault-0
        - vault/cray-vault-1
        - vault/cray-vault-2
        - vault/cray-vault-configurer-56df7f768d-z2wzn
      v1/Secret:
        - vault/cray-vault-unseal-keys
      v1/Service:
        - vault/cray-vault
        - vault/cray-vault-0
        - vault/cray-vault-1
        - vault/cray-vault-2
        - vault/cray-vault-configurer

    Velero-Native Snapshots: <none included>

    Restic Backups:
      Completed:
        vault/cray-vault-0: vault-raft
        vault/cray-vault-1: vault-raft
        vault/cray-vault-2: vault-raft
    ```

## Restore from a backup

1. (`ncn-mw#`) Verify the backup being restored contains a manifest of resources and Restic volume backups.

    Object names will vary.

    ```bash
    velero describe backup BACKUP_NAME --details
    ```

    Example output:

    ```text
    Name:         vault-daily-backup-20210217020038
    Namespace:    velero
    Labels:       app.kubernetes.io/managed-by=Helm
                  velero.io/schedule-name=vault-daily-backup
                  velero.io/storage-location=default
    Annotations:  velero.io/source-cluster-k8s-gitversion=v1.18.6
                  velero.io/source-cluster-k8s-major-version=1
                  velero.io/source-cluster-k8s-minor-version=18

    Phase:  Completed

    Errors:    0
    Warnings:  0

    Namespaces:
      Included:  vault
      Excluded:  <none>

    Resources:
      Included:        pv, pvc, secret, sealedsecret, vault, configmap, deployment, service, statefulset, pod, ingress, replicaset
      Excluded:        <none>
      Cluster-scoped:  included

    Label selector:  vault_cr=cray-vault

    Storage Location:  default

    Velero-Native Snapshot PVs:  auto

    TTL:  720h0m0s

    Hooks:  <none>

    Backup Format Version:  1.1.0

    Started:    2021-02-17 02:00:38 +0000 UTC
    Completed:  2021-02-17 02:00:52 +0000 UTC

    Expiration:  2021-03-19 02:00:38 +0000 UTC

    Total items to be backed up:  21
    Items backed up:              21

    Resource List:
      apps/v1/Deployment:
        - vault/cray-vault-configurer
      apps/v1/ReplicaSet:
        - vault/cray-vault-configurer-56df7f768d
      apps/v1/StatefulSet:
        - vault/cray-vault
      v1/ConfigMap:
        - vault/cray-vault-configurer
        - vault/cray-vault-statsd-mapping
      v1/PersistentVolume:
        - pvc-0ea5065b-d5e1-45f9-8b54-b8f56281b81b
        - pvc-34d11110-1ff3-4267-8e66-696045f35af4
        - pvc-e3d07b75-1b27-4a55-b8d5-8e57857ad619
      v1/PersistentVolumeClaim:
        - vault/vault-raft-cray-vault-0
        - vault/vault-raft-cray-vault-1
        - vault/vault-raft-cray-vault-2
      v1/Pod:
        - vault/cray-vault-0
        - vault/cray-vault-1
        - vault/cray-vault-2
        - vault/cray-vault-configurer-56df7f768d-z2wzn
      v1/Secret:
        - vault/cray-vault-unseal-keys
      v1/Service:
        - vault/cray-vault
        - vault/cray-vault-0
        - vault/cray-vault-1
        - vault/cray-vault-2
        - vault/cray-vault-configurer

    Velero-Native Snapshots: <none included>

    Restic Backups:
      Completed:
        vault/cray-vault-0: vault-raft
        vault/cray-vault-1: vault-raft
        vault/cray-vault-2: vault-raft
    ```

1. (`ncn-mw#`) Scale down the Vault operator.

    This will prevent it from attempting to reconcile the instance while the restore is in progress.

    1. Submit the request to scale down the Vault operator.

        ```bash
        kubectl -n vault scale deployment cray-vault-operator --replicas=0
        ```

        Example output:

        ```text
        deployment.apps/cray-vault-operator scaled
        ```

    1. Verify that the changes were successfully made.

        ```bash
        kubectl -n vault get deployment
        ```

        Example output:

        ```text
        NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
        cray-vault-operator   0/0     0            0           19h
        ```

1. (`ncn-mw#`) Delete the Vault instance.

    This is done to minimize the risk of Vault being in a partially restored state.

    Vault will be inaccessible \(if not already\) after running the following commands.

    ```bash
    kubectl -n vault delete vault -l vault_cr=cray-vault
    kubectl -n vault delete pvc -l vault_cr=cray-vault
    kubectl -n vault delete secret -l vault_cr=cray-vault
    ```

1. (`ncn-mw#`) Submit the restore action.

    Monitor the progress of the restore job until it is in a completed phase. The progress can be viewed by using the logs command shown in the output.

    ```bash
    velero restore create --from-backup BACKUP_NAME
    ```

    Example output:

    ```text
    Restore request "vault-daily-backup-20210217100000" submitted successfully.
    Run `velero restore describe vault-daily-backup-20210217100000` or `velero restore logs vault-daily-backup-20210217100000` for more details.
    ```

1. (`ncn-mw#`) Scale the Vault operator back to one replica.

    1. Submit the request to scale the Vault operator.

        ```bash
        kubectl -n vault scale deployment cray-vault-operator --replicas=1
        ```

        Example output:

        ```text
        deployment.apps/cray-vault-operator scaled
        ```

    1. Verify that the changes were successfully made.

        ```bash
        kubectl -n vault get deployment
        ```

        Example output:

        ```text
        NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
        cray-vault-operator   1/1     1            1           19h
        ```

1. (`ncn-mw#`) If necessary, delete the Vault pods and allow the operator to restart them.

    The pods need to be manually restarted if the Vault `statefulset` pods are in `CrashLoopBackOff` after 5-10 minutes of performing the restore operation.
    The Vault `statefulset` pods normally go through a number of restarts on a clean start-up.

    1. Check that the pods are in a `CrashLoopBackOff` state.

        ```bash
        kubectl -n vault get pod -o wide -l vault_cr=cray-vault
        ```

        Example output:

        ```text
        NAME                                     READY   STATUS             RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
        cray-vault-0                             4/5     CrashLoopBackOff   9          30m     10.44.0.33   ncn-w001   <none>           <none>
        cray-vault-1                             4/5     CrashLoopBackOff   9          30m     10.42.0.10   ncn-w002   <none>           <none>
        cray-vault-2                             4/5     CrashLoopBackOff   9          30m     10.40.0.12   ncn-w003   <none>           <none>
        cray-vault-configurer-56df7f768d-c228k   2/2     Running            0          30m     10.44.0.8    ncn-w001   <none>           <none>
        ```

    1. Delete the pods to restart them.

        ```bash
        kubectl delete pod -n vault -l vault_cr=cray-vault
        ```

        Example output:

        ```text
        pod "cray-vault-0" deleted
        pod "cray-vault-1" deleted
        pod "cray-vault-2" deleted
        pod "cray-vault-configurer-56df7f768d-c228k" deleted
        ```

    1. Verify that the pods are in a `Running` state.

        ```bash
        kubectl get pod -n vault -l vault_cr=cray-vault
        ```

        Example output:

        ```text
        NAME                                     READY   STATUS    RESTARTS   AGE
        cray-vault-0                             5/5     Running   2          105s
        cray-vault-1                             5/5     Running   2          67s
        cray-vault-2                             5/5     Running   2          38s
        cray-vault-configurer-56df7f768d-c7mk2   2/2     Running   0          2m21s
        ```
