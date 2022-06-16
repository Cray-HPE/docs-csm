# ConMan

ConMan is a tool used for connecting to remote consoles and collecting console logs. These node logs can then be used for various administrative purposes, such as troubleshooting node boot issues.

ConMan runs on the system as a containerized service. It runs in a set of Docker containers within Kubernetes pods named `cray-console-operator` and `cray-console-node`.
Node console logs are stored locally within the `cray-console-node` pods in the `/var/log/conman/` directory, as well as being collected by the System Monitoring Framework \(SMF\).

In CSM versions 1.0 and later, the ConMan logs and interactive consoles are accessible through one of the `cray-console-node` pods.
There are multiple `cray-console-node` pods, scaled to the size of the system.

## How To Use

See [Log in to a Node Using ConMan](Log_in_to_a_Node_Using_ConMan.md) for more information.
