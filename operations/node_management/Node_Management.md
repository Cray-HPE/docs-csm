# Node Management

The HPE Cray EX systems include two node types:

- **Compute Nodes** that run high-performance computing applications and are named `nidXXXXXX`. Every system must contain four or more compute nodes, starting at `nid000001`.
- **Non-Compute Nodes \(NCNs\)** that carry out system management functions as part of the management Kubernetes cluster. NCNs outside of the Kubernetes cluster function as application nodes \(AN\).


Nine or more management NCNs host system services:
- `ncn-m001`, `ncn-m002`, and `ncn-m003` are Kubernetes **master** nodes.
- `ncn-w001`, `ncn-w002`, and `ncn-w003` are Kubernetes **worker** nodes. Every system contains three or more worker nodes.
- `ncn-s001`, `ncn-s002`, and `ncn-s003` are **utility storage** nodes. Every system contains three or more utility storage nodes.
    

Application nodes \(AN\) are any NCN that is not providing system management functions. One special type of AN is the UAN (User Access Node), but different systems may have need for other types of ANs, such as:
- Nodes which provide a Lustre routing function (LNet router)
- Gateways between the HSN and other networks
- Data movers between two different network file systems
- Visualization servers
- Other special-purpose nodes

