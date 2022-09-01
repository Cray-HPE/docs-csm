# Establish a Serial Connection to NCNs

The ConMan pod can be used to establish a serial console connection with each non-compute node (NCN) in the system.

In the scenario of a power down or reboot of an NCN worker, one must first determine if any `cray-console` pods
are running on that NCN. It is important to move `cray-console` pods to other worker nodes before rebooting or
powering off a worker node to minimize disruption in console logging. If a brief interruption in console logging
and interactive access is acceptable while the NCN worker is being drained, the evacuation may be skipped.

If a `cray-console-node` pod is running on a worker node when it is powered off or rebooted, then access to its
associated consoles will be unavailable until one of the following things happens:

* the worker node comes back up and the `cray-console-node` pod begins running on it.
* the `cray-console-node` pod is terminated and comes up on another worker node.
* the `cray-console-operator` pod assigns the associated consoles to a different `cray-console-node` pod.

## Prerequisites

The user performing these procedures needs to have access permission to the `cray-console-operator` and `cray-console-node` pods.

## Connection procedure

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

1. Check which NCN worker node the `cray-console-node` pod is running on.

    ```bash
    ncn-mw# kubectl -n services get pods -o wide | grep $NODE_POD
    ```

    Example output:

    ```text
    cray-console-node-1   3/3  Running  0  3h55m   10.42.0.12  ncn-w010   <none>   <none>
    ```

    If the pod is running on the node that is going to be rebooted, the interactive session
    and logging will be interrupted while the NCN worker is drained and the pods are all
    migrated to different NCN workers. To maintain an interactive console session, the
    `cray-console-node` pod must be moved:

    1. Cordon the NCN worker node to suspend scheduling and delete the pod

        ```bash
        ncn-mw# WNODE=ncn-wxxx
        ncn-mw# kubectl cordon $WNODE
        ncn-mw# kubectl -n services delete pod $NODE_POD
        ```

    1. Wait for the pod to restart on another NCN worker

    1. Repeat the previous step to find if this node is now being monitored by a different `cray-console-node` pod.

    **NOTE:** To insure the minimum disruption to console logging and interaction, you may
    optionally follow the [Evacuation procedure](#evacuation-procedure) to remove all console
    logging services prior to draining this node.

1. Establish a serial console session with the desired NCN.

    ```bash
    ncn-mw# kubectl -n services exec -it $NODE_POD -- conman -j $XNAME
    ```

    The console session log files for each NCN are located in a shared volume in the `cray-console-node` pods.
    In those pods, the log files are in the `/var/log/conman/` directory and are named `console.<xname>`.

1. Exit the connection to the console by entering `&.`.

## Evacuation procedure

In order to avoid losing data while monitoring a reboot or power down of a worker node,
first follow this procedure to evacuate the target worker node of its pods.

**NOTE:** If multiple `cray-console-node` pods are present on the worker being evacuated, the
deployment may be edited to add anti-affinity to the Kubernetes scheduling. Follow the directions
in [Console Node Affinity](../../troubleshooting/known_issues/console_node_affinity.md).

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

        Run the following command until both deployments show `2/2` pods are ready.

        ```bash
        ncn-mw# kubectl -n services get deployment | grep cray-console
        ```

        Example output:

        ```text
        cray-console-data           2/2     1          1     1m
        cray-console-operator       2/2     1          1     1m
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
        cray-console-node   3/3     1m
        ```

1. After the node has been rebooted and can accept `cray-console` pods again, remove the node cordon.

    ```bash
    ncn-mw# kubectl uncordon $WNODE
    ```
