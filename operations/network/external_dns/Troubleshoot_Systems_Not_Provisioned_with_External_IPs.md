## Troubleshoot Connectivity to Services with External IPs

Systems that do not support CAN will not have services provisioned with external IPs on CAN. Kubernetes will report a `<pending>` status for the external IP of the service experiencing connectivity issues.

If SSH access to a non-compute node \(NCN\) is available, it is possible to override resolution of external hostnames and forward local ports into the cluster for the cluster IP of the corresponding service.

**Warning:** This will bypass the Keycloak gatekeeper and Istio ingress gateway, which handle authentication and authorization.

Enable systems without CAN to provision services with external hostnames.

### Prerequisites

The Customer Access Network \(CAN\) is not supported on the system.

### Procedure

1.  Search for the VirtualService object that corresponds to the desired service.

    The command below will list all external hostnames.

    ```bash
    ncn-w001# kubectl get vs -A | grep -v '[*]'
    NAMESPACE        NAME                              GATEWAYS                       HOSTS                                                      AGE
    istio-system     kiali                             [services/services-gateway]    [kiali-istio.SYSTEM_DOMAIN_NAME]                           2d16h
    istio-system     prometheus                        [services/services-gateway]    [prometheus-istio.SYSTEM_DOMAIN_NAME]                      2d16h
    istio-system     tracing                           [services/services-gateway]    [jaeger-istio.SYSTEM_DOMAIN_NAME]                          2d16h
    nexus            nexus                             [services/services-gateway]    [packages.local registry.local nexus.SYSTEM_DOMAIN_NAME]   2d16h
    services         gitea-vcs-external                [services/services-gateway]    [vcs.SYSTEM_DOMAIN_NAME]                                   2d16h
    services         sma-grafana                       [services-gateway]             [sma-grafana.SYSTEM_DOMAIN_NAME]                           2d16h
    services         sma-kibana                        [services-gateway]             [sma-kibana.SYSTEM_DOMAIN_NAME]                            2d16h
    sysmgmt-health   cray-sysmgmt-health-alertmanager  [services/services-gateway]    [alertmanager.SYSTEM_DOMAIN_NAME]                          2d16h
    sysmgmt-health   cray-sysmgmt-health-grafana       [services/services-gateway]    [grafana.SYSTEM_DOMAIN_NAME]                               2d16h
    sysmgmt-health   cray-sysmgmt-health-prometheus    [services/services-gateway]    [prometheus.SYSTEM_DOMAIN_NAME]                            2d16h
    ```

2.  Lookup the cluster IP and port for service.

    The example below is for the cray-sysmgmt-health-promet-prometheus service.

    ```bash
    ncn-w001# kubectl -n sysmgmt-health get service cray-sysmgmt-health-promet-prometheus
    NAME                                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    cray-sysmgmt-health-promet-prometheus   ClusterIP   10.25.124.159   <none>        9090/TCP   23h
    ```

3.  Setup port forwarding from a laptop or workstation to access the service.

    Use the cluster IP and port for the service obtained in the previous step. If the port is unprivileged, use the same port number on the local side.

    Replace the cluster IP, port, and system name values in the example below.

    ```bash
    $ ssh -L 9090:10.22.78.59:9090 root@SYSTEM_NCN_DOMAIN_NAME
    ```

4.  Visit http://localhost:9090/ in a laptop or workstation browser.


