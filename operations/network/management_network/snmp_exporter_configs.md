# Prometheus SNMP Exporter

The Prometheus SNMP Exporter is deployed by the `cray-sysmgmt-health` chart to the `sysmgmt-health` namespace as part of
the [Cray System Management (CSM)](../../../glossary.md#cray-system-management-csm) release.

## Configuration

In order to provide data to the Grafana SNMP dashboards, the SNMP Exporter must be configured with a list of management network switches to scrape metrics from.

This procedure assumes that this is being done as part of a CSM install as part of the
[Prepare `site-init`](../../../install/prepare_site_init.md#configure-prometheus-snmp-exporter) procedure.
Specifically, it assumes that the `SYSTEM_NAME` and `PITDATA` variables are set, and that the `PITDATA` mount is
in place.

1. Obtain the list of switches to use as targets using [CSM Automatic Network Utility (CANU)](../../../glossary.md#csm-automatic-network-utility-canu).

    ```bash
    linux# canu init --sls-file ${PITDATA}/prep/${SYSTEM_NAME}/sls_input_file.json --out -
    ```

    Expected output looks similar to the following:

    ```text
    10.252.0.2
    10.252.0.3
    10.252.0.4
    10.252.0.5
    4 IP addresses saved to <stdout>
    ```

1. Update `customizations.yaml` with the list of switches.

    ```bash
    linux# yq write -s - -i ${PITDATA}/prep/site-init/customizations.yaml <<EOF
    - command: update
      path: spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter
      value:
              serviceMonitor:
                enabled: true
                params:
                  enabled: true
                  conf:
                    module:
                    - if_mib
                    target:
                    - 127.0.0.1
                    - 10.252.0.2
                    - 10.252.0.3
                    - 10.252.0.4
                    - 10.252.0.5
    EOF
    ```

1. Review the SNMP Exporter configuration.

    ```bash
    linux# yq r ${PITDATA}/prep/site-init/customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter
    ```

    The expected output looks similar to:

    ```yaml
    serviceMonitor:
      enabled: true
      params:
        enabled: true
        conf:
          module:
            - if_mib
          target:
            - 127.0.0.1
            - 10.252.0.2
            - 10.252.0.3
            - 10.252.0.4
            - 10.252.0.5
    ```

The most common configuration parameters are specified in the following table. They must be set in the `customizations.yaml` file
under the `spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter` service definition.

| Customization            | Default     | Description                                                                                  |
|--------------------------|-------------|----------------------------------------------------------------------------------------------|
| `serviceMonitor.enabled` | `true`      | Enables `serviceMonitor` for SNMP Exporter \(default chart value is `true`\)                 |
| `params.enabled`         | `false`     | Sets the SNMP Exporter `params` change to `true` \(default chart value is `false`\)          |
| `params.conf.module`     | `if_mib`    | SNMP Exporter to select which module \(default chart value is `if_mib`\)                     |
| `params.conf.target`     | `127.0.0.1` | Add list of switch targets to SNMP Exporter to monitor \(default chart value is `127.0.0.1`\)|

For a complete set of available parameters, consult the `values.yaml` file for the `cray-sysmgmt-health` chart.

## Configuration after CSM install

This procedure is to correct the SNMP exporter settings once the PIT node no longer exists by editing manifest and deploying `cray-sysmgmt-health chart`.

1. Get the current cached customizations.

   ```bash
   ncn-mw# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' |
                base64 -d > customizations.yaml
   ```

1. Get the current cached platform manifest.

   ```bash
   ncn-mw# kubectl get cm -n loftsman loftsman-platform -o jsonpath='{.data.manifest\.yaml}'  > platform.yaml
   ```

1. Edit the customizations as desired by adding or updating `spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter`.

   ```bash
   ncn-mw# yq write -s - -i /root/customizations.yaml <<EOF
   - command: update
     path: spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter
     value:
             serviceMonitor:
               enabled: true
               params:
                 enabled: true
                 conf:
                   module:
                   - if_mib
                   target:
                   - 127.0.0.1s
                   - 10.252.0.2
                   - 10.252.0.3
                   - 10.252.0.4
                   - 10.252.0.5
   EOF
   ```

1. Check that the customization file has been updated.

   ```bash
   ncn-mw# yq read customizations.yaml "spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter"
   ```

   Example output:

   ```yaml
   serviceMonitor:
     enabled: true
     params:
       enabled: true
       conf:
         module:
         - if_mib
         target:
         - 127.0.0.1
         - 10.252.0.2
         - 10.252.0.3
         - 10.252.0.4
         - 10.252.0.5
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

1. Generate the manifest that will be used to redeploy the chart with the modified resources.

   ```bash
   ncn-mw# manifestgen -c customizations.yaml -i platform.yaml -o manifest.yaml
   ```

1. Check that the manifest file contains the desired resource settings.

   ```bash
   ncn-mw# yq read manifest.yaml 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-snmp-exporter'
   ```

   Example output:

   ```yaml
   serviceMonitor:
     enabled: true
     params:
       enabled: true
       conf:
         module:
         - if_mib
         target:
         - 127.0.0.1
         - 10.252.0.2
         - 10.252.0.3
         - 10.252.0.4
         - 10.252.0.5
   ```

1. Redeploy the same chart version but with the desired SNMP configuration settings.

   ```bash
   ncn-mw# loftsman ship charts-path /helm --manifest-path /root/manifest.yaml
   ```

1. Verify that the pod restarts and that the desired resources have been applied.

   Watch the `cray-sysmgmt-health-prometheus-snmp-exporter-*` pod restart.

   ```bash
   ncn-mw# watch "kubectl get pods -n sysmgmt-health -l app.kubernetes.io/name=prometheus-snmp-exporter"
   ```

   It may take about 10 minutes for the `cray-sysmgmt-health-prometheus-snmp-exporter-*` pod to terminate.
   It can be forced deleted if it remains in the terminating state:

   ```bash
   ncn-mw# kubectl delete pod cray-sysmgmt-health-prometheus-snmp-exporter-* --force --grace-period=0 -n sysmgmt-health
   ```

1. Store the modified `customizations.yaml` file in the `site-init` repository in the customer-managed location.

   **This step is critical.** If this is not done, then these changes will not persist in future installs or upgrades.

   ```bash
   ncn-mw# kubectl delete secret -n loftsman site-init
   ncn-mw# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Verify that the resource changes are in place.

   ```bash
   ncn-mw# kubectl get servicemonitor cray-sysmgmt-health-prometheus-snmp-exporter -n sysmgmt-health -o json |
                jq -r '.spec.endpoints[].params'
   ```

   Example output:

   ```json
   {
   "module": [
      "if_mib"
    ],
   "target": [
      "10.254.0.2"
    ]
   }
   ```
