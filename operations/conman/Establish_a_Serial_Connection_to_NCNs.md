# Establish a Serial Connection to NCNs

The ConMan pod can be used to establish a serial console connection with each non-compute node (NCN) in the system.
In the scenario of a power down or reboot of an NCN worker, one must first determine if any `cray-console-node` pods
are running on that NCN. It is important to move `cray-console-node` pods to other worker nodes before rebooting or
powering off a worker node.

If a `cray-console-node` pod is running on a worker node when it is powered off or rebooted, then access to its
associated consoles will be unavailable until one of the following things happens:
* the worker node comes back up and the `cray-console-node` pod begins running on it.
* the `cray-console-node` pod is terminated and comes up on another worker node.
* the `cray-console-operator` pod assigns the associated consoles to a different `cray-console-node` pod.

## Prerequisites

The user performing this procedure needs to have access permission to the `cray-console-operator` and `cray-console-node` pods.

## Procedure

**Note:** this procedure has changed since the CSM 0.9 release.

1. Find the `cray-console-operator` pod.

    ```bash
    ncn# OP_POD=$(kubectl get pods -n services \
            -o wide|grep cray-console-operator|awk '{print $1}')
    ncn# echo $OP_POD
    ```

    Example output:
    ```text
    cray-console-operator-6cf89ff566-kfnjr
    ```

1. Set the `XNAME` variable to the component name (xname) of the NCN whose console is of interest.

    NCN component names (xnames) can be gathered from the `/opt/cray/platform-utils/ncnGetXnames.sh` script.

    ```bash
    ncn# XNAME=<xname>
    ```

1. Find the `cray-console-node` pod that is connecting with the console.

    ```bash
    ncn# NODE_POD=$(kubectl -n services exec $OP_POD -c cray-console-operator -- sh -c \
        "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
    ncn# echo $NODE_POD
    ```

    Example output:
    ```text
    cray-console-node-2
    ```

1. Find the worker node on which this pod is running.

    ```bash
    ncn# WNODE=$(kubectl get pods -o custom-columns=:.spec.nodeName -n services --no-headers $NODE_POD)
    ncn# echo $WNODE
    ```

    Example output:
    ```text
    ncn-w003
    ```

1. **Optional:** Move the `cray-console-node` pod.

    The pod can be proactively moved to a different worker if a power or reboot operation is going to be performed on the node where the pod is running.

    1. Prevent new pods from being scheduled on the NCN worker node currently running ConMan.

        ```bash
        ncn# kubectl cordon $WNODE
        ```

    1. Delete the pod.

        When the pod comes back up, it will be on a different NCN worker node.

        ```bash
        ncn# kubectl -n services delete $NODE_POD
        ```

    1. Wait for pod to terminate and come back up again.

        It may take several minutes even after the pod is running for the console connections to be re-established.

    1. Find the `cray-console-node` pod that is connecting with the console.

        While the pod was being terminated and restarted, there is a small chance that the console connection was
        moved to a different `cray-console-node` pod.

        ```bash
        ncn# NODE_POD=$(kubectl -n services exec $OP_POD -c cray-console-operator -- sh -c \
            "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
        ncn# echo $NODE_POD
        ```

        Example output:
        ```text
        cray-console-node-1
        ```

1. Establish a serial console session (from `ncn-m001`) with the desired NCN.

    ```bash
    ncn-m001# kubectl -n services exec -it $NOD_EPOD -- conman -j $XNAME
    ```

    The console session log files for each NCN is located in the `cray-console-operator` and `cray-console-node` pods in a shared volume at the `/var/log/conman/` directory in a file named `console.<xname>`.

    **IMPORTANT:** If the `cray-console-node` pod the user is connected through is running on the NCN that the console session is connected to, and a reboot is initiated, expect the connection to terminate and there to be a gap in the console log file. The gap will last until the console connection is reestablished through a different cray-console-node pod or until the existing pod is restarted on a different NCN. If the `cray-console-node` pod was running on a different NCN or was moved prior to the reboot, the console log and session should persist through the operation.

1.  Exit the connection to the console with the `&.` command.
