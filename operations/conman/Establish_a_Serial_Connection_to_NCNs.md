# Establish a Serial Connection to NCNs

The ConMan pod can be used to establish a serial console connection with each non-compute node (NCN) in the system.

In the scenario of a power down or reboot of an NCN worker, one must first determine if any `cray-console` pods
are running on that NCN. It is important to move `cray-console` pods to other worker nodes before rebooting or
powering off a worker node to minimize disruption in console logging.

If a `cray-console-node` pod is running on a worker node when it is powered off or rebooted, then access to its
associated consoles will be unavailable until one of the following things happens:

* the worker node comes back up and the `cray-console-node` pod begins running on it.
* the `cray-console-node` pod is terminated and comes up on another worker node.
* the `cray-console-operator` pod assigns the associated consoles to a different `cray-console-node` pod.

## Prerequisites

The user performing these procedures needs to have access permission to the `cray-console-operator` and `cray-console-node` pods.

## Connection procedure

1. When trying to monitor a worker node that will be rebooted or powered down, first follow the
   [Evacuation procedure](#evacuation-procedure).

1. Find the `cray-console-operator` pod.

    ```bash
    ncn-mw# OP_POD=$(kubectl get pods -n services \
            -o wide|grep cray-console-operator|awk '{print $1}')
    ncn-mw# echo $OP_POD
    ```

    Example output:

    ```text
    cray-console-operator-6cf89ff566-kfnjr
    ```

1. Find the `cray-console-node` pod that is connecting with the console.

    ```bash
    ncn-mw# NODE_POD=$(kubectl -n services exec $OP_POD -c cray-console-operator -- sh -c \
        "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
    ncn-mw# echo $NODE_POD
    ```

    Example output:

    ```text
    cray-console-node-1
    ```

1. Establish a serial console session with the desired NCN.

    ```bash
    ncn-mw# kubectl -n services exec -it $NODE_POD -- conman -j $XNAME
    ```

    The console session log files for each NCN are located in a shared volume in the  `cray-console-node` pods.
    In those pods, the log files are in the `/var/log/conman/` directory and are named `console.<xname>`.

    **IMPORTANT:** If the `cray-console-node` pod the user is connected through is running on the same NCN that the console session is connected to,
    and a reboot of that same NCN is initiated, then expect the connection to terminate and there to be a gap in the console log file.
    The gap will last until the console connection is reestablished through a different `cray-console-node` pod or until the existing pod is restarted on a different NCN.
    If the `cray-console-node` pod was running on a different NCN or was moved prior to the reboot, then the console log and session should persist through the operation.

1. Exit the connection to the console by entering `&.`.

## Evacuation procedure

In order to avoid losing data while monitoring a reboot or power down of a worker node,
first follow this procedure to evacuate the target worker node of its pods.

1. Set the `WNODE` variable to the name of the worker node being evacuated.

    Modify the following example to reflect the actual worker node number.

    ```bash
    ncn-mw# WNODE=ncn-wxxx
    ```

1. Cordon the node so that rescheduled pods do not end up back on the same node.

    ```bash
    ncn-mw# kubectl cordon $WNODE
    ```

1. Find all `cray-console` pods that need to be migrated.

    This includes `cray-console-node`, `cray-console-data` (but not its Postgres pods), and `cray-console-operator`.

    ```bash
    ncn-mw# kubectl get pods -n services -l 'app.kubernetes.io/name in (cray-console-node, cray-console-data, cray-console-operator)' \
        --field-selector spec.nodeName=$WNODE | awk '{print $1}'
    ```

    Example output:

    ```text
    cray-console-operator-6cf89ff566-kfnjr
    ```

1. Delete the `cray-console-operator` and `cray-console-data` pods listed in the previous step.

    If none were listed, then skip this step.

    1. Delete the pods.

        ```bash
        ncn-mw# for POD in $(kubectl get pods -n services -l 'app.kubernetes.io/name in (cray-console-data, cray-console-operator)' \
            --field-selector spec.nodeName=$WNODE | awk '{print $1}'); do
                    kubectl -n services delete pod $POD
            done
        ```

    1. Wait for the `console-operator` and `console-data` pods to be re-scheduled on other nodes.

        Run the following command until both deployments show `1/1` pods are ready.

        ```bash
        ncn-mw# kubectl -n services get deployment | grep cray-console
        ```

        Example output:

        ```text
        cray-console-data           1/1     1          1     1m
        cray-console-operator       1/1     1          1     1m
        ```

1. Delete any `cray-console-node` pods listed in the earlier step.

    If none were listed, then skip this step.

    1. Delete the pods.

        ```bash
        ncn-mw# for POD in $(kubectl get pods -n services -l 'app.kubernetes.io/name=cray-console-node' --field-selector spec.nodeName=$WNODE | awk '{print $1}'); do
                kubectl -n services delete pod $POD
            done
        ```

    1. Wait for the `console-node` pods to be re-scheduled on other nodes.

        Run the following command until all pods show ready.

        ```bash
        ncn-mw# kubectl -n services get statefulset cray-console-node
        ```

        Example output:

        ```text
        NAME                READY   AGE
        cray-console-node   2/2     1m
        ```

1. After the node has been rebooted and can accept `cray-console` pods again, remove the node cordon.

    ```bash
    ncn-mw# kubectl uncordon $WNODE
    ```
