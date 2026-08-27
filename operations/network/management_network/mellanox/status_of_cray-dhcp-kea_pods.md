# Confirm The Status Of The `cray-dhcp-kea` Pods/Services

(`ncn-mw#`) Check if the Kea DHCP services are running.

```bash
kubectl get -n services pods | grep kea
```

Expected output:

```text
cray-dhcp-kea-api Cluster IP 10.31.247.201   <none> 8000/TCP 3h36m
cray-dhcp-kea-tcp-hmn LoadBalancer 10.25.109.178   10.94.100.222 67:30833/TCP 3h36m
cray-dhcp-kea-tcp-nmn LoadBalancer 10.21.240.208 10.92.100.222   67:31915/TCP 3h36m
cray-dhcp-kea-udp-hmn LoadBalancer 10.20.37.60 10.94.100.222 67:30357/UDP 3h36m
cray-dhcp-kea-udp-nmn LoadBalancer 10.24.246.19 10.92.100.222 67:32188/UDP 3h36m
```

(`ncn-mw#`) Get more detailed information about the pods.

```bash
kubectl get pods -n services -o wide | grep kea
```

Expected output:

```text
cray-dhcp-kea-788b4c899b-x6ltd 3/3 Running 0 36h 10.40.3.183 ncn-w002 <none> <none>
```

This output also shows which worker node the pod is currently on.

[Back to Index](../README.md)
