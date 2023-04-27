# Troubleshoot ConMan Asking for Password on SSH Connection

If ConMan starts to ask for a password when there is an SSH connection to the
node on liquid-cooled hardware, that usually indicates there is a problem with
the SSH key that was established on the node BMC. The key may have been
replaced or overwritten on the hardware.

Use this procedure to renew or reinstall the SSH key on the BMCs.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

> **`NOTE`** this procedure has changed since the CSM 0.9 release.

1. Scale the `cray-console-operator` pods to 0 replicas.

    ```bash
    kubectl -n services scale --replicas=0 deployment/cray-console-operator
    ```

    Example output:

    ```text
    deployment.apps/cray-console-operator scaled
    ```

1. Verify that the `cray-console-operator` service is no longer running.

    The following command will give no output when the pod is no longer running.

    ```bash
    kubectl -n services get pods | grep console-operator
    ```

1. Delete the SSH keys in a `cray-console-node` pod.

    ```bash
    kubectl -n services exec -it cray-console-node-0 -c cray-console-node \
        -- rm -v /var/log/console/conman.key /var/log/console/conman.key.pub
    ```

1. Restart the `cray-console-operator` pod.

    ```bash
    kubectl -n services scale --replicas=1 deployment/cray-console-operator
    ```

    Example output:

    ```text
    deployment.apps/cray-console-operator scaled
    ```

    It may take some time to regenerate the keys and get them deployed to the BMCs,
    but after a while the console connections using SSH should be reestablished. Note
    that it may be worthwhile to determine how the SSH key was modified and
    establish site procedures to coordinate SSH key use; otherwise, they may be
    overwritten again at a later time.
