# Increase Pod Resource Limits

Increase the appropriate resource limits for pods after determining if a pod is being CPU throttled or OOMKilled.

Return Kubernetes pods to a healthy state with resources available.

### Prerequisites

- `kubectl` is installed.
- The names of the pods hitting their resource limits are known. See [Determine if Pods are Hitting Resource Limits](Determine_if_Pods_are_Hitting_Resource_Limits.md).

### Procedure

1.  Determine the current limits of a pod.

    In the example below, cray-hbtd-etcd-8r2scmpb58 is the POD\_ID being used.

    ```bash
    ncn-w001# kubectl get po -n services POD_ID -o yaml
    ```

    Look for the following section returned in the output:

    ```
    [...]

        resources:
          limits:
            cpu: "2"
            memory: 2Gi
          requests:
            cpu: 10m
            memory: 64Mi
    ```

2.  Determine which Kubernetes entity \(etcdcluster, deployment, statefulset\) is creating the pod.

    The Kubernetes entity can be found with either of the following options:

    -   Find the Kubernetes entity and grep for the pod in question.

        Replace hbtd-etcd with the pod being used.

        ```bash
        ncn-w001# kubectl get deployment,statefulset,etcdcluster,postgresql,daemonsets \
        -A | grep hbtd-etcd
        ```

        Example output:

        ```
        services    etcdcluster.etcd.database.coreos.com/cray-hbtd-etcd               32d
        ```

    -   Describe the pod and look in the Labels section.

        This section is helpful for tracking down which entity is creating the pod.

        ```bash
        ncn-w001# kubectl describe pod -n services POD_ID
        ```

        Example output:

        ```
        [...]

        Labels:       app=etcd
                      etcd_cluster=cray-hbtd-etcd
                      etcd_node=cray-hbtd-etcd-8r2scmpb58

        [...]
        ```

3.  Edit the entity.

    In the example below, the ENTITY is etcdcluster and the CLUSTER\_NAME is cray-hbtd-etcd.

    ```bash
    ncn-w001# kubectl edit ENTITY -n services CLUSTER_NAME
    ```

4.  Increase the resource limits for the pod.

    ```
        resources: {}
    ```

    Replace the text above with the following section, increasing the limits value\(s\):

    ```
        resources:
        limits:
          cpu: "4"
          memory: 8Gi
        requests:
          cpu: 10m
          memory: 64Mi
    ```

5.  Run a rolling restart of the pods.

    ```bash
    ncn-w001# kubectl get po -n services | grep CLUSTER_NAME
    ```

    Example output:

    ```
    cray-hbtd-etcd-8r2scmpb58 1/1 Running 0 5d11h
    cray-hbtd-etcd-qvz4zzjzw2 1/1 Running 0 5d11h
    cray-hbtd-etcd-vzjzmbn6nr 1/1 Running 0 5d11h
    ```

6.  Kill the pods off one by one.

    ```bash
    ncn-w001# kubectl -n services delete pod POD_ID
    ```

7.  Wait for a replacement pod to come up and be in a Running state before proceeding to the next pod.

    They should all be running with a more recent age.

    ```bash
    ncn-w001# kubectl get po -n services | grep CLUSTER_NAME
    ```

    Example output:

    ```
    cray-hbtd-etcd-8r2scmpb58 1/1 Running 0 12s
    cray-hbtd-etcd-qvz4zzjzw2 1/1 Running 0 32s
    cray-hbtd-etcd-vzjzmbn6nr 1/1 Running 0 98s
    ```

