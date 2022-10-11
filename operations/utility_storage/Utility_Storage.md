# Utility Storage

- [Overview](#overview)
- [Storage tools and information references](#storage-tools-and-information-references)
- [Storage troubleshooting references](#storage-troubleshooting-references)

## Overview

Utility storage is designed to support Kubernetes and the System Management Services (SMS) it orchestrates. Utility storage is a cost-effective solution for storing the large amounts of telemetry and log data collected.

Ceph is the utility storage platform that is used to enable pods to store persistent data. It is deployed to provide block, object, and file storage to the management services running on Kubernetes, as well as for telemetry data coming from the compute nodes.

**IMPORTANT NOTES:**

- Commands for Ceph health must be run from either a master NCN,`ncn-s001`, `ncn-s002`, or `ncn-s003`, unless they are otherwise specified to run on the host in question.
Those nodes are the only ones with the necessary credentials. Individual procedures will specify when to run a command from a node other than those.

### Key Concepts

- **Shrink:** This only pertains to removing nodes from a cluster. Since Octopus and the move to utilize Ceph orchestrator, the Ceph cluster is probing nodes and adding unused drives. Removing a drive will only work if the actual drive is removed from a server.
- **Add:** This will most commonly pertain to adding a node with its full allotment of drives.
- **Replace:** This will most commonly pertain to replacing a drive or a node after hardware repairs.

## Storage tools and information references

Adjust Ceph cluster

- [Adding a Ceph Node to the Ceph Cluster](Add_Ceph_Node.md)
- [Add Ceph OSDs](Add_Ceph_OSDs.md)
- [Shrink the Ceph Cluster](Remove_Ceph_Node.md): remove a ceph node
- [Shrink Ceph OSDs](Shrink_Ceph_OSDs.md): remove OSDs from a ceph cluster
- [Adjust Ceph Pool Quotas](Adjust_Ceph_Pool_Quotas.md)
- [Alternate Storage Pools](Alternate_Storage_Pools.md)

Ceph information

- [Ceph Storage Types](Ceph_Storage_Types.md)
- [Ceph Health States](Ceph_Health_States.md)
- [Cephadm Reference Material](Cephadm_Reference_Material.md)

Ceph related operations

- [Ceph Daemon Memory Profiling](Ceph_Daemon_Memory_Profiling.md)
- [Ceph Deep Scrubs](Ceph_Deep_Scrubs.md)
- [Dump Ceph Crash Data](Dump_Ceph_Crash_Data.md)
- [Identify Ceph Latency Issues](Identify_Ceph_Latency_Issues.md)
- [Manage Ceph Services](Manage_Ceph_Services.md)
- [Restore Nexus Data After Data Corruption](Restore_Corrupt_Nexus.md)
- [Collect Information about the Ceph Cluster](Collect_Information_About_the_Ceph_Cluster.md)

Ceph tools' usage documentation

- [Ceph Orchestrator Usage](Ceph_Orchestrator_Usage.md)
- [CSM RBD Tool Usage](CSM_rbd_tool_Usage.md)
- [Ceph Service Check Script Usage](Ceph_Service_Check_Script_Usage.md)
- [cubs_tool Usage](Cubs_tool_Usage.md)

## Storage troubleshooting references

 MDS

- [Troubleshoot Ceph MDS Client Connectivity Issues](Troubleshoot_Ceph_FS_Client_Connectivity_issues.md)
- [Troubleshooting Ceph MDS Reporting Slow Requests and Failure on Client](Troubleshoot_Ceph_MDS_reporting_slow_requests_and_failure_on_client.md)
- [Troubleshoot Insufficient Standby MDS Daemons Available](Troubleshoot_Insufficient_Standby_MDS_Daemons_Available.md)

RGW

- [Troubleshoot if RGW Health Check Fails](Troubleshoot_RGW_Health_Check_Fail.md)
- [Troubleshoot an Unresponsive Rados-Gateway (radosgw) S3 Endpoint](Troubleshoot_an_Unresponsive_S3_Endpoint.md)

OSD

- [Troubleshoot Ceph OSDs Reporting Full](Troubleshoot_Ceph_OSDs_Reporting_Full.md)
- [Troubleshoot a Down OSD](Troubleshoot_a_Down_OSD.md)

Ceph Health

- [Troubleshoot Large Object Map Objects in Ceph Health](Troubleshoot_Large_Object_Map_Objects_in_Ceph_Health.md)
- [Troubleshoot Failure to Get Ceph Health](Troubleshoot_Failure_to_Get_Ceph_Health.md)

Other

- [Troubleshoot Ceph-Mon Processes Stopping and Exceeding Max Restarts](Troubleshoot_Ceph-Mon_Processes_Stopping_and_Exceeding_Max_Restarts.md)
- [Troubleshoot S3FS Mount Issues](Troubleshoot_S3FS_Mounts.md)
- [Troubleshoot System Clock Skew](Troubleshoot_System_Clock_Skew.md)
- [Troubleshoot Ceph Services Not Starting After a Server Crash](Troubleshoot_Ceph_Services_Not_Starting.md)
- [Troubleshoot Pods Failing to Restart on Other Worker Nodes](Troubleshoot_Pods_Multi-Attach_Error.md)
