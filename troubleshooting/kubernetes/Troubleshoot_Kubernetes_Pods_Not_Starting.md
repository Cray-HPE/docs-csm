# Troubleshoot Kubernetes Pods Not Starting

Use this procedure to check if Kubernetes pods get scheduled on an NCN, but do not eventually reach the `Running` state.

## Prerequisites

The `kubectl get pod` command returns pods that seem to be stuck in the `Init` or `ContainerCreating` state.

## Identify the node in question

1. Run the `kubectl get pod -o wide` command to identify the node where the pod is not starting.

    ```bash
    ncn-w001# kubectl get pod -A -o wide | egrep 'Init|ContainerCreating'
    services  cray-sls-58cfdb7c46-b7dbj   0/2  Init:0/2           0  2d22h   10.39.0.165  ncn-w002  <none>  <none>
    services  gitea-vcs-65c98746b-jk5v7   0/2  ContainerCreating  0  2d3h    10.47.0.104  ncn-w002  <none>  <none>
    ```

    In the above example, `ncn-w002` is the node that may need attention.

## Recovery Steps

Execute the following steps on the node that was determined in the previous step.

1. Restart the `kubelet` service.

   ```bash
   ncn-w002# systemctl restart kubelet
   ```

1. Ensure that `kubelet` is running.

   ```bash
   ncn-w002# systemctl status kubelet
   ```

1. Restart the `containerd` service.

   ```bash
   ncn-w002# systemctl restart containerd
   ```

1. Ensure that `containerd` is running.

   ```bash
   ncn-w002# systemctl status containerd
   ```

Try running the `kubectl get pod` command again; within a few minutes, the pods should transition to the `Running` state.
