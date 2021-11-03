## Troubleshoot Loss of Console Connections and Logs on Gigabyte Nodes

Gigabyte console log information will no longer be collected, and if attempting to initiate a console session through the `cray-conman` pod, there will be an error reported. This error will occur every time the node is rebooted unless this workaround is applied.

### Prerequisites

Console log information is no longer being collected for Gigabyte nodes or ConMan is reporting an error.

### Procedure

1.  Use `ipmitool` to deactivate the current console connection.

    ```bash
    ncn-m001# export USERNAME=root
    ncn-m001# export IPMI_PASSWORD=changeme
    ncn-m001# ipmitool -H xname -U $USERNAME -E sol deactivate
    ```

2.  Retrieve the `cray-conman` pod ID.

    ```bash
    ncn-m001# CONPOD=$(kubectl get pods -n services \
    -o wide|grep cray-conman|awk '{print $1}')
    ncn-m001# echo $CONPOD
    cray-conman-77fdfc9f66-m2s9k
    ```

3.  Log on to the pod.

    ```bash
    ncn-m001# kubectl exec -it -n services $CONPOD /bin/bash
    ```

4.  Initiate a console session to reconnect.

    ```bash
    [root@cray-conman-POD_ID app]# conman -j XNAME
    ```


