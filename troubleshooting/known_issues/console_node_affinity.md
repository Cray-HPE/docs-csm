# Console Node Pods On the Same Worker

In versions before CSM v1.3.0, there is no anti-affinity specified for the `cray-console-node` pods. This
leads to the possibility of several pods running on the same worker node. This can be inconvenient during
worker reboot operations and reduce service reliability.

## Fix

To implement anti-affinity Kubernetes scheduling in versions prior to CSM v1.3.0 it is possible to edit the
deployment manually. This will remain in effect until the service is reinstalled, downgraded, or upgraded.

To bring up the deployment in an editor:

```bash
ncn# kubectl -n services edit statefulset cray-console-node
```

Look for the `spec.template.spec` section:

```text
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

Add a new `affinity` section before `containers` so it looks like:

```text
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

The `cray-console-node` pods should restart one at a time until all have restarted. As they restart,
Kubernetes will try to schedule them on different worker nodes.

They are set to only prefer to schedule them on different nodes, meaning that if there are not enough
valid nodes running at the time they are scheduled, there still may be more than on running on a
single node. If this is the case, look at the health of the worker nodes.

The anti-affinity property is only examined when a new pod is started. If there are not enough healthy
workers for all of the `cray-console-node` pods requested and multiple pods are running on the same worker,
the pods will not be moved later to rebalance the deployment. If more healthy workers are added, the extra
pods will need to be deleted manually to have them shifted to a different worker node.
