


## Bring Up the Slingshot Fabric

This procedure assumes the Slingshot fabric is installed an configured. The slingshot-fabric-manager software controls the fabric. On systems running Kubernetes, the slingshot-fabric-manager pod controls the fabric. 

### Prerequisites

The fabric manager software is installed and configured.

### Procedure

1.  From the Kubernetes management node, determine the name of the fabric manager pod \(FMN\).

    ```bash
    ncn-m001# kubectl get pods -l app.kubernetes.io/name=slingshot-fabric-manager -n services
    NAME                                        READY   STATUS    RESTARTS   AGE
    slingshot-fabric-manager-5dc448779c-d8n6q   2/2     Running   0          4d21h
    ```

2.  Open a shell to access the fabric manager pod \(in this example, slingshot-fabric-manager-5dc448779c-d8n6q\).

    ```bash
    ncn-m001# kubectl exec -it slingshot-fabric-manager-5dc448779c-d8n6q -n services -- /bin/bash
    slingshot-fabric-manager:#
    ```

3. Bring up the Slingshot fabric.

   ```bash
   slingshot-fabric-manager:# fmn_fabric_bringup -c
   ```

5.  Check the status of the fabric.

    From within in the fabric manager pod:

    ```bash
    slingshot-fabric-manager:# fmn_status --details
    ```

    To save fabric status to a file from a management node:

    ```bash
    ncn-m001# kubectl exec -it -n services slingshot-fabric-manager-5dc448779c-d8n6q \
    -c slingshot-fabric-manager -- fmn_status --details > fabric.status
    ```



