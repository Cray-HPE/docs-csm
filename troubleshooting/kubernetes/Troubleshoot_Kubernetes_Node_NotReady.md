# Troubleshoot Kubernetes Master or Worker node in NotReady state

Use this procedure to check if a Kubernetes master or worker node is in a NotReady state.

### Prerequisites

The `kubectl get nodes` command returns a NotReady state for a master or worker node.

### Identify the node in question

1.  Run the`kubectl get nodes` command to identify the node in NotReady state.

    ```bash
    ncn-w001# kubectl get nodes
    NAME       STATUS   ROLES    AGE   VERSION
    ncn-m001   Ready    master   27h   v1.19.9
    ncn-m002   Ready    master   19h   v1.19.9
    ncn-m003   Ready    master   18h   v1.19.9
    ncn-w001   NotReady <none>   36h   v1.19.9
    ncn-w002   Ready    <none>   36h   v1.19.9
    ncn-w003   Ready    <none>   36h   v1.19.9
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
