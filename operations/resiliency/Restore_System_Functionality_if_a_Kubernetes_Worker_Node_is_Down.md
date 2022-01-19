## Restore System Functionality if a Kubernetes Worker Node is Down

Services running on Kubernetes worker nodes can be properly restored if downtime occurs. Use this procedure to ensure that if a Kubernetes worker node is lost or restored after being down, certain features the node was providing can also be restored or recovered on another node.

Capture the metadata for the unhealthy node before bringing down the node. The pods will successfully terminate when the node goes down, which should resolve most pods in an error state. Once any remaining testing or validation work is complete, these pods can be restored with the file used to capture the metadata.

### Prerequisites

This procedure requires administrative privileges.

### Collect Information Before Powering Down the Node

1.  Check the Persistent Volume Claims \(PVC\) that have been created on the system.

    1.  View the PVCs in all namespaces.

        ```bash
        ncn# kubectl get pvc –A
        NAMESPACE         NAME                                                                                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
        jhub              claim-user                                                                                           Bound    pvc-3cf34569-4db4-11ea-b8e1-a4bf01581d70   10Gi       RWO            ceph-rbd-external      14d
        jhub              claim-users                                                                                          Bound    pvc-18b7155a-4dba-11ea-bf78-a4bf01684f9e   10Gi       RWO            ceph-rbd-external      14d
        jhub              claim-user01                                                                                         Bound    pvc-c5df3ba1-4db3-11ea-b8e1-a4bf01581d70   10Gi       RWO            ceph-rbd-external      14d
        jhub              hub-db-dir                                                                                           Bound    pvc-b41675c6-4d4e-11ea-b8e1-a4bf01581d70   1Gi        RWO            ceph-rbd-external      15d
        loftsman          loftsman-chartmuseum-data-pvc                                                                        Bound    pvc-7d45b88b-4575-11ea-bf78-a4bf01684f9e   1Gi        RWO            ceph-rbd-external      25d
        ...
        ```

    2.  Get a list of PVCs for a particular pod.

        ```bash
        ncn# kubectl get pod POD_NAME -o \
        jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}{"\n"}'
        ```

2.  Verify the time is synced across all NCNs.

    ```bash
    ncn# pdsh -w ncn-s00[1-3],ncn-m00[1-3],ncn-w00[1-3] date
    ncn-m001: Thu Feb 27 08:41:11 CST 2020
    ncn-s002: Thu Feb 27 08:41:11 CST 2020
    ncn-s003: Thu Feb 27 08:41:11 CST 2020
    ncn-m002: Thu Feb 27 08:41:11 CST 2020
    ncn-s001: Thu Feb 27 08:41:11 CST 2020
    ncn-m003: Thu Feb 27 08:41:11 CST 2020
    ncn-w001: Thu Feb 27 08:41:11 CST 2020
    ncn-w003: Thu Feb 27 08:41:11 CST 2020
    ncn-w002: Thu Feb 27 08:41:11 CST 2020
    ```

