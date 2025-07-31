# PostgreSQL cluster upgrades failing

## Description

Istio routes certain traffic through a passthrough cluster which results in a connection having an IP address of 127.0.0.6.
This IP address appears in the PostgreSQL `pg_stat_replication` table as the client address of a database cluster member
instead of the pod IP address which causes database version upgrades to fail.

See [Postgres Operator Issue 1629](https://github.com/zalando/postgres-operator/issues/1629) for more information.

## Symptoms

`cfs-ara` or other services that rely on PostgreSQL may be in a `CrashLoopBackOff` state with log entries pointing to a database version mismatch.

Example output:

```console
[ara] Creating data & configuration directory: /tmp/ara
[ara] Using settings file: /opt/ara-config/settings.yaml
Traceback (most recent call last):
  File "/app/venv/bin/ara-manage", line 8, in <module>
    sys.exit(main())
             ^^^^^^
...
  File "/app/venv/lib/python3.12/site-packages/django/db/backends/base/base.py", line 214, in check_database_version_supported
    raise NotSupportedError(
django.db.utils.NotSupportedError: PostgreSQL 12 or later is required (found 11.19).
```

The `cray-postgres-operator` pod log will be repeatedly logging messages that indicate the database needs upgrading.

Example output:

```console
time="2025-07-31T09:42:22Z" level=info msg="healthy cluster ready to upgrade, current: 110019 desired: 140000" cluster-name=services/cfs-ara-postgres pkg=cluster
time="2025-07-31T09:42:22Z" level=info msg="triggering major version upgrade on pod cfs-ara-postgres-0 of 3 pods" cluster-name=services/cfs-ara-postgres pkg=cluster
```

## Solution

Istio sidecar injection must be temporarily disabled to allow the database upgrade to proceed.

The following steps use the `cfs-ara-postgres` database as an example.

1. (`ncn-mw#`) Disable Istio sidecar injection on the target database cluster.

   Command:

   ```bash
   kubectl -n services patch postgresql cfs-ara-postgres --type=merge --patch '{"spec": {"podAnnotations": {"sidecar.istio.io/inject": "false"}}}'
   ```

   The `cray-postgres-operator` will update the target database cluster

   Command:

   ```bash
   kubectl -n services get postgresql cfs-ara-postgres
   ```

   Example output:

   ```console
   NAME               TEAM      VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE    STATUS
   cfs-ara-postgres   cfs-ara   14        3      50Gi                                    524d   Updating
   ```

1. (`ncn-mw#`) Verify the target database cluster has finished Updating and is now Running.

   Command:

   ```bash
   kubectl -n services get postgresql cfs-ara-postgres
   ```

   Example output:

   ```console
   NAME               TEAM      VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE    STATUS
   cfs-ara-postgres   cfs-ara   14        3      50Gi                                    524d   Running
   ```

1. (`ncn-mw#`) Enable Istio sidecar injection on the target database cluster.

   Command:

   ```bash
   kubectl -n services patch postgresql cfs-ara-postgres --type=merge --patch '{"spec": {"podAnnotations": {"sidecar.istio.io/inject": "false"}}}'
   ```

   The database cluster will once again transition to Updating and then Running.

The `cray-postgres-operator` pod log should now contain the following for the target database cluster.

```console
time="2025-07-31T09:42:43Z" level=info msg="cluster version up to date. current: 140008, min desired: 140000" cluster-name=services/cray-dns-powerdns-postgres pkg=cluster
```

This will be resolved in a future CSM release.
