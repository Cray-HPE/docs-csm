# Utility Storage

Utility storage is designed to support Kubernetes and the System Management Services (SMS) it orchestrates. Utility storage is a cost-effective solution for storing the large amounts of telemetry and log data collected.

Ceph is the utility storage platform that is used to enable pods to store persistent data. It is deployed to provide block, object, and file storage to the management services running on Kubernetes, as well as for telemetry data coming from the compute nodes.

**IMPORTANT NOTES:**

- Commands for Ceph health must be run from either a master NCN,`ncn-s001`, `nnc-s002`, or `ncn-s003`, unless they are otherwise specified to run on the host in question. Those nodes are the only ones with the necessary credentials. Individual procedures will specify when to run a command from a node other than those.

## Key Concepts

- **Shrink:** This only pertains to removing nodes from a cluster. Since Octopus and the move to utilize Ceph orchestrator, the Ceph cluster is probing nodes and adding unused drives. Removing a drive will only work if the actual drive is removed from a server.
- **Add:** This will most commonly pertain to adding a node with its full allotment of drives.  
- **Replace:** This will most commonly pertain to replacing a drive or a node after hardware repairs.