3.  Generate a list of pods that are running on the node that will be taken down.

    The example below is displaying all of the pods running on `ncn-w001`.

    ```bash
    ncn# kubectl get pods -A -o wide | grep NODE_NAME
    default        cray-dhcp-7b5c6496c6-76rst                                       1/1   Running      0  5d14h  10.252.1.1  ncn-w001   <none>  <none>
    default        kube-keepalived-vip-mgmt-plane-nmn-local-vxldv                   1/1   Running      1  25d    10.252.1.1   ncn-w001  <none>  <none>
    ims            cray-ims-57b4f98b-bc0d-422e-8891-808ab69bf158-create-nbd5c       0/2   Init:Error   0  6d21h  10.40.1.36   ncn-w001  <none>  <none>
    ims            cray-ims-60ed661b-acf2-45fd-af44-300baabfc299-customize-skswx    0/2   Completed    0  40h    10.40.1.38   ncn-w001  <none>  <none>
    ims            cray-ims-bc748ef4-49ad-4211-92db-993d097ac80e-create-6j6xv       0/2   Completed    0  6d21h  10.40.1.40   ncn-w001  <none>  <none>
    ims            cray-ims-c31232bc-d4e0-4491-90fb-e3d2fd3ca0ce-create-gzbvk       0/2   Init:Error   0  6d21h  10.40.1.45   ncn-w001  <none>  <none>
    ims            cray-ims-ccacd186-854e-4057-acfa-192ccea16ad0-customize-6qkkg    0/2   Completed    0  46h    10.40.1.52   ncn-w001  <none>  <none>
    istio-system   istio-pilot-9d769b86c-mzshz                                      2/2   Running      0  4m54s  10.40.1.38   ncn-w001  <none>  <none>
    istio-system   istio-pilot-9d769b86c-t8mtg                                      2/2   Running      0  5m10s  10.40.1.51   ncn-w001  <none>  <none>
    istio-system   istio-sidecar-injector-b887db765-td7db                           1/1   Running      0  12d    10.40.0.173  ncn-w001  <none>  <none>
    ...
    ```

    Take note of any pods that are not in a `Running` or `Completed` state, or have another state that is not considered to be healthy. This will help identify after the node is brought back up what new issues have occurred.

    To view the pods in an unhealthy state:

    ```bash
    ncn# kubectl get pods -A -o wide | grep -v -e Completed -e Running
    NAMESPACE   NAME                                                   READY   STATUS  RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
    backups     benji-k8s-backup-backups-namespace-1594161300-gk72h    0/1     Error   0          5d20h   10.45.0.109   ncn-w001   <none>           <none>
    backups     benji-k8s-backup-backups-namespace-1594161600-kqprj    0/1     Error   0          5d20h   10.45.0.126   ncn-w001   <none>           <none>
    backups     benji-k8s-backup-backups-namespace-1594161900-6rqcx    0/1     Error   0          5d20h   10.45.0.125   ncn-w001   <none>           <none>
    loftsman    helm-1594233719                                        0/1     Error   0          5d      10.36.0.192   ncn-w003   <none>           <none>
    loftsman    helm-1594312289                                        0/1     Error   0          4d2h    10.36.0.186   ncn-w003   <none>           <none>
    loftsman    helm-1594329768                                        0/1     Error   0          3d21h   10.36.0.164   ncn-w003   <none>           <none>
    loftsman    helm-1594400189                                        0/1     Error   0          3d1h    10.36.0.191   ncn-w003   <none>           <none>
    loftsman    helm-1594400232                                        0/1     Error   0          3d1h    10.36.0.191   ncn-w003   <none>           <none>
    loftsman    shipper-1594216843-v5hh4                               0/1     Error   0          5d4h    10.36.0.179   ncn-w003   <none>           <none>
    loftsman    shipper-1594216923-z5clh                               0/1     Error   0          5d4h    10.36.0.179   ncn-w003   <none>           <none>
    loftsman    shipper-1594217083-w5mzk                               0/1     Error   0          5d4h    10.36.0.179   ncn-w003   <none>           <none>
    loftsman    shipper-1594312344-87555                               0/1     Error   0          4d2h    10.36.0.194   ncn-w003   <none>           <none>
    loftsman    shipper-1594317770-z8z7q                               0/1     Error   0          4d      10.36.0.186   ncn-w003   <none>           <none>
    loftsman    shipper-1594328454-khsfc                               0/1     Error   0          3d21h   10.36.0.190   ncn-w003   <none>           <none>
    loftsman    shipper-1594329426-75shp                               0/1     Error   0          3d21h   10.36.0.195   ncn-w003   <none>           <none>
    loftsman    shipper-1594329510-q8bsj                               0/1     Error   0          3d21h   10.36.0.164   ncn-w003   <none>           <none>
    services    boa-8b1687b2-2c5b-4c92-8cd7-a44965fef41a-mbfsj         0/2     Error   0          6d      10.42.0.152   ncn-w002   <none>           <none>
    services    boa-8b1687b2-2c5b-4c92-8cd7-a44965fef41a-q7cr4         0/2     Error   0          6d      10.42.0.154   ncn-w002   <none>           <none>
    services    boa-cf973765-92e7-4c5e-b52a-e904088976b8-cplj6         0/2     Error   0          5d23h   10.42.0.158   ncn-w002   <none>           <none>
    services    boa-f6f86426-58bf-4c6f-b3cd-e25010aa9ff6-s7zph         0/2     Error   0          4d2h    10.36.0.191   ncn-w003   <none>           <none>
    services    cfs-0336105c-e697-4d9d-a129-badde6da3218-vn6n4         0/3     Error   0          6d20h   10.42.0.98    ncn-w002   <none>           <none>
    ...
    ```

