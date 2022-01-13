## Post-Install Customizations

Post-install customizations may be needed as systems scale. These customizations also need to persist across future installs or upgrades. Not all resources can be customized post-install; common scenarios are documented in the following sections.

The following is a guide for determining where issues may exist, how to adjust the resources, and how to ensure the changes will persist. Different values may be be needed for systems as they scale.

### Kubectl Events `OOMKilled`

Check to see if there are any recent out of memory events.

1. Check `kubectl` events to see if there are any recent out of memory events.

    ```bash
    ncn# kubectl get event -A | grep OOM
    ```

1. Use the Grafana "Kubernetes/Compute Resources/Pod" Dashboard to view the memory utilization graphs over time for any pod that has been `OOMKilled`.

### Prometheus `CPUThrottlingHigh` Alerts

Check Prometheus for recent `CPUThrottlingHigh` Alerts.

1. From Prometheus (https://prometheus.SYSTEM-NAME_DOMAIN-NAME/), select the **Alert** tab and scroll down to the alert for `CPUThrottlingHigh`.

1. Use the Grafana "Kubernetes/Compute Resources/Pod" Dashboard to view the throttling graphs over time for any pod that is alerting.

### Grafana Kubernetes/Compute Resources/Pod Dashboard

Use Grafana to investigate and analyze CPU Throttling and/or Memory Usage.

1. From Grafana (https://grafana.SYSTEM-NAME_DOMAIN-NAME/) and the Home Dashboard, select the "Kubernetes/Compute Resources/Pod" Dashboard.

1. Select the datasource, namespace, and pod based on the pod being examined. For example:
    
    ```
    datasource: default
    namespace: sysmgmt-health
    pod: prometheus-cray-sysmgmt-health-promet-prometheus-0
    ```

#### For CPU Throttling

1. Select the **CPU Throttling** drop-down to see the CPU Throttling graph for the pod during the selected time (from the top right), and select the container (from the legends under the x axis).

1. The presence of CPU throttling does not always indicate a problem, but if a service is being slow or experiencing latency issues, reviewing the graph and adjusting the `resources.limits.cpu` can be beneficial. If the pod is being throttled at or near 100% for any period of time, then adjustments are likely needed. If the service's response time is critical, then adjusting the pod's resources to greatly reduce or eliminate any CPU throttling may be required.

1. The `resources.requests.cpu` are used by the Kubernetes scheduler to decide which node to place the pod on and do not impact CPU Throttling. The `resources.limits.cpu` can never be lower than the `resources.requests.cpu`.

#### For Memory Usage

1. Select the **Memory Usage** drop-down to see the Memory Usage graph for the pod during the selected time (from the top right), and select the container (from the legends under the x axis).

1. From the Memory Usage graph for the container, determine the steady state memory usage. This is where the `resources.requests.memory` should be minimally set. But more importantly, determine the spike usage for the container and set the `resources.limits.memory` based on the spike values with some additional headroom.

### Common Customization Scenarios

- [Prerequisite](#prerequisite)
- [Prometheus Pod is `OOMKilled` or CPU Throttled](#prometheus_resources)
- [Postgres Pods are `OOMKilled` or CPU Throttled](#postgres_resources)
- [Scale `cray-bss` Service](#bss_scale)
- [Postgres PVC Resize](#postgres_pvc_resize)

<a name="prerequisite"></a>
### Prerequisite

In order to apply post-install customizations to a system, the affected Helm chart must exist on the system so that the same chart version can be redeployed with the desired customizations.

This example unpacks the the csm-1.0.0 tarball under /root and lists the Helm charts that are now on your system. Set `PATH_TO_RELEASE` to the release directory where the Helm directory exists. `PATH_TO_RELEASE` will be used below when deploying a customization.

These unpacked files can be safely removed after the customizations are deployed through `loftsman ship` in the examples below.

```bash
## This example assumes the csm-1.0.0 release is currently running and the csm-1.0.0.tar.gz has been pulled down under /root
ncn# cd /root
ncn# tar -xzf csm-1.0.0.tar.gz
ncn# rm csm-1.0.0.tar.gz
ncn# PATH_TO_RELEASE=/root/csm-1.0.0
ncn# ls $PATH_TO_RELEASE/helm
```

<a name="prometheus_resources"></a>
### Prometheus Pod is `OOMKilled` or CPU Throttled
Update resources associated with Prometheus in the `sysmgmt-health` namespace. This example is based on what was needed for a system with 4000 compute nodes. Trial and error may be needed to determine what is best for a given system at scale.


1. Get the current cached customizations.
   
   ```bash
   ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. Get the current cached platform manifest.
   
   ```bash
   ncn# kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}'  > platform.yaml
   ```

1. Edit the customizations as desired by adding or updating `spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources`.
   
   ```bash
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.requests.cpu' --style=double '2'
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.requests.memory' '15Gi'
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.limits.cpu' --style=double '6'
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.limits.memory' '30Gi'
   ```

1. Check that the customization file has been updated.
   
   ```bash
   ncn# yq read customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources'
   ```

   Example output:

   ```
   requests:
     cpu: "3"
     memory: 15Gi
   limits:
     cpu: "6"
     memory: 30Gi
   ```

1. Edit the `platform.yaml` to only include the `cray-sysmgmt-health` chart and all its current data. (The resources specified above will be updated in the next step and the version may differ, because this is an example).
   
   ```
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

1. Generate the manifest that will be used to redeploy the chart with the modified resources.
   
   ```bash
   ncn# manifestgen -c customizations.yaml -i platform.yaml -o manifest.yaml
   ```

1. Check that the manifest file contains the desired resource settings.
   
   ```bash
   ncn# yq read manifest.yaml 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-operator.prometheus.prometheusSpec.resources'
   ```

   Example output:

   ```
   requests:
     cpu: "3"
     memory: 15Gi
   limits:
     cpu: "6"
     memory: 30Gi
   ```

1. Redeploy the same chart version but with the desired resource settings.
   
   ```bash
   ncn# loftsman ship charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify the pod restarts and that the desired resources have been applied.
   
   1. Watch the pod prometheus-cray-sysmgmt-health-promet-prometheus-0 restart.
      
      ```bash
      ncn# watch "kubectl get pods -n sysmgmt-health -l prometheus=cray-sysmgmt-health-promet-prometheus"
      ```
      It may take about ten minutes for the prometheus-cray-sysmgmt-health-promet-prometheus-0 pod to Terminate.
      It can be forced deleted if it remains in Terminating state:
      
      ```bash
      ncn# kubectl delete pod prometheus-cray-sysmgmt-health-promet-prometheus-0 --force --grace-period=0 -n sysmgmt-health
      ```

   1. Verify that the resource changes are in place.

      ```bash
      ncn#  kubectl get pod prometheus-cray-sysmgmt-health-promet-prometheus-0 -n sysmgmt-health -o json | jq -r '.spec.containers[] | select(.name == "prometheus").resources'
      ```

2. **This step is critical.** Store the modified `customizations.yaml` in the `site-init` repository in the customer-managed location. If not done, these changes will not persist in future installs or upgrades.

<a name="postgres_resources"></a>
### Postgres Pods are `OOMKilled` or CPU Throttled

Update resources associated with spire-postgres in the `spire` namespace. This example is based on what was needed for a system with 4000 compute nodes. Trial and error may be needed to determine what is best for a given system at scale.

A similar flow can be used to update the resources for `cray-sls-postgres`, `cray-smd-postgres`, or `gitea-vcs-postgres`. Refer to the note at the end of this section for more details.

1. Get the current cached customizations.
   
   ```bash
   ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. Get the current cached sysmgmt manifest.
   
   ```bash
   ncn# kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}'  > sysmgmt.yaml
   ```

1. Edit the customizations as desired by adding or updating `spec.kubernetes.services.spire.cray-service.sqlCluster.resources`.
   
   ```bash
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.requests.cpu' --style=double '4'
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.requests.memory' '4Gi'
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.limits.cpu' --style=double '8'
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.limits.memory' '8Gi'
   ```

1. Check that the customization file has been updated.
   
   ```bash
   ncn# yq read customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources'
   ```

   Example output:

   ```
   requests:
     cpu: "4"
     memory: 4Gi
   limits:
     cpu: "8"
     memory: 8Gi
   ```

1. Edit the `sysmgmt.yaml` to only include the `spire` chart and all its current data. (The resources specified above will be updated in the next step and the version may differ, because this is an example).
   
   ```
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

1. Generate the manifest that will be used to redeploy the chart with the modified resources.
   
   ```bash
   ncn# manifestgen -c customizations.yaml -i sysmgmt.yaml -o manifest.yaml
   ```

1. Check that the manifest file contains the desired resource settings.
   
   ```bash
   ncn# yq read manifest.yaml 'spec.charts.(name==spire).values.cray-service.sqlCluster.resources'
   ```

   Example output:

   ```
   requests:
     cpu: "4"
     memory: 4Gi
   limits:
     cpu: "8"
     memory: 8Gi
   ```

1. Redeploy the same chart version but with the desired resource settings.
   
   ```bash
   ncn# loftsman ship charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify the pods restart and that the desired resources have been applied.
   
   1. Watch the pod restart.
   
      ```bash
      ncn# watch "kubectl get pods -n spire -l application=spilo,cluster-name=spire-postgres"
      ```
   
   1. Verify the desired resources have been applied.
      
      ```bash
      ncn# kubectl get pod spire-postgres-0 -n spire -o json | jq -r '.spec.containers[] | select(.name == "postgres").resources'
      ```

      Example output:

      ```
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

1. **This step is critical.** Store the modified `customizations.yaml` in the `site-init` repository in the customer-managed location. If not done, these changes will not persist in future installs or upgrades.

**IMPORTANT:** If `cray-sls-postgres`, `cray-smd-postgres`, or `gitea-vcs-postgres` resources need to be adjusted, the same procedure as above can be used with the following changes:

  * `cray-sls-postgres`

    Get the current cached manifest configmap from: `loftsman-core-services`
    Resource path: `spec.kubernetes.services.cray-hms-sls.cray-service.sqlCluster.resources`

  * `cray-smd-postgres`

    Get the current cached manifest configmap from: `loftsman-core-services`
    Resource path: `spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.resources`

  * `gitea-vcs-postgres`

    Get the current cached manifest configmap from: `loftsman-sysmgmt`
    Resource path: `spec.kubernetes.services.gitea.cray-service.sqlCluster.resources`


<a name="bss_scale"></a>
### Scale `cray-bss` Service
Scale the replica count associated with the `cray-bss` service in the `services` namespace. This example is based on what was needed for a system with 4000 compute nodes. Trial and error may be needed to determine what is best for a given system at scale.

1. Get the current cached customizations.
   
   ```bash
   ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. Get the current cached `sysmgmt` manifest.
   
   ```bash
   ncn# kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}' > sysmgmt.yaml
   ```

1. Edit the customizations as desired by adding or updating `spec.kubernetes.services.cray-hms-bss.cray-service.replicaCount`.
   
   ```bash
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.cray-hms-bss.cray-service.replicaCount' '5'
   ```

1. Check that the customization file has been updated.
   
   ```bash
   ncn# yq read customizations.yaml 'spec.kubernetes.services.cray-hms-bss.cray-service.replicaCount'
   5
   ```

1. Edit the `sysmgmt.yaml` to only include the `cray-hms-bss` chart and all its current data. (The replicaCount specified above will be updated in the next step and the version may differ, because this is an example).
   
   ```
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

1. Generate the manifest that will be used to redeploy the chart with the modified resources.
   
   ```bash
   ncn# manifestgen -c customizations.yaml -i sysmgmt.yaml -o manifest.yaml
   ```

1. Check that the manifest file contains the desired resource settings.
   
   ```bash
   ncn# yq read manifest.yaml 'spec.charts.(name==cray-hms-bss).values.cray-service.replicaCount'
   5
   ```

1. Redeploy the same chart version but with the desired resource settings.
   
   ```bash
   ncn# loftsman ship charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify the `cray-bss` pods scale.
   
   1. Watch the `cray-bss` pods scale to 5 and each reach a 2/2 ready state.
   
      ```bash
      ncn# watch "kubectl get pods -l app.kubernetes.io/instance=cray-hms-bss -n services"
      ```

      Example output:

      ```
      NAME                       READY   STATUS    RESTARTS   AGE
      cray-bss-fccbc9f7d-7jw2q   2/2     Running   0          82m
      cray-bss-fccbc9f7d-l524g   2/2     Running   0          93s
      cray-bss-fccbc9f7d-qwzst   2/2     Running   0          93s
      cray-bss-fccbc9f7d-sw48b   2/2     Running   0          82m
      cray-bss-fccbc9f7d-xr26l   2/2     Running   0          82m
      ```

   1. Verify that the replicas change is present in the Kubernetes `cray-bss` deployment.

      ```bash
      ncn# kubectl get deployment cray-bss -n services -o json | jq -r '.spec.replicas'
      ```

      In this example, `5` will be the returned value.

1. **This step is critical.** Store the modified `customizations.yaml` in the `site-init` repository in the customer-managed location. If not done, these changes will not persist in future installs or upgrades.

<a name="postgres_pvc_resize"></a>
### Postgres PVC Resize

Increase the PVC volume size associated with `cray-smd-postgres` cluster in the `services` namespace. This example is based on what was needed for a system with 4000 compute nodes. Trial and error may be needed to determine what is best for a given system at scale. The PVC size can only ever be increased.

A similar flow can be used to update the volume size for `cray-sls-postgres`, `gitea-vcs-postgres`, or `spire-postgres`. Refer to the note at the end of this section for more details.

1. Get the current cached customizations.
   
   ```bash
   ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. Get the current cached `core-services` manifest.
   
   ```bash
   ncn# kubectl get cm -n loftsman loftsman-core-services -o jsonpath='{.data.manifest\.yaml}'  > core-services.yaml
   ```

1. Edit the customizations as desired by adding or updating `spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.volumeSize`.
   
   ```bash
   ncn# yq write -i customizations.yaml 'spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.volumeSize' '100Gi'
   ```

1. Check that the customization file has been updated.
   
   ```bash
   ncn# yq read customizations.yaml 'spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.volumeSize'

   100Gi
   ```

1. Edit the `core-services.yaml` to only include the `cray-hms-smd` chart and all its current data. (The `volumeSize` specified above will be updated in the next step and the version may differ, because this is an example).
   
   ```
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

1. Generate the manifest that will be used to redeploy the chart with the modified volume size.
   
   ```bash
   ncn# manifestgen -c customizations.yaml -i core-services.yaml -o manifest.yaml
   ```

1. Check that the manifest file contains the desired volume size setting.
   
   ```bash
   ncn# yq read manifest.yaml 'spec.charts.(name==cray-hms-smd).values.cray-service.sqlCluster.volumeSize'

   100Gi
   ```

1. Redeploy the same chart version but with the desired volume size setting.
   
   ```bash
   ncn# loftsman ship charts-path ${PATH_TO_RELEASE}/helm --manifest-path ${PWD}/manifest.yaml
   ```

1. Verify that the increased volume size has been applied.
   
   ```bash
   ncn# watch "kubectl get postgresql cray-smd-postgres -n services"
   ```

   Example output:

   ```
   NAME                TEAM       VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
   cray-smd-postgres   cray-smd   11        3      100Gi     500m          8Gi              45m  Running
   ```

1. If the status on the above command is `SyncFailed` instead of `Running`, refer to *Case 1* in the *SyncFailed* section of [Troubleshoot Postgres Database](../kubernetes/Troubleshoot_Postgres_Database.md#syncfailed). At this point the Postgres cluster is healthy, but additional steps are required to complete the resize of the Postgres PVCs.

1. **This step is critical.** Store the modified `customizations.yaml` in the `site-init` repository in the customer-managed location. If not done, these changes will not persist in future installs or upgrades.

**IMPORTANT:** If `cray-sls-postgres`, `gitea-vcs-postgres`, or `spire-postgres` `volumeSize` need to be adjusted, the same procedure as above can be used with the following changes:

  * `cray-sls-postgres`

    Get the current cached manifest configmap from: `loftsman-core-services`
    Resource path: `spec.kubernetes.services.cray-hms-sls.cray-service.sqlCluster.volumeSize`

  * `gitea-vcs-postgres`

    Get the current cached manifest configmap from: `loftsman-sysmgmt`
    Resource path: `spec.kubernetes.services.gitea.cray-service.sqlCluster.volumeSize`

  * `spire-postgres`

    Get the current cached manifest configmap from: `loftsman-sysmgmt`
    Resource path: `spec.kubernetes.services.spire.cray-service.sqlCluster.volumeSize`

### References

To make changes that will not persist across installs or upgrades, see the following references. These procedures will also help to verify and eliminate any issues in the short term. As other resource customizations are needed, contact support to request the feature.

* Reference [Determine if Pods are Hitting Resource Limits](../kubernetes/Determine_if_Pods_are_Hitting_Resource_Limits.md)
* Reference [Increase Pod Resource Limits](../kubernetes/Increase_Pod_Resource_Limits.md)

