# Adjust HM Collector Ingress Replicas and Resource Limits

* [Replica Count and Resource Limit Tuning Guidance](#resource-limit-tuning)
* [Customize cray-hms-hmcollector Replica Count and Resource Limits and Requests in customizations.yaml](#customize-resource-limits)
* [Redeploy cray-hms-hmcollector with New Replica Count and Resource Limits and Requests](#redeploy-cray-hms-hmcollector)

<a name="resource-limit-tuning"></a>

## Replica Count and Resource Limit Tuning Guidance

### Inspect current resource usage in the cray-hms-hmcollector-ingress pods

View resource usage of the containers in the cray-hms-hmcollector-ingress pods:

```console
ncn-m001# kubectl -n services top pod -l app.kubernetes.io/name=cray-hms-hmcollector-ingress --containers
POD                                             NAME                           CPU(cores)   MEMORY(bytes)
cray-hms-hmcollector-ingress-554bb46784-dvjzq   cray-hms-hmcollector-ingress   7m           99Mi
cray-hms-hmcollector-ingress-554bb46784-dvjzq   istio-proxy                    5m           132Mi
cray-hms-hmcollector-ingress-554bb46784-hctwm   cray-hms-hmcollector-ingress   4m           82Mi
cray-hms-hmcollector-ingress-554bb46784-hctwm   istio-proxy                    4m           120Mi
cray-hms-hmcollector-ingress-554bb46784-zdhwc   cray-hms-hmcollector-ingress   5m           97Mi
cray-hms-hmcollector-ingress-554bb46784-zdhwc   istio-proxy                    4m           133Mi
```

The default replica count for the cray-hms-hmcollector-ingress deployment is 3. **NOTE: Tuning the replica count requires cray-hms-hmcollector chart v2.15.7**

The default resource limits for the cray-hms-hmcollector-ingress containers are:

* CPU: `4` or `4000m`

* Memory: `5Gi`

The default resource limits for the istio-proxy containers are:

* CPU: `2` or `2000m`

* Memory: `1Gi`

### Inspect the cray-hms-hmcollector-ingress pods for OOMKilled events

Describe the cray-hms-hmcollector-ingress pods to determine if it has been OOMKilled in the recent past:

```console
ncn-m001# kubectl -n services describe pod -l app.kubernetes.io/name=cray-hms-hmcollector-ingress
```

Look for the `cray-hms-hmcollector-ingress` containers and check their `Last State` (if present) to see if the container has been previously terminated due to it running out of memory:

```console
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
```

> In the above example output the `cray-hms-hmcollector-ingress` container was previously OOMKilled, but the container is currently running.

Look for the `isitio-proxy` containers and check their `Last State` (if present) to see if the container has been previously terminated due to it running out of memory:

```console
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

> In the above example output the `istio-proxy` container was previously OOMKilled, but the container is currently running.

### How to adjust replicas and CPU and Memory limits

If the `cray-hms-hmcollector-ingress` containers are hitting their CPU limit and memory usage is steadily increasing till they get OOMKilled, then the number of replicas should be increased.
It can be increased in increments of `1` up to the number of worker nodes. This is a situation were the collector is unable to process events fast enough and they start to collect build up inside of it.

If the `cray-hms-hmcollector-ingress` containers are consistency hitting their CPU limit, then their CPU limit should be increased. It can be increased in increments of `8` or `8000m`.

If the `cray-hms-hmcollector-ingress` containers are consistency hitting their memory limit, then their memory limit should be increased. It can be increased in increments of `5Gi`.

If the `istio-proxy` container is getting OOMKilled, then its memory limit should be increased in increments of 5 Gigabytes (`5Gi`) at a time.

Otherwise, if the `cray-hms-hmcollector-ingress` and `istio-proxy` containers are not hitting their CPU or memory limits nothing needs to change.

For reference, on a system with 4 fully populated liquid cooled cabinets a single `cray-hms-hmcollector-ingress` pod (replicas = 1) was consuming `~5` or `~5000m` of CPU and `~300Mi` of memory.

<a name="customize-resource-limits"></a>

## Customize cray-hms-hmcollector Replica Count and Resource Limits and Requests in customizations.yaml

1. If the [`site-init` repository is available as a remote repository](../../install/prepare_site_init.md#push-to-a-remote-repository)
   then clone it on the host orchestrating the upgrade:

   ```console
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

   Otherwise, create a new `site-init` working tree:

   ```console
   ncn-m001# git init site-init
   ```

2. Download `customizations.yaml`:

   ```console
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

   ```console
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

4. Update `customizations.yaml` with the existing `cray-hms-hmcollector-ingress` resource limits settings:

   Persist resource requests and limits from the cray-hms-hmcollector-ingress deployment:

   ```console
   ncn-m001# kubectl -n services get deployments cray-hms-hmcollector-ingress \
      -o jsonpath='{.spec.template.spec.containers[].resources}' | yq r -P - | \
      yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.collectorIngressConfig.resources
   ```

   Persist annotations manually added to `cray-hms-hmcollector-ingress` deployment:

   ```console
   ncn-m001# kubectl -n services get deployments cray-hms-hmcollector-ingress \
      -o jsonpath='{.spec.template.metadata.annotations}' | \
      yq d -P - '"traffic.sidecar.istio.io/excludeOutboundPorts"' | \
      yq w -f - -i ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector.podAnnotations
   ```

   View the updated overrides added to `customizations.yaml`. If the value overrides look different to the sample output below then the replica count or the resource limits and requests have been manually modified in the past.

   ```console
   ncn-m001# yq r ./customizations.yaml spec.kubernetes.services.cray-hms-hmcollector
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

5. If desired adjust the replica count or resource limits and requests for `cray-hms-hmcollector-ingress`. Otherwise this step can be skipped.
   Refer to [Resource Limit Tuning Guidance](#resource-limit-tuning) for information on how the resource limits could be adjusted.

   Edit `customizations.yaml` and the value overrides for the `cray-hms-hmcollector-ingress` Helm chart are defined at `spec.kubernetes.services.cray-hms-hmcollector.collectorIngressConfig`

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

   To specify a non-default memory limit for the Istio proxy used by all `cray-hms-hmcollector-*` pods,  `sidecar.istio.io/proxyMemoryLimit` can be added under `podAnnotations`. By default the Istio proxy memory limit is `1Gi`.

   ```yaml
         cray-hms-hmcollector:
            podAnnotations:
               sidecar.istio.io/proxyMemoryLimit: 5Gi
   ```

6. Review the changes to `customizations.yaml` and verify [baseline system customizations](../../install/prepare_site_init.md#create-baseline-system-customizations)
   and any customer-specific settings are correct.

   ```console
   ncn-m001# git diff
   ```

7. Add and commit `customizations.yaml` if there are any changes:

   ```console
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m "Update customizations.yaml consistent with CSM $CSM_RELEASE_VERSION"
   ```

8. Update `site-init` sealed secret in `loftsman` namespace:

   ```console
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

9. Push to the remote repository as appropriate:

   ```console
   ncn-m001# git push
   ```

10. **If this document was referenced during an upgrade procure, then skip.** Otherwise, continue on to [Redeploy cray-hms-hmcollector with new resource limits and requests](#redeploy-cray-hms-hmcollector)
    for the new replica count and resource limits and requests to take effect.

<a name="redeploy-cray-hms-hmcollector"></a>

## Redeploy cray-hms-hmcollector with New Replica Count and Resource Limits and Requests

1. Determine the version of HM Collector:

    ```console
    ncn-m001# HMCOLLECTOR_VERSION=$(kubectl -n loftsman get cm loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-hms-hmcollector).version')
    ncn-m001# echo $HMCOLLECTOR_VERSION
    ```

2. Create `hmcollector-manifest.yaml`:

    ```console
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

   ```console
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

4. Merge `customizations.yaml` with `hmcollector-manifest.yaml`:

    ```console
    ncn-m001# manifestgen -c customizations.yaml -i ./hmcollector-manifest.yaml > ./hmcollector-manifest.out.yaml
    ```

5. Redeploy the HM Collector helm chart:

    ```console
    ncn-m001# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path hmcollector-manifest.out.yaml
    ```
