## Manage Node Consoles

ConMan is used for connecting to remote consoles and collecting console logs. These node logs can then be used for various administrative purposes, such as troubleshooting node boot issues.

ConMan runs on the system in a set of containers within Kubernetes pods named cray-console-operator and cray-console-node.

The `cray-console-operator` and `cray-console-node` pods determine which nodes they should monitor by checking with the
Hardware State Manager (HSM) service. They do this once when they starts. If HSM has not discovered some nodes when
they start, then HSM is unaware of them and therefore so are the `cray-console-operator` and `cray-console-node` pods.

Verify that all nodes are being monitored for console logging and connect to them if desired.

See [ConMan](ConMan.md) for other procedures related to remote consoles and node console logging.

### Procedure

This procedure can be run from any member of the Kubernetes cluster to verify node consoles are being managed
by ConMan and to connect to a console.

**NOTE:** this procedure has changed since the CSM 0.9 release.

1. Find the `cray-console-operator` pod ID
    
    ```bash
    ncn# CONPOD=$(kubectl get pods -n services \-o wide|grep cray-console-operator|awk '{print $1}')
    ncn# echo $CONPOD
    ```

1. Find the cray-console-node pod that is connected to the node. Be sure to substitute the actual component name (xname) of the node in the command below.
    
    ```bash
    ncn# XNAME=<xname>
    ncn# NODEPOD=$(kubectl -n services exec $CONPOD -c cray-console-operator -- sh -c "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
    ncn# echo $NODEPOD
    ```

1. Log into the `cray-console-node` container in this pod:

   ```bash
   ncn# kubectl exec -n services -it $NODEPOD -c cray-console-node -- bash
   ```

1. Check the list of nodes being monitored.

   ```bash
   cray-console-node# conman -q
   ```

   Output looks similar to the following:

   ```
   x9000c0s1b0n0
   x9000c0s20b0n0
   x9000c0s22b0n0
   x9000c0s24b0n0
   x9000c0s27b1n0
   x9000c0s27b2n0
   x9000c0s27b3n0
   ```

1. Compute nodes or UANs are automatically added to this list a short time after they are discovered.

1. To access the node's console, run the following command from within the pod. Again, remember to substitute the actual component name (xname) of the node.
    
    ```bash
    cray-console-node# conman -j <xname>
    ```

    > The console session can be exited by entering `&.`

1. Repeat the previous steps to verify that cray-console is now managing all nodes that are included in HSM.

