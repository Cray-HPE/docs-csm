# Troubleshoot Kubernetes Master or Worker node in `NotReady` state

Use this procedure to check if a Kubernetes master or worker node is in a `NotReady` state.

## Identify the node in question

1. (`ncn-mw#`) Identify the node in `NotReady` state.

    ```bash
    kubectl get nodes
    ```

    Example output:

    ```text
    NAME       STATUS   ROLES                  AGE   VERSION
    ncn-m001   Ready    control-plane,master   27h   v1.20.13
    ncn-m002   Ready    control-plane,master   8d    v1.20.13
    ncn-m003   Ready    control-plane,master   8d    v1.20.13
    ncn-w001   NotReady <none>                 8d    v1.20.13
    ncn-w002   Ready    <none>                 8d    v1.20.13
    ncn-w003   Ready    <none>                 8d    v1.20.13
    ```

## Recovery steps

1. Ensure that the node does not have an intentional `NoSchedule` taint.

    See [About Kubernetes Taints and Labels](../../operations/kubernetes/About_Kubernetes_Taints_and_Labels.md) for more information about tainting and untainting a node.

    If the node in question is not intentionally tainted causing the `NotReady` state, then proceed to the next step and attempt to restart the `kubelet`.

1. (`ncn-mw#`) Restart the `kubelet`.

    Run the following command on the node in a `NotReady` state.

    ```bash
    systemctl restart kubelet
    ```

1. (`ncn-mw#`) Ensure that the node is now in a `Ready` state.

    ```bash
    kubectl get nodes
    ```

    Example output:

    ```text
    NAME       STATUS   ROLES                  AGE   VERSION
    ncn-m001   Ready    control-plane,master   27h   v1.20.13
    ncn-m002   Ready    control-plane,master   8d    v1.20.13
    ncn-m003   Ready    control-plane,master   8d    v1.20.13
    ncn-w001   Ready    <none>                 8d    v1.20.13
    ncn-w002   Ready    <none>                 8d    v1.20.13
    ncn-w003   Ready    <none>                 8d    v1.20.13
    ```
