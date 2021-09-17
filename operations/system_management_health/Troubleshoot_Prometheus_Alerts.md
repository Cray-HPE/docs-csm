# Troubleshoot Prometheus Alerts

General Prometheus Alert Troubleshooting Topics
- [PostgresqlFollowerReplicationLagSMA](#followerlagsma)
- [PostgresqlHighRollbackRate](#highrollbackrate)
- [PostgresqlInactiveReplicationSlot](#inactiveslot)
- [PostgresqlNotEnoughConnections](#notenoughconnections)
- [CPUThrottlingHigh](#cputhrottlinghigh)

<a name="followerlagsma"></a>
## PostgresqlFollowerReplicationLagSMA

Alerts for PostgresqlFollowerReplicationLagSMA on sma-postgres-cluster pods with slot_name="permanent_physical_1" can be ignored. This slot_name is disabled and will be removed in a future release.


<a name="highrollbackrate"></a>
## PostgresqlHighRollbackRate

Alerts for PostgresqlHighRollbackRate on spire-postgres pods can be ignored. This is caused by an idle session that requires a timeout. This will be fixed in a future release.


<a name="inactiveslot"></a>
## PostgresqlInactiveReplicationSlot

Alerts for PostgresqlInactiveReplicationSlot on sma-postgres-cluster pods with slot_name="permanent_physical_1" can be ignored. This slot_name is disabled and will be removed in a future release.


<a name="notenoughconnections"></a>
## PostgresqlNotEnoughConnections

Alerts for PostgresqlNotEnoughConnections for datname="foo" and datname="bar" can be ignored. These databases are not used and will be removed in a future release.


<a name="cputhrottlinghigh"></a>
## CPUThrottlingHigh

Alerts for CPUThrottlingHigh on gatekeeper-audit can be ignored. This pod is not utilized in this release.

Alerts for CPUThrottlingHigh on CFS services such as cfs-batcher and cfs-trust can be ignored. Because CFS is idle most of the time these services have low CPU requests, and it is normal for CFS service resource usage to spike when it is in use.


<a name="networkpacketsdropped"></a>
## CephNetworkPacketsDropped

The CephNetworkPacketsDropped alert doesn't necessarily indicate there are packets being dropped on an interface on a storage node.  In a future release this alert will be renamed to be more generic.  If this alert fires, inspect the IP address in the details of the alert to determine the node in question (can be storage, master or worker node).  If the interface in question is determined to be healthy, this alert can be ignored.



