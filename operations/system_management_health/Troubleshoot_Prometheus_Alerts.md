# Troubleshoot Prometheus Alerts

- [`CephMgrIsAbsent` and `CephMgrIsMissingReplicas`](#cephmgrisabsent-and-cephmgrismissingreplicas)
- [`CephNetworkPacketsDropped`](#cephnetworkpacketsdropped)
- [`CPUThrottlingHigh`](#cputhrottlinghigh)
- [`PostgresqlFollowerReplicationLagSMA`](#postgresqlfollowerreplicationlagsma)
- [`PostgresqlHighRollbackRate`](#postgresqlhighrollbackrate)
- [`PostgresqlInactiveReplicationSlot`](#postgresqlinactivereplicationslot)
- [`PostgresqlNotEnoughConnections`](#postgresqlnotenoughconnections)
- [`TargetDown`](#targetdown)

## `CephMgrIsAbsent` and `CephMgrIsMissingReplicas`

If the `CephMgrIsAbsent` and/or `CephMgrIsMissingReplicas` alerts fire, use the following steps to ensure the `prometheus` module has been enabled for `Ceph`. The following steps should be executed on `ncn-s001`:

```bash
ceph mgr module ls | jq '.enabled_modules'
```

Example output:

```json
[
  "cephadm",
  "iostat",
  "restful"
]
```

If `prometheus` is missing from the output, enable with the following command:

```bash
ceph mgr module enable prometheus
```

Confirm the module is now enabled:

```bash
ceph mgr module ls | jq '.enabled_modules'
```

Example output:

```json
[
  "cephadm",
  "iostat",
  "prometheus",
  "restful"
]
```

The `CephMgrIsAbsent` and `CephMgrIsMissingReplicas` alerts should now clear in Prometheus.

## `CephNetworkPacketsDropped`

The `CephNetworkPacketsDropped` alert does not necessarily indicate there are packets being dropped on an interface on a storage node. In a future release this alert will be renamed
to be more generic. If this alert fires, inspect the IP address in the details of the alert to determine the node in question (it can be storage, master, or worker node). If the
interface in question is determined to be healthy, then this alert can be ignored.

## `CPUThrottlingHigh`

Alerts for `CPUThrottlingHigh` on `gatekeeper-audit` can be ignored. This pod is not utilized in this release.

Alerts for `CPUThrottlingHigh` on `gatekeeper-controller-manager` can be ignored. These have low CPU requests, and it is normal for resource usage to spike when it is in use.

Alerts for `CPUThrottlingHigh` on `smartmon` pods can be ignored. It is normal for `smartmon` pods' resource usage to spike when it is polling. This will be fixed in a future release.

Alerts for `CPUThrottlingHigh` on CFS services such as `cfs-batcher` and `cfs-trust` can be ignored. Because CFS is idle most of the time, these services have low CPU requests, and it is normal for CFS service resource usage to spike when it is in use.

## `PostgresqlFollowerReplicationLagSMA`

Alerts for `PostgresqlFollowerReplicationLagSMA` on `sma-postgres-cluster` pods with `slot_name="permanent_physical_1"` can be ignored. This `slot_name` is disabled and will be removed in a future release.

## `PostgresqlHighRollbackRate`

Alerts for `PostgresqlHighRollbackRate` on `spire-postgres` and `smd-postgres` pods can be ignored. This is caused by an idle session that requires a timeout. This will be fixed in a future release.

## `PostgresqlInactiveReplicationSlot`

Alerts for `PostgresqlInactiveReplicationSlot` on `sma-postgres-cluster` pods with `slot_name="permanent_physical_1"` can be ignored. This `slot_name` is disabled and will be removed in a future release.

## `PostgresqlNotEnoughConnections`

Alerts for `PostgresqlNotEnoughConnections` for `datname="foo"` and `datname="bar"` can be ignored. These databases are not used and will be removed in a future release.

## `TargetDown`

Many of the alerts for `TargetDown` for `sysmgmt-health/cray-sysmgmt-health-kubernetes-pods/0` are due to job pods that have `Completed` and no longer have an active endpoint that
can be scraped. If the target that is down is from a job pod that has completed, the `TargetDown` alert for that pod can be ignored. This is being fixed in a future release.
