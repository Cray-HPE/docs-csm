## Troubleshoot ConMan Asking for Password on SSH Connection

If ConMan starts to ask for a password when there is an SSH connection to the node on liquid-cooled hardware, that usually indicates there is a problem with the SSH key that was established on the node BMC. The key may have been replaced or overwritten on the hardware.

Use this procedure to renew or reinstall the SSH key on the BMCs.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1. Scale the cray-console-operator pods to 0 replicas.

    ```
    ncn-m001# kubectl -n services scale --replicas=0 deployment/cray-console-operator
    ```

    The following output is expected:

    ```
    deployment.apps/cray-console-operator scaled
    ```

2. Verify that the cray-console-operator service is no longer running.

    ```
    ncn-m001# kubectl -n services get pods | grep console-operator
    ```

    No output is expected if the service is no longer running.

3. Exec into a cray-console-node pod.

    ```
    ncn-m001# kubectl -n services exec -it cray-console-node-0 -- /bin/bash
    ```

4. Delete the SSH keys and exit from the pod.

    ```
    cray-console-node-0:/ # rm /var/log/console/conman.key
    cray-console-node-0:/ # rm /var/log/console/conman.key.pub
    cray-console-node-0:/ # exit
    ```

5. Restart the cray-console-operator pod.

    ```
    ncn-m001# kubectl -n services scale --replicas=1 deployment/cray-console-operator
    ```

    The following output is expected:

    ```
    deployment.apps/cray-console-operator scaled
    ```

    It may take some time to regenerate the keys and get them deployed to the BMCs, but in a while the console connections using SSH should be reestablished. Note that it may be worthwhile to determine how the SSH key was modified and establish site procedures to coordinate SSH key use or they may be overwritten again at a later time.

