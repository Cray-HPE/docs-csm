# Access System Management Health Services

All System Management Health services are exposed outside the cluster through the OAuth2 Proxy and Istio's ingress gateway to enforce the authentication and authorization policies. The URLs
to access these services are available on any system with CMN, BGP, MetalLB, and external DNS properly configured.

- [Prerequisites](#prerequisites)
- [System domain name](#system-domain-name)
- [System Management Health service links](#system-management-health-service-links)
  - [Prometheus](#prometheus)
  - [Thanos] (#thanos)
  - [Alertmanager](#alertmanager)
  - [Grafana](#grafana)
  - [Kiali](#kiali)

## Prerequisites

- Access to the System Management Health web UIs is through Istio's ingress gateway and requires clients \(browsers\) to set the appropriate HTTP Host header to route traffic to the desired service.
- Access to these URLs may require administrative privileges on the workstation running the user's web browser.
- The Customer Management Network \(CMN\), Border Gateway Protocol \(BGP\), MetalLB, and external DNS are properly configured.

## System domain name

The `SYSTEM_DOMAIN_NAME` value found in some of the URLs on this page is expected to be the system's fully qualified domain name (FQDN).

(`ncn-mw#`) The FQDN can be found by running the following command on any Kubernetes NCN.

```bash
kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | yq r - spec.network.dns.external
```

Example output:

```text
system..hpc.amslabs.hpecorp.net
```

Be sure to modify the example URLs on this page by replacing `SYSTEM_DOMAIN_NAME` with the actual value found using the above command.

## System Management Health service links

Access any System Management Health service with the provided links.

When accessing the URLs listed below, it will be necessary to accept one or more browser security warnings in order to proceed to the login screen and navigate through the application after successfully
logging in. The details of the security warning will indicate that a self-signed certificate/unknown issuer is being used for the site. Support for incorporation of certificates from Trusted Certificate
Authorities is planned for a future release.

### Prometheus

URL: `https://prometheus.cmn.SYSTEM_DOMAIN_NAME/`

Central Prometheus instance scrapes metrics from Kubernetes, Ceph, and the hosts (part of `kube-prometheus-stack` Helm chart).

Prometheus generates alerts based on metrics and reports them to the Alertmanager. The 'Alerts' link at the top of the page will show all of the inactive, pending, and firing alerts on the system.
Clicking on any of the alerts will expand them, enabling users to use the 'Labels' data to discern the details of the alert. The details will also show the state of the alert, how long it has been
active, and the value for the alert.

For more information regarding the use of the Prometheus interface, see
[Getting Started/](https://prometheus.io/docs/prometheus/latest/getting_started/) in the Prometheus online documentation.

Some alerts may be falsely triggered. This occurs if they are alerts which will be improved in the future, or if they are alerts impacted by whether all software products have been installed yet.
See [Troubleshoot Prometheus Alerts](Troubleshoot_Prometheus_Alerts.md).

### Thanos

URL: `https://thanos.cmn.SYSTEM_DOMAIN_NAME/`

Thanos is a set of components that can be composed into a highly available, multi Prometheus metric system with potentially unlimited storage capacity, if your Object Storage allows for it.
It leverages the Prometheus 2.0 storage format to cost-efficiently store historical metric data in any object storage while retaining fast query latencies.
Additionally, it provides a global query view across all Prometheus installations and can merge data from Prometheus HA pairs.

For more information regarding the use of the Thanos interface, see
[Getting Started/](https://thanos.io/tip/thanos/getting-started.md/) in the thanos online documentation.

### Alertmanager

URL: `https://alertmanager.cmn.SYSTEM_DOMAIN_NAME/`

Central Alertmanager instance that manages Prometheus alerts.

The Alertmanager manages the alerts it receives and generates notifications to users or applications. For more information about `alert-manager`, see
[Getting Started/](https://prometheus.io/docs/prometheus/latest/getting_started/) in the Prometheus online documentation.

Some alerts may be falsely triggered. This occurs if they are alerts which will be improved in the future, or if they are alerts impacted by whether all software products have been installed yet. See
[Troubleshoot Prometheus Alerts](Troubleshoot_Prometheus_Alerts.md).

### Grafana

URL: `https://grafana.cmn.SYSTEM_DOMAIN_NAME/`

Central Grafana instance that includes numerous dashboards for visualizing metrics from `prometheus` and `prometheus-istio`.

For more information, see the Grafana online documentation:

- For more information about Grafana's features and dashboard creation, see [the latest Grafana online documentation](https://grafana.com/docs/grafana/latest/).
- For a description of the Grafana Panel, see [Grafana panels](https://grafana.com/docs/grafana/latest/features/panels/panels/).
- For a description of the Grafana Dashboard, see [Grafana dashboards/](https://grafana.com/docs/grafana/latest/features/dashboard/dashboards/).

### Kiali

URL: `https://kiali-istio.cmn.SYSTEM_DOMAIN_NAME/`

Kiali provides real-time introspection into the Istio service mesh using metrics and traces from Istio.

For more information about the features of this interface, refer to the [Kiali online documentation/](https://kiali.io/documentation/).
