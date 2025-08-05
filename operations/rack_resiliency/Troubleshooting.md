# Troubleshooting Rack Resiliency(RR)

This page contains general Rack Resiliency troubleshooting topics.

* [Cray CLI tool](#cray-cli-tool)
  * [Wrong critical service type](#wrong-critical-service-type)
* [Resiliency Monitoring Service](#resiliency-monitoring-service-rms)
  * [Steps to view RMS logs](#steps-to-view-rms-logs)
  * [Interpreting RMS logs](#interpreting-rms-logs)
    * [State change notification from HMNFD](#state-change-notification-from-hmnfd)
    * [Node failure](#node-failure)
    * [Rack failure](#rack-failure)
    * [Status of Ceph](#status-of-ceph)
    * [Critical services events](#critical-services-events)
      * [Imbalance of services](#imbalance-of-services)
      * [Status of service](#status-of-service)
      * [Service not found](#service-not-found)
      * [Unable to register for notification](#unable-to-register-for-notification)
* [Critical Services `Healthcheck`](#critical-services-healthcheck)
  * [List the status of all the critical services](#1-list-the-status-of-all-the-critical-services)
  * [Get detailed status for a specific critical service](#2-get-detailed-status-for-a-specific-critical-service)
* [Getting details about Resiliency Monitoring Service (RMS)](#getting-details-about-resiliency-monitoring-service-rms)

## Cray CLI tool

The Cray CLI is used to get information related to multiple components of Rack Resiliency. Use the following command for more information on RR support:

```bash
(ncn-mw#) cray rrs --help
```
### Wrong critical service type

If a new critical service of type other than 'Deployment' or 'StatefulSet' is added through Cray CLI then the following error is encountered.

"Error: Bad Request: Invalid request body: 1 validation error for `ValidateCriticalServiceCmStaticType`"

Example command:

```bash
(ncn-mw#) cray rrs criticalservices update --from-file file.json
```
Example output:

```text
Usage: cray rrs criticalservices update [OPTIONS]
Try 'cray rrs criticalservices update -h' for help.

Error: Bad Request: Invalid request body: 1 validation error for ValidateCriticalServiceCmStaticType
critical_service_cm_static_type.critical_services.kube-proxy.type
  Input should be 'Deployment' or 'StatefulSet' [type=literal_error, input_value='DaemonSet', input_type=str]
    For further information visit https://errors.pydantic.dev/2.11/v/literal_error
```

## Resiliency Monitoring Service (RMS)

To monitor and debug RMS, check the logs of the `cray-rrs` Kubernetes pod running in the `rack-resiliency` namespace. Follow the steps below:

### Steps to view RMS logs

1. Get the `cray-rrs` pod

```bash
(ncn-mw#) RRS_POD=$(kubectl get pods -n rack-resiliency -l app.kubernetes.io/instance=cray-rrs -o custom-columns=:.metadata.name --no-headers); echo "${RRS_POD}"
```

2. Check Resiliency Monitoring Logs

```bash
(ncn-mw#) kubectl logs $RRS_POD -c cray-rrs-rms -n rack-resiliency
```

### Interpreting RMS logs

#### State change notification from HMNFD

  ```text
  2025-06-26 12:49:59,725 - INFO in rms - Notification received from HMNFD 2025-06-26 12:49:59,725 - WARNING in rms - Components '['x3000c0s11b0n0']' are changed to Off state.
  ```

* Cause: The node(s) were shutdown or powered off.
* Effect: This leads to critical service redistribution based on `Kyverno` policy.
* Recovery: Power on the node(s).


#### Node failure

  ```text
  2025-06-26 12:49:59,997 - INFO in rms - Some nodes in rack x3000 are down. Failed nodes: ['x3000c0s11b0n0']
  ```

* Cause: The node(s) were shutdown or powered off.
* Effect: This leads to critical service redistribution based on `Kyverno` policy.
* Recovery: Power on the node(s).

#### Rack failure

  ```text
  2025-06-26 12:49:59,997 - INFO in rms - All the nodes in the rack x3000 are not healthy - RACK FAILURE
  ```

* Cause: All the nodes in the rack were shutdown or powered off.
* Effect: This leads to critical service redistribution based on `Kyverno` policy.
* Recovery: Power on the all the nodes in the rack.

#### Status of Ceph

  ```text
  ...
  2025-06-26 12:51:03,661 - WARNING in lib_rms - 1 out of 3 ceph nodes are not healthy
  2025-06-26 12:51:05,069 - WARNING in lib_rms - CEPH is not healthy with health status as HEALTH_WARN
  2025-06-26 12:51:05,069 - WARNING in lib_rms - CEPH PGs are in degraded state, but recovery is not happening
  2025-06-26 12:51:06,341 - WARNING in lib_rms - Service alertmanager running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,341 - WARNING in lib_rms - Service crash running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,341 - WARNING in lib_rms - Service mds.admin-tools running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service mds.cephfs running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service mgr running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service mon running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service node-exporter running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service osd.all-available-devices running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service prometheus running on ncn-s002 is in host is offline state
  2025-06-26 12:51:06,342 - WARNING in lib_rms - Service rgw.site1 running on ncn-s002 is in host is offline state
  ```

* Cause: The storage node was shutdown or powered off.
* Effect: This leads to Ceph storage becoming unhealthy.
* Recovery: Power on the node and wait for Ceph to restore.

#### Critical services events

##### Imbalance of services

```text
2025-06-30 07:02:36,235 - WARNING in lib_rms - list of imbalanced services are - ['istiod']
```

* Cause: Due to node failure the pod are not spread equally across zones.
* Effect: This leads to danger of losing multiple replicas if another node failure happens.
* Recovery: Ensure sufficient resources(CPU and memory) are available in each zone so that pods can be equally distributed.

##### Status of service

```text
2025-06-30 07:02:34,906 - WARNING in lib_rms - Deployment 'cray-capmc' in namespace 'services' is not ready. Only 1 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,036 - WARNING in lib_rms - StatefulSet 'cray-console-data-postgres' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,057 - WARNING in lib_rms - StatefulSet 'cray-console-node' in namespace 'services' is not ready. Only 1 replicas are ready out of 2 desired replicas
2025-06-30 07:02:35,118 - WARNING in lib_rms - StatefulSet 'cray-dhcp-kea-postgres' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,249 - WARNING in lib_rms - StatefulSet 'cray-hbtd-bitnami-etcd' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,291 - WARNING in lib_rms - StatefulSet 'cray-hmnfd-bitnami-etcd' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,314 - WARNING in lib_rms - StatefulSet 'cray-keycloak' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,418 - WARNING in lib_rms - StatefulSet 'cray-power-control-bitnami-etcd' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,541 - WARNING in lib_rms - StatefulSet 'cray-spire-postgres' in namespace 'spire' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,562 - WARNING in lib_rms - StatefulSet 'cray-spire-server' in namespace 'spire' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,601 - WARNING in lib_rms - StatefulSet 'cray-vault' in namespace 'vault' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,700 - WARNING in lib_rms - StatefulSet 'hpe-slingshot-vnid' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:35,830 - WARNING in lib_rms - Deployment 'istiod' in namespace 'istio-system' is not ready. Only 3 replicas are ready out of 8 desired replicas
2025-06-30 07:02:35,851 - WARNING in lib_rms - StatefulSet 'keycloak-postgres' in namespace 'services' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:36,141 - WARNING in lib_rms - StatefulSet 'slurmdb-pxc' in namespace 'user' is not ready. Only 2 replicas are ready out of 3 desired replicas
2025-06-30 07:02:36,234 - WARNING in lib_rms - list of partially configured services are - ['cray-capmc', 'cray-console-data-postgres', 'cray-console-node', 'cray-dhcp-kea-postgres', 'cray-hbtd-bitnami-etcd', 'cray-hmnfd-bitnami-etcd', 'cray-keycloak', 'cray-power-control-bitnami-etcd', 'cray-spire-postgres', 'cray-spire-server', 'cray-vault', 'hpe-slingshot-vnid', 'istiod', 'keycloak-postgres', 'slurmdb-pxc']
2025-06-30 07:02:36,235 - WARNING in lib_rms - list of unconfigured services are - ['cilium-operator', 'cray-dvs-mqtt-ss', '`Kyverno`-cleanup-controller', '`Kyverno`-reports-controller', 'k8s-zone-api', 'kube-multus-ds']
```

* Cause: Due to node failure the pod are not spread equally across zones.
* Effect: This leads to danger of losing multiple replicas if another node failure happens.
* Recovery: Ensure sufficient resources(CPU and memory) are available in each zone so that pods can be equally distributed and to make StatefulSet configured, it need to be rollout restarted.

##### Service not found

```text
2025-06-30 07:02:36,233 - ERROR in lib_rms - Error fetching StatefulSet kube-multus-ds: Not Found
```

* Cause: Wrong service is added to critical service list or the service is not yet configured on system.
* Effect: This leads RMS to monitor unknown service.
* Recovery: Delete or modify the critical service.

#### Unable to register for notification

```text
[2025-05-26 11:49:25,744] ERROR in rms: Attempt 1 : Failed to fetch subscription list from hmnfd. Error: 503 Server Error: Service Unavailable for url: https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions
```

* Cause: The HMNFD service is nor running.
* Effect: This leads to RMS not receiving notifications from HMNFD.
* Recovery: Ensure HMNFD service is running.

## Critical Services `Healthcheck`

In order to check the health of critical services run the following commands:

### 1. List the status of all the critical services

```bash
  (`ncn-mw#`) cray rrs criticalservices status list
```

Example Output:

```text
    [critical_services.namespace]
    [[critical_services.namespace.kube-system]]
    name = "cilium-operator"
    type = "Deployment"
    status = "Configured"
    balanced = "true"

    [[critical_services.namespace.kube-system]]
    name = "coredns"
    type = "Deployment"
    status = "Configured"
    balanced = "true"

    [[critical_services.namespace.kube-system]]
    name = "sealed-secrets"
    type = "Deployment"
    status = "Configured"
    balanced = "true"

    [[critical_services.namespace.dvs]]
    name = "cray-activemq-artemis-operator-controller-manager"
    type = "Deployment"
    status = "Configured"
    balanced = "true"

    [[critical_services.namespace.dvs]]
    name = "cray-dvs-mqtt-ss"
    type = "StatefulSet"
    status = "PartiallyConfigured"
    balanced = "true"

    [[critical_services.namespace.services]]
    name = "cray-capmc"
    type = "Deployment"
    status = "Configured"
    balanced = "true"

    [[critical_services.namespace.services]]
    name = "cray-console-data"
    type = "Deployment"
    status = "Configured"
    balanced = "true"
```

This command returns information on the current state of every critical service. Specifically, for each service, it returns its status (e.g., balanced, no pods found) and the distribution of its pods across zones and nodes.

### 2. Get detailed status for a specific critical service

```bash
    (`ncn-mw#`) cray rrs criticalservices status describe <critical-service-name>
```

Example Output:

```text
    [critical_service]
    name = "cray-capmc"
    namespace = "services"
    type = "Deployment"
    status = "Configured"
    balanced = "true"
    configured_instances = 3
    currently_running_instances = 3
    [[critical_service.pods]]
    name = "cray-capmc-5cf667b54c-6xsm5"
    status = "Running"
    node = "ncn-w004"
    zone = "x3000"

    [[critical_service.pods]]
    name = "cray-capmc-5cf667b54c-hpwxb"
    status = "Running"
    node = "ncn-w002"
    zone = "x3001"

    [[critical_service.pods]]
    name = "cray-capmc-5cf667b54c-pww8p"
    status = "Running"
    node = "ncn-w003"
    zone = "x3002"
```
This command returns detailed pod information including pod names, nodes, statuses, and zones.

## Getting details about Resiliency Monitoring Service (RMS)

To know the startup time, last monitoring cycle timestamp, the polling intervals and the configured critical services it is necessary to [view the ConfigMap](ConfigMaps.md#2-veiwing-configmap). This helps to understand the various configuration parameters which control RMS behavior.

**Note**: It is recommended not to modify those configuration parameters without consulting HPE support.
