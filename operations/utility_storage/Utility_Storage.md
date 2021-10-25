

# Utility Storage

Utility storage is designed to support Kubernetes and the System Management Services (SMS) it orchestrates. Utility storage is a cost-effective solution for storing the large amounts of telemetry and log data collected.

Ceph is the utility storage platform that is used to enable pods to store persistent data. It is deployed to provide block, object, and file storage to the management services running on Kubernetes, as well as for telemetry data coming from the compute nodes.

**IMPORTANT NOTES:**

- Commands for Ceph health must be run from either ncn-m or ncn-s001/2/3 unless they are otherwise specified to run on the host in question. 
- ncn-m and ncn-s001/2/3 are the only servers with the credentials. Individual procedures will specify when to run a command from a node other than those.

