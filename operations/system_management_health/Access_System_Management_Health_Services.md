## Access System Management Health Services

All System Management Health services are exposed outside the cluster through the Keycloak gatekeeper and Istio's ingress gateway to enforce the authentication and authorization policies. The URLs to access these services are available on any system with CAN, BGP, MetalLB, and external DNS properly configured.

The `{{shasta_domain}}` value in the examples below is an Ansible variable defined as follows and is expected to be the systems' FQDN from the CAN.

```screen
ncn-m001# kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' \
| base64 -d | grep "external:"
      external: SHASTA_EXTERNAL_DOMAIN
```

This procedure enables administrators to set up the service and access its components via the Grafana and Kiali applications.

### Prerequisites

-   Access to the System Management Health web UIs is through Istio's ingress gateway and requires clients \(browsers\) to set the appropriate HTTP Host header to route traffic to the desired service.
-   This procedure requires administrative privileges on the workstation running the user's web browser.
-   The Customer Access Network \(CAN\), Border Gateway Protocol \(BGP\), MetalLB, and external DNS are properly configured.

### Procedure

1.  Access any System Management Health service with the provided links.

    When accessing the URLs listed below, it will be necessary to accept one or more browser security warnings in order to proceed to the login screen and navigate through the application after successfully logging in. The details of the security warning will indicate that a self-signed certificate/unknown issuer is being used for the site. Support for incorporation of certificates from Trusted Certificate Authorities is planned for a future release.

    -   **https://prometheus.\{\{shasta\_domain\}\}/**

        Central Prometheus instance scrapes metrics from Kubernetes, Ceph, and the hosts \(part of `prometheus-operator` Helm chart\).

        Prometheus generates alerts based on metrics and reports them to the alertmanager. The 'Alerts' link at the top of the page will show all of the inactive, pending, and firing alerts on the system. Clicking on any of the alerts will expand them, enabling users to use the 'Labels' data to discern the details of the alert. The details will also show the state of the alert, how long it has been active, and the value for the alert.

        For more information regarding the use of the Prometheus interface, see [https://prometheus.io/docs/prometheus/latest/getting\_started/](https://prometheus.io/docs/prometheus/latest/getting_started/).

        Some alerts may be falsely triggering whether based on alerts which will be improved in the future or alerts related to whether all software products have been installed yet. See [Troubleshoot Prometheus Alerts](operations/system_management_health/Troubleshoot_Prometheus_Alerts.md)

    -   **https://alertmanager.\{\{shasta\_domain\}\}/**

        Central Alertmanager instance that manages prometheus alerts.

        The alertmanager manages the alerts it receives and generates notifications to users or applications. For more information about `alert-manager`, refer to the following documentation: [https://prometheus.io/docs/prometheus/latest/getting\_started/](https://prometheus.io/docs/prometheus/latest/getting_started/).

        Some alerts may be falsely triggering whether based on alerts which will be improved in the future or alerts related to whether all software products have been installed yet. See [Troubleshoot Prometheus Alerts](operations/system_management_health/Troubleshoot_Prometheus_Alerts.md)

    -   **https://grafana.\{\{shasta\_domain\}\}/**

        Central Grafana instance that includes numerous dashboards for visualizing metrics from prometheus and prometheus-istio.

        For more information about Grafana's features and dashboard creation, please see the online documentation here: [https://grafana.com/docs/grafana/latest/](https://grafana.com/docs/grafana/latest/).

        For a description of the Grafana Panel: [https://grafana.com/docs/grafana/latest/features/panels/panels/](https://grafana.com/docs/grafana/latest/features/panels/panels/).

        For a description of the Grafana Dashboard: [https://grafana.com/docs/grafana/latest/features/dashboard/dashboards/](https://grafana.com/docs/grafana/latest/features/dashboard/dashboards/).

    -   **https://kiali-istio.\{\{shasta\_domain\}\}/**

        Kiali provides real-time introspection into the Istio service mesh using metrics from prometheus-istio and traces from jaeger-istio.

        For more information about the features of this interface, refer to the following documentation: [https://kiali.io/documentation/](https://kiali.io/documentation/).

    -   **https://jaeger-istio.\{\{shasta\_domain\}\}/**

        Jaeger provides distributed tracing of requests across micro-services based on headers automatically injected by Envoy.

        For more information regarding the `jaeger-istio` front end/UI configuration, refer to the online documentation \([https://www.jaegertracing.io/](https://www.jaegertracing.io/)\). Click on the 'Docs' section to get more information around the Jaeger Frontend/UI.

    Additional components are also exposed, though only for convenience. Do not rely on these components to always be available:

    -   **https://prometheus-istio.\{\{shasta\_domain\}\}/**

        Prometheus instance that collects Istio metrics \(included as part of `istio` Helm chart\).

        For more information regarding the use of the Prometheus interface, see [https://prometheus.io/docs/alerting/overview/](https://prometheus.io/docs/alerting/overview/).


