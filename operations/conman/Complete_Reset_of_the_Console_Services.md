# Complete Reset of the Console Services

At times the easiest way to get console services back up and running is to do a complete
reset of the services. There is no persistent state so there is no backup/restore operation
needed.

> **`NOTE`** The console connections to all nodes will be disrupted for the duration of this
procedure. Any active console sessions will be terminated and no console logging will occur.
The existing console log files will be retained, but there will be a gap in the log file coverage.

1. (`ncn-mw#`) Find the `cray-console-operator` pod.

    The `cray-console-operator` pod controls the other pods in the console services. This pod will be
    used to control the other pods.

    ```bash
    OP_POD=$(kubectl get pods -n services \
            -o wide|grep cray-console-operator|awk '{print $1}')
    echo $OP_POD
    ```

    Example output:

    ```text
    cray-console-operator-6cf89ff566-kfnjr
    ```

1. Suspend the `cray-console-operator` and clear the current data.

    1. (`ncn-mw#`) Exec into the `cray-console-operator` pod.

        ```bash
        kubectl -n services exec -it $OP_POD -c cray-console-operator -- sh
        ```

    1. (`pod#`) Source the helper function file.

        ```bash
        source /app/bashrc
        ```

    1. (`pod#`) Suspend the current updates.

        ```bash
        suspend
        ```

    1. (`pod#`) Clear the current status data in the database.

        ```bash
        clearData
        ```

    1. (`pod#`) Exit from the `cray-console-operator` pod.

        ```bash
        exit
        ```

1. (`ncn-mw#`) Scale down the `cray-console-node` pods.

    ```bash
    kubectl -n services scale --replicas=0 statefulset/cray-console-node
    ```

1. (`ncn-mw#`) (Optional) Reinstall the `cray-console-data` service.

    If the database has been irretrievably harmed, it may be completely uninstalled and
    re-installed to restore it to a functional state. It only contains current state data
    so there is no need to backup and restore information. It will be automatically
    repopulated when the services start back up again.

    1. Find the current version of the installed `cray-console-data` service.

        ```bash
        helm -n services history cray-console-data
        ```

        Example output:

        ``` text
        REVISION  UPDATED                   STATUS      CHART                    APP VERSION  DESCRIPTION
        1         Tue May 16 21:39:34 2023  superseded  cray-console-data-1.6.3  1.6.3        Install complete
        2         Wed Jun 28 21:05:49 2023  deployed    cray-console-data-2.0.0  2.0.0        Upgrade complete
        ```

        Make note of the latest `APP VERSION` as it will be needed later.

    1. Create a manifest file for re-installing the `cray-console-data` service.

        ```bash
        cat > cray-console-data.yaml << EOF
        apiVersion: manifests/v1beta1
        metadata:
        name: cray-console-data-20230712194246
        spec:
        charts:
            - name: cray-console-data
            namespace: services
            version: 2.0.0
        EOF
        ```

        Make sure the version in the file `cray-console-data.yaml` matches the latest installed
        version from the previous step.

    1. Uninstall the `cray-console-data` service.

        ```bash
        helm -n services uninstall cray-console-data
        ```

        Example output:

        ```text
        release "cray-console-data" uninstalled
        ```

    1. Wait for the `cray-console-data` services to complete the uninstall.

        ```bash
        watch 'kubectl -n services get pods | grep console'
        ```

        When the uninstall starts there will be pods in the process of terminating. Example
        output starting the uninstall process:

        ```text
        Every 2.0s: kubectl -n services get pods | grep console

        cray-console-data-65ccc6f988-v9sss                 2/2     Running        0    30m
        cray-console-data-postgres-0                       3/3     Running        0    30m
        cray-console-data-postgres-1                       3/3     Terminating    0    29m
        cray-console-data-wait-for-postgres-1-dv5t4        0/2     Completed      0    30m
        cray-console-operator-6d4d5b84d9-66svs             2/2     Running        0    24m
        ```

        Wait for all the `cray-console-data` pods to terminate. Example output when complete:

        ```text
        Every 2.0s: kubectl -n services get pods | grep console

        cray-console-operator-6d4d5b84d9-66svs             2/2     Running        0    24m
        ```

    1. Reinstall the `cray-console-data` service.

        ```bash
        loftsman ship --charts-repo https://packages.local/repository/charts --manifest-path cray-console-data.yaml
        ```

        Example output:

        ```text
        2023-07-12T19:57:08Z INF Initializing the connection to the Kubernetes cluster using KUBECONFIG (system default), and context (current-context) command=ship
        2023-07-12T19:57:08Z INF Initializing helm client object command=ship
                |\
                | \
                |  \
                |___\      Shipping your Helm workloads with Loftsman
            \--||___/
        ~~~~~~\_____/~~~~~~~
        
        2023-07-12T19:57:08Z INF Ensuring that the loftsman namespace exists command=ship
        2023-07-12T19:57:08Z INF Loftsman will use the charts repo at https://packages.local/repository/charts as the
        Helm install source command=ship
        2023-07-12T19:57:08Z INF Running a release for the provided manifest at /root/dlaine/tmp/cray-console-data-customized.yaml command=ship

        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        Releasing cray-console-data v1.6.3
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        2023-07-12T19:57:08Z INF Running helm install/upgrade with arguments: upgrade --install cray-console-data
        https://packages.local/repository/charts/cray-console-data-1.6.3.tgz --namespace services --create-namespace
        --set global.chart.name=cray-console-data --set global.chart.version=1.6.3 chart=cray-console-data
        command=ship namespace=services version=1.6.3
        2023-07-12T19:57:15Z INF Release "cray-console-data" does not exist. Installing it now.
        NAME: cray-console-data
        LAST DEPLOYED: Wed Jul 12 19:57:14 2023
        NAMESPACE: services
        STATUS: deployed
        REVISION: 1
        TEST SUITE: None
        chart=cray-console-data command=ship namespace=services version=1.6.3
        2023-07-12T19:57:15Z INF Ship status: success. Recording status, manifest to configmap 
        loftsman-cray-console-data-20230712194246 in namespace loftsman command=ship
        2023-07-12T19:57:15Z INF Recording log data to configmap loftsman-cray-console-data-20230712194246-ship-log in
        namespace loftsman command=ship
        ```

    1. Wait for the `cray-console-data` services to start.

        ```bash
        watch 'kubectl -n services get pods | grep console'
        ```

        When the install starts there will be pods in the process of starting. Example
        output starting the install process:

        ```text
        Every 2.0s: kubectl -n services get pods | grep console

        cray-console-data-65ccc6f988-v9sss                 0/2     Init              0    15s
        cray-console-data-postgres-0                       0/3     PodInitializing   0    10s
        cray-console-data-wait-for-postgres-1-dv5t4        0/2     Completed         0    50s
        cray-console-operator-6d4d5b84d9-66svs             2/2     Running           0    45m
        ```

        Wait for all the `cray-console-data` pods to transition to `Running`.
        Example output when complete:

        ```text
        Every 2.0s: kubectl -n services get pods | grep console

        cray-console-data-65ccc6f988-v9sss           2/2     Running     0    80s
        cray-console-data-postgres-0                 3/3     Running     0    8m
        cray-console-data-postgres-1                 3/3     Running     0    7m
        cray-console-data-postgres-2                 3/3     Running     0    5m
        cray-console-data-wait-for-postgres-1-dv5t4  0/2     Completed   0    10m
        cray-console-operator-6d4d5b84d9-66svs       2/2     Running     0    55m
        ```

