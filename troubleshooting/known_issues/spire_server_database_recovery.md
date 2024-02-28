# Spire Server Reports Database is in Recovery

## Description

There is a known issue where when the PostgreSQL cluster changes leader the cluster can enter
a silent failure state where clients report the cluster is in recovery while it is not.
This leads to clients not able to transact with the cluster leading to errors.

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

## Solution

1. (`ncn-mw#`) Restart the Postgres cluster

    * If the `spire-server` has the errors, restart the `spire-postgres` `statefulset`

      ```bash
      kubectl -n spire rollout restart statefulset spire-postgres
      ```

    * If the `cray-spire-server` has the errors, restart the `cray-spire-postgres` `statefulset`

      ```bash
      kubectl -n spire rollout restart statefulset cray-spire-postgres
      ```

1. (`ncn-mw#`) Wait for the cluster to restart and check the logs to ensure there is no more errors
