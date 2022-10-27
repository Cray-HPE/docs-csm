# Troubleshoot Kubernetes Master or Worker node in `NotReady` state

Use this procedure to check if a Kubernetes master or worker node is in a `NotReady` state.

## Identify the node in question

1. Identify the node in `NotReady` state.

    ```bash
    ncn-mw# kubectl get nodes
    ```

    Example output:

    ```text
    NAME       STATUS   ROLES    AGE   VERSION
    ncn-m001   Ready    master   27h   v1.19.9
    ncn-m002   Ready    master   19h   v1.19.9
    ncn-m003   Ready    master   18h   v1.19.9
    ncn-w001   NotReady <none>   36h   v1.19.9
    ncn-w002   Ready    <none>   36h   v1.19.9
    ncn-w003   Ready    <none>   36h   v1.19.9
    ```

## Recovery steps

1. Ensure that the node does not have an intentional `NoSchedule` taint.

    See [About Kubernetes Taints and Labels](../../operations/kubernetes/About_Kubernetes_Taints_and_Labels.md) for more information about tainting and untainting a node.

    If the node in question is not intentionally tainted causing the `NotReady` state, then proceed to the next step and attempt to restart the `kubelet`.

1. Restart the `kubelet`.

    Run the following command on the node in a `NotReady` state.

    ```bash
    ncn-mw# systemctl restart kubelet
    ```

1. Ensure that the node is now in a `Ready` state.

    ```bash
    ncn-mw# kubectl get nodes
    ```

    Example output:

    ```text
    NAME       STATUS   ROLES    AGE   VERSION
    ncn-m001   Ready    master   27h   v1.19.9
    ncn-m002   Ready    master   19h   v1.19.9
    ncn-m003   Ready    master   18h   v1.19.9
    ncn-w001   NotReady <none>   36h   v1.19.9
    ncn-w002   Ready    <none>   36h   v1.19.9
    ncn-w003   Ready    <none>   36h   v1.19.9
    ```
