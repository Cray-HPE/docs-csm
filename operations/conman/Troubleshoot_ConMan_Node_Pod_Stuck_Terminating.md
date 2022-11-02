# Troubleshoot Console Node Pod Stuck in Terminating State

When a worker node goes down unexpectedly, a `cray-console-node` pod running on that worker
may get stuck in a `Terminating` state that prevents it moving to a healthy worker. This can
leave consoles unmonitored and not available for interactive access.

## Prerequisite

Determine if this is a scenario where the `cray-console-node` pod is stuck in `Terminating` because
of the failure of the worker node it is running on, or for some other reason. This fix should only
be applied in the case where the worker node did not properly drain before being shut down.

1. (`ncn-mw#`) Find which worker the `Terminating` pod is running on.

    ```bash
    kubectl -n services get pods | grep console
    ```

    Example output:

    ```text
    cray-console-data-6ff47b7454-ch5dj             2/2     Running        0      4d3h   ncn-w003
    cray-console-data-postgres-0                   3/3     Running        0      5h50m  ncn-w002
    cray-console-data-postgres-1                   3/3     Terminating    0      3d22h  ncn-w001
    cray-console-data-postgres-2                   3/3     Running        0      4d1h   ncn-w003
    cray-console-node-0                            3/3     Terminating    0      16h    ncn-w001
    cray-console-node-1                            3/3     Running        0      4d22h  ncn-w002
    cray-console-operator-575d8b9f9d-s95v9         2/2     Running        0      30m    ncn-w002
    cray-console-operator-575d8b9f9d-x2bvm         2/2     Terminating    0      16h    ncn-w001
    ```

    In this example, `cray-console-node-0` is stuck in `Terminating` and running on `ncn-w001`.

    **NOTE** Other pods are also stuck in `Terminating`, but only the `cray-console-node` pods
    need to be manually terminated and forced to a different worker node.

1. (`ncn-mw#`) Find the state of the worker node.

    ```bash
    kubectl get nodes
    ```

    Example output:

    ```text
    NAME       STATUS     ROLES                  AGE   VERSION
    ncn-m001   Ready      control-plane,master   34d   v1.21.12
    ncn-m002   Ready      control-plane,master   35d   v1.21.12
    ncn-m003   Ready      control-plane,master   35d   v1.21.12
    ncn-w001   NotReady   <none>                 35d   v1.21.12
    ncn-w002   Ready      <none>                 35d   v1.21.12
    ncn-w003   Ready      <none>                 35d   v1.21.12
    ```

    In this example, the worker node `ncn-w001` is not reporting to the cluster.

1. Wait some time to see if the worker node rejoins the cluster.

    If the node rejoins the cluster, then the issue will sort itself out with no further manual
    intervention. If too much time has passed and the node is not resolving the problem on its
    own, then perform the following procedure in order to force the `cray-console-node` pod to
    move to a different worker.

## Procedure

A force terminate will remove the old pod and it will start up on a healthy worker. There
is a slight chance that if the old pod is really still working despite the node being
unhealthy, then the new and old pods will conflict. Only do the following if the worker node is
down.

1. (`ncn-mw#`) Force terminate the `cray-console-node` pod.

    In the above example the `cray-console-node-0` pod was on the worker node that shut down
    unexpectedly. The following command example uses that pod name. Be sure to modify the example
    command with the actual pod name before running it.

    ```bash
    kubectl -n services delete pod cray-console-node-0 --grace-period=0 --force
    ```

1. (`ncn-mw#`) Wait for the new pod to restart on a healthy worker.

    ```bash
    kubectl -n services get pods | grep console
    ```

    Example output when healthy:

    ```text
    cray-console-data-6ff47b7454-ch5dj             2/2     Running        0      4d3h   ncn-w003
    cray-console-data-postgres-0                   3/3     Running        0      5h50m  ncn-w002
    cray-console-data-postgres-1                   3/3     Terminating    0      3d22h  ncn-w001
    cray-console-data-postgres-2                   3/3     Running        0      4d1h   ncn-w003
    cray-console-node-0                            3/3     Running        0      2m     ncn-w003
    cray-console-node-1                            3/3     Running        0      4d22h  ncn-w002
    cray-console-operator-575d8b9f9d-s95v9         2/2     Running        0      30m    ncn-w002
    cray-console-operator-575d8b9f9d-x2bvm         2/2     Terminating    0      16h    ncn-w001
    ```

    It will take a few minutes for the new pod to resume console interactions.
