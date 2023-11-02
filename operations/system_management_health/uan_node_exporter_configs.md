# UAN NODE Exporter

The Prometheus UAN NODE Exporter service, service monitor and endpoints are deployed to scrape SMARTMON data by the `cray-sysmgmt-health` chart in the `sysmgmt-health` namespace as part of the Cray System Management \(CSM\) release.

## Configuration

In order to provide data to the Grafana SMART dashboards, the UAN NODE Exporter must be configured with a list of UAN
NMN IP Address to scrape metrics from.

### Pre-install CSM

> **`NOTE`** All variables used within this page depend on the `/etc/environment` setup done in [Pre-installation](../../install/pre-installation.md).

1. Obtain the list of site specific UAN NMN IP Address.

1. (`pit#`) Update `customizations.yaml` with the list of UAN nodes IPs.

    ```bash
    yq write -s - -i ${PITDATA}/prep/site-init/customizations.yaml <<EOF
    - command: update
      path: spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter
      value:
                enabled: true
                endpoints:
                - 10.252.1.18
                - 10.252.1.13
    EOF
    ```

1. (`pit#`) Review the UAN NODE Exporter configuration.

    ```bash
    yq r ${PITDATA}/prep/site-init/customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter
    ```

   The expected output looks similar to:

    ```yaml
    uanNodeExporter:
      enabled: true
      endpoints:
      - 10.252.1.18
      - 10.252.1.13
    ```

The most common configuration parameters are specified in the following table. They must be set in the `customizations.yaml` file
under the `spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter` service definition.

| Customization | Default       | Description                                                                |
|---------------|---------------|----------------------------------------------------------------------------|
| `enabled`     | `false`       | Enables `service` for UAN NODE Exporter \(default chart value is `false`\) |
| `endpoints`   | `10.252.1.13` | list of UAN NMN IP Address to monitor SMARTMON data                        |

For a complete set of available parameters, consult the `values.yaml` file for the `cray-sysmgmt-health` chart.

### Post-install CSM

This procedure is to configure the UAN NODE Exporter once the PIT node no longer exists by editing manifest and deploying `cray-sysmgmt-health chart`.

1. (`uan#`) Obtain the list of UAN NMN IP Address.
    Login to UAN node
   (`uan#`)

    ```bash
    hostname -i
    ```

   Expected output looks similar to the following:

    ```text
    ::1 127.0.0.1 10.252.1.13
    ```

1. (`ncn#`) Get the current cached customizations.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
   ```

1. (`ncn#`) Get the current cached platform manifest.

   ```bash
   kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}'  > platform.yaml
   ```

1. (`ncn#`) Update `customizations.yaml` with the list of UAN nodes IPs.

    ```bash
    yq write -s - -i customizations.yaml <<EOF
    - command: update
      path: spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter
      value:
                enabled: true
                endpoints:
                - 10.252.1.18
                - 10.252.1.13
    EOF
    ```

1. (`ncn#`) Review the UAN NODE Exporter configuration.

    ```bash
    yq r customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.uanNodeExporter
    ```

   The expected output looks similar to:

    ```yam
      enabled: true
      endpoints:
      - 10.252.1.18
      - 10.252.1.13
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
       version: 0.28.9
   ```

1. (`ncn#`) Generate the manifest that will be used to redeploy the chart with the modified resources.

   ```bash
   manifestgen -c customizations.yaml -i platform.yaml -o manifest.yaml
   ```

1. (`ncn#`) Check that the manifest file contains the desired resource settings.

   ```bash
   yq read manifest.yaml 'spec.charts.(name==cray-sysmgmt-health).values.uanNodeExporter'
   ```

   Example output:

   ```yaml
      enabled: true
      endpoints:
      - 10.252.1.18
      - 10.252.1.13

   ```

1. (`ncn#`) Redeploy the same chart version but with the desired UAN NODE Exporter configuration settings.

   ```bash
   loftsman ship --charts-path /etc/cray/upgrade/csm/csm-${CSM_RELEASE}/tarball/csm-${CSM_RELEASE}/helm/ --manifest-path manifest.yaml
   ```

   Here, `/etc/cray/upgrade/csm/csm-${CSM_RELEASE}/tarball/csm-${CSM_RELEASE}/helm/` is the path of the `cray-sysmgmt-health` chart.

1. (`ncn#`) **This step is critical.** Store the modified `customizations.yaml` file in the `site-init` repository in the customer-managed location.

   If this is not done, these changes will not persist in future installs or upgrades.

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. (`ncn#`) Verify that the changes are in place.

   ```bash
   kubectl get endpoints cray-sysmgmt-health-uan-node-exporter -n sysmgmt-health -o json | jq -r '.subsets[0].addresses'
   ```

   Example output:

   ```json
   [
     {
       "ip": "10.252.1.18"
     },
     {
       "ip": "10.252.1.13"
     }
   ]    
   ```
