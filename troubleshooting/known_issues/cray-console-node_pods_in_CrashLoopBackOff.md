# `cray-console-node` pods in `CrashLoopBackOff`

## Issue description

The `cray-console-node` Kubernetes pods may go into a `CrashLoopBackOff` state.
This happens because of a permission issue with the `/var/log/conman` directory inside the container.

## Error identification

The symptom of this problem is that the `cray-console-node` pods will be in a `CrashLoopBackOff` state.
The pod logs will contain messages resembling the following:

```text
2023/02/03 16:30:37 Starting a new instance of conmand
2023/02/03 16:30:37 Starting to parse file: /var/log/conman/console.x3000c0s7b0n0
2023/02/03 16:30:37 Starting to parse file: /var/log/conman/console.x3000c0s21b3n0
2023/02/03 16:30:37 Starting conmand process
2023/02/03 16:30:37 Starting to parse file: /var/log/conman/console.x3000c0s9b0n0
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x701979]

goroutine 57 [running]:
main.watchConsoleLogFile({0x835878, 0xc0003185c0}, {0xc000040920, 0xd})
    /usr/local/golib/src/console_node/logAggregation.go:154 +0x2b9
created by main.aggregateFile
    /usr/local/golib/src/console_node/logAggregation.go:68 +0x14b
```

## Fix procedure

The workaround is to assign the correct permissions to the `/var/log/conman` directory inside the
container. This only needs to be done for a single pod, since the directory is shared between them.

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

1. (`pod#`) Change the permission of the `/var/log/` directory.

    ```bash
    chmod -R 700 /var/log/
    ```

1. (`pod#`) Verify the permission of the `/var/log/` directory.

    ```bash
    ls -ld /var/log/*
    ```

    Example output:

    ```text
    drwx------ 2 nobody nobody 15 Jan 30 22:05 conman
    drwx------ 2 nobody nobody 21 Jan 30 22:05 conman.old
    drwx------ 2 nobody nobody  1 Dec  1  2023 console
    ```

1. (`pod#`) Exit the pod.

    ```bash
    exit
    ```

1. (`ncn-mw#`) Verify that the `cray-console-node` pods are now in the `Running` state.

    ```bash
    kubectl get pods -n services --no-headers -o wide | grep cray-console-node
    ```

    Example output:

    ```text
    cray-console-node-0   1/1     Running   0          2d
    cray-console-node-1   1/1     Running   0          2d
    ```
