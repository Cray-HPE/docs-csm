# Adjust HM Collector resource limits and requests

* [Inspect current resource usage](#inspect-current-resource-usage)
* [Inspect pods for `OOMKilled` events](#inspect-pods-for-oomkilled-events)
* [How to adjust resource limits](#how-to-adjust-resource-limits)

## Inspect current resource usage

View resource usage of the containers in the `cray-hms-hmcollector-ingress` pods:

```bash
ncn-mw# kubectl -n services top pod -l app.kubernetes.io/name=cray-hms-hmcollector --containers
```

Example output:

```text
POD                                     NAME                   CPU(cores)   MEMORY(bytes)
cray-hms-hmcollector-7c5b797c5c-zxt67   istio-proxy            187m         275Mi
cray-hms-hmcollector-7c5b797c5c-zxt67   cray-hms-hmcollector   4398m        296Mi
```

The default resource limits for the `cray-hms-hmcollector container` are:

* CPU: `4` or `4000m`
* Memory: `5Gi`

The default resource limits for the `istio-proxy` container are:

* CPU: `2` or `2000m`
* Memory: `1Gi`

### Inspect pods for `OOMKilled` events

Describe the `cray-hms-hmcollector-ingress` pod to determine if it has been `OOMKilled` in the recent past:

```bash
ncn-mw# kubectl -n services describe pod -l app.kubernetes.io/name=cray-hms-hmcollector
```

```text
...
Containers:
  cray-hms-hmcollector:
    Container ID:   containerd://a35853bacdcea350e70c57fe1667b5b9d3c82d41e1e7c1f901832bae97b722fb
    Image:          dtr.dev.cray.com/cray/hms-hmcollector:2.10.6
    Image ID:       dtr.dev.cray.com/cray/hms-hmcollector@sha256:b043617f83b9ff7e542e56af5bbf47f4ca35876f83b5eb07314054726c895b08
    Ports:          80/TCP, 443/TCP
    Host Ports:     0/TCP, 0/TCP
    State:          Running
      Started:      Tue, 21 Sep 2021 20:52:13 +0000
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Tue, 21 Sep 2021 20:51:08 +0000
      Finished:     Tue, 21 Sep 2021 20:52:12 +0000
...
```

> In the above example output, the `cray-hms-hmcollector` container was previously `OOMKilled`, but the container is currently running.

Look for the `istio-proxy` container and check its `Last State` (if present) to see if the container has been previously terminated due to it running out of memory:

```text
...
 istio-proxy:
    Container ID:  containerd://f439317c16f7db43e87fbcec59b7d36a0254dabd57ab71865d9d7953d154bb1a
    Image:         dtr.dev.cray.com/cray/proxyv2:1.7.8-cray1
    Image ID:      dtr.dev.cray.com/cray/proxyv2@sha256:8f2bccd346381e0399564142f9534c6c76d8d0b8bd637e9440d53bf96a9d86c7
    Port:          15090/TCP
    Host Port:     0/TCP
    Args:
      proxy
      sidecar
      --domain
      $(POD_NAMESPACE).svc.cluster.local
      --serviceCluster
      cray-hms-hmcollector.services
      --proxyLogLevel=warning
      --proxyComponentLogLevel=misc:error
      --trust-domain=cluster.local
      --concurrency
      2
    State:          Running
      Started:      Tue, 21 Sep 2021 20:51:09 +0000
   Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Tue, 21 Sep 2021 20:51:08 +0000
      Finished:     Tue, 21 Sep 2021 20:52:12 +0000
...
```

> In the above example output, the `istio-proxy` container was previously `OOMKilled`, but the container is currently running.

## How to adjust resource limits

If the `cray-hms-hmcollector` container is hitting its CPU limit and memory usage is steadily increasing till it gets `OOMKilled`, then the CPU limit for the `cray-hms-hmcollector`
should be increased. It can be increased in increments of `8` or `8000m` This is a situation were the collector is unable to process events fast enough and they start to collect
build up inside of it.

If the `cray-hms-hmcollector` container is consistently hitting its CPU limit, then its CPU limit should be increased. It can be increased in increments of `8` or `8000m`.

If the `cray-hms-hmcollector` container is consistently hitting its memory limit, then its memory limit should be increased. It can be increased in increments of `5Gi`.

If the `istio-proxy` container is getting `OOMKilled`, then its memory limit should be increased in increments of 5 Gigabytes (`5Gi`) at a time.

For reference, on a system with 4 fully populated liquid-cooled cabinets the `cray-hms-hmcollector` was consuming `~5` or `~5000m` of CPU and `~300Mi` of memory.

Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure **with the following specifications**:

* Chart name: `cray-hms-hmcollector`
* Base manifest name: `sysmgmt`
* (`ncn-mw#`) When reaching the step to update the customizations, perform the following steps:

   **Only follow these steps as part of the previously linked chart redeploy procedure.**

   1. Update `customizations.yaml` with the existing `cray-hms-hmcollector-ingress` resource settings.

      1. Persist resource requests and limits from the `cray-hms-hmcollector-ingress` deployment.

         ```bash
         ncn-mw# kubectl -n services get deployments cray-hms-hmcollector-ingress \
                   -o jsonpath='{.spec.template.spec.containers[].resources}' | yq r -P - | \
                   yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.collectorIngressConfig.resources
         ```

      1. Persist annotations manually added to `cray-hms-hmcollector-ingress` deployment.

         ```bash
         ncn-mw# kubectl -n services get deployments cray-hms-hmcollector-ingress \
                   -o jsonpath='{.spec.template.metadata.annotations}' | \
                   yq d -P - '"traffic.sidecar.istio.io/excludeOutboundPorts"' | \
                   yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.podAnnotations
         ```

      1. View the updated overrides added to `customizations.yaml`.

         If the value overrides look different to the sample output below, then the resource limits
         and requests have been manually modified in the past.

         ```bash
         ncn-mw# yq r ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector
         ```

         Example output:

         ```yaml
         hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
         collectorIngressConfig:
            resources:
               limits:
                  cpu: "4"
                  memory: 5Gi
               requests:
                  cpu: 500m
                  memory: 256Mi
         podAnnotations: {}
         ```

   1. If desired, adjust the resource limits and requests for `cray-hms-hmcollector-ingress`.

      Otherwise this step can be skipped.

      The value overrides for the `cray-hms-hmcollector-ingress` Helm chart are defined at `spec.kubernetes.services.cray-hms-hmcollector.collectorIngressConfig`.

      Adjust the resource limits and requests for the `cray-hms-hmcollector-ingress` deployment in `customizations.yaml`:

      ```yaml
            cray-hms-hmcollector:
               hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
               collectorIngressConfig:
                  resources:
                     limits:
                        cpu: "4"
                        memory: 5Gi
                     requests:
                        cpu: 500m
                        memory: 256Mi
      ```

      In order to specify a non-default memory limit for the Istio proxy used by all `cray-hms-hmcollector-*` pods,  add `sidecar.istio.io/proxyMemoryLimit` under `podAnnotations`.
      By default, the Istio proxy memory limit is `1Gi`.

      ```yaml
            cray-hms-hmcollector:
               podAnnotations:
                  sidecar.istio.io/proxyMemoryLimit: 5Gi
      ```

   1. Review the changes to `customizations.yaml`.

      Verify that [baseline system customizations](../../install/prepare_site_init.md#create-baseline-system-customizations)
      and any customer-specific settings are correct.

   1. Update the `site-init` sealed secret in the `loftsman` namespace.

      ```bash
      ncn-mw# kubectl delete secret -n loftsman site-init
      ncn-mw# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
      ```

   1. **If this document was referenced during an upgrade procure, then skip the rest of the redeploy procedure and also skip the rest of this page.**

* When reaching the step to validate that the redeploy was successful, there are no validation steps to perform.
