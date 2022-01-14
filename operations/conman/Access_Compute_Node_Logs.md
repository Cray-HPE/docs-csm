## Access Compute Node Logs

This procedure shows how the ConMan utility can be used to retrieve compute node logs.

### Prerequisites

The user performing this procedure needs to have access permission to the cray-console-operator pod.

### Limitations

Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.

### Procedure

1. Log on to a Kubernetes master or worker node.

2. Retrieve the cray-console-operator pod ID.

    ```
    ncn-m001# CONPOD=$(kubectl get pods -n services \
    -o wide|grep cray-console-operator|awk '{print $1}')
    ncn-m001# echo $CONPOD
    ```

3. Log on to the pod.

    ```
    ncn-m001# kubectl exec -it -n services $CONPOD -- sh
    ```

4. Go to the log directory.

    ```
    # cd /var/log/conman
    ```

5. List the directory contents to identify node IDs.

    ```
    /var/log/conman # ls -la
    ```

    Example output:

    ```
    total 44
    -rw------- 1 root root 1415 Nov 30 20:00 console.NODE_ID
    
    [...]
    ```

6. Use the node's ID to retrieve its logs.

    ```
    /var/log/conman # tail console.NODE_ID
    ```

7. Exit out of the pod.

    ```
    /var/log/conman # exit
    ```