1. (`ncn-mw#`) Delete the `cray-console-operator` pod.

    The `cray-console-operator` deployment will automatically create a new pod and
    on startup it will repopulate the `cray-console-data` service with the current
    node inventory, then scale up the number of `cray-console-node` pods to match
    the requirements of the system.

    ```bash
    kubectl -n services delete pod $OP_POD
    ```

    NOTE: the name of the current `cray-console-operator` pod will change when the new
    pod starts up. Re-fetch the value of `$OP_POD` if needed after this step.

1. (`ncn-mw#`) Wait for the full set of console pods to transition to `Running`.

    ```bash
    watch 'kubectl -n services get pods | grep console'
    ```

    Watch for the `cray-console-node` pods to scale up. Exmaple output when the
    system is still updating:

    ```text
    Every 2.0s: kubectl -n services get pods | grep console

    cray-console-data-65ccc6f988-v9sss           2/2     Running     0    80s
    cray-console-data-postgres-0                 3/3     Running     0    8m
    cray-console-data-postgres-1                 3/3     Running     0    7m
    cray-console-data-postgres-2                 3/3     Running     0    5m
    cray-console-data-wait-for-postgres-1-dv5t4  0/2     Completed   0    10m
    cray-console-operator-6d4d5b84d9-66svs       1/2     Running     0    30s
    ```

    Wait for all the `cray-console-nodes` pods to transition to `Running`.
    Example output when complete:

    ```text
    Every 2.0s: kubectl -n services get pods | grep console

    cray-console-data-65ccc6f988-v9sss           2/2     Running     0    10m
    cray-console-data-postgres-0                 3/3     Running     0    18m
    cray-console-data-postgres-1                 3/3     Running     0    17m
    cray-console-data-postgres-2                 3/3     Running     0    15m
    cray-console-data-wait-for-postgres-1-dv5t4  0/2     Completed   0    20m
    cray-console-node-0                          3/3     Running     0    60s
    cray-console-node-1                          3/3     Running     0    30s
    cray-console-operator-6d4d5b84d9-66svs       2/2     Running     0    65m
    ```

The `cray-console-node` pods may take a couple of minutes to get nodes assigned to them
and start the console connections.
