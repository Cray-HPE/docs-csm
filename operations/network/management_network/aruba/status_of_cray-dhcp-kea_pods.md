# Confirm the Status of the cray-dhcp-kea Pods

Use this procedure to verify the status of the cray-dhcp-kea pods and services. The commands in this procedure must be run on ncn-w001 or a worker/manager NCN with `kubectl` installed.

## Procedure

1. Check if the Kea DHCP services are running.

    ```bash
    ncn# kubectl get -n services pods | grep kea
    ```

    The following services should be returned as output:

    ```bash
    ncn-w001# kubectl get services -n services | grep kea
    cray-dhcp-kea-api Cluster IP 10.31.247.201   <none> 8000/TCP 3h36m
    cray-dhcp-kea-tcp-hmn LoadBalancer 10.25.109.178   10.94.100.222 67:30833/TCP 3h36m
    cray-dhcp-kea-tcp-nmn LoadBalancer 10.21.240.208 10.92.100.222   67:31915/TCP 3h36m
    cray-dhcp-kea-udp-hmn LoadBalancer 10.20.37.60 10.94.100.222 67:30357/UDP 3h36m
    cray-dhcp-kea-udp-nmn LoadBalancer 10.24.246.19 10.92.100.222 67:32188/UDP 3h36m
    ```

1. View the Kea pods.

    ```bash
    ncn# kubectl get pods -n services -o wide | grep kea
    ```

    A list of the following pods will be returned as output:

    ```bash
    ncn-w001# kubectl get pods -n services -o wide | grep kea
    cray-dhcp-kea-788b4c899b-x6ltd 3/3 Running 0 36h 10.40.3.183 ncn-w002 <none> <none>
    cray-dhcp-kea-postgres-0 2/2 Running 0 5d23h 10.40.3.121 ncn-w002 <none> <none>
    cray-dhcp-kea-postgres-1 2/2 Running 0 5d23h 10.42.2.181 ncn-w003 <none> <none>
    cray-dhcp-kea-postgres-2 2/2 Running 0 5d23h 10.39.0.208 ncn-w001 <none> <none>
    ```

    This output will also show which worker node the kea-dhcp pod is currently on.

[Back to Index](../index_aruba.md)