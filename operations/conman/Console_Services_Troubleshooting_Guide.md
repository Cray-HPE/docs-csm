# Console Services Troubleshooting Guide

There are many things that can prevent the ConMan service from successfully connecting to a
single node console or can cause problems with the entire deployment. This is a guide on
how to look at all aspects of the service to determine what the current problem is.

* [Prerequisites](#prerequisites)
* [Check the states of the console pods](#check-the-states-of-the-console-pods)
* [Find the `cray-console-node` pod for a specific node](#find-the-cray-console-node-pod-for-a-specific-node)
* [Investigate service problem](#investigate-service-problem)
* [Investigate Postgres deployment](#investigate-postgres-deployment)
* [Check the capacity of the PVC](#check-the-capacity-of-the-pvc)

## Prerequisites

(`ncn-mw#`) The user performing these procedures needs to have access permission to the `cray-console-operator`
and `cray-console-node` pods. There will be a lot of interaction with the `cray-console-operator` pod,
so set up an environment variable to refer to that pod:

```bash
OP_POD=$(kubectl get pods -n services -o wide|grep cray-console-operator|awk '{print $1}')
```

## Check the states of the console pods

There are a number of pods that work together to provide the console services. If any of the pods are
not working correctly, it will impact the ability to connect to specific consoles and monitor the console
logs.

1. (`ncn-mw#`) Query Kubernetes to inspect the console pods:

    ```bash
    kubectl -n services get pods | grep console
    ```

    Example output:

    ```text
    cray-console-data-5448f99fb-mbrf4             2/2     Running        0     18d
    cray-console-data-postgres-0                  3/3     Running        0     18d
    cray-console-data-postgres-1                  3/3     Running        0     18d
    cray-console-data-postgres-2                  3/3     Running        0     18d
    cray-console-data-wait-for-postgres-1-rnrt6   0/2     Completed      0     18d
    cray-console-node-0                           3/3     Running        0     18d
    cray-console-node-1                           3/3     Running        0     18d
    cray-console-operator-6d4d5b84d9-rwsdd        2/2     Running        3     25d
    ```

    There should be one `cray-console-operator` pod.

    There should be multiple `cray-console-node` pods. A standard deployment will start with two
    pods and scale up from there depending on the size of the system and the configuration.

    There should be one `cray-console-data` pod and three `cray-console-data-postgres` pods.

    All pods should be in the `Completed` or `Running` state. If pods are in any other state, then
    use the usual Kubernetes techniques to find out what is wrong with those pods.

## Find the `cray-console-node` pod for a specific node

The first thing to check is if the specific node is assigned to a `cray-console-node` pod that should
be monitoring the node for log traffic and providing a means to interact with the console.

1. (`ncn-mw#`) Set the component name (xname) of the node whose console is being checked.

    ```bash
    XNAME="xName of the node - e.g. x3000c0s19b2n0"
    ```

1. (`ncn-mw#`) Find which `cray-console-node` pod the node is assigned to.

    ```bash
    NODEPOD=$(kubectl -n services exec $OP_POD -c cray-console-operator -- \
        sh -c "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
    echo $NODEPOD
    ```

    The returned node pod should be one of the `cray-console-node` pods see in the listing
    of pods above. An expected output from the above would be:

    ```text
    cray-console-node-0
    ```

    If this is the case, proceed to [Troubleshoot ConMan Failing to Connect to a Console](Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md).

    If the node is not assigned to a `cray-console-node` pod, then the result will have an invalid pod name. For example:

    ```text
    cray-console-node-
    ```

    In this case, proceed to [Investigate service problem](#investigate-service-problem) to find out why the
    node is not assigned to a pod.

## Investigate service problem

When the entire service is having problems, the next step is to determine which component is causing the
issue. All three services need to work together to provide console connections.

1. Check the underlying database.

    Sometimes the `cray-console-data` pods can report healthy, but the actual Postgres instance
    can be unhealthy. See [Investigate Postgres deployment](#investigate-postgres-deployment) for
    information on how to investigate further.

1. (`ncn-mw#`) Restart the `cray-console-operator` pod.

    There are rare cases where the `cray-console-operator` pod may be reporting as `Running`
    to Kubernetes, but actually be unhealthy. In this case a restart of the pod will resolve
    the issue and start the communication between the services again.

    1. Restart the pod.

        ```bash
        kubectl -n services delete pod $OP_POD
        ```

    1. Wait for the new `cray-console-operator` pod to reach a `Running` state.

        ```bash
        kubectl -n services get pods | grep cray-console-operator
        ```

        Example output when ready to proceed:

        ```text
        cray-console-operator-6d4d5b84d9-66svs       2/2     Running     0    60s
        ```

    1. Now there is a different pod name, so the `OP_POD` variable needs to be set again.

        ```bash
        OP_POD=$(kubectl get pods -n services -o wide|grep cray-console-operator|awk '{print $1}')
        ```

    1. Wait several minutes, then see if the issue is resolved.

1. Restart the entire set of services.

    To restart everything from scratch, follow the directions in
    [Complete Reset of the Console Services](Complete_Reset_of_the_Console_Services.md).

## Investigate Postgres deployment

Sometimes the database that is holding the current status information for the console services has
problems that keep it from saving and reporting data. Depending on when this happens, the other
services may be different states of managing node consoles. The `cray-console-node` pods will continue
to monitor the nodes that have been assigned to them, but if the pod restarts or new nodes are added
to the system, they will not be able to get new nodes assigned to the currently running pods. This may
lead to some `cray-console-node` pods continuing to monitor nodes, but other pods not having any nodes
assigned to them.

> **`NOTE`** There is no persistent data in the `cray-console-data` Postgres database. It only contains
current state information and will rebuild itself automatically once it is functional again. There is no
need to save or restore data from this database.

Check on the current running state of the `cray-console-data-postgres` database.

1. (`ncn-mw#`) Find the `cray-console-data-postgres` pods and note one that is in `Running` state.

    ```bash
    kubectl -n services get pods | grep cray-console-data-postgres
    ```

    Example output:

    ```text
    cray-console-data-postgres-0    3/3     Running  0  26d
    cray-console-data-postgres-1    3/3     Running  0  26d
    cray-console-data-postgres-2    3/3     Running  0  26d
    ```

1. (`ncn-mw#`) Log into one of the healthy pods.

    ```bash
    DATA_PG_POD=cray-console-data-postgres-1
    kubectl -n services exec -it $DATA_PG_POD -c postgres -- sh
    ```

1. (`pod#`) Check the status of the database.

    ```bash
    patronictl list
    ```

    Expected result for a healthy database:

    ```text
    + Cluster: cray-console-data-postgres (7244964360609890381) ---+----+-----------+
    |            Member            |    Host    |  Role  |  State  | TL | Lag in MB |
    +------------------------------+------------+--------+---------+----+-----------+
    | cray-console-data-postgres-0 | 10.43.0.8  | Leader | running |  1 |           |
    | cray-console-data-postgres-1 | 10.37.0.45 |        | running |  1 |         0 |
    | cray-console-data-postgres-2 | 10.32.0.52 |        | running |  1 |         0 |
    +------------------------------+------------+--------+---------+----+-----------+
    ```

    Example output if replication is broken:

    ```text
    + Cluster: cray-console-data-postgres (7244964360609890381) ----+----+-----------+
    |            Member            |    Host    |  Role  |  State   | TL | Lag in MB |
    +------------------------------+------------+--------+----------+----+-----------+
    | cray-console-data-postgres-0 | 10.43.0.8  |        | starting |    |   unknown |
    | cray-console-data-postgres-1 | 10.37.0.45 | Leader | running  | 47 |         0 |
    | cray-console-data-postgres-2 | 10.32.0.52 |        | running  | 14 |       608 |
    +------------------------------+------------+--------+---------+----+-----------+
    ```

    Example output if the leader is missing:

    ```text
    + Cluster: cray-console-data-postgres (7244964360609890381) --------+----+-----------+
    |            Member            |    Host    |  Role  |  State       | TL | Lag in MB |
    +------------------------------+------------+--------+--------------+----+-----------+
    | cray-console-data-postgres-0 | 10.43.0.8  |        | running      |    |   unknown |
    | cray-console-data-postgres-1 | 10.37.0.45 |        | start failed |    |   unknown |
    | cray-console-data-postgres-2 | 10.32.0.52 |        | start failed |    |   unknown |
    +------------------------------+------------+--------+--------------+----+-----------+
    ```

If any of the replicas are showing a problem, look at the following troubleshooting
pages to attempt to fix the Postgres instance:

* [Troubleshoot Postgres Database](../kubernetes/Troubleshoot_Postgres_Database.md)
* [Recover from Postgres WAL Event](../kubernetes/Recover_from_Postgres_WAL_Event.md)

If the database can not be made healthy through these procedures, the easiest way to
resolve this is to perform a complete reset of the console services including
reinstalling the `cray-console-data` service. See
[Complete Reset of the Console Services](Complete_Reset_of_the_Console_Services.md).

## Check the capacity of the PVC

There is a shared PVC that is mounted to all the `cray-console-node` pods that is used to
write the individual console log files. If this volume fills up, the log files will no
longer be written to and log data will be lost. If following a log file it will look like
the logging has stopped, but logging into the log directly with 'conman' will still show
the current console log.

This volume is mounted on the `/var/log` directory inside the `cray-console-node` pods.
To check the usage of this PVC:

1. (`ncn-mw#`) Log into one of the `cray-console-node` pods.

    ```bash
    kubectl -n services exec -it cray-console-node-0 -c cray-console-node -- sh
    ```

1. (`pod#`) Check the volume usage.

    ```bash
    df -h | grep -E 'Size|/var/log'
    ```

    Expected results will look something like:

    ```text
        Filesystem                                     Size  Used Avail Use% Mounted on
        10.252.1.18:6789:/volumes/csi/csi-vol-0f39...  100G   36M  100G   1% /var/log
    ```

    If the 'used' value is approaching or equal to the 'Size' value, the volume is
    filling up.

There are a couple of ways to resolve this situation.

1. Remove excess files from the volume.

    The console files are stored in `/var/log/conman` and named `console.XNAME` to
    distinguish which log files are from which nodes. If there are some log files that
    are left over from nodes no longer in use, they may be removed.

    The backup files for the console logs are stored in `/var/log/conman.old`. When
    the individual files get too large they are moved to this directory by the
    `logrotate` application. If these files are not needed for looking through historical
    console logs, they may be removed.

    The files in the `/var/log/console` directory are small and required for the
    operation of the console services so do not remove them.

1. Adjust the log rotation settings.

    The `logrotate` application is used to manage the size of the log files as they
    grow over time. The settings for this functionality are described in
    [Configure Log Rotation](Configure_Log_Rotation.md). Tune the settings for this
    system to prevent the log files from filling up the PVC.

1. (`ncn-mw#`) Increase the size of the PVC.

    If the system is large, the default settings for the log rotation and the PVC
    size may not be sufficient to hold the console log files and the backups. If
    more backups are required than can fit on the current PVC, it may be increased
    in size without losing any of the current data on the volume.

    1. Edit the PVC to increase the size.

        ```bash
        kubectl -n services edit pvc cray-console-operator-data-claim
        ```

        Modify the value of `spec.resources.requests.storage` to increased value required:

        ```text
        spec:
        accessModes:
        - ReadWriteMany
        resources:
            requests:
            storage: 150Gi
        ```

    1. Scale the number of `cray-console-operator` pods to zero.

        ```bash
        kubectl -n services scale deployment --replicas=0 cray-console-operator
        ```

    1. Scale the number of `cray-console-node` pods to zero.

        ```bash
        kubectl -n services scale statefulset --replicas=0 cray-console-node
        ```

    1. Wait for these pods to terminate.

    1. Scale the number of `cray-console-operator` pods to one.

        ```bash
        kubectl -n services scale deployment --replicas=1 cray-console-operator
        ```

    When the `cray-console-operator` pod resumes operation it will scale the number
    `cray-console-node` pods back up automatically. After all pods are back up and
    ready, the new increased size of the PVC will be visible from within the pods.
