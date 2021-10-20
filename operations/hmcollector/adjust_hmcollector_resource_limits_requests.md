# Adjust HM Collector resource limits and requests

* [Resource Limit Tuning Guidance](#resource-limit-tuning)
* [Customize cray-hms-hmcollector resource limits and requests in customizations.yaml](#customize-resource-limits)
* [Redeploy cray-hms-hmcollector with new resource limits and requests](#redeploy-cray-hms-hmcollector)

<a name="resource-limit-tuning"></a>
## Resource Limit Tuning Guidance

### Inspect current resource usage in the cray-hms-hmcollector pod

View resource usage of the containers in the cray-hms-hmcollector pod:
```bash
ncn-m001# kubectl -n services top pod -l app.kubernetes.io/name=cray-hms-hmcollector --containers
POD                                     NAME                   CPU(cores)   MEMORY(bytes)
cray-hms-hmcollector-7c5b797c5c-zxt67   istio-proxy            187m         275Mi
cray-hms-hmcollector-7c5b797c5c-zxt67   cray-hms-hmcollector   4398m        296Mi
```

The default resource limits for the cray-hms-hmcollector container are:
   * CPU: `4` or `4000m`
   * Memory: `5Gi`

The default resource limits for the istio-proxy container are:
   * CPU: `2` or `2000m`
   * Memory: `1Gi`

### Inspect the cray-hms-hmcollector pod for OOMKilled events

Describe the collector-hms-hmcollector pod to determine if it has been OOMKilled in the recent past:
```
ncn-m001# kubectl -n services describe pod -l app.kubernetes.io/name=cray-hms-hmcollector
```

Look for the `cray-hms-hmcollector` container and check its `Last State` (if present) to see if the container has been perviously terminated due to it running out of memory:
```
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
> In the above example output the `cray-hms-hmcollector` container was perviously OOMKilled, but the container is currently running.

Look for the `isitio-proxy` container and check its `Last State` (if present) to see if the container has been perviously terminated due to it running out of memory:
```
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
> In the above example output the `istio-proxy` container was perviously OOMKilled, but the container is currently running.

### How to adjust CPU and Memory limits
If the `cray-hms-hmcollector` container is hitting its CPU limit and memory usage is steadily increasing till it gets OOMKilled, then the CPU limit for the `cray-hms-hmcollector` should be increased. It can be increased in increments of `8` or `8000m` This is a situation were the collector is unable to process events fast enough and they start to collect build up inside of it.

If the `cray-hms-hmcollector` container is consistency hitting its CPU limit, then its CPU limit should be increased. It can be increased in increments of `8` or `8000m`.

If the `cray-hms-hmcollector` container is consistency hitting its memory limit, then its memory limit should be increased. It can be increased in increments of `5Gi`.

If the `istio-proxy` container is getting OOMKilled, then its memory limit should be increased in increments of 5 Gigabytes (`5Gi`) at a time.

Otherwise, if the `cray-hms-hmcollector` and `istio-proxy` containers are not hitting their CPU or memory limits

For reference, on a system with 4 fully populated liquid cooled cabinets the cray-hms-hmcollector was consuming `~5` or `~5000m` of CPU and `~300Mi` of memory.

<a name="customize-resource-limits"></a>
## Customize cray-hms-hmcollector resource limits and requests in customizations.yaml

1. If the [`site-init` repository is available as a remote
   repository](../../../067-SHASTA-CFG.md#push-to-a-remote-repository) then clone
   it on the host orchestrating the upgrade:

   ```bash
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

   Otherwise, create a new `site-init` working tree:

   ```bash
   ncn-m001# git init site-init
   ```

2. Download `customizations.yaml`:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

3. Review, add, and commit `customizations.yaml` to the local `site-init`
   repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what is in the repository and what
   > was stored in the `site-init`, then it suggests settings were improperly
   > changed at some point. If that is the case then be cautious, _there may be
   > dragons ahead_.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

4. Update `customizations.yaml` with the existing `cray-hms-hmcollector` resource limits and requests settings:

   Persist resource requests and limits from the cray-hms-hmcollector deployment:
   ```bash
   ncn-m001# kubectl -n services get deployments cray-hms-hmcollector \
      -o jsonpath='{.spec.template.spec.containers[].resources}' | yq r -P - | \
      yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.resources
   ```

   Persist annotations manually added to `cray-hms-hmcollector` deployment:
   ```bash
   ncn-m001# kubectl -n services get deployments cray-hms-hmcollector \
      -o jsonpath='{.spec.template.metadata.annotations}' | \
      yq d -P - '"traffic.sidecar.istio.io/excludeOutboundPorts"' | \
      yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.podAnnotations
   ```

   View the updated overrides added to `customizations.yaml`. If the value overrides look different to the sample output below then the resource limits and requests have been manually modified in the past.
   ```bash
   ncn-m001# yq r ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector
   hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
   resources:
   limits:
      cpu: "4"
      memory: 5Gi
   requests:
      cpu: 500m
      memory: 256Mi
   podAnnotations: {}
   ```

5. If desired adjust the resource limits and requests for the `cray-hms-hmcollector`. Otherwise this step can be skipped. Refer to [Resource Limit Tuning Guidance](#resource-limit-tuning) for information on how the resource limits could be adjusted.

   Edit `customizations.yaml` and the value overrides for the `cray-hms-hmcollector` Helm chart are defined at `spec.kubernetes.services.cray-hms-hmcollector`

   Adjust the resource limits and requests for the `cray-hms-hmcollector` deployment in `customizations.yaml`:
   ```yaml
         cray-hms-hmcollector:
            hmcollector_external_ip: '{{ network.netstaticips.hmn_api_gw }}'
            resources:
               limits:
                  cpu: "4"
                  memory: 5Gi
               requests:
                  cpu: 500m
                  memory: 256Mi
   ```

   To specify a non-default memory limit for the Istio proxy used by the `cray-hms-hmcollector` to pod annotation `sidecar.istio.io/proxyMemoryLimit` can added under `podAnnotations`. By default the Istio proxy memory limit is `1Gi`.
   ```yaml
         cray-hms-hmcollector:
            podAnnotations:
               sidecar.istio.io/proxyMemoryLimit: 5Gi
   ```

6. Review the changes to `customizations.yaml` and verify [baseline system
   customizations](../../../067-SHASTA-CFG.md#create-baseline-system-customizations)
   and any customer-specific settings are correct.

   ```
   ncn-m001# git diff
   ```

7. Add and commit `customizations.yaml` if there are any changes:

   ```
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m "Update customizations.yaml consistent with CSM $CSM_RELEASE_VERSION"
   ```

8. Update `site-init` sealed secret in `loftsman` namespace:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

9. Push to the remote repository as appropriate:

   ```bash
   ncn-m001# git push
   ```

10. __If this document was referenced during an upgrade procure, then skip__ Otherwise, continue on to [Redeploy cray-hms-hmcollector with new resource limits and requests](#redeploy-cray-hms-hmcollector) for the the new resource limits and requests to take effect.


<a name="redeploy-cray-hms-hmcollector"></a>
## Redeploy cray-hms-hmcollector with new resource limits and requests
1. Determine the version of HM Collector:
    ```bash
    ncn-m001# HMCOLLECTOR_VERSION=$(kubectl -n loftsman get cm loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-hms-hmcollector).version')
    ncn-m001# echo $HMCOLLECTOR_VERSION
    ```

2. Create `hmcollector-manifest.yaml`:
    ```bash
    ncn-m001# cat > hmcollector-manifest.yaml << EOF
    apiVersion: manifests/v1beta1
    metadata:
        name: hmcollector
    spec:
        charts:
        - name: cray-hms-hmcollector
          version: $HMCOLLECTOR_VERSION
          namespace: services
    EOF
    ```

3. Acquire `customizations.yaml`:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

4. Merge `customizations.yaml` with `hmcollector-manifest.yaml`:
    ```bash
    ncn-m001# manifestgen -c customizations.yaml -i ./hmcollector-manifest.yaml > ./hmcollector-manifest.out.yaml
    ```

5. Redeploy the HM Collector helm chart:
    ```bash
    ncn-m001# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path hmcollector-manifest.out.yaml
    ```