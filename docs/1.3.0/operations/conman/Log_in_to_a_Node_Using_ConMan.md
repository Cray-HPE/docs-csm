# Log in to a Node Using ConMan

This procedure shows how to connect to the node's Serial Over Lan (SOL) via ConMan.

## Prerequisites

The user performing this procedure needs to have access permission to the `cray-console-operator` and `cray-console-node` pods.

## Procedure

> **`NOTE`** this procedure has changed since the CSM 0.9 release.

1. Log on to a Kubernetes master or worker node.

1. Find the `cray-console-operator` pod.

    ```bash
    OP_POD=$(kubectl get pods -n services \
            -o wide|grep cray-console-operator|awk '{print $1}')
    echo $OP_POD
    ```

    Example output:

    ```text
    cray-console-operator-6cf89ff566-kfnjr
    ```

1. Set the `XNAME` variable to the component name (xname) of the node whose console you wish to open.

    ```bash
    XNAME=x123456789s0c0n0
    ```

1. Find the `cray-console-node` pod that is connected to that node.

    ```bash
    NODEPOD=$(kubectl -n services exec $OP_POD -c cray-console-operator -- \
        sh -c "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
    echo $NODEPOD
    ```

    Example output:

    ```text
    cray-console-node-1
    ```

1. Connect to the node's console using ConMan on the `cray-console-node` pod you found.

    ```bash
    kubectl exec -it -n services $NODEPOD -c cray-console-node -- conman -j $XNAME
    ```

    Example output:

    ```text
    <ConMan> Connection to console [x3000c0s25b1] opened.

    nid000009 login:
    ```

    Using the command above, a user can also attach to an already active SOL session that is being used by another user, so both can access the node's SOL simultaneously.

1. Exit the connection to the console with the `&.` command.
