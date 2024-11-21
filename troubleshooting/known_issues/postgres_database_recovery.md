# PostgreSQL Database is in Recovery

## Description

There is a known issue that can occur when a Kubernetes control-plane (master) node is rebooted or rebuilt.

Rebooting a control-plan node can result in a brief interruption of service to the Kubernetes API which may cause the leader of a PostgreSQL
database cluster to demote itself and force a leadership race. When this occurs a different instance may become leader of the cluster and while the
Kubernetes service load balancer is correctly updated to reflect this change, the database connection to the client was never broken so the client
continues to send transactions to the former leader which is now a replica and can only handle read-only queries.

## Symptoms

* The `spire-server` or `cray-spire-server` pods may be in a `CrashLoopBackOff` state.
* The `spire-agent` or `cray-spire-agent` pods may be in a `CrashLoopBackOff` state.
* Services may fail to acquire tokens from the `spire-server` or `cray-spire-server`.
* The `spire-server` or `cray-spire-server` pods contain the following error in the logs.

  ```text
  2024-02-04T22:57:25.145365496Z time="2024-02-04T22:57:25Z" level=error msg="Could not generate TLS config for gRPC client" address="10.47.0.0:63042" error="get bundle from datastore: datastore-sql: pq: cannot set transaction read-write mode during recovery" subsystem_name=endpoints
  ```

* The `spire-agent` or `cray-spire-agent` pods contain the following error in the logs.

  ```text
  time="2024-02-26T22:24:55Z" level=error msg="Agent crashed" error="failed to get SVID: error getting attestation response from SPIRE server: rpc error: code = Internal desc = failed to attest: k8s-sat: unable to get agent info: rpc error: code = Unknown desc = datastore-sql: pq: cannot set transaction read-write mode during recovery"
  ```

* Services that rely on PostgreSQL such as `cray-sls`, `cray-smd`, or `cray-console-data` may have errors similar to the following in their logs.

  ```text
  error="datastore-sql: pq: cannot set transaction read-write mode during recovery"
  ```

* Some `cray` commands that query services like SLS or HSM may fail with the following error.

  ```text
  Error: Internal Server Error: failed to query DB.
  ```

## Solution

### Apply workaround

The Patroni database monitor usually relies on the `kubernetes` service to communicate with the Kubernetes API. The following parameter causes
Patroni to resolve the list of API nodes behind the service and connect directly to them reducing the chance of timeout or failure when performing
API calls.

1. (`ncn-mw#`) Apply the `postgres-pod` `RoleBinding` to allow the PostgreSQL clusters to access the Kubernetes API endpoint.

   ```bash
   kubectl apply -f /usr/share/doc/csm/upgrade/scripts/upgrade/postgres-pod.yaml
   ```

1. (`ncn-mw#`) Update the `postgres-nodes-pod-env` ConfigMap.

   ```bash
   kubectl -n services patch cm postgres-nodes-pod-env -p '{"data":{"PATRONI_KUBERNETES_BYPASS_API_SERVICE":"true"}}'
   ```

This workaround will cause the `cray-postgres-operator` to perform a rolling restart of all the PostgreSQL clusters to apply the parameter.

### Restart affected services

If the workaround was not previously applied then it will be necessary to restart affected services in order to force them to connect to the correct
instance of the database.

#### Spire

1. (`ncn-mw#`) Restart the Postgres connection pool.

    * If the `spire-server` has the errors, restart the `spire-postgres-pooler` deployment.

      ```bash
      kubectl -n spire rollout restart deployment spire-postgres-pooler
      ```

    * If the `cray-spire-server` has the errors, restart the `cray-spire-postgres-pooler` deployment.

      ```bash
      kubectl -n spire rollout restart deployment cray-spire-postgres-pooler
      ```

1. (`ncn-mw#`) Wait for the service to restart and check the logs to ensure that there are no more errors.

#### Other services

If other services are exhibiting this problem restart their database cluster.

The below example uses the `cray-sls-postgres` database cluster, refer to the output of `kubectl get postgresql -A` for all possible database clusters.

1. (`ncn-mw#`) Restart the impacted Postgres database StatefulSet.

      ```bash
      kubectl -n services rollout restart statefulset cray-sls-postgres
      ```

1. (`ncn-mw#`) Wait for the cluster to restart and check the logs to ensure that there are no more errors.
