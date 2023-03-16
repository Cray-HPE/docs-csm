# System Management Health

The primary goal of the System Management Health service is to enable system administrators to assess the health of
their system. Operators need to quickly and efficiently troubleshoot system issues as they occur and be confident that a
lack of issues indicates the system is operating normally. This service currently runs as a Helm chart on the system's
management Kubernetes cluster and monitors the health status of core system components, triggering alerts as potential
issues are observed. It uses Prometheus to aggregate metrics from etcd, Kubernetes, Istio, and Ceph, all of which
include support for the Prometheus API. The System Management Health service relies on the following tools:

- Prometheus is the standard cloud-native metrics and monitoring tool, which includes Alertmanager, a tool that handles
  alert duplication, silences, and notifications
- The Prometheus operator provides custom resource definitions \(CRDs\) that make it easy to operate Prometheus and
  Alertmanager instances, scrape metrics from service endpoints, and trigger alerts
- Grafana supports pulling data from Prometheus, and dashboards for system components are readily available from the
  open source community
- The `stable/kube-prometheus-stack` Helm chart integrates the Prometheus operator, Prometheus, Alertmanager, Grafana,
  node exporters \(DaemonSet\), and `kube-state-metrics` to provide a monitoring solution for Kubernetes clusters
- Istio supports service mesh tracing and observability using Jaeger and Kiali, respectively

The System Management Health service is intended to complement the System Monitoring Application \(SMA\) Framework, but
the two are currently not integrated. The System Management Health metrics are not available using the Telemetry API.
This service scrapes metrics from system components like Ceph, Kubernetes, and the hosts using node exporter,
`kube-state-metrics`, and `cadvisor`. The design is flexible and supports:

- Filtering metrics such that only those necessary to determine system health are aggregated to the top level; all
  metrics are currently aggregated—no filtering is implemented
- Independent retention and persistence settings based on needs for specific services; the current default configuration
  retains metrics for ten days at the top level and four hours at intermediate levels
- Component-specific tooling for more detailed visibility:
  - Grafana dashboards for Kubernetes
  - Grafana dashboards, Kiali, and Jaeger for Istio
  - Grafana dashboards for Ceph
