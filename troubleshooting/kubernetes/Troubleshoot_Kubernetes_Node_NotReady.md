# Troubleshoot Kubernetes Master or Worker node in NotReady state

Use this procedure to check if a Kubernetes master or worker node is in a NotReady state.

### Prerequisites

The `kubectl get nodes` command returns a NotReady state for a master or worker node.

### Identify the node in question

1.  Run the`kubectl get nodes` command to identify the node in NotReady state.

    ```bash
    ncn-w001# kubectl get nodes
    NAME       STATUS   ROLES                  AGE   VERSION
    ncn-m001   Ready    control-plane,master   27h   v1.20.13
    ncn-m002   Ready    control-plane,master   8d    v1.20.13
    ncn-m003   Ready    control-plane,master   8d    v1.20.13
    ncn-w001   NotReady <none>                 8d    v1.20.13
    ncn-w002   Ready    <none>                 8d    v1.20.13
    ncn-w003   Ready    <none>                 8d    v1.20.13
    ```

### Recovery Steps

1.  Ensure the node does not have an intentional `NoSchedule` taint.

    See [About Kubernetes Taints and Labels](../../operations/kubernetes/About_Kubernetes_Taints_and_Labels.md) for more information about tainting and untainting a node.

    If the node in question is not intentionally tainted causing the `NotReady` state, proceed to the next step and attempt to restart kubelet.

1.  Restart the kubelet.

    Run the following command on the node in a NotReady state.

    ```bash
    ncn-w001# systemctl restart kubelet
    ```

Try running the `kubectl get nodes` command and ensure the node is now in a Ready state.
