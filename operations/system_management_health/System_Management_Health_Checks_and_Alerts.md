# System Management Health Checks and Alerts

A health check corresponds to a VMalert query against metrics aggregated to the VMalert instance. Core platform
components like Kubernetes and Istio collect service-related metrics by default, which enables the System Management
Health service to implement generic service health checks without custom instrumentation. Health checks are intended to
be coarse-grained and comprehensive, as opposed to fine-grained and exhaustive. Health checks related to infrastructure
adhere to the Utilization Saturation Errors \(USE\) method whereas services follow the Rate Errors Duration \(RED\)
method.

VMalert alerting rules periodically evaluate health checks and trigger alerts to Alertmanager, which manages
silencing, inhibition, aggregation, and sending out notifications. Alertmanager supports a number of notification
options, but the most relevant ones are listed below:

- Email - Sends notification emails periodically regarding alerts
- Slack - Publishes notifications to a Slack channel
- Webhook- Send an HTTP request to a configurable URL \(requires custom integration\)

Similar to VictoriaMetrics, alerts use labels to identify a particular dimensional instantiation, and the
Alertmanager dashboard enables operators to preemptively silence alerts based on them.

## Check Active Alerts from NCNs

VMalert includes the `api/v1/alerts` endpoint, which returns a JSON object containing the active alerts. From a
non-compute node \(NCN\), can connect to `vmalert-vms` directly and bypass
service authentication and authorization.

Obtain the cluster IP address:

```bash
kubectl -n sysmgmt-health get svc cray-sysmgmt-health-kube-p-prometheus
```

Example output:

```text
NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
vmalert-vms   ClusterIP   10.21.216.162   <none>        8080/TCP   2d14h
```

Get active alerts, which includes `KubeletTooManyPods` if it is going off:

```bash
curl 10.21.216.162:8080/api/v1/alerts | jq . | grep -B 10 -A 20 KubePersistentVolumeInodesFillingUp
```

Example output:

```json
{
 
  "state": "firing",
        "name": "KubePersistentVolumeInodesFillingUp",
        "value": "0",
        "labels": {
          "alertgroup": "kubernetes-storage",
          "alertname": "KubePersistentVolumeInodesFillingUp",
          "beta_kubernetes_io_arch": "amd64",
          "beta_kubernetes_io_os": "linux",
          "cluster": "cluster-name",
          "group": "prometheus",
          "instance": "ncn-w010",
          "job": "kubelet",
```

In the example above, the alert actually indicates it is getting close to the limit, but the value included in the alert
is the actual number of pods on `ncn-w003`.

**Troubleshooting:** If an alert titled `KubeCronJobRunning` is encountered, this could be an indication that a
Kubernetes cronjob is misbehaving. The Labels section under the firing alert will indicate the name of the cronjob that
is taking longer than expected to complete. Refer to the "CHECK CRON JOBS" header in
the [Power On and Start the Management Kubernetes Cluster](../power_management/Power_On_and_Start_the_Management_Kubernetes_Cluster.md)
procedure for instructions on how to troubleshoot the cronjob, as well as how to restart \(export and reapply\) the
cronjob.
