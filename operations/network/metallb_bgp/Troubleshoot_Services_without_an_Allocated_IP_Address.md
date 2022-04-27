# Troubleshoot Services without an Allocated IP Address

Check if a given service has an IP address allocated for it if the Kubernetes LoadBalancer services in the NMN, HMN, CMN, CHN, or CAN address pools are not accessible from outside the cluster.

Regain access to Kubernetes LoadBalancer services from outside the cluster.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Check the status of the services with the `kubectl` command to see the External-IP of the service.

    If <pending\> appears in this column, the service is having a problem getting an IP address assigned from MetalLB.

    ```bash
    ncn-w001# kubectl get service -A | grep Load
    ```

    Example output:

    ```
    ims            cray-ims-b9cdea70-223f-4968-a0f4-589518c89a80-service   LoadBalancer   10.17.97.66    <pending>      22:32678/TCP                 2d9h
    ims            cray-ims-eca49ecd-5434-46b2-9a3c-f4f0467f8ecb-service   LoadBalancer   10.18.171.14   <pending>      22:30821/TCP                 2d5h
    istio-system   istio-ingressgateway                                    LoadBalancer   10.26.49.253   10.92.100.50  80:30517/TCP,443:30754/TCP   3d5h
    istio-system   istio-ingressgateway-cmn                                LoadBalancer   10.28.192.172  <pending>      80:30708/TCP,443:31430/TCP   3d5h
    istio-system   istio-ingressgateway-hmn                                LoadBalancer   10.17.46.139   10.94.100.1   80:32444/TCP                 3d5h
    ```

2.  Check that the address pool in the annotation for the service matches one of the address pools in the MetalLB ConfigMap.

    To view information on the service:

    ```bash
    ncn-w001# kubectl -n istio-system describe service istio-ingressgateway-cmn
    ```

    Example output:

    ```
    Name:                     istio-ingressgateway-cmn
    Namespace:                istio-system
    Labels:                   app=istio-ingressgateway
                              chart=cray-istio
                              heritage=Tiller
                              istio=ingressgateway
                              release=cray-istio
    Annotations:              external-dns.alpha.kubernetes.io/hostname: api.cmn.SYSTEM_DOMAIN_NAME,auth.cmn.SYSTEM_DOMAIN_NAME,nexus.cmn.SYSTEM_DOMAIN_NAME
                             ** metallb.universe.tf/address-pool: customer-management**
    Selector:                 app=istio-ingressgateway,istio=ingressgateway,release=cray-istio
    Type:                     LoadBalancer
    IP:                       10.28.192.172
    Port:                     http2 80/TCP
    TargetPort:               80/TCP
    NodePort:                 http2 30708/TCP
    Endpoints:                10.39.0.5:80
    Port:                     https 443/TCP
    TargetPort:               443/TCP
    NodePort:                 https 31430/TCP
    Endpoints:                10.39.0.5:443
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:                   <none>
    ```

    Run the following command to view the ConfigMap. There is no customer-management address pool in the example below, indicated it has not been added yet. This is why the external IP address value is <pending\>.

    ```bash
    ncn-w001# kubectl -n metallb-system get cm config -o yaml
    ```

    Example output:

    ```
    apiVersion: v1
    data:
      config: |
        **address-pools:**
        - name: node-management
          protocol: layer2
          addresses:
          - 10.92.100.0/24
        - name: hardware-management
          protocol: layer2
          addresses:
          - 10.94.100.0/24
        - name: customer-high-speed
          protocol: layer2
          addresses:
          - 169.0.100.16/28
    kind: ConfigMap
    metadata:
      annotations:

          kubectl.kubernetes.io/last-applied-configuration: |
            {"apiVersion":"v1","data":{"config":"address-pools:\n- name: node-management\n protocol: layer2\n addresses:\n - 10.92.100.0/24\n- name: hardware-management\n protocol: layer2\n addresses:\n - 10.94.100.0/24\n- name: customer-high-speed\n protocol: layer2\n addresses:\n - 169.0.100.16/28\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"config","namespace":"metallb-system"}}
    creationTimestamp: "2020-01-09T20:33:25Z"
    name: config
    namespace: metallb-system
    resourceVersion: "1645"
    selfLink: /api/v1/namespaces/metallb-system/configmaps/config
    uid: 49967541-331f-11ea-9421-b42e993a2608
    ```

