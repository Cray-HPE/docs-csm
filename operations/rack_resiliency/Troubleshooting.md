# Troubleshooting Rack Resiliency

This page contains general Rack Resiliency troubleshooting topics.

- [Cray CLI](#cray-cli)
    - [Wrong critical service type](#wrong-critical-service-type)
- [Resiliency Monitoring Service](#resiliency-monitoring-service-rms)
    - [Steps to view RMS logs](#steps-to-view-rms-logs)
    - [Interpreting RMS logs](#interpreting-rms-logs)
        - [State change notification from HMNFD](#state-change-notification-from-hmnfd)
        - [Node failure](#node-failure)
        - [Rack failure](#rack-failure)
        - [Status of Ceph](#status-of-ceph)
        - [Critical services events](#critical-services-events)
            - [Service imbalance](#service-imbalance)
            - [Service status](#service-status)
            - [Service not found](#service-not-found)
            - [Unable to register for notification](#unable-to-register-for-notification)
    - [Getting details about RMS](#getting-details-about-rms)
- [Critical services health check](#critical-services-health-check)
- [Deployment status](#cray-rrs-pod-is-in-init-state)
- [Node movement troubleshooting](#physical-movement-of-nodes-from-one-rack-to-another)

## Cray CLI

(`ncn-mw#`) The Cray CLI is used to interact with multiple components of Rack Resiliency. Use the following command for usage information:

```bash
cray rrs --help
```

### Wrong critical service type

If a new critical service of type other than 'Deployment' or 'StatefulSet' is added through the Cray CLI,
then an error is encountered.

(`ncn-mw#`) For example:

```bash
cray rrs criticalservices update --from-file file.json
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

1. (`ncn-mw#`) Get the `cray-rrs` pod name.

   ```bash
   RRS_POD=$(kubectl get pods -n rack-resiliency \
     -l app.kubernetes.io/instance=cray-rrs \
     -o custom-columns=:.metadata.name \
     --no-headers); echo "${RRS_POD}"
   ```

2. (`ncn-mw#`) View its RMS container logs.

   ```bash
   kubectl logs "${RRS_POD}" -c cray-rrs-rms -n rack-resiliency
   ```

### Interpreting RMS logs

#### State change notification from HMNFD

Example log entry for a state change notification from the
[Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd):

```text
2025-06-26 12:49:59,725 - INFO in rms - Notification received from HMNFD 2025-06-26 12:49:59,725 - WARNING in rms - Components '['x3000c0s11b0n0']' are changed to Off state.
```

- Cause: The node(s) were shutdown or powered off.
- Effect: This leads to critical service redistribution based on `Kyverno` policy.
- Recovery: Power on the node(s).

#### Node failure

Example log entry reporting a node being down:

```text
2025-06-26 12:49:59,997 - INFO in rms - Some nodes in rack x3000 are down. Failed nodes: ['x3000c0s11b0n0']
```

- Cause: The node(s) were shutdown or powered off.
- Effect: This leads to critical service redistribution based on `Kyverno` policy.
- Recovery: Power on the node(s).

#### Rack failure

Example log entry reporting a rack health issue:

```text
2025-06-26 12:49:59,997 - INFO in rms - All the nodes in the rack x3000 are not healthy - RACK FAILURE
```

- Cause: All the nodes in the rack were shutdown or powered off.
- Effect: This leads to critical service redistribution based on `Kyverno` policy.
- Recovery: Power on the all the nodes in the rack.

#### Status of Ceph

Example log entries reporting Ceph status:

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

- Cause: The storage node was shutdown or powered off.
- Effect: This leads to Ceph storage becoming unhealthy.
- Recovery: Power on the node and wait for Ceph to restore.

#### Critical services events

##### Service imbalance

Example log entry reporting an imbalanced service:

```text
2025-06-30 07:02:36,235 - WARNING in lib_rms - list of imbalanced services are - ['istiod']
```

- Cause: Due to node failure the pod are not spread equally across zones.
- Effect: This leads to danger of losing multiple replicas if another node failure happens.
- Recovery: Ensure sufficient resources(CPU and memory) are available in each zone so that pods can be equally distributed.

##### Service status

Example log entries reporting on the status of a service:

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

- Cause: Due to node failure the pod are not spread equally across zones.
- Effect: This leads to danger of losing multiple replicas if another node failure happens.
- Recovery: Ensure sufficient resources(CPU and memory) are available in each zone so that pods can be equally distributed and to make StatefulSet configured, it need to be rollout restarted.

##### Service not found

Example log entry reporting that a critical service was not found:

```text
2025-06-30 07:02:36,233 - ERROR in lib_rms - Error fetching StatefulSet kube-multus-ds: Not Found
```

- Cause: Wrong service is added to critical service list or the service is not yet configured on system.
- Effect: This leads RMS to monitor unknown service.
- Recovery: Delete or modify the critical service.

#### Unable to register for notification

Example log entry reporting a failure to register with HMNFD:

```text
[2025-05-26 11:49:25,744] ERROR in rms: Attempt 1 : Failed to fetch subscription list from hmnfd. Error: 503 Server Error: Service Unavailable for url: https://api-gw-service-nmn.local/apis/hmnfd/hmi/v2/subscriptions
```

- Cause: The HMNFD service is not running.
- Effect: RMS is not receiving notifications from HMNFD.
- Recovery: Ensure that the HMNFD service is running.

### Getting details about RMS

To know the startup time, last monitoring cycle timestamp, the polling intervals and the configured critical services it is necessary to [view the ConfigMap](ConfigMaps.md#viewing-configmap).
This helps to understand the various configuration parameters which control RMS behavior.

**Note**: It is recommended not to modify those configuration parameters without consulting HPE support.

## Critical services health check

The health of the critical services can be checked by listing and describing them using the
RRS API or CLI. See [Manage Critical Services](Manage_Critical_Services.md).

## `cray-rrs` pod is in `init` state

When rack resiliency is disabled the status if the `cray-rrs` deployment continues to be in `init` state.

This is an expected behavior as the `cray-rrs` deployment waits in case the following three conditions are not met:

1. Rack Resiliency is not enabled
2. [Zones](Zones.md) are not configured(Kubernetes or Ceph)
3. [ConfigMaps](ConfigMaps.md) not present

Check the status of pod for `cray-rrs` deployment:

```bash
kubectl get pod -n rack-resiliency
```

```text
NAME                        READY   STATUS     RESTARTS   AGE
cray-rrs-6c5585cfdf-lmctt   0/2     Init:0/2   0          6d5h
```

### 1. Rack Resiliency is not enabled

This can be confirmed by checking the logs of the `cray-rrs-check` container.

```bash
kubectl logs -n rack-resiliency cray-rrs-6c5585cfdf-lmctt cray-rrs-check
```

```text
/etc/ssh/sshd_config line 32: Unsupported option UsePAM
2025-09-18 22:06:22,589 - INFO in wait: Checking Rack Resiliency enablement and Kubernetes/CEPH zone creation...
2025-09-18 22:06:22,815 - INFO in wait: 'spec.kubernetes.services.rack-resiliency.enabled' value in customizations.yaml is: False
2025-09-18 22:06:22,817 - INFO in wait: Rack Resiliency is disabled.
```

### 2. Zones are not configured(Kubernetes or Ceph)

This can be confirmed by checking the logs of the `cray-rrs-check` container.

```bash
kubectl logs -n rack-resiliency cray-rrs-6c5585cfdf-lmctt cray-rrs-check
```

```text
/etc/ssh/sshd_config line 32: Unsupported option UsePAM
2025-09-29 15:20:19,675 - INFO in wait: Checking Rack Resiliency enablement and Kubernetes/CEPH zone creation...
2025-09-29 15:20:19,884 - INFO in wait: 'spec.kubernetes.services.rack-resiliency.enabled' value in customizations.yaml is: True
2025-09-29 15:20:19,885 - INFO in wait: Rack resiliency is enabled.
2025-09-29 15:20:19,885 - INFO in wait: Checking zoning for Kubernetes and CEPH nodes...
2025-09-29 15:20:19,964 - ERROR in lib_rms: No K8s topology zone present
2025-09-29 15:20:19,966 - INFO in wait: Kubernetes zones are not created.
```

### 3. ConfigMaps not present

This can be confirmed by checking the logs of the `cray-rrs-init` container.

```bash
kubectl logs -n rack-resiliency cray-rrs-6c5585cfdf-lmctt cray-rrs-init
```

```text
/etc/ssh/sshd_config line 32: Unsupported option UsePAM
2025-09-30 07:26:28,705 - WARNING in lib_configmap: Lock ConfigMap rrs-mon-dynamic-lock does not exist in namespace rack-resiliency; nothing to release
2025-09-30 07:26:28,717 - WARNING in lib_configmap: Lock ConfigMap rrs-mon-static-lock does not exist in namespace rack-resiliency; nothing to release
2025-09-30 07:26:28,718 - INFO in lib_configmap: [ad365f4c] Fetching ConfigMap rrs-mon-dynamic from namespace rack-resiliency
2025-09-30 07:26:28,735 - INFO in init: Reinitializing the Rack Resiliency Service.This could happen if previous RRS pod has been terminated
2025-09-30 07:26:28,736 - INFO in init: RMS is in init state. Resetting to init state
2025-09-30 07:26:28,770 - INFO in lib_configmap: Updating ConfigMap rrs-mon-dynamic in namespace rack-resiliency
2025-09-30 07:26:28,810 - WARNING in lib_configmap: Lock ConfigMap rrs-mon-dynamic-lock does not exist in namespace rack-resiliency; nothing to release
2025-09-30 07:26:28,811 - INFO in lib_configmap: ConfigMap rrs-mon-dynamic in namespace rack-resiliency updated successfully
2025-09-30 07:26:28,886 - INFO in init: Retrieving zone information and status of k8s and CEPH nodes
2025-09-30 07:26:32,785 - INFO in lib_rms: CEPH is healthy
2025-09-30 07:26:34,292 - INFO in init: RMS pod is running on node: ncn-w006 in rack x3000c0s9b0n0 under zone zone3
2025-09-30 07:26:34,293 - INFO in lib_configmap: [85f28042] Fetching ConfigMap rrs-mon-static from namespace rack-resiliency
2025-09-30 07:26:34,304 - ERROR in lib_configmap: [85f28042] API error fetching ConfigMap
Traceback (most recent call last):
  File "/app/src/lib/lib_configmap.py", line 319, in read_configmap
    config_map = v1.read_namespaced_config_map(
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/kubernetes/client/api/core_v1_api.py", line 23231, in read_namespaced_config_map
    return self.read_namespaced_config_map_with_http_info(name, namespace, **kwargs)  # noqa: E501
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/kubernetes/client/api/core_v1_api.py", line 23318, in read_namespaced_config_map_with_http_info
    return self.api_client.call_api(
           ^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/kubernetes/client/api_client.py", line 348, in call_api
    return self.__call_api(resource_path, method,
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/kubernetes/client/api_client.py", line 180, in __call_api
    response_data = self.request(
                    ^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/kubernetes/client/api_client.py", line 373, in request
    return self.rest_client.GET(url,
           ^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/kubernetes/client/rest.py", line 244, in GET
    return self.request("GET", url,
           ^^^^^^^^^^^^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/kubernetes/client/rest.py", line 238, in request
    raise ApiException(http_resp=r)
kubernetes.client.exceptions.ApiException: (404)
Reason: Not Found
HTTP response headers: HTTPHeaderDict({'Audit-Id': '4464c112-3ebe-4187-ad92-37455e2adc01', 'Cache-Control': 'no-cache, private', 'Content-Type': 'application/json', 'X-Kubernetes-Pf-Flowschema-Uid': 'a48f299c-32b4-46dd-b465-b67aed410a1d', 'X-Kubernetes-Pf-Prioritylevel-Uid': '8de31b72-3590-42e5-909f-b0b2aa8b8245', 'Date': 'Tue, 30 Sep 2025 07:26:34 GMT', 'Content-Length': '208'})
HTTP response body: {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"configmaps \"rrs-mon-static\" not found","reason":"NotFound","details":{"name":"rrs-mon-static","kind":"configmaps"},"code":404}


2025-09-30 07:26:34,318 - ERROR in init: Could not read static configmap rrs-mon-static: API error: (404)
Reason: Not Found
HTTP response headers: HTTPHeaderDict({'Audit-Id': '4464c112-3ebe-4187-ad92-37455e2adc01', 'Cache-Control': 'no-cache, private', 'Content-Type': 'application/json', 'X-Kubernetes-Pf-Flowschema-Uid': 'a48f299c-32b4-46dd-b465-b67aed410a1d', 'X-Kubernetes-Pf-Prioritylevel-Uid': '8de31b72-3590-42e5-909f-b0b2aa8b8245', 'Date': 'Tue, 30 Sep 2025 07:26:34 GMT', 'Content-Length': '208'})
HTTP response body: {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"configmaps \"rrs-mon-static\" not found","reason":"NotFound","details":{"name":"rrs-mon-static","kind":"configmaps"},"code":404}


2025-09-30 07:26:34,318 - INFO in init: Updating rms state to init_fail because of initialization failure
```


## Physical movement of node(s) from one rack to another

When the nodes are moved physically from one rack to another using the [procedure](../node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md), after completing the procedure always rollout restart the `cray-rrs` deployment.

```bash
(ncn-mw) kubectl rollout restart deployment -n rack-resiliency cray-rrs
```