4.  View the status of the node before taking it down.

    ```bash
    ncn# kubectl get nodes -o wide
    NAME       STATUS   ROLES                  AGE   VERSION    INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                  KERNEL-VERSION         CONTAINER-RUNTIME
    ncn-m001   Ready    control-plane,master   27h   v1.20.13   10.252.1.4    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-m002   Ready    control-plane,master   8d    v1.20.13   10.252.1.5    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-m003   Ready    control-plane,master   8d    v1.20.13   10.252.1.6    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w001   Ready    <none>                 8d    v1.20.13   10.252.1.7    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w002   Ready    <none>                 8d    v1.20.13   10.252.1.8    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ncn-w003   Ready    <none>                 8d    v1.20.13   10.252.1.9    <none>        SUSE Linux Enterprise High Performance Computing 15 SP3   5.3.18-59.19-default   containerd://1.5.7
    ```

### Collect Information After Powering Down the Node

1.  Shut down the node.

    ```bash
    ncn# export USERNAME=root
    ncn# export IPMI_PASSWORD=changeme
    ncn# ipmitool -H BMC_IP_ADDRESS -v -I lanplus -U $USERNAME -E chassis power off
    ```

2. View the node status after the node is taken down.

    ```bash
    ncn# kubectl get nodes
    ```

3.  View the pods on the system to see if their states have changed.

    1.  View all of the pods on the system.

        The following are important things to look for when viewing the pods:

        -   Check for any pods that are still running on the node that was brought down, and if there are still some, make sure those are expected
        -   View the status for all pods before looking for any new error states

        ```bash
        ncn# kubectl get pods -A -o wide
        ```

    2.  Take note of any pods that are in a `Pending` state.

        ```bash
        ncn# kubectl get pods -A -o wide | grep Pending
        ```

    3.  Capture the details for any pod that is in an unexpected state.

        ```bash
        ncn# kubectl describe pod POD_NAME
        ```


### Collect Information After the Node is Powered On

1.  Power the node back on.

    ```bash
    ncn# export USERNAME=root
    ncn# export IPMI_PASSWORD=changeme
    ncn# ipmitool -H BMC_IP_ADDRESS -v -I lanplus -U $USERNAME -E chassis power on
    ```

2. Record the status of the pods again.

    The pods will go to an Unknown state as the node is coming up and taking inventory of its assigned pods. The number of Unknown states will increase as it does this inventory, and then they will decrease as it finds their actual state and puts them back to Running, Terminated, or another state.

    1.  View all the pods on the system.

        ```bash
        ncn# kubectl get pods --all-namespaces -o wide
        ```

    2.  Take note of any pods that are in a `Pending` or `Error` state.

        ```bash
        ncn# kubectl get pods -A -o wide | grep -e 'Pending|Error'
        ```

    3.  Capture the details for any pod that is in an unexpected state.

        ```bash
        ncn# kubectl describe pod POD_NAME
        ```

The node that encountered issues should now be returned to a healthy state.

