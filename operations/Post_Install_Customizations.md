## Post-Install Customizations

Post-install customizations may be needed as systems scale. These customizations also need to persist across future installs or upgrades. Not all resources can be customized post-install; common scenarios are documented in the following sections.

The following is a guide for determining where issues may exist and how to adjust the resources as needed to ensure the change will persist.

### Kubectl Events OOMKilled

Check kubectl events to see if there are any recent out of memory events.

```
ncn-w001# kubectl get event -A | grep OOM
```

Use the Grafana "Kubernetes/Compute Resources/Pod" Dashboard to view the memory utilization graphs over time for any pod that has been OOMKilled. 

### Prometheus CPUThrottlingHigh Alerts

Check Prometheus for recent CPUThrottlingHigh Alerts.

From Prometheus (https://prometheus.SYSTEM-NAME_DOMAIN-NAME/), select the **Alert** tab and scroll down to the alert for CPUThrottlingHigh.  

Use the Grafana "Kubernetes/Compute Resources/Pod" Dashboard to view the throttling graphs over time for any pod that is alerting.  

### Grafana Kubernetes/Compute Resources/Pod Dashboard

Use Grafana to investigate and analyze CPU Throttling and/or Memory Usage.

From Grafana (https://grafana.SYSTEM-NAME_DOMAIN-NAME/) and the Home Dashboard, select the "Kubernetes/Compute Resources/Pod" Dashboard.

Select the datasource, namespace, and pod based on the pod being examined. For example:
```
datasource: default
namespace: sysmgmt-health
pod: prometheus-cray-sysmgmt-health-promet-prometheus-0
```

**For CPU Throttling:**

Select the **CPU Throttling** drop down to see the CPU Throttling graph for the pod during the selected time (from the top right), and select the container (from the legends under the x axis).

The presence of CPU throttling does not always indicate a problem, but if a service is being slow or experiencing latency issues, reviewing the graph and adjusting the resources.limits.cpu can be beneficial. If the pod is being throttled at or near 100% for any period of time, then adjustments are likely needed. If the service's response time is critical, then adjusting the pod's resources to greatly reduce or eliminate any CPU throttling may be required.  

The resources.requests.cpu are used by the Kubernetes scheduler to decide which node to place the pod on and do not impact CPU Throttling. The resources.limits.cpu can never be lower than the resources.requests.cpu.

**For Memory Usage:**

Select the **Memory Usage** drop down to see the Memory Usage graph for the pod during the selected time (from the top right), and select the container (from the legends under the x axis).

From the Memory Usage graph for the container, determine the steady state memory usage. This is where the resources.requests.memory should be minimally set. But more importantly, determine the spike usage for the container and set the resources.limits.memory based on the spike values with some additional headroom.

### Common Customization Scenarios

#### Prometheus Pod is OOMKilled or CPU Throttled
Update resources associated with Prometheus in the sysmgmt-health namespace.

1. Get the current cached customizations.

   ```
   ncn-w001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. Get the current cached platform manifest.

   ```
   ncn-w001# kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}'  > platform.yaml
   ```

1.  Edit the customizations as desired - add or update spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.

   ```
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.requests.cpu' --style=double '2'
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.requests.memory' '15Gi'
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.limits.cpu' --style=double '6'
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources.limits.memory' '30Gi'
   ```

1. Check that the customization file has been updated.

   ```
   ncn-w001# yq read customizations.yaml 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources'

   requests:
     cpu: "3"
     memory: 15Gi
   limits:
     cpu: "6"
     memory: 30Gi
   ```

1. Edit the platform.yaml to only include the cray-sysmgmt-health chart and all its current data. (The resources specified above will be updated in the next step and the version may differ as this is an example).

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

1. Generate the manifest that will be used to re-deploy the chart with the modified resources.

   ```
   ncn-w001# manifestgen -c customizations.yaml -i platform.yaml -o manifest.yaml
   ```

1. Check that the manifest file contains the desired resource settings.

   ```
   ncn-w001# yq read manifest.yaml 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-operator.prometheus.prometheusSpec.resources'

   requests:
     cpu: "3"
     memory: 15Gi
   limits:
     cpu: "6"
     memory: 30Gi
   ```

1. Re-deploy the same chart version but with the desired resource settings.

   ```
   ncn-w001# loftsman ship --charts-repo http://helmrepo.dev.cray.com:8080 --manifest-path $PWD/manifest.yaml
   ```

1. Verify the pod restarts and that the desired resources have been applied.

   ```
   # Watch the pod prometheus-cray-sysmgmt-health-promet-prometheus-0 restart
   ncn-w001# watch "kubectl get pods -n sysmgmt-health -l prometheus=cray-sysmgmt-health-promet-prometheus"

   # It may take 10m for the prometheus-cray-sysmgmt-health-promet-prometheus-0 pod to Terminate - it can be forced deleted if it remains in Terminating state
   ncn-w001#  kubectl delete pod prometheus-cray-sysmgmt-health-promet-prometheus-0 --force --grace-period=0 -n sysmgmt-health

   # Verify that the resource changes are in place
   ncn-w001#  kubectl get pod prometheus-cray-sysmgmt-health-promet-prometheus-0 -n sysmgmt-health -o json | jq -r '.spec.containers[] | select(.name == "prometheus").resources'
   ```

1. Store the modified customizations.yaml in the site-init repository in the customer-managed location. **This step is critical.**  If not done, these changes will not persist in future installs or updates.


#### Postgres Pods are OOMKilled or CPU Throttled

Update resources associated with spire-postgres in the spire namespace.

A similar flow can be used to update the resources for cray-sls-postgres, cray-smd-postgres, or gitea-vcs-postgres. Refer to the note at the end of this section for more details.

1. Get the current cached customizations.

   ```
   ncn-w001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. Get the current cached sysmgmt manifest.

   ```
   ncn-w001# kubectl get cm -n loftsman loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}'  > sysmgmt.yaml
   ```

1.  Edit the customizations as desired by adding or updating spec.kubernetes.services.spire.cray-service.sqlCluster.resources.

   ```
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.requests.cpu' --style=double '4'
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.requests.memory' '4Gi'
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.limits.cpu' --style=double '8'
   ncn-w001# yq write -i customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources.limits.memory' '8Gi'
   ```

1. Check that the customization file has been updated.

   ```
   ncn-w001# yq read customizations.yaml 'spec.kubernetes.services.spire.cray-service.sqlCluster.resources'

   requests:
     cpu: "4"
     memory: 4Gi
   limits:
     cpu: "8"
     memory: 8Gi
   ```

1. Edit the sysmgmt.yaml to only include the spire chart and all its current data. (The resources specified above will be updated in the next step and the version may differ as this is an example).

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

1. Generate the manifest that will be used to re-deploy the chart with the modified resources.

   ```
   ncn-w001# manifestgen -c customizations.yaml -i sysmgmt.yaml -o manifest.yaml
   ```

1. Check that the manifest file contains the desired resource settings.

   ```
   ncn-w001# yq read manifest.yaml 'spec.charts.(name==spire).values.cray-service.sqlCluster.resources'

   requests:
     cpu: "4"
     memory: 4Gi
   limits:
     cpu: "8"
     memory: 8Gi
   ```

1. Redeploy the same chart version but with the desired resource settings.

   ```
   ncn-w001# loftsman ship --charts-repo http://helmrepo.dev.cray.com:8080 --manifest-path $PWD/manifest.yaml
   ```

1. Verify the pods restart and that the desired resources have been applied.

   ```
   ncn-w001# watch "kubectl get pods -n spire -l application=spilo,cluster-name=spire-postgres"

   ncn-w001# kubectl get pod spire-postgres-0 -n spire -o json | jq -r '.spec.containers[] | select(.name == "postgres").resources'
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

1. Store the modified customizations.yaml in the site-init repository in the customer-managed location. **This step is critical.** If not done, these changes will not persist in future installs or updates.

  **IMPORTANT:** If cray-sls-postgres, cray-smd-postgres, or gitea-vcs-postgres resources need to be adjusted, the same procedure as above can be used with the following changes:

  cray-sls-postgres:

    Get the current cached manifest configmap from: loftsman-core-services
    Resource path: spec.kubernetes.services.cray-hms-sls.cray-service.sqlCluster.resources

  cray-smd-postgres:

    Get the current cached manifest configmap from: loftsman-core-services
    Resource path: spec.kubernetes.services.cray-hms-smd.cray-service.sqlCluster.resources

  gitea-vcs-postgres:

    Get the current cached manifest configmap from: loftsman-sysmgmt
    Resource path: spec.kubernetes.services.gitea.cray-service.sqlCluster.resources


### References

To make changes that will not persist across installs or upgrades, see the following references. These procedures will also help to verify and eliminate any issues in the short term. As other resource customizations are needed, contact support to request the feature.

* Reference [Determine if Pods are Hitting Resource Limits](Determine_if_Pods_are_Hitting_Resource_Limits.md)
* Reference [Increase Pod Resource Limits](Increase_Pod_Resource_Limits.md)

