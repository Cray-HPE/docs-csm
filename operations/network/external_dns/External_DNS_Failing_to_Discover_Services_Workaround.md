## External DNS Failing to Discover Services Workaround

Many external DNS issues can be worked around by directly connecting to the desired backend service. This can circumvent authentication and authorization protections, but it may be necessary to access specific services when mitigating critical issues.

Istio's ingress gateway uses Gateway and VirtualService objects to configure how traffic is routed to backend services. Currently, there is only one Gateway supporting the Customer Access Network \(CAN\), which is services/services-gateway. It is configured to support traffic for any host. Consequently, it's the VirtualService objects that ultimately control routing based on hostname.

Use this procedure to resolve any external DNS routing issues with backend services.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Search for the VirtualService object that corresponds to the desired service.

    The command below will list all external hostnames.

    ```bash
    ncn-w001# kubectl get vs -A | grep -v '[*]'
    NAMESPACE        NAME                              GATEWAYS                       HOSTS                                                      AGE
    istio-system     kiali                             [services/services-gateway]    [kiali-istio.groot.dev.cray.com]                           2d16h
    istio-system     prometheus                        [services/services-gateway]    [prometheus-istio.groot.dev.cray.com]                      2d16h
    istio-system     tracing                           [services/services-gateway]    [jaeger-istio.groot.dev.cray.com]                          2d16h
    nexus            nexus                             [services/services-gateway]    [packages.local registry.local nexus.groot.dev.cray.com]   2d16h
    services         gitea-vcs-external                [services/services-gateway]    [vcs.groot.dev.cray.com]                                   2d16h
    services         sma-grafana                       [services-gateway]             [sma-grafana.groot.dev.cray.com]                           2d16h
    services         sma-kibana                        [services-gateway]             [sma-kibana.groot.dev.cray.com]                            2d16h
    sysmgmt-health   cray-sysmgmt-health-alertmanager  [services/services-gateway]    [alertmanager.groot.dev.cray.com]                          2d16h
    sysmgmt-health   cray-sysmgmt-health-grafana       [services/services-gateway]    [grafana.groot.dev.cray.com]                               2d16h
    sysmgmt-health   cray-sysmgmt-health-prometheus    [services/services-gateway]    [prometheus.groot.dev.cray.com]                            2d16h
    ```

2.  Inspect the VirtualService object\(s\) to learn the destination service and port.

    Use the NAME value returned in the previous step. The following example is for the cray-sysmgmt-health-prometheus service.

    ```bash
    ncn-w001# kubectl get vs -n sysmgmt-health cray-sysmgmt-health-prometheus -o yaml
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
      creationTimestamp: "2020-07-09T17:49:07Z"
      generation: 1
      labels:
        app: cray-sysmgmt-health-prometheus
        app.kubernetes.io/instance: cray-sysmgmt-health
        app.kubernetes.io/managed-by: Tiller
        app.kubernetes.io/name: cray-sysmgmt-health
        app.kubernetes.io/version: 8.15.4
        helm.sh/chart: cray-sysmgmt-health-0.3.1
      name: cray-sysmgmt-health-prometheus
      namespace: sysmgmt-health
      resourceVersion: "41620"
      selfLink: /apis/networking.istio.io/v1beta1/namespaces/sysmgmt-health/virtualservices/cray-sysmgmt-health-prometheus
      uid: d239dfcc-a827-4a51-9b73-6eccfb937088
    spec:
      gateways:
      - services/services-gateway
      hosts:
      - prometheus.pepsi.dev.cray.com
      http:
      - match:
        - authority:
            exact: prometheus.pepsi.dev.cray.com
        route:
        - destination:
            host: cray-sysmgmt-health-promet-prometheus
            port:
              number: 9090
    ```

    From the VirtualService data, it is straightforward to see how traffic will be routed. In this example, connections to prometheus.pepsi.dev.cray.com will be routed to the cray-sysmgmt-health-prometheus service in the sysmgmt-health namespace on port 9090.


External DNS will now be connected to the back-end service.


