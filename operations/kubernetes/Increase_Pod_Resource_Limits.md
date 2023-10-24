# Increase Pod Resource Limits

Increase the appropriate resource limits for pods after determining if a pod is being CPU throttled or `OOMKilled`.

Return Kubernetes pods to a healthy state with resources available.

## Prerequisites

- The names of the pods hitting their resource limits are known. See [Determine if Pods are Hitting Resource Limits](Determine_if_Pods_are_Hitting_Resource_Limits.md).

## Procedure

1. (`ncn-mw#`) Determine the current limits of a pod.

    ```bash
    kubectl get po -n services POD_ID -o yaml
    ```

    Look for the following section returned in the output:

    ```yaml
        resources:
          limits:
            cpu: "2"
            memory: 2Gi
          requests:
            cpu: 10m
            memory: 64Mi
    ```

1. (`ncn-mw#`) Determine which Kubernetes entity \(`etcdcluster`, `deployment`, `statefulset`, etc\) is creating the pod.

    The Kubernetes entity can be found with either of the following options:

    - Find the Kubernetes entity and `grep` for the pod in question.

        In the following example, replace `hbtd-etcd` with the pod being used.

        ```bash
        kubectl get deployment,statefulset,etcdcluster,postgresql,daemonsets -A | grep hbtd-etcd
        ```

        Example output:

        ```text
        services    etcdcluster.etcd.database.coreos.com/cray-hbtd-etcd               32d
        ```

    - Describe the pod and look in the `Labels` section.

        This section is helpful for tracking down which entity is creating the pod.

        ```bash
        kubectl describe pod -n services POD_ID
        ```

        Excerpt from example output:

        ```text
        Labels:       app=etcd
                      etcd_cluster=cray-hbtd-etcd
                      etcd_node=cray-hbtd-etcd-8r2scmpb58
        ```

1. (`ncn-mw#`) Edit the entity.

    In the example below, be sure to replace `ENTITY_TYPE` and `ENTITY_NAME` with the values determined in
    the previous step (in the example output for the following step, these would be `etcdcluster` and
    `cray-hbtd-etcd`, respectively).

    ```bash
    kubectl edit ENTITY_TYPE -n services ENTITY_NAME
    ```

1. (`ncn-mw#`) Increase the resource limits for the pod.

    ```yaml
        resources: {}
    ```

    Replace the text above with the following section, increasing the limits values:

    ```yaml
        resources:
        limits:
          cpu: "4"
          memory: 8Gi
        requests:
          cpu: 10m
          memory: 64Mi
    ```

1. (`ncn-mw#`) Run a rolling restart of the pods.

    ```bash
    kubectl get po -n services | grep ENTITY_NAME
    ```

    Example output:

    ```text
    cray-hbtd-etcd-8r2scmpb58 1/1 Running 0 5d11h
    cray-hbtd-etcd-qvz4zzjzw2 1/1 Running 0 5d11h
    cray-hbtd-etcd-vzjzmbn6nr 1/1 Running 0 5d11h
    ```

1. (`ncn-mw#`) Kill the pods off one by one.

    Wait for each replacement pod to come up and be in a `Running` state before proceeding to the next pod.

    ```bash
    kubectl -n services delete pod POD_ID
    ```

1. (`ncn-mw#`) Verify that all pods are now `Running` with a more recent age.

    ```bash
    kubectl get po -n services | grep ENTITY_NAME
    ```

    Example output:

    ```text
    cray-hbtd-etcd-8r2scmpb58 1/1 Running 0 12s
    cray-hbtd-etcd-qvz4zzjzw2 1/1 Running 0 32s
    cray-hbtd-etcd-vzjzmbn6nr 1/1 Running 0 98s
    ```
