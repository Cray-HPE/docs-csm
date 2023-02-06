# Post-Install Customizations

Post-install customizations may be needed as systems scale.
These customizations also need to persist across future installs or upgrades.
Not all resources can be customized post-install; common scenarios are documented in the following sections.

The following is a guide for determining where issues may exist, how to adjust the resources, and how to ensure the changes will persist.
Different values may be be needed for systems as they scale.

## `kubectl` events `OOMKilled`

Check to see if there are any recent out of memory events.

1. (`ncn#`) Check `kubectl` events to see if there are any recent out of memory events.

    ```bash
    kubectl get event -A | grep OOM
    ```

1. Log in to Grafana.

   ```text
   https://grafana.cmn.SYSTEM_DOMAIN_NAME/
   ```

1. Search for the "Kubernetes / Compute Resources / Pod" dashboard to view the memory utilization graphs over time for any pod that has been `OOMKilled`.

## Prometheus `CPUThrottlingHigh` alerts

Check Prometheus for recent `CPUThrottlingHigh` alerts.

1. Log in to Prometheus.

   ```text
   https://prometheus.cmn.SYSTEM_DOMAIN_NAME/
   ```

   1. Select the **Alert** tab.

   1. Scroll down to the alert for `CPUThrottlingHigh`.

1. Log in to Grafana.

   ```text
   https://grafana.cmn.SYSTEM_DOMAIN_NAME/
   ```

1. Search for the "Kubernetes / Compute Resources / Pod" dashboard to view the throttling graphs over time for any pod that is alerting.

## Grafana "Kubernetes / Compute Resources / Pod" dashboard

Use Grafana to investigate and analyze CPU throttling and memory usage.

1. Log in to Grafana.

   ```text
   https://grafana.cmn.SYSTEM_DOMAIN_NAME/
   ```

1. Search for the "Kubernetes / Compute Resources / Pod" dashboard.

1. Select the `datasource`, `namespace`, and `pod` based on the pod being examined.

   For example:

   ```yaml
   datasource: default
   namespace: sysmgmt-health
   pod: prometheus-cray-sysmgmt-health-promet-prometheus-0
   ```

### CPU throttling

1. Select the **CPU Throttling** drop-down to see the CPU Throttling graph for the pod during the selected time (from the top right).

1. Select the container (from the legends under the x axis).

1. Review the graph and adjust the `resources.limits.cpu` value as needed.

   The presence of CPU throttling does not always indicate a problem, but if a service is being slow or experiencing latency
   issues, adjusting `resources.limits.cpu` may be beneficial.

   For example:

   * If the pod is being throttled at or near 100% for any period of time, then adjustments are likely needed.
   * If the service's response time is critical, then adjusting the pod's resources to greatly reduce or eliminate any CPU throttling may be required.

   > **NOTE:** The `resources.requests.cpu` values are used by the Kubernetes scheduler to decide which node to place the pod on and do not impact CPU
   > throttling. The value of `resources.limits.cpu` can never be lower than the value of `resources.requests.cpu`.

### Memory usage

1. Select the **Memory Usage** drop-down to see the memory usage graph for the pod during the selected time (from the top right).

1. Select the container (from the legends under the x axis).

1. Determine the steady state memory usage by looking at the memory usage graph for the container.

   This is where the `resources.requests.memory` value should be minimally set.
   But more importantly, determine the spike usage for the container and set the `resources.limits.memory` value based on the spike values with some additional headroom.

## Common customization scenarios

