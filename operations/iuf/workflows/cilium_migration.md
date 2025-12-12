# Migrating Kubernetes CNI from Weave to Cilium

This describes how to migrate Kubernetes CNI from Weave to Cilium during a CSM upgrade.

- [Steps](#steps)
- [Known issues](#known-issues)
    - [Missing BSS Global Metadata Parameter](#missing-bss-global-metadata-parameter)
    - [Node drain blocked by Kafka](#node-drain-blocked-by-kafka)
    - [Node drain blocked by an `etcd` cluster](#node-drain-blocked-by-an-etcd-cluster)

> **Note:** This migration process applies only to upgrades from CSM 1.6 to CSM 1.7

## Steps

1. (`ncn-m#`) Run the migration script:

    ```bash
    /usr/share/doc/csm/scripts/cilium_migration.sh
    ```

    This script will:
    - Create and execute the migration workflow in the `argo` namespace.
    - Migrate the CNI from Weave to Cilium.
    - Continuously monitor the workflow status using `kubectl`.

1. (`ncn-mw#`) Monitor the migration workflow:

    The workflow status can also be tracked using the Argo CLI:

    The Argo CLI watch function can be used to view the overall progress of the workflow.

    ```bash
    argo watch <workflow-name> -n argo
    ```

    The Argo CLI logs function can be used to monitor the workflow in more detail.

    ```bash
    argo logs <workflow-name> -n argo -f
    ```

    Replace `<workflow-name>` with the actual name of the workflow created by the cilium_migration.sh script.

## Known issues

### Missing BSS Global Metadata Parameter

On systems originally installed with CSM 1.3 or earlier, the Cilium migration process may fail if the `k8s-primary-cni` BSS Global meta-data parameter is not set.

See [Cilium Migration Failure Due to Missing BSS Global Metadata Parameter](../../../troubleshooting/known_issues/cilium_migration_k8s_primary_cni_not_set.md) for details and resolution steps.

### Node drain blocked by Kafka

When restarting the pods on the NCN worker nodes, it is possible for the workflow to get stuck trying to evict `cray-shared-kafka-kafka` or SMA `cluster-kafka` pods.

Example output:

```console
evicting pod services/cray-shared-kafka-kafka-1
error when evicting pods/"cray-shared-kafka-kafka-1" -n "services" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget. 
```

The issue is that one of the restarted Kafka pods cannot communicate with Zookeeper. This is the problem described in
[`cfs-api` pods in CLBO state during CSM install](../../../troubleshooting/known_issues/cfs-api_pods_in_CLBO_state.md),
and it has the same workaround.

- (`ncn-mw#`) If the stuck pod is part of `cray-shared-kafka`, then restart that Zookeeper instance.

   ```bash
   kubectl delete pods -n services -l strimzi.io/controller-name=cray-shared-kafka-zookeeper
   ```

- (`ncn-mw#`) If the stuck pod is a member of SMA `cluster-kafka`, then restart the SMA Zookeeper instance.

   ```bash
   kubectl delete pod -n sma -l strimzi.io/controller-name=cluster-zookeeper
   ```

### Node drain blocked by an `etcd` cluster

When restarting the pods on the NCN worker nodes, it is possible for the workflow to get stuck trying to evict pods from an `etcd` cluster.

Example output:

```console
evicting pod services/cray-hbtd-bitnami-etcd-2
error when evicting pods/"cray-hbtd-bitnami-etcd-2" -n "services" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget. 
```

See [`etcd` Pods in CLBO State](../../../troubleshooting/known_issues/etcd_pods_in_CLBO_state.md) for more information and a workaround.
