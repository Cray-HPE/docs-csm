# Manage Node Consoles

The cray-conman service determines which nodes it should monitor by checking with the Hardware State
Manager (HSM) service. It does this once when it starts. If HSM has not discovered some nodes when
cray-conman starts, then HSM is unaware of them and so is cray-conman.

Verify that all nodes are being monitored for console logging and connect to them if desired.

Refer to "About the ConMan Containerized Service" in the _HPE Cray EX System Administration Guide 1.5 S-8001_
for more information about these topics.

   * Access Compute Node Logs Using ConMan
   * Access Console Log Data Via the System Monitoring Framework (SMF)
   * Log in to a Node Using ConMan
   * Establish a Serial Connection to NCNs
   * Troubleshoot ConMan Blocking Access to a Node BMC
   * Troubleshoot ConMan Failing to Recognize New or Removed Nodes


## Procedure

This procedure can be run from any member of the Kubernetes cluster to verify node consoles are being managed
by conman and to connect to a console. **Note** this procedure has changed since the CSM 0.9 release.

1. Find the cray-console-operator pod ID
    ```bash
    ncn# CONPOD=$(kubectl get pods -n services \-o wide|grep cray-console-operator|awk '{print $1}')
    ncn# echo $CONPOD
    ```

1. Find the cray-console-node pod that is connected to the node. Be sure to substitute the actual xname of the node in the command below.
    ```bash
    ncn# NODEPOD=$(kubectl -n services exec $CONPOD -c cray-console-operator -- sh -c "/app/get-node <xname>" | jq .podname | sed 's/"//g')
    ncn# echo $NODEPOD
    ```

1. Log into the `cray-console-node` container in this pod:

   ```bash
   ncn# kubectl exec -n services -it $NODEPOD -c cray-console-node -- bash
   cray-console-node#
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

1. To access the node's console, run the following command from within the pod. Again, remember to substitute the actual xname of the node.
    ```bash
    cray-console-node# conman -j <xname>
    ```
    
    > The console session can be exited by entering `&.`

1. Repeat the previous steps to verify that cray-conman is now managing all nodes that are included in HSM.

