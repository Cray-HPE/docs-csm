## Disable ConMan After the System Software Installation

The ConMan utility is enabled by default. This procedure provides instructions for disabling it after the system software has been installed.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1. Log on to a non-compute node (NCN) that acts as a Kubernetes master. This procedure assumes that it is being carried out on an NCN acting as a Kubernetes master.

2. Scale the cray-console-operator pods to 0 replicas.

    ```
    ncn-m001# kubectl -n services scale --replicas=0 deployment/cray-console-operator
    deployment.apps/cray-console-operator scaled
    ```

3. Verify the cray-console-operator service is no longer running.
   
    ```
    ncn-m001# kubectl -n services get pods | grep console-operator
    ncn-m001#
    ```

4. Scale the cray-console-node pods to 0 replicas.
   
    ```
    ncn-m001# kubectl -n services scale --replicas=0 statefulset/cray-console-node
    statefulset.apps/cray-console-node scaled
    ```

5. Verify the cray-console-node service is no longer running.
   
    ```
    ncn-m001# kubectl -n services get pods | grep console-node
    ncn-m001#
    ```

6. Restore the services.
   
    Scale the cray-console-operator service back to 1 replica to restore the service at a later time. It will scale the cray-console-node pods after it starts operation.

    ```
    ncn-m001# kubectl -n services scale --replicas=1 deployment/cray-console-operator
    deployment.apps/cray-console-operator scaled
    ```

7. Verify services are running again.
   
    ```
    ncn-m001# kubectl -n services get pods | grep -e console-operator -e console-node
    cray-console-node-0                      3/3     Running      0      8m44s
    cray-console-node-1                      3/3     Running      0      8m18s
    cray-console-operator-79bf95964-lngpz    2/2     Running      0      9m29s
    ```