* [Prerequisites](#prerequisites)
* [Prometheus pod is `OOMKilled` or CPU throttled](#prometheus-pod-is-oomkilled-or-cpu-throttled)
* [Postgres pods are `OOMKilled` or CPU throttled](#postgres-pods-are-oomkilled-or-cpu-throttled)
* [Scale `cray-bss` service](#scale-cray-bss-service)
* [Postgres PVC resize](#postgres-pvc-resize)
* [`cray-hms-hmcollector` pods are `OOMKilled`](#cray-hms-hmcollector-pods-are-oomkilled)

### Prerequisites

In order to apply post-install customizations to a system, the affected Helm chart must exist on the system so that the same chart version can be redeployed with the desired customizations.

This example unpacks the the `csm-1.0.0` tarball under `/root` and lists the Helm charts that are now on the system.
Set `PATH_TO_RELEASE` to the release directory where the `helm` directory exists.
`PATH_TO_RELEASE` will be used below when deploying a customization.

These unpacked files can be safely removed after the customizations are deployed through `loftsman ship` in the examples below.

(`ncn#`)

```bash
## This example assumes the csm-1.0.0 release is currently running and the csm-1.0.0.tar.gz has been pulled down under /root
cd /root
tar -xzf csm-1.0.0.tar.gz
rm csm-1.0.0.tar.gz
PATH_TO_RELEASE=/root/csm-1.0.0
ls $PATH_TO_RELEASE/helm
```

### Prometheus pod is `OOMKilled` or CPU throttled

Update resources associated with Prometheus in the `sysmgmt-health` namespace.
This example is based on what was needed for a system with 4000 compute nodes.
Trial and error may be needed to determine what is best for a given system at scale.

1. (`ncn#`) Get the current cached customizations.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. (`ncn#`) Get the current cached platform manifest.

   ```bash
   kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}'  > platform.yaml
   ```

1. (`ncn#`) Edit the customizations as desired by adding or updating `spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources`.

   ```bash
   yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.requests.cpu' --style=double '2'
   yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.requests.memory' '15Gi'
   yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.limits.cpu' --style=double '6'
   yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.limits.memory' '30Gi'
   ```

1. (`ncn#`) Check that the customization file has been updated.

   ```bash
   yq read customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources'
   ```

   Example output:

   ```yaml
   requests:
     cpu: "3"
     memory: 15Gi
   limits:
     cpu: "6"
     memory: 30Gi
   ```

1. Edit the `platform.yaml` to only include the `cray-sysmgmt-health` chart and all its current data.

   The resources specified above will be updated in the next step. The version may differ, because this is an example.

   ```yaml
   apiVersion: manifests/v1beta1
   metadata:
     name: platform
   spec:
     charts:
     - name: cray-sysmgmt-health
       namespace: sysmgmt-health
       values:
   .
   .
   .
       version: 0.12.0
   ```

1. (`ncn#`) Generate the manifest that will be used to redeploy the chart with the modified resources.

   ```bash
   manifestgen -c customizations.yaml -i platform.yaml -o manifest.yaml
   ```

1. (`ncn#`) Check that the manifest file contains the desired resource settings.

   ```bash
   yq read manifest.yaml 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-operator.prometheus.prometheusSpec.resources'
   ```

   Example output:

   ```yaml
   requests:
     cpu: "3"
     memory: 15Gi
   limits:
     cpu: "6"
     memory: 30Gi
   ```

1. (`ncn#`) Redeploy the same chart version but with the desired resource settings.

   ```bash
   loftsman ship --charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify that the pod restarts and that the desired resources have been applied.

   1. (`ncn#`) Watch the `prometheus-cray-sysmgmt-health-promet-prometheus-0` pod restart.

      ```bash
      watch "kubectl get pods -n sysmgmt-health -l prometheus=cray-sysmgmt-health-promet-prometheus"
      ```

      It may take about 10 minutes for the `prometheus-cray-sysmgmt-health-promet-prometheus-0` pod to terminate.
      It can be forced deleted if it remains in the terminating state:

      ```bash
      kubectl delete pod prometheus-cray-sysmgmt-health-promet-prometheus-0 --force --grace-period=0 -n sysmgmt-health
      ```

   1. (`ncn#`) Verify that the resource changes are in place.

      ```bash
      kubectl get pod prometheus-cray-sysmgmt-health-promet-prometheus-0 -n sysmgmt-health -o json | jq -r '.spec.containers[] | select(.name == "prometheus").resources'
      ```

1. (`ncn#`) **This step is critical.** Store the modified `customizations.yaml` file in the `site-init` repository in the customer-managed location.

   If this is not done, these changes will not persist in future installs or upgrades.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

### Postgres pods are `OOMKilled` or CPU throttled

Update resources associated with `spire-postgres` in the `spire` namespace.
This example is based on what was needed for a system with 4000 compute nodes.
Trial and error may be needed to determine what is best for a given system at scale.

A similar flow can be used to update the resources for `cray-sls-postgres`, `cray-smd-postgres`, or `gitea-vcs-postgres`.
Refer to the note at the end of this section for more details.

1. (`ncn#`) Get the current cached customizations.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. (`ncn#`) Get the current cached `sysmgmt` manifest.

   ```bash
   kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}'  > sysmgmt.yaml
   ```

1. (`ncn#`) Edit the customizations as desired by adding or updating `spec.kubernetes.services.spire.cray-service.sqlCluster.resources`.

   ```bash
   yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.requests.cpu' --style=double '4'
   yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.requests.memory' '4Gi'
   yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.limits.cpu' --style=double '8'
   yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.limits.memory' '8Gi'
   ```

1. (`ncn#`) Check that the customization file has been updated.

   ```bash
   yq read customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources'
   ```

   Example output:

   ```yaml
   requests:
     cpu: "4"
     memory: 4Gi
   limits:
     cpu: "8"
     memory: 8Gi
   ```

1. Edit the `sysmgmt.yaml` to only include the `spire` chart and all its current data.

   The resources specified above will be updated in the next step. The version may differ, because this is an example.

   ```yaml
   apiVersion: manifests/v1beta1
   metadata:
     name: platform
   spec:
     charts:
     - name: spire
       namespace: spire
       values:
   .
   .
   .
       version: 0.9.1
   ```

1. (`ncn#`) Generate the manifest that will be used to redeploy the chart with the modified resources.

   ```bash
   manifestgen -c customizations.yaml -i sysmgmt.yaml -o manifest.yaml
   ```

1. (`ncn#`) Check that the manifest file contains the desired resource settings.

   ```bash
   yq read manifest.yaml 'spec.charts.(name==spire).values.cray-service.sqlCluster.resources'
   ```

   Example output:

   ```yaml
   requests:
     cpu: "4"
     memory: 4Gi
   limits:
     cpu: "8"
     memory: 8Gi
   ```

1. (`ncn#`) Redeploy the same chart version but with the desired resource settings.

   ```bash
   loftsman ship --charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify the pods restart and that the desired resources have been applied.

   1. (`ncn#`) Watch the pod restart.

      ```bash
      watch "kubectl get pods -n spire -l application=spilo,cluster-name=spire-postgres"
      ```

   1. (`ncn#`) Verify that the desired resources have been applied.

      ```bash
      kubectl get pod spire-postgres-0 -n spire -o json | jq -r '.spec.containers[] | select(.name == "postgres").resources'
      ```

      Example output:

      ```json
      {
      "limits": {
         "cpu": "8",
         "memory": "8Gi"
      },
      "requests": {
         "cpu": "4",
         "memory": "4Gi"
      }
      }
      ```

1. (`ncn#`) **This step is critical.** Store the modified `customizations.yaml` file in the `site-init` repository in the customer-managed location.

   If this is not done, these changes will not persist in future installs or upgrades.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

**IMPORTANT:** If `cray-sls-postgres`, `cray-smd-postgres`, or `gitea-vcs-postgres` resources need to be adjusted,
the same procedure as above can be used with the following changes:

* `cray-sls-postgres`

  * Get the current cached manifest ConfigMap from: `loftsman-core-services`
  * Resource path: `spec.kubernetes.services.cray-hms-sls.cray-service.sqlCluster.resources`

* `cray-smd-postgres`

  * Get the current cached manifest ConfigMap from: `loftsman-core-services`
  * Resource path: `spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.resources`

* `gitea-vcs-postgres`

  * Get the current cached manifest ConfigMap from: `loftsman-sysmgmt`
  * Resource path: `spec.kubernetes.services.gitea.cray-service.sqlCluster.resources`

### Scale `cray-bss` service

Scale the replica count associated with the `cray-bss` service in the `services` namespace.
This example is based on what was needed for a system with 4000 compute nodes.
Trial and error may be needed to determine what is best for a given system at scale.

1. (`ncn#`) Get the current cached customizations.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. (`ncn#`) Get the current cached `sysmgmt` manifest.

   ```bash
   kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}' > sysmgmt.yaml
   ```

1. (`ncn#`) Edit the customizations as desired by adding or updating `spec.kubernetes.services.cray-hms-bss.cray-service.replicaCount`.

   ```bash
   yq write -i customizations.yaml 'spec.kubernetes.services.cray-hms-bss.cray-service.replicaCount' '5'
   ```

1. (`ncn#`) Check that the customization file has been updated.

   ```bash
   yq read customizations.yaml 'spec.kubernetes.services.cray-hms-bss.cray-service.replicaCount'
   5
   ```

1. Edit the `sysmgmt.yaml` to only include the `cray-hms-bss` chart and all its current data.

   The `replicaCount` specified above will be updated in the next step. The version may differ, because this is an example.

   ```yaml
   apiVersion: manifests/v1beta1
   metadata:
     name: sysmgmt
   spec:
     charts:
     - name: cray-hms-bss
       namespace: services
       values:
   .
   .
   .
       version: 1.5.8
   ```

1. (`ncn#`) Generate the manifest that will be used to redeploy the chart with the modified resources.

   ```bash
   manifestgen -c customizations.yaml -i sysmgmt.yaml -o manifest.yaml
   ```

1. (`ncn#`) Check that the manifest file contains the desired resource settings.

   ```bash
   yq read manifest.yaml 'spec.charts.(name==cray-hms-bss).values.cray-service.replicaCount'
   5
   ```

1. (`ncn#`) Redeploy the same chart version but with the desired resource settings.

   ```bash
   loftsman ship --charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify the `cray-bss` pods scale.

   1. (`ncn#`) Watch the `cray-bss` pods scale to 5, with each pod reaching a `2/2` ready state.

      ```bash
      watch "kubectl get pods -l app.kubernetes.io/instance=cray-hms-bss -n services"
      ```

      Example output:

      ```text
      NAME                       READY   STATUS    RESTARTS   AGE
      cray-bss-fccbc9f7d-7jw2q   2/2     Running   0          82m
      cray-bss-fccbc9f7d-l524g   2/2     Running   0          93s
      cray-bss-fccbc9f7d-qwzst   2/2     Running   0          93s
      cray-bss-fccbc9f7d-sw48b   2/2     Running   0          82m
      cray-bss-fccbc9f7d-xr26l   2/2     Running   0          82m
      ```

   1. (`ncn#`) Verify that the replicas change is present in the Kubernetes `cray-bss` deployment.

      ```bash
      kubectl get deployment cray-bss -n services -o json | jq -r '.spec.replicas'
      ```

      In this example, `5` will be the returned value.

1. (`ncn#`) **This step is critical.** Store the modified `customizations.yaml` in the `site-init` repository in the customer-managed location.

   If this is not done, these changes will not persist in future installs or upgrades.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

### Postgres PVC resize

Increase the PVC volume size associated with `cray-smd-postgres` cluster in the `services` namespace.
This example is based on what was needed for a system with 4000 compute nodes.
Trial and error may be needed to determine what is best for a given system at scale. The PVC size can only ever be increased.

A similar flow can be used to update the volume size for `cray-sls-postgres`, `gitea-vcs-postgres`, or `spire-postgres`.
Refer to the note at the end of this section for more details.

1. (`ncn#`) Get the current cached customizations.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. (`ncn#`) Get the current cached `core-services` manifest.

   ```bash
   kubectl get cm -n loftsman loftsman-core-services -o jsonpath='{.data.manifest\.yaml}'  > core-services.yaml
   ```

1. (`ncn#`) Edit the customizations as desired by adding or updating `spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.volumeSize`.

   ```bash
   yq write -i customizations.yaml 'spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.volumeSize' '100Gi'
   ```

1. (`ncn#`) Check that the customization file has been updated.

   ```bash
   yq read customizations.yaml 'spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.volumeSize'

   100Gi
   ```

1. Edit the `core-services.yaml` to only include the `cray-hms-smd` chart and all its current data.

   The `volumeSize` specified above will be updated in the next step. The version may differ, because this is an example.

   ```yaml
   apiVersion: manifests/v1beta1
   metadata:
     name: core-services
   spec:
     charts:
     - name: cray-hms-smd
       namespace: service
       values:
   .
   .
   .
       version: 1.26.20
   ```

1. (`ncn#`) Generate the manifest that will be used to redeploy the chart with the modified volume size.

   ```bash
   manifestgen -c customizations.yaml -i core-services.yaml -o manifest.yaml
   ```

1. (`ncn#`) Check that the manifest file contains the desired volume size setting.

   ```bash
   yq read manifest.yaml 'spec.charts.(name==cray-hms-smd).values.cray-service.sqlCluster.volumeSize'

   100Gi
   ```

1. (`ncn#`) Redeploy the same chart version but with the desired volume size setting.

   ```bash
   loftsman ship --charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. (`ncn#`) Verify that the increased volume size has been applied.

   ```bash
   watch "kubectl get postgresql cray-smd-postgres -n services"
   ```

   Example output:

   ```text
   NAME                TEAM       VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
   cray-smd-postgres   cray-smd   11        3      100Gi     500m          8Gi              45m  Running
   ```

1. If the status on the above command is `SyncFailed` instead of `Running`, refer to *Case 1* in the
   `SyncFailed` section of [Troubleshoot Postgres Database](../kubernetes/Troubleshoot_Postgres_Database.md#postgres-status-syncfailed).

   At this point the Postgres cluster is healthy, but additional steps are required to complete the resize of the Postgres PVCs.

1. (`ncn#`) **This step is critical.** Store the modified `customizations.yaml` in the `site-init` repository in the customer-managed location.

   If this is not done, these changes will not persist in future installs or upgrades.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

**IMPORTANT:** If the volume sizes of `cray-sls-postgres`, `gitea-vcs-postgres`, or `spire-postgres` need to be adjusted, the same procedure as above can be used with the following changes:

* `cray-sls-postgres`

  * Get the current cached manifest ConfigMap from: `loftsman-core-services`
  * Resource path: `spec.kubernetes.services.cray-hms-sls.cray-service.sqlCluster.volumeSize`

* `gitea-vcs-postgres`

  * Get the current cached manifest ConfigMap from: `loftsman-sysmgmt`
  * Resource path: `spec.kubernetes.services.gitea.cray-service.sqlCluster.volumeSize`

* `spire-postgres`

  * Get the current cached manifest ConfigMap from: `loftsman-sysmgmt`
  * Resource path: `spec.kubernetes.services.spire.cray-service.sqlCluster.volumeSize`

### `cray-hms-hmcollector` pods are `OOMKilled`

Update resources associated with `cray-hms-hmcollector` in the `services` namespace.
Trial and error may be needed to determine what is best for a given system at scale.

* [Adjust HM Collector Ingress Replicas and Resource Limits](../hmcollector/adjust_hmcollector_resource_limits_requests.md)

## References

To make changes that will not persist across installs or upgrades, see the following references.
These procedures will also help to verify and eliminate any issues in the short term.
As other resource customizations are needed, contact support to request the feature.

* [Determine if Pods are Hitting Resource Limits](../kubernetes/Determine_if_Pods_are_Hitting_Resource_Limits.md)
* [Increase Pod Resource Limits](../kubernetes/Increase_Pod_Resource_Limits.md)
