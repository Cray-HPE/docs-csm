# Console SSH Key Permissions

## Issue description

Sometimes the permissions of the private key file used to connect with the Mountain nodes via SSH
are not set correctly. This can cause the SSH connection to the node to fail. The log file will not
contain the console output and interactive sessions will fail.

## Error identification

The console log file will contain an error message similar to the following:

```text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0777 for '/var/log/console/conman.key' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "/var/log/console/conman.key": bad permissions
n0@x1000c5s5b0's password: 
```

## Fix procedure

The workaround is to manually assign the correct permissions to the SSH private key file. This file is
located on a shared volume mounted in the `cray-console-node` pods. Fixing the permissions of the file
within one pod will resolve the issue for all pods.

1. (`ncn-mw#`) Find the `cray-console-node` pod IDs.

    ```bash
    kubectl get pods -n services --no-headers -o wide | grep cray-console-node | awk '{print $1}'
    ```

   Example output:

    ```text
    cray-console-node-0
    cray-console-node-1
    ```

1. (`ncn-mw#`) Log into one of the `cray-console-node` pods using their IDs.

    ```bash
    kubectl exec -n services -it CRAY-CONSOLE-NODE-POD-ID -- /bin/sh
    ```

1. (`pod#`) Find the permissions of the private key file.

    ```bash
    ls -la /var/log/console
    ```

    Example output:

    ```text
    total 3
    drwxrwxrwx 2 nobody nobody    3 Feb 12 12:57 .
    drwxrwxrwx 5 nobody nobody    4 Feb  7  2024 ..
    -rwxrwxrwx 1 nobody nobody   20 Apr 22 16:23 TargetNodes.txt
    -rwxrwxrwx 1 nobody nobody 1679 Feb 12 12:57 conman.key
    -rwxrwxrwx 1 nobody nobody  381 Feb 12 12:57 conman.key.pub
    ```

1. (`pod#`) Correct the permissions of the private key file.

    ```bash
    chmod 600 /var/log/console/conman.key
    ```

1. (`pod#`) Verify that the permissions of the private key file are now correct.

    ```bash
    ls -la /var/log/console
    ```

    Example output:

    ```text
    total 3
    drwxr-xr-x 2 nobody nobody    3 Feb 12 12:57 .
    drwxr-xr-x 5 nobody nobody    4 Feb  7  2024 ..
    -rwxrwxrwx 1 nobody nobody   20 Apr 22 16:23 TargetNodes.txt
    -rw------- 1 nobody nobody 1679 Feb 12 12:57 conman.key
    -rwxrwxrwx 1 nobody nobody  381 Feb 12 12:57 conman.key.pub
    ```

1. (`pod#`) Restart the `conmand` process.

    In order for the new SSH key to be used, the `conmand` process must be restarted. This can be done
    by sending a `SIGHUP` signal to the process.

    1. Find the `conmand` process ID.

        ```bash
        ps -aux | grep conmand
        ```

        Example output:

        ```text
        nobody     88657  1.1  0.0 243624  4096 ?        Sl   21:37   0:03 conmand -F -v -c /etc/conman.conf
        nobody     88716  0.0  0.0   5340  1024 pts/8    S+   21:42   0:00 grep conmand
        ```

        In this example, the conmand process ID is `88657`.

    1. Send the `SIGHUP` signal to the conmand process.

        ```bash
        kill 88657
        ```

    1. Wait for the conmand process to restart. This can take a few seconds.

        ```bash
        ps -aux | grep conmand
        ```

        Example output:

        ```text
        nobody     88957  0.0  0.0 243624  4096 ?        Sl   21:37   0:03 conmand -F -v -c /etc/conman.conf
        nobody     89116  0.0  0.0   5340  1024 pts/8    S+   21:42   0:00 grep conmand
        ```

        The conmand process ID will change to a new number.

1. (`pod#`) Exit the pod.

    ```bash
    exit
    ```

1. (`ncn-mw#`) Restart the `conmand` process on the other `cray-console-node` pods.

    The key file permissions are now correct for all pods, but the `conmand` process must be
    restarted on the other pods as well. This can be done by sending a `SIGHUP` signal to the
    `conmand` process on each pod.

    Repeat the step 'Restart the `conmand` process' for each of the other `cray-console-node` pods.
