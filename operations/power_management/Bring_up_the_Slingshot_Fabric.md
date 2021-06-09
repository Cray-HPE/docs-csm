


## Bring Up the Slingshot Fabric

Use ansible to bring up the Slingshot fabric.

This procedure assumes the Slingshot fabric is installed an configured.

The fabric manager software is installed and configured.

In release 1.4, the slingshot-fabric-manager pod controls the fabric.

-   **LEVEL**

    **Level 1 HaaS**

-   **ROLE**

    System administrator

-   **OBJECTIVE**

    Bring up the Slingshot fabric.

1.  From the Kubernetes management node, determine the name of the fabric manager pod \(FMN\).

    ```screen
    ncn-m001# kubectl get pods -l app.kubernetes.io/name=slingshot-fabric-manager -n services
    NAME                                        READY   STATUS    RESTARTS   AGE
    slingshot-fabric-manager-5dc448779c-d8n6q   2/2     Running   0          4d21h
    ```

2.  Open a shell to access the fabric manager pod \(in this example, slingshot-fabric-manager-5dc448779c-d8n6q\).

    ```screen
    ncn-m001# kubectl exec -it slingshot-fabric-manager-5dc448779c-d8n6q -n services -- /bin/bash
    slingshot-fabric-manager:#
    ```

3. Bring up the Slingshot fabric.

   ```screen
   slingshot-fabric-manager:# fmn\_fabric\_bringup -c
   ```

5.  Check the status of the fabric.

    From within in the fabric manager pod:

    ```screen
    slingshot-fabric-manager:# fmn\_status --details
    ```

    To save fabric status to a file from a management node:

    ```screen
    ncn-m001# kubectl exec -it -n services slingshot-fabric-manager-5dc448779c-d8n6q \\
    -c slingshot-fabric-manager -- fmn\_status --details \> fabric.status
    ```



