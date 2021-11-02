## Node Management

The HPE Cray EX system includes two types of nodes:

-   **Compute Nodes**, where high performance computing applications are run, and node names in the form of `nidXXXXXX`
-   **Non-Compute Nodes \(NCNs\)**, which carry out system functions and come in three versions:
    -   **Master** nodes, with names in the form of `ncn-mXXX`
    -   **Worker** nodes, with names in the form of `ncn-wXXX`
    -   **Utility Storage** nodes, with names in the form of `ncn-sXXX`

The HPE Cray EX system includes the following nodes:

-   Nine or more non-compute nodes \(NCNs\) that host system services:
    -   `ncn-m001`, `ncn-m002`, and `ncn-m003` are configured as Kubernetes master nodes.
    -   `ncn-w001`, `ncn-w002`, and `ncn-w003` are configured as Kubernetes worker nodes. Every system contains three or more worker nodes.
    -   `ncn-s001`, `ncn-s002`, and `ncn-s003` for storage. Every system contains three or more utility storage node.
-   Four or more compute nodes, starting at `nid000001`.




