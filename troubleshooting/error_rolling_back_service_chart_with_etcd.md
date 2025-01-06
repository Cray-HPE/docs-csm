# Error Rolling Back Service Chart With etcd

If rolling back a service with Bitnami etcd, the `helm rollback` could fail when going from an etcd chart 9.x version to an etcd chart 8.x version.
This is because the Bitnami 9.x etcd cluster StatefulSet and Pods have the `app.kubernetes.io/component=etcd` label and the
Bitnami 8.x etcd cluster StatefulSet and Pods do not, causing the StatefulSet to complain on rollback.

## Prerequisites

If you are hitting the etcd chart version issue on rollback, helm will throw this error:

```text
Error: cannot patch "cray-hmnfd-bitnami-etcd" with kind StatefulSet: StatefulSet.apps "cray-hmnfd-bitnami-etcd" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minReadySeconds' are forbidden
```

You will also see the error in the `helm history` output.

Example output:

```text
# helm history -n services cray-hms-hmnfd
REVISION    UPDATED                     STATUS      CHART                   APP VERSION DESCRIPTION
1           Mon Dec  9 21:00:24 2024    superseded  cray-hms-hmnfd-3.0.2    1.18.1      Install complete
2           Thu Dec 19 13:53:27 2024    deployed    cray-hms-hmnfd-4.0.4    1.21.0      Upgrade complete
3           Fri Dec 20 19:50:42 2024    failed      cray-hms-hmnfd-3.0.2    1.18.1      Rollback "cray-hms-hmnfd" failed: cannot patch "cray-hmnfd-bitnami-etcd" with kind StatefulSet: StatefulSet.apps "cray-hmnfd-bitnami-etcd" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minReadySeconds' are forbidden
```

If `helm.sh/chart` is `etcd-9.x.x` or greater and the StatefulSet and Pods have the `app.kubernetes.io/component=etcd` label, you can get past the error by removing the offending label from the etcd cluster Pods and StatefulSet.

1. (`ncn-m001#`) Check which etcd helm chart version is currently running using `kubectl describe pod`.

    ```bash
    kubectl describe pod -n services cray-hmnfd-bitnami-etcd-0 | grep "helm.sh/chart"
    ```

    Example output:

    ```text
    ncn-m001:~ # kubectl describe pod -n services cray-hmnfd-bitnami-etcd-0 | grep "helm.sh/chart"
                helm.sh/chart=etcd-9.5.6
    ncn-m001:~ #
    ```

1. (`ncn-m001#`) Check that the StatefulSet and the pods have the `app.kubernetes.io/component` label.

    1. Check if the StatefulSet has the label.

        ```bash
        kubectl get statefulset -n services -l app.kubernetes.io/component=etcd | grep hmnfd
        ```

        Example output:

        ```text
        ncn-m001:~ # kubectl get statefulset -n services -l app.kubernetes.io/component=etcd | grep hmnfd
        cray-hmnfd-bitnami-etcd           3/3     26h
        ncn-m001:~ #
        ```

    1. Check if the Pods have the label.

        ```bash
        kubectl get pods -n services -l app.kubernetes.io/component=etcd | grep hmnfd
        ```

        Example output:

        ```text
        ncn-m001:~ # kubectl get pods -n services -l app.kubernetes.io/component=etcd | grep hmnfd
        cray-hmnfd-bitnami-etcd-0           2/2     Running   0          33m
        cray-hmnfd-bitnami-etcd-1           2/2     Running   0          34m
        cray-hmnfd-bitnami-etcd-2           2/2     Running   0          35m
        ncn-m001:~ #
        ```

## Create a Manual Backup of the etcd Cluster

If a manual backup of the etcd cluster was not done prior to running `helm rollback`, do so now by following [Create a Manual Backup of a Healthy etcd Cluster](../operations/kubernetes/Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md)

## Run Script to Remove Label

Run the script `remove_label_from_etcd_cluster.sh` in `/usr/share/doc/csm/troubleshooting/scripts/` to remove the `app.kubernetes.io/component=etcd` label from the StatefulSet and Pods in the etcd cluster.

`remove_label_from_etcd_cluster.sh` usage:

```text
Usage:

./remove_label_from_etcd_cluster.sh <namespace> <etcd-cluster>

    <namespace>    - The Kubernetes namespace the etcd cluster pods are running in.
                    Example, 'services'.
    <etcd-cluster> - The base name of the etcd cluster pods. Example, 'cray-hmnfd'.
```

(`ncn-m001#`) Run `remove_label_from_etcd_cluster.sh`.

```bash
/usr/share/doc/csm/troubleshooting/scripts/remove_label_from_etcd_cluster.sh services cray-hmnfd
```

Example output:

```bash
ncn-m001:/usr/share/doc/csm/troubleshooting/scripts # ./remove_label_from_etcd_cluster.sh services cray-hmnfd
Ensuring cray-hmnfd-bitnami-etcd members do not have 'app.kubernetes.io/component=etcd' label for rollback to bitnami 8.x chart...
Removing 'app.kubernetes.io/component=etcd' label from cray-hmnfd-bitnami-etcd-0...
pod/cray-hmnfd-bitnami-etcd-0 unlabeled
Removing 'app.kubernetes.io/component=etcd' label from cray-hmnfd-bitnami-etcd-1...
pod/cray-hmnfd-bitnami-etcd-1 unlabeled
Removing 'app.kubernetes.io/component=etcd' label from cray-hmnfd-bitnami-etcd-2...
pod/cray-hmnfd-bitnami-etcd-2 unlabeled
Removing label 'app.kubernetes.io/component=etcd' from statefulset for cray-hmnfd-bitnami-etcd
statefulset.apps/cray-hmnfd-bitnami-etcd unlabeled
Label 'app.kubernetes.io/component=etcd' was removed from pods and 'cray-hmnfd-bitnami-etcd' statefulset. Continue with rollback.
ncn-m001:/usr/share/doc/csm/troubleshooting/scripts #
```

The label `app.kubernetes.io/component=etcd` that was causing the StatefulSet error has been removed from the StatefulSet and etcd cluster Pods. Re-running the `helm rollback` should now succeed.

## Re-run `helm rollback`

(`ncn-m001#`) With the label `app.kubernetes.io/component=etcd` removed from the etcd cluster Pods and the StatefulSet, re-run `helm rollback`. The rollback should succeed and the expected revision should be running.

```bash
helm rollback -n services cray-hms-hmnfd 1
```

Example output:

```bash
ncn-m001:~ # helm rollback -n services cray-hms-hmnfd 1
Rollback was a success! Happy Helming!
ncn-m001:~ #
ncn-m001:~ # helm history -n services cray-hms-hmnfd
REVISION    UPDATED                     STATUS      CHART                   APP VERSION DESCRIPTION
1           Mon Dec  9 21:00:24 2024    superseded  cray-hms-hmnfd-3.0.2    1.18.1      Install complete
2           Thu Dec 19 13:53:27 2024    superseded  cray-hms-hmnfd-4.0.4    1.21.0      Upgrade complete
3           Fri Dec 20 19:50:42 2024    failed      cray-hms-hmnfd-3.0.2    1.18.1      Rollback "cray-hms-hmnfd" failed: cannot patch "cray-hmnfd-bitnami-etcd" with kind StatefulSet: StatefulSet.apps "cray-hmnfd-bitnami-etcd" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minReadySeconds' are forbidden
4           Fri Dec 20 20:06:38 2024    deployed    cray-hms-hmnfd-3.0.2    1.18.1      Rollback to 1
```
