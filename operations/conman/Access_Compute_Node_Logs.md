# Access Compute Node Logs

This procedure shows how the ConMan utility can be used to retrieve compute node logs.

## Prerequisites

The user performing this procedure needs to have access permission to the `cray-console-operator` pod.

## Limitations

Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.

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

1. Log on to the pod.

    ```bash
    kubectl exec -it -n services $OP_POD  -c cray-console-operator -- sh
    ```

1. The console log file for each node is labeled with the component name (xname) of that node.

    List the log directory contents.

    ```bash
    # ls -la /var/log/conman
    total 44
    -rw------- 1 root root 1415 Nov 30 20:00 console.XNAME
    ...
    ```

    > The log directory is also accessible from the `cray-console-node` pods.

1. The log files are plain text files which can be viewed with commands like `cat` or `tail`.

    ```bash
    tail /var/log/conman/console.XNAME
    ```

1. Exit out of the pod.

    ```bash
    exit
    ```
