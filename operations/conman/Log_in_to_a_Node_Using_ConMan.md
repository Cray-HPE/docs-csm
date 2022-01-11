## Log in to a Node Using ConMan

This procedure shows how to connect to the node's Serial Over Lan (SOL) via ConMan.

### Prerequisites

The user performing this procedure needs to have access permission to the `cray-console-operator` and `cray-console-node` pods.

### Procedure

1. Log in to a non-compute node (NCN) that acts as a Kubernetes master or worker.

2. Retrieve the cray-console-operator pod ID.

    ```
    ncn-m001# CONPOD=$(kubectl get pods -n services \
    -o wide|grep cray-console-operator|awk '{print $1}')
    ncn-m001# echo $CONPOD
    cray-console-operator-79bf95964-qpcpp
    ```

3. Find the cray-console-node pod that is connected to the node.

    ```
    ncn-m001: # NODEPOD=$(kubectl -n services exec $CONPOD -c cray-console-operator -- sh -c '/app/get-node XNAME' | jq .podname | sed 's/"//g')
    ncn-m001: # echo $NODEPOD
    cray-console-node-1
    ```

4. Log into the correct console-node pod.

    ```
    ncn-m001# kubectl exec -it -n services $NODEPOD -- /bin/bash
    cray-console-node-1:/ #
    ```

5. Use the node's ID to connect to the node's SOL via ConMan.

    ```
    cray-console-node-1:/ # conman -j NODE_ID
    <ConMan> Connection to console [x3000c0s25b1] opened.

    nid000009 login:
    ```
    Using the command above, a user can also attach to an already active SOL session that is being used by another user, so both can access the node's SOL simultaneously.

6. Exit the connection to the console with the `&.` command.

7. Exit the cray-console-node pod.

    ```
    cray-console-node-1:/ # exit
    ncn-m001: #
    ```
