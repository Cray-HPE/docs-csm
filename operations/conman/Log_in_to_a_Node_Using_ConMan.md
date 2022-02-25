## Log in to a Node Using ConMan

This procedure shows how to connect to the node's Serial Over Lan (SOL) via ConMan.

### Prerequisites

The user performing this procedure needs to have access permission to the `cray-console-operator` and `cray-console-node` pods.

### Procedure

1. Log in to a non-compute node (NCN) that acts as a Kubernetes master or worker.

1. Retrieve the `cray-console-operator` pod ID.

    ```bash
    ncn# CONPOD=$(kubectl get pods -n services \
        -o wide|grep cray-console-operator|awk '{print $1}')
    ncn# echo $CONPOD
    ```

2. Set the `XNAME` variable to the component name (xname) of the node whose console you wish to open.

    ```bash
    ncn# XNAME=x123456789s0c0n0
    ```

3. Find the `cray-console-node` pod that is connected to that node.

    ```bash
    ncn# NODEPOD=$(kubectl -n services exec $CONPOD -c cray-console-operator -- \
        sh -c "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
    ncn# echo $NODEPOD
    ```

4. Connect to the node's console using ConMan on the `cray-console-node` pod you found.

    ```bash
    ncn# kubectl exec -it -n services $NODEPOD -- conman -j $XNAME
    ```

    Example output:

    ```
    <ConMan> Connection to console [x3000c0s25b1] opened.

    nid000009 login:
    ```

    Using the command above, a user can also attach to an already active SOL session that is being used by another user, so both can access the node's SOL simultaneously.

5. Exit the connection to the console with the `&.` command.
