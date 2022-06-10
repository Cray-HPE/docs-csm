# Retrieve Cluster Health Information Using Kubernetes

The `kubectl` CLI commands can be used to retrieve information about the Kubernetes cluster components.

## Nodes

### Retrieve node status

```bash
kubectl get nodes
```

Example output:

```text
NAME       STATUS   ROLES                  AGE   VERSION
ncn-m001   Ready    control-plane,master   27h   v1.20.13
ncn-m002   Ready    control-plane,master   8d    v1.20.13
ncn-m003   Ready    control-plane,master   8d    v1.20.13
ncn-w001   Ready    <none>                 8d    v1.20.13
ncn-w002   Ready    <none>                 8d    v1.20.13
ncn-w003   Ready    <none>                 8d    v1.20.13
```

## Pods

### Retrieve information about individual pods

```bash
kubectl describe pod POD_NAME -n NAMESPACE_NAME
```

### Retrieve a list of all pods

```bash
kubectl get pods -A
```

### Retrieve a list of healthy pods

```bash
kubectl get pods -A | grep -E 'Completed|Running'
```

### Retrieve a list of unhealthy pods

- Option 1: List all pods that are not reported as `Completed` or `Running`.

    ```bash
    kubectl get pods -A | grep -Ev 'Completed|Running'
    ```

- Option 2: List all pods that are reported as `Creating`, `ImagePull`, `Error`, `Init`, or `Crash`.

    ```bash
    kubectl get pods -A | grep -E 'Creating|ImagePull|Error|Init|Crash'
    ```

### Retrieve status of pods in a specific namespace

```bash
kubectl get pods -n NAMESPACE_NAME
```

Example output for `vault` namespace:

```text
NAME                                     READY   STATUS      RESTARTS   AGE
cray-vault-0                             5/5     Running     2          7d
cray-vault-1                             5/5     Running     2          7d
cray-vault-2                             5/5     Running     2          7d
cray-vault-configurer-7c7dcdb958-p8jfv   2/2     Running     0          7d
cray-vault-operator-b48b7874f-flstw      2/2     Running     1          7d
spire-intermediate-1-ltzwk               0/2     Completed   0          7d
```

### Retrieve pod logs

```bash
kubectl logs -n NAMESPACE_NAME POD_NAME
```

## Services

### Retrieve a list of all services

```bash
kubectl get services -A
```

### Retrieve status of services in a specific namespace

```bash
kubectl get services -n NAMESPACE_NAME
```

Example output for `operators` namespace:

```text
NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
cray-hms-trs-operator-metrics       ClusterIP   10.16.222.4     <none>        8383/TCP,8686/TCP   7d
cray-kiali-kiali-operator-metrics   ClusterIP   10.20.177.208   <none>        8383/TCP,8686/TCP   7d
etcd-restore-operator               ClusterIP   10.28.72.18     <none>        19999/TCP           7d
```
