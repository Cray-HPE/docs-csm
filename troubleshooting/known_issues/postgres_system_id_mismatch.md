# PostgreSQL System ID Mismatch

## Description

Occasionally when recovering an unhealthy PostgreSQL cluster, one or more cluster members may end
up with a different database system identifier than what is expected by other cluster members.
This system ID mismatch prevents the cluster from forming a proper quorum and maintaining healthy
replication between nodes.

The PostgreSQL system identifier is a unique value assigned when a database cluster is initialized.
When cluster members have mismatched system IDs, they cannot participate in the same logical cluster,
causing replication failures and preventing proper cluster recovery.

## Symptoms

PostgreSQL pods display unhealthy status and the affected pod logs contain "system ID mismatch"
error messages.

(`ncn-mw#`) Check the pod log.

```bash
kubectl -n services logs cfs-ara-postgres-1 -c postgres
```

If an unhealthy pod is experiencing this problem, then its log will contain a
line that resembles the following:

```text
2025-08-21 20:27:39,777 CRITICAL: system ID mismatch, node cfs-ara-postgres-1 belongs to a different cluster: 7541118075072872658 != 7233898320826871891
```

## Solution

The issue can be resolved by scaling down the affected cluster to a single instance, removing the
problematic persistent volume claims, and then scaling back up to rebuild the cluster with
consistent system IDs.

**Note:** This procedure uses `cfs-ara-postgres` as an example. Replace with the actual name of
the affected PostgreSQL cluster.

1. (`ncn-mw#`) Scale the PostgreSQL cluster down to a single instance.

   Command:

   ```bash
   kubectl edit postgresql cfs-ara-postgres -n services
   ```

   Change the `numberOfInstances` value from `3` to `1` and save the file.

1. (`ncn-mw#`) Wait for the replica pods to be deleted.

   Monitor the pods until only the primary remains:

   ```bash
   kubectl -n services get pods -l application=spilo,cluster-name=cfs-ara-postgres
   ```

   Wait until `cfs-ara-postgres-1` and `cfs-ara-postgres-2` pods are deleted.

1. (`ncn-mw#`) Delete the persistent volume claims for the deleted replica pods.

   Commands:

   ```bash
   kubectl delete pvc pgdata-cfs-ara-postgres-1 -n services
   kubectl delete pvc pgdata-cfs-ara-postgres-2 -n services
   ```

1. (`ncn-mw#`) Scale the PostgreSQL cluster back up to three instances.

   Command:

   ```bash
   kubectl edit postgresql cfs-ara-postgres -n services
   ```

   Change the `numberOfInstances` value from `1` to `3` and save the file.

1. (`ncn-mw#`) Wait for all three pods to be running and verify cluster health.

   Command:

   ```bash
   kubectl -n services get pods -l application=spilo,cluster-name=cfs-ara-postgres
   ```

   Wait until all three pods are in `Running` state.

1. (`ncn-mw#`) Verify the PostgreSQL cluster status is healthy.

   Command:

   ```bash
   kubectl -n services exec -it cfs-ara-postgres-0 -c postgres -- patronictl list
   ```

   Example output:

   ```text
   + Cluster: cfs-ara-postgres -------+---------+---------+----+-----------+
   | Member             | Host        | Role    | State   | TL | Lag in MB |
   +--------------------+-------------+---------+---------+----+-----------+
   | cfs-ara-postgres-0 | 10.32.2.175 | Leader  | running |  1 |           |
   | cfs-ara-postgres-1 | 10.32.4.80  | Replica | running |  1 |         0 |
   | cfs-ara-postgres-2 | 10.32.3.211 | Replica | running |  1 |         0 |
   +--------------------+-------------+---------+---------+----+-----------+
   ```

All cluster members should show as `running` with consistent timeline (TL) values and minimal lag.
