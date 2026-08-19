# Manage Node Consoles

ConMan is used for connecting to remote consoles and collecting console logs. These node logs can then be used for various
administrative purposes, such as troubleshooting node boot issues.

ConMan runs on the system in a set of containers within Kubernetes pods named `cray-console-operator` and `cray-console-node`.

The `cray-console-operator` and `cray-console-node` pods determine which nodes they should monitor by checking with the
Hardware State Manager (HSM) service. They do this once when they starts. If HSM has not discovered some nodes when
they start, then HSM is unaware of them and therefore so are the `cray-console-operator` and `cray-console-node` pods.

Verify that all nodes are being monitored for console logging and connect to them if desired.

See [ConMan](ConMan.md) for other procedures related to remote consoles and node console logging.

## Procedure

This procedure can be run from any member of the Kubernetes cluster to verify node consoles are being managed
by ConMan and to connect to a console.

**NOTE** this procedure has changed since the CSM 1.6.x releases.

1. Follow a node's console logs.

    Follow the procedure in [Access Compute Node Logs](Access_Compute_Node_Logs.md) to follow the console logs of a node.

1. Interact with a node through its console.

    Follow the procedure in [Log in to a Node Using ConMan](Log_in_to_a_Node_Using_ConMan.md) to interact with a node through its console.
