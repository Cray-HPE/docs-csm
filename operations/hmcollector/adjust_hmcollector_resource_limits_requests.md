# Adjust HM Collector Ingress Replicas and Resource Limits

* [Inspect current resource usage](#inspect-current-resource-usage)
* [Inspect pods for `OOMKilled` events](#inspect-pods-for-oomkilled-events)
* [How to adjust replicas and limits](#how-to-adjust-replicas-and-limits)

## Inspect current resource usage

(`ncn-mw#`) View resource usage of the containers in the `cray-hms-hmcollector-ingress` pods:

```bash
kubectl -n services top pod -l app.kubernetes.io/name=cray-hms-hmcollector-ingress --containers
```

Example output:

```text
POD                                             NAME                           CPU(cores)   MEMORY(bytes)
cray-hms-hmcollector-ingress-554bb46784-dvjzq   cray-hms-hmcollector-ingress   7m           99Mi
cray-hms-hmcollector-ingress-554bb46784-dvjzq   istio-proxy                    5m           132Mi
cray-hms-hmcollector-ingress-554bb46784-hctwm   cray-hms-hmcollector-ingress   4m           82Mi
cray-hms-hmcollector-ingress-554bb46784-hctwm   istio-proxy                    4m           120Mi
cray-hms-hmcollector-ingress-554bb46784-zdhwc   cray-hms-hmcollector-ingress   5m           97Mi
cray-hms-hmcollector-ingress-554bb46784-zdhwc   istio-proxy                    4m           133Mi
```

The default replica count for the `cray-hms-hmcollector-ingress` deployment is `3`. **NOTE: Tuning the replica count requires `cray-hms-hmcollector` chart `v2.15.7` or higher.**

The default resource limits for the `cray-hms-hmcollector-ingress` containers are:

* CPU: `4` or `4000m`
* Memory: `5Gi`

The default resource limits for the `istio-proxy` containers are:

* CPU: `2` or `2000m`
* Memory: `1Gi`

## Inspect pods for `OOMKilled` events

(`ncn-mw#`) Describe the `cray-hms-hmcollector-ingress` pods to determine if any have been `OOMKilled` in the recent past:

```bash
kubectl -n services describe pod -l app.kubernetes.io/name=cray-hms-hmcollector-ingress
```

In the command output, look for the `cray-hms-hmcollector-ingress` and `isitio-proxy` containers. Check their `Last State` (if present) in order to see if the container has been previously terminated because it ran out of memory:

```text
[...]

Containers:
  cray-hms-hmcollector-ingress:
    Container ID:   containerd://a35853bacdcea350e70c57fe1667b5b9d3c82d41e1e7c1f901832bae97b722fb
    Image:          artifactory.algol60.net/csm-docker/stable/hms-hmcollector:2.17.0
    Image ID:       artifactory.algol60.net/csm-docker/stable/hms-hmcollector@sha256:43aa7b7c2361a47e56d2ee05fbe37ace1faedc5292bbce4da5d2e79826a45f81
    Ports:          80/TCP, 443/TCP
    Host Ports:     0/TCP, 0/TCP
    State:          Running
      Started:      Tue, 21 Sep 2021 20:52:13 +0000
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Tue, 21 Sep 2021 20:51:08 +0000
      Finished:     Tue, 21 Sep 2021 20:52:12 +0000

[...]

  istio-proxy:
    Container ID:  containerd://f7e778cf91eedfa86382aabe2c43f3ae1fcf8fea166013c96b8c6794a53cfe1e
    Image:         artifactory.algol60.net/csm-docker/stable/istio/proxyv2:1.8.6-cray2-distroless
    Image ID:      artifactory.algol60.net/csm-docker/stable/istio/proxyv2@sha256:824b59554d6e9765f6226faeaf78902e1df2206b747c05f5b8eb23933eb2e85d
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

[...]
```

In the above example output, the `cray-hms-hmcollector-ingress` and the `istio-proxy` containers were previously `OOMKilled`, but both containers are currently running.

## How to adjust replicas and limits

* If the `cray-hms-hmcollector-ingress` containers are hitting their CPU limit and memory usage is steadily increasing until they get `OOMKilled`, then the number of replicas should be increased.
  It can be increased in increments of `1`, up to the number of worker nodes. This is a situation were the collector is unable to process events fast enough and they start to build up inside of it.
* If the `cray-hms-hmcollector-ingress` containers are consistently hitting their CPU limit, then their CPU limit should be increased. It can be increased in increments of `8` or `8000m`.
* If the `cray-hms-hmcollector-ingress` containers are consistently hitting their memory limit, then their memory limit should be increased. It can be increased in increments of `5Gi`.
* If the `istio-proxy` container is getting `OOMKilled`, then its memory limit should be increased. It can be increased in increments of `5Gi`.
* Otherwise, if the `cray-hms-hmcollector-ingress` and `istio-proxy` containers are not hitting their CPU or memory limits, then nothing should be changed.

For reference, on a system with four fully populated liquid-cooled cabinets, a single `cray-hms-hmcollector-ingress` pod (with a single replica) was consuming about `5000m` of CPU and
about `300Mi` of memory.

Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure **with the following specifications**:

* Chart name: `cray-hms-hmcollector`
* Base manifest name: `sysmgmt`
* (`ncn-mw#`) When reaching the step to update the customizations, perform the following steps:

   **Only follow these steps as part of the previously linked chart redeploy procedure.**

   1. Update `customizations.yaml` with the existing `cray-hms-hmcollector-ingress` resource settings.

      1. Persist resource requests and limits from the `cray-hms-hmcollector-ingress` deployment.

         ```bash
         kubectl -n services get deployments cray-hms-hmcollector-ingress \
            -o jsonpath='{.spec.template.spec.containers[].resources}' | yq r -P - | \
            yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.collectorIngressConfig.resources
         ```

      1. Persist annotations manually added to `cray-hms-hmcollector-ingress` deployment.

         ```bash
         kubectl -n services get deployments cray-hms-hmcollector-ingress \
            -o jsonpath='{.spec.template.metadata.annotations}' | \
            yq d -P - '"traffic.sidecar.istio.io/excludeOutboundPorts"' | \
            yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.podAnnotations
         ```

      1. View the updated overrides added to `customizations.yaml`.

         If the value overrides look different to the sample output below, then the replica count or the resource limits
         and requests have been manually modified in the past.

         ```bash
         yq r ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector
         ```

         Example output:

         ```yaml
         hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
         collectorIngressConfig:
            replicas: 3
            resources:
               limits:
                  cpu: "4"
                  memory: 5Gi
               requests:
                  cpu: 500m
                  memory: 256Mi
         podAnnotations: {}
         ```

   1. If desired, adjust the replica count, resource limits, and resource requests for `cray-hms-hmcollector-ingress`.

      Otherwise this step can be skipped.

      The value overrides for the `cray-hms-hmcollector-ingress` Helm chart are defined at `spec.kubernetes.services.cray-hms-hmcollector.collectorIngressConfig`.

      Adjust the resource limits and requests for the `cray-hms-hmcollector-ingress` deployment in `customizations.yaml`:

      ```yaml
            cray-hms-hmcollector:
               hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
               collectorIngressConfig:
                  replicas: 3
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

      Verify that [baseline system customizations](../../install/prepare_site_init.md#3-create-baseline-system-customizations)
      and any customer-specific settings are correct.

   1. Update the `site-init` sealed secret in the `loftsman` namespace.

      ```bash
      kubectl delete secret -n loftsman site-init
      kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
      ```

   1. **If this document was referenced during an upgrade procure, then skip the rest of the redeploy procedure and also skip the rest of this page.**

* When reaching the step to validate that the redeploy was successful, there are no validation steps to perform.
