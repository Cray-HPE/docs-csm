# Spire database connection pool configuration in an air-gapped environment

## Description

Due to the way the resolver code works in certain versions of Alpine Linux, it may be necessary to reconfigure the `spire-postgres-pooler` to use the fully qualified domain name of the database in order to prevent DNS lookup errors.

## Symptoms

* The `spire-server` pods are logging `query_wait_timeout` errors.

  ```text
  time="2022-11-15T09:39:38Z" level=error msg="Fatal run error" error="datastore-sql: pq: query_wait_timeout"
  time="2022-11-15T09:39:38Z" level=error msg="Server crashed" error="datastore-sql: pq: query_wait_timeout"
  ```

* The `spire-postgres-pooler` pods are logging DNS lookup failure errors.

  ```text
  2022-11-15 09:38:40.290 UTC [1] WARNING DNS lookup failed: spire-postgres: result=0
  2022-11-15 09:38:56.211 UTC [1] WARNING DNS lookup failed: spire-postgres: result=0
  2022-11-15 09:39:11.881 UTC [1] WARNING DNS lookup failed: spire-postgres: result=0
  2022-11-15 09:39:27.879 UTC [1] WARNING DNS lookup failed: spire-postgres: result=0
  2022-11-15 09:39:38.541 UTC [1] WARNING C-0x55729bbc56c0: spire/(nouser)@127.0.0.6:56151 pooler error: query_wait_timeout
  ```

## Solution

1. (`ncn-mw#`) Edit the `spire-postgres-pooler` deployment.

   Command:

   ```bash
   kubectl -n spire edit deployment spire-postgres-pooler
   ```

1. Update the `PGHOST` environment variable to use the fully qualified domain name.

   An example of the deployment before being edited:

   ```yaml
   containers:
   - env:
     - name: PGHOST
       value: spire-postgres
   ```

   Change `PGHOST` to:

   ```yaml
   containers:
   - env:
     - name: PGHOST
       value: spire-postgres.spire.svc.cluster.local
   ```

   The `spire-postgres-pooler` pods will automatically restart to pick up the new value.

**IMPORTANT:** This change will need to be reapplied if the `spire` Helm chart is re-installed.

This will be resolved in a future CSM release when the PostgreSQL operator is upgraded to a newer version.
