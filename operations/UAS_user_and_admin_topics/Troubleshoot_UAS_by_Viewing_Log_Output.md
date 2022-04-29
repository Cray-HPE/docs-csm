# Troubleshoot UAS by Viewing Log Output

At times there will be problems with UAS. Usually this takes the form of errors showing up on CLI commands that are not immediately interpretable as some sort of input error.
It is sometimes useful to examine the UAS service logs to find out what is wrong.

## Procedure

1. Find the names of the Kubernetes pods running UAS:

    ```bash
    ncn-m001-pit# kubectl get po -n services | grep uas | grep -v etcd
    ```

    Example output:

    ```bash
    cray-uas-mgr-6bbd584ccb-zg8vx                                    2/2     Running     0          7d7h
    cray-uas-mgr-6bbd584ccb-acg7y                                    2/2     Running     0          7d7h
    ```

1. View the logs for the pods running UAS.

    The logs are collected in the pods, and can be seen using the `kubectl logs` command on each of the pods. The pods produce a lot of debug logging in the form:

    ```bash
    127.0.0.1 - - [02/Feb/2021 22:57:18] "GET /v1/mgr-info HTTP/1.1" 200 -
    ```

    Because of that, it is a good idea to filter this out unless the problem lies in specifically in the area of GET operations or aliveness checks.
    The following is an example where the last 25 lines of useful log output are retrieved from the pod `cray-uas-mgr-6bbd584ccb-zg8vx`:

    ```bash
    ncn-m001-pit# kubectl logs -n services cray-uas-mgr-6bbd584ccb-zg8vx cray-uas-mgr | grep -v '"GET ' | tail -25
    ```

    Example output:

    ```bash
    2021-02-03 22:02:01,576 - uas_mgr - INFO - UAS request for: vers
    2021-02-03 22:02:01,628 - uas_mgr - INFO - opt_ports: []
    2021-02-03 22:02:01,702 - uas_mgr - INFO - cfg_ports: [30123]
    2021-02-03 22:02:01,702 - uas_mgr - INFO - UAI Name: uai-vers-32079250; Container ports: [{'container_port': 30123,
    'host_ip': None,
    'host_port': None,
    'name': 'port30123',
    'protocol': 'TCP'}]; Optional ports: []
    2021-02-03 22:02:02,211 - uas_mgr - INFO - opt_ports: []
    2021-02-03 22:02:02,566 - uas_mgr - INFO - cfg_ports: [30123]
    2021-02-03 22:02:02,703 - uas_mgr - INFO - getting deployment uai-vers-32079250 in namespace user
    2021-02-03 22:02:02,718 - uas_mgr - INFO - creating deployment uai-vers-32079250 in namespace user
    2021-02-03 22:02:02,734 - uas_mgr - INFO - creating the UAI service uai-vers-32079250-ssh
    2021-02-03 22:02:02,734 - uas_mgr - INFO - getting service uai-vers-32079250-ssh in namespace user
    2021-02-03 22:02:02,746 - uas_mgr - INFO - creating service uai-vers-32079250-ssh in namespace user
    2021-02-03 22:02:02,757 - uas_mgr - INFO - getting pod info uai-vers-32079250
    2021-02-03 22:02:02,841 - uas_mgr - INFO - No start time provided from pod
    2021-02-03 22:02:02,841 - uas_mgr - INFO - getting service info for uai-vers-32079250-ssh in namespace user
    127.0.0.1 - - [03/Feb/2021 22:02:02] "POST /v1/uas HTTP/1.1" 200 -
    2021-02-03 22:15:32,697 - uas_auth - INFO - UasAuth lookup complete for user vers
    2021-02-03 22:15:32,698 - uas_mgr - INFO - UAS request for: vers
    2021-02-03 22:15:32,698 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
    2021-02-03 22:15:32,770 - uas_mgr - INFO - deleting service uai-vers-32079250-ssh in namespace user
    2021-02-03 22:15:32,802 - uas_mgr - INFO - delete deployment uai-vers-32079250 in namespace user
    127.0.0.1 - - [03/Feb/2021 22:15:32] "DELETE /v1/uas?uai_list=uai-vers-32079250 HTTP/1.1" 200 -
    ```

If an error had occurred in UAS that error would likely show up here.
Because there are two replicas of `cray-uas-mgr` running, the logging of interest may be in the other pod, so apply the same command to the other pod if the information is not here.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Troubleshoot UAIs by Viewing Log Output](Troubleshoot_UAIs_by_Viewing_Log_Output.md)
