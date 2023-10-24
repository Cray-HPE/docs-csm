# Configure `kubectl` Credentials to Access the Kubernetes APIs

The credentials for `kubectl` are located in the admin configuration file on all non-compute node \(NCN\) master and worker nodes.
They can be found at `/etc/kubernetes/admin.conf` for the `root` user. Use `kubectl` to access the Kubernetes cluster from a
device outside the cluster.

For more information, refer to [the Kubernetes home page](https://kubernetes.io/).

## Prerequisites

This procedure requires administrative privileges and assumes that the device being used has:

- `kubectl` is installed
- Access to the site admin network

## Procedure

1. Access the credentials file used by `kubectl` at `/etc/kubernetes/admin.conf` on any one of the master or worker NCNs.

    If copying this file to another system, be sure to set the environmental variable `KUBECONFIG` to the new location on that system.

1. Verify access by executing the following command:

    ```bash
    ncn# kubectl get nodes
    ```

    Successful output will resemble the following:

    ```text
    NAME       STATUS   ROLES    AGE   VERSION
    ncn-m001   Ready    master   23h   v1.14.3
    ncn-m002   Ready    master   23h   v1.14.3
    ncn-m003   Ready    master   23h   v1.14.3
    ncn-w001   Ready    <none>   23h   v1.14.3
    ncn-w002   Ready    <none>   23h   v1.14.3
    ncn-w003   Ready    <none>   23h   v1.14.3
    ```
