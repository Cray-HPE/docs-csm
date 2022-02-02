## Retrieve Cluster Health Information Using Kubernetes

The `kubectl` CLI commands can be used to retrieve information about the Kubernetes cluster components.


### Retrieve Node Status

```bash
ncn# kubectl get nodes
```

Example output:

```
NAME       STATUS   ROLES                  AGE   VERSION
ncn-m001   Ready    control-plane,master   27h   v1.20.13
ncn-m002   Ready    control-plane,master   8d    v1.20.13
ncn-m003   Ready    control-plane,master   8d    v1.20.13
ncn-w001   Ready    <none>                 8d    v1.20.13
ncn-w002   Ready    <none>                 8d    v1.20.13
ncn-w003   Ready    <none>                 8d    v1.20.13
```

### Retrieve Pod Status

```bash
ncn# kubectl get pods options
```

Example output:

```
NAME                                    READY     STATUS    RESTARTS   AGE
api-gateway-6fffd4d854-btp4v            1/1       Running   2          11d
api-gateway-6fffd4d854-l7z8m            1/1       Running   1          11d
api-gateway-6fffd4d854-tqx8v            1/1       Running   1          11d
api-gateway-database-8555685975-xw5gm   1/1       Running   1          11d
cray-ars-6466bcf77d-s99rq               1/1       Running   1          11d
cray-bss-7589d7459f-ttwf4               1/1       Running   1          11d
cray-capmc-6bf5855b78-np72d             1/1       Running   1          11d
cray-datastore-768576677d-gpnl7         1/1       Running   1          11d
cray-dhcp-5fccf85696-wrqxb              1/1       Running   1          11d
cray-tftp-885cc65c4-568jz               2/2       Running   2          11d
kvstore-1-56fdb6574c-ts79v              1/1       Running   1          11d
kvstore-2-694bc7567b-k99tl              1/1       Running   1          11d
kvstore-3-5b658b9bd9-n9dgt              1/1       Running   1          11d
```

### Retrieve Information about Individual Pods

```bash
ncn# kubectl describe pod POD_NAME -n NAMESPACE_NAME
```

### Retrieve a List of Healthy Pods

```bash
ncn# kubectl get pods -A | grep -e 'Completed|Running'
```

Example output:

```
ceph-cephfs       cephfs-provisioner-74599ccfcd-bzf5b                1/1     Running      3    2d11h
ceph-rbd          rbd-provisioner-76c464c567-jvvk6                   1/1     Running      3    2d11h
cert-manager      cray-certmanager-cainjector-8487d996d7-phbfr       1/1     Running      0    2d11h
cert-manager      cray-certmanager-cert-manager-d5fb67664-v9sgf      1/1     Running      0    2d11h
cert-manager      cray-certmanager-webhook-6b58c6bb79-dtpl7          1/1     Running      0    2d11h
default           kube-keepalived-vip-mgmt-plane-nmn-local-pkbxj     1/1     Running      0    2d11h
default           kube-keepalived-vip-mgmt-plane-nmn-local-v8w6k     1/1     Running      0    2d11h
default           kube-keepalived-vip-mgmt-plane-nmn-local-zzc4n     1/1     Running      1    2d11h
istio-system      grafana-ff8b4b964-grg8m                            1/1     Running      0    2d11h
istio-system      istio-citadel-699fc7bcf-rn99p                      1/1     Running      0    2d11h
istio-system      istio-ingressgateway-59bf97fbc5-h6x4w              1/1     Running      0    2d11h
istio-system      istio-ingressgateway-hmn-5d7777c75-2c5nz           1/1     Running      0    2d11h
istio-system      istio-ingressgateway-hmn-5d7777c75-dh4fl           1/1     Running      0    2d11h
istio-system      istio-init-crd-10-1.2.10-wgg99                     0/1     Completed    0    2d11h
istio-system      istio-init-crd-11-1.2.10-dcp4h                     0/1     Completed    0    2d11h
```

### Retrieve a List of Unhealthy Pods

```bash
ncn# kubectl get pods -A | grep -e 'Creating|ImagePull|Error|Init|Crash'
```

Example output:

```
services   cray-conman-68fffd8d9d-8h6zb               1/2    CrashLoopBackOff             694    2d10h
services   cray-crus-549cb9cb5d-7gv6n                 0/4    Init:0/2                     0      2d10h
services   cray-hms-badger-api-69bd7bc5b6-2v5sf       0/2    Init:0/2                     0      2d10h
services   cray-hms-badger-wait-for-postgres-8q94h    1/3    ImagePullBackOff             0      2d10h
services   cray-hms-pmdbd-6b7c9fc5d-fpcwp             1/2    CrashLoopBackOff             694    2d10h
services   cray-hms-rts-68f48765b-j2jcp               0/3    Init:0/2                     0      2d10h
services   cray-hms-rts-init-n6df4                    0/2    Init:0/2                     0      2d10h
services   cray-meds-76f5d9848-f9rsn                  1/2    CreateContainerConfigError   0      2d10h
services   cray-reds-77b9575457-qx7m5                 0/2    Init:2/4                     0      2d10h
```

### Retrieve Service Status

```bash
ncn# kubectl get services -n NAMESPACE_NAME
```

Example output:

```
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP  PORT(S)                      AGE
cray-ars           ClusterIP   10.96.216.213    <none>       80/TCP                       5d
cray-capmc         ClusterIP   10.99.76.144     <none>       27777/TCP                    5d
cray-datastore     ClusterIP   10.111.46.185    <none>       80/TCP                       5d
cray-tftp-service  NodePort    10.103.83.144    <none>       69:69/UDP                    5d
kubernetes         ClusterIP   10.96.0.1        <none>       443/TCP                      5d
kvstore-1          ClusterIP   10.110.91.156    <none>       2181/TCP,2888/TCP,3888/TCP   5d
kvstore-2          ClusterIP   10.106.148.164   <none>       2181/TCP,2888/TCP,3888/TCP   5d
kvstore-3          ClusterIP   10.108.198.177   <none>       2181/TCP,2888/TCP,3888/TCP   5d
```

### Retrieve Status of Pods in a Specific Namespace

```bash
ncn# kubectl get pods -n NAMESPACE_NAME
```

Example output:

```
NAME                             READY     STATUS    RESTARTS   AGE
kube-apiserver-sms-01            1/1       Running   2          11d
kube-apiserver-sms-02            1/1       Running   1          11d
kube-apiserver-sms-03            1/1       Running   1          11d
kube-controller-manager-sms-01   1/1       Running   1          11d
kube-controller-manager-sms-02   1/1       Running   1          11d
kube-controller-manager-sms-03   1/1       Running   1          11d
kube-dns-86f4d74b45-7g544        3/3       Running   3          11d
kube-proxy-4b2cb                 1/1       Running   1          11d
kube-proxy-b9jgw                 1/1       Running   1          11d
kube-proxy-xzld7                 1/1       Running   1          11d
kube-scheduler-sms-01            1/1       Running   1          11d
kube-scheduler-sms-02            1/1       Running   1          11d
kube-scheduler-sms-03            1/1       Running   1          11d
weave-net-mg2kp                  2/2       Running   7          11d
weave-net-qfd69                  2/2       Running   13         11d
weave-net-xnlm9                  2/2       Running   30         11d
```

### Retrieve Pod Logs

```bash
ncn# kubectl logs -n NAMESPACE_NAME POD_NAME
```




