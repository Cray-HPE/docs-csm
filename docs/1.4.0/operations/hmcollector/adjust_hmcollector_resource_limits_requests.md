# Adjust HM Collector Ingress Replicas and Resource Limits

* [Replica count and resource limit tuning guidance](#replica-count-and-resource-limit-tuning-guidance)
* [Customize `cray-hms-hmcollector` in `customizations.yaml`](#customize-cray-hms-hmcollector-in-customizationsyaml)
* [Redeploy `cray-hms-hmcollector` with new customizations](#redeploy-cray-hms-hmcollector-with-new-customizations)

## Replica count and resource limit tuning guidance

### Inspect current resource usage

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

### Inspect pods for `OOMKilled` events

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

### How to adjust replicas and limits

* If the `cray-hms-hmcollector-ingress` containers are hitting their CPU limit and memory usage is steadily increasing until they get `OOMKilled`, then the number of replicas should be increased.
  It can be increased in increments of `1`, up to the number of worker nodes. This is a situation were the collector is unable to process events fast enough and they start to build up inside of it.
* If the `cray-hms-hmcollector-ingress` containers are consistently hitting their CPU limit, then their CPU limit should be increased. It can be increased in increments of `8` or `8000m`.
* If the `cray-hms-hmcollector-ingress` containers are consistently hitting their memory limit, then their memory limit should be increased. It can be increased in increments of `5Gi`.
* If the `istio-proxy` container is getting `OOMKilled`, then its memory limit should be increased. It can be increased in increments of `5Gi`.
* Otherwise, if the `cray-hms-hmcollector-ingress` and `istio-proxy` containers are not hitting their CPU or memory limits, then nothing should be changed.

For reference, on a system with four fully populated liquid-cooled cabinets, a single `cray-hms-hmcollector-ingress` pod (with a single replica) was consuming about `5000m` of CPU and
about `300Mi` of memory.

## Customize `cray-hms-hmcollector` in `customizations.yaml`

1. (`ncn-mw#`) If the `site-init` repository is available as a remote repository, then clone it on the host orchestrating the upgrade.

   ```bash
   git clone "$SITE_INIT_REPO_URL" site-init
   ```

   Otherwise, create a new `site-init` working tree:

   ```bash
   git init site-init
   ```

1. (`ncn-mw#`) Download `customizations.yaml`.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

1. (`ncn-mw#`) Review, add, and commit `customizations.yaml` to the local `site-init` repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository, then
   > there may not be any differences, and hence nothing to commit. This is
   > okay. If there are differences between what is in the repository and what
   > was stored in the `site-init`, then it suggests settings were improperly
   > changed at some point. If that is the case, then be cautious.

   ```bash
   cd site-init
   git diff
   git add customizations.yaml
   git commit -m 'Add customizations.yaml from site-init secret'
   ```

1. (`ncn-mw#`) Update `customizations.yaml` with the existing `cray-hms-hmcollector-ingress` resource settings.

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

1. (`ncn-mw#`) If desired, adjust the replica count, resource limits, and resource requests for `cray-hms-hmcollector-ingress`.

   Otherwise this step can be skipped.

   For information on possible adjustments, see [Replica count and resource limit tuning guidance](#replica-count-and-resource-limit-tuning-guidance).

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

1. (`ncn-mw#`) Review the changes to `customizations.yaml`.

   Verify that [baseline system customizations](../../install/prepare_site_init.md#3-create-baseline-system-customizations)
   and any customer-specific settings are correct.

   ```bash
   git diff
   ```

1. (`ncn-mw#`) Add and commit `customizations.yaml` if there are any changes.

   ```bash
   git add customizations.yaml
   git commit -m "Update customizations.yaml consistent with CSM $CSM_RELEASE_VERSION"
   ```

1. (`ncn-mw#`) Update the `site-init` sealed secret in the `loftsman` namespace.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. (`ncn-mw#`) Push to the remote repository, if applicable.

   ```bash
   git push
   ```

1. **If this document was referenced during an upgrade procure, then skip the rest of this page.**

   Otherwise, proceed to [Redeploy `cray-hms-hmcollector` with new customizations](#redeploy-cray-hms-hmcollector-with-new-customizations)
   in order for the new replica count and resource limits and requests to take effect.

## Redeploy `cray-hms-hmcollector` with new customizations

1. (`ncn-mw#`) Determine the version of HM Collector:

    ```bash
    kubectl -n loftsman get cm loftsman-sysmgmt -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-hms-hmcollector).version'
    ```

1. (`ncn-mw#`) Create `hmcollector-manifest.yaml` with the following contents.

    > Be sure to replace `<HMCOLLECTOR_VERSION>` with the version determined in the previous step.

    ```yaml
    apiVersion: manifests/v1beta1
    metadata:
        name: hmcollector
    spec:
        charts:
        - name: cray-hms-hmcollector
          version: <HMCOLLECTOR_VERSION>
          namespace: services
    ```

1. (`ncn-mw#`) Acquire `customizations.yaml`.

   This step can be skipped if the `customizations.yaml` file is still available from the
   [Customize `cray-hms-hmcollector` in `customizations.yaml`](#customize-cray-hms-hmcollector-in-customizationsyaml) procedure.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. (`ncn-mw#`) Merge `customizations.yaml` with `hmcollector-manifest.yaml`.

    ```bash
    manifestgen -c customizations.yaml -i ./hmcollector-manifest.yaml > ./hmcollector-manifest.out.yaml
    ```

1. (`ncn-mw#`) Redeploy the HM Collector Helm chart.

    ```bash
    loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path hmcollector-manifest.out.yaml
    ```
