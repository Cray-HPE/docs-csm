# Multiple Console Node Pods on the Same Worker

In versions before CSM v1.3.0, there is no anti-affinity specified for the `cray-console-node` pods. This
leads to the possibility of several pods running on the same worker node. This can be inconvenient during
worker reboot operations and can reduce service reliability.

- [Manually edit deployment](#manually-edit-deployment)
- [Pod scheduling behavior](#pod-scheduling-behavior)

## Manually edit deployment

This procedure implements anti-affinity Kubernetes scheduling in versions prior to CSM v1.3.0 by
manually editing the `cray-console-node` deployment. This will remain in effect until the service is reinstalled, downgraded,
or upgraded. In CSM v1.3.0, the `cray-console-node` deployment already includes anti-affinity, so after an upgrade to that CSM
version, no manual editing is required in order to implement pod anti-affinity for this deployment.

1. Bring up the deployment in an editor.

    ```bash
    ncn-mw# kubectl -n services edit statefulset cray-console-node
    ```

1. Find the `spec.template.spec` section.

    It will look similar to the following:

    ```yaml
    spec:
      podManagementPolicy: OrderedReady
      replicas: 2
      revisionHistoryLimit: 10
      selector:
        matchLabels:
          app.kubernetes.io/instance: cray-console-node
          app.kubernetes.io/name: cray-console-node
      serviceName: cray-console-node
      template:
        metadata:
          annotations:
            service.cray.io/public: "true"
          creationTimestamp: null
          labels:
            app.kubernetes.io/instance: cray-console-node
            app.kubernetes.io/name: cray-console-node
        spec:
          containers:
          - env:
            - name: LOG_ROTATE_ENABLE
              value: "True"
            - name: LOG_ROTATE_FILE_SIZE
    ```

1. Add a new `affinity` section before `containers`.

    The new section contents are:

    ```yaml
          affinity:
            podAntiAffinity:
              preferredDuringSchedulingIgnoredDuringExecution:
              - podAffinityTerm:
                  labelSelector:
                    matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                      - cray-console-node
                  topologyKey: kubernetes.io/hostname
                weight: 100
    ```

    After the addition, the deployment should look similar to the following:

    ```yaml
    spec:
      podManagementPolicy: OrderedReady
      replicas: 2
      revisionHistoryLimit: 10
      selector:
        matchLabels:
          app.kubernetes.io/instance: cray-console-node
          app.kubernetes.io/name: cray-console-node
      serviceName: cray-console-node
      template:
        metadata:
          annotations:
            service.cray.io/public: "true"
          creationTimestamp: null
          labels:
            app.kubernetes.io/instance: cray-console-node
            app.kubernetes.io/name: cray-console-node
        spec:
          affinity:
            podAntiAffinity:
              preferredDuringSchedulingIgnoredDuringExecution:
              - podAffinityTerm:
                  labelSelector:
                    matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                      - cray-console-node
                  topologyKey: kubernetes.io/hostname
                weight: 100
          containers:
          - env:
            - name: LOG_ROTATE_ENABLE
              value: "True"
            - name: LOG_ROTATE_FILE_SIZE
    ```

1. Save the deployment and exit the editor.

    The `cray-console-node` pods should restart one at a time until all have restarted. As they restart,
    Kubernetes will try to schedule them on different worker nodes.

## Pod scheduling behavior

The above manually edited deployment only **prefers** to schedule the pods on different nodes, meaning that if
there are not enough valid nodes running at the time they are scheduled, then there still may be more than one running on a
single node. If this is the case, then look at the health of the worker nodes.

The anti-affinity property is only examined when a new pod is started. If there are not enough healthy
workers for all of the `cray-console-node` pods requested, causing multiple pods to run on the same worker,
then these pods will not be automatically moved later to rebalance the deployment. If more healthy workers are added
later, then the extra pods will need to be deleted manually in order to have them shifted to a different worker node.
