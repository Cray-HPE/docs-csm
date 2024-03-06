# Confirm the status of the cray-dhcp-kea pods/services

Check if the kea DHCP services are running.
On `ncn-w001` or a worker/manager with `kubectl`, run:

```
kubectl get -n services pods | grep kea
```

You should see the following services as output:

```
kubectl get services -n services | grep kea

cray-dhcp-kea-api Cluster IP 10.31.247.201   <none> 8000/TCP 3h36m
cray-dhcp-kea-tcp-hmn LoadBalancer 10.25.109.178   10.94.100.222 67:30833/TCP 3h36m
cray-dhcp-kea-tcp-nmn LoadBalancer 10.21.240.208 10.92.100.222   67:31915/TCP 3h36m
cray-dhcp-kea-udp-hmn LoadBalancer 10.20.37.60 10.94.100.222 67:30357/UDP 3h36m
cray-dhcp-kea-udp-nmn LoadBalancer 10.24.246.19 10.92.100.222 67:32188/UDP 3h36m
```

On `ncn-w001` or a worker/manager with `kubectl`, run:

```
kubectl get pods -n services -o wide | grep kea
```

You should get a list of the following pods as output:

```
kubectl get pods -n services -o wide | grep kea
cray-dhcp-kea-788b4c899b-x6ltd 3/3 Running 0 36h 10.40.3.183 ncn-w002 <none> <none>
```

This output will also show which worker node the kea-dhcp pod is currently on.

[Back to Index](../README.md)
