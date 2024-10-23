# External DNS Failing to Discover Services Workaround

Many external DNS issues can be worked around by directly connecting to the desired backend service. This can circumvent authentication and authorization protections,
but it may be necessary to access specific services when mitigating critical issues.

Istio's ingress gateway uses `Gateway` and `VirtualService` objects to configure how traffic is routed to backend services. Currently, there are three gateways supporting the externally
accessible services: `services-gateway`, `customer-admin-gateway`, and `customer-user-gateway`. They are configured to support traffic on any host depending on the network over which the
services are accessed. It is the `VirtualService` objects that ultimately control routing based on hostname.

Use this procedure to resolve any external DNS routing issues with backend services.

## Procedure

1. (`ncn-mw#`) Search for the `VirtualService` object that corresponds to the desired service.

    The command below will list all external hostnames.

    ```bash
    kubectl get vs -A | grep -v '[*]'
    ```

    Example output:

    ```text
    NAMESPACE        NAME                              GATEWAYS                       HOSTS                                                          AGE
    istio-system     kiali                             [services/services-gateway]    [kiali-istio.cmn.SYSTEM_DOMAIN_NAME]                           2d16h
    nexus            nexus                             [services/services-gateway]    [packages.local registry.local nexus.cmn.SYSTEM_DOMAIN_NAME]   2d16h
    services         gitea-vcs-external                [services/services-gateway]    [vcs.cmn.SYSTEM_DOMAIN_NAME]                                   2d16h
    services         sma-grafana                       [services-gateway]             [sma-grafana.cmn.SYSTEM_DOMAIN_NAME]                           2d16h
    services         sma-kibana                        [services-gateway]             [sma-kibana.cmn.SYSTEM_DOMAIN_NAME]                            2d16h
    sysmgmt-health   cray-sysmgmt-health-alertmanager  [services/services-gateway]    [alertmanager.cmn.SYSTEM_DOMAIN_NAME]                          2d16h
    sysmgmt-health   cray-sysmgmt-health-grafana       [services/services-gateway]    [grafana.cmn.SYSTEM_DOMAIN_NAME]                               2d16h
    sysmgmt-health   cray-sysmgmt-health-vm-select     [services/services-gateway]    [vmselect.cmn.SYSTEM_DOMAIN_NAME]                              2d16h
    ```

1. (`ncn-mw#`) Inspect the `VirtualService` objects to learn the destination service and port.

    Use the `NAME` value returned in the previous step. The following example is for the `cray-sysmgmt-health-prometheus` service.

    ```bash
    kubectl get vs -n sysmgmt-health cray-sysmgmt-health-prometheus -o yaml
    ```

    Example output:

    ```yaml
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
      annotations:
      meta.helm.sh/release-name: cray-sysmgmt-health
      meta.helm.sh/release-namespace: sysmgmt-health
    creationTimestamp: "2024-10-15T12:59:14Z"
    generation: 1
    labels:
      app: cray-sysmgmt-health-vm-select
      app.kubernetes.io/instance: cray-sysmgmt-health
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: cray-sysmgmt-health
      app.kubernetes.io/version: 0.17.5
      helm.sh/chart: cray-sysmgmt-health-1.0.17-20241016103148_b40f1aa
    name: cray-sysmgmt-health-vm-select
    namespace: sysmgmt-health
    resourceVersion: "149049132"
    uid: d166065d-1b3b-4434-b25b-e95cb8940b01
   spec:
     gateways:
     - services/services-gateway
     - services/customer-admin-gateway
     hosts:
      - vmselect.cmn.mug.hpc.amslabs.hpecorp.net
      http:
      - match:
      - authority:
        exact: vmselect.cmn.mug.hpc.amslabs.hpecorp.net
     route:
       - destination:
          host: vmselect-vms
          port:
            number: 8481

    ```

    From the `VirtualService data`, it is straightforward to see how traffic will be routed. In this example, connections to `vmselect.cmn.SYSTEM_DOMAIN_NAME` will be routed to the
    `cray-sysmgmt-health-prometheus` service in the `sysmgmt-health` namespace on port 8481.

External DNS will now be connected to the backend service.
