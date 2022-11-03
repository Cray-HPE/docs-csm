# Prometheus SNMP Exporter

The Prometheus SNMP Exporter is deployed by the `cray-sysmgmt-health` chart to the `sysmgmt-health` namespace as part of the Cray System Management \(CSM\) release.

## Configuration

In order to provide data to the Grafana SNMP dashboards, the SNMP Exporter must be configured with a list of management network switches to scrape metrics from.

> **`NOTE`** All variables used within this page depend on the `/etc/environment` setup done in the [pre-installation document](../../../install/pre-installation.md).

1. (`pit#`) Obtain the list of switches to use as targets using CSM Automatic Network Utility (CANU).

    ```bash
    canu init --sls-file ${PITDATA}/prep/${SYSTEM_NAME}/sls_input_file.json --out -
    ```

    Expected output looks similar to the following:

    ```bash
    10.252.0.2
    10.252.0.3
    10.252.0.4
    10.252.0.5
    4 IP addresses saved to <stdout>
    ```

1. (`pit#`) Update `customizations.yaml` with the list of switches.

    ```bash
    yq write -s - -i ${PITDATA}/prep/site-init/customizations.yaml <<EOF
    - command: update
      path: spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter
      value:
              serviceMonitor:
                enabled: true
                params:
                - name: snmp1
                  target: 10.252.0.2
                - name: snmp2
                  target: 10.252.0.3
                - name: snmp3
                  target: 10.252.0.4
    EOF
    ```

1. (`pit#`) Review the SNMP Exporter configuration.

    ```bash
    yq r ${PITDATA}/prep/site-init/customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter
    ```

    The expected output looks similar to:

    ```yaml
    serviceMonitor:
      enabled: true
      params:
      - name: snmp1
        target: 10.252.0.2
      - name: snmp2
        target: 10.252.0.3
      - name: snmp3
        target: 10.252.0.4
    ```

The most common configuration parameters are specified in the following table. They must be set in the `customizations.yaml` file under the `spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter` service definition.

|Customization|Default|Description|
|-------------|-------|-----------|
|`serviceMonitor.enabled`|`true`|Enables `serviceMonitor` for SNMP exporter \(default chart value is `true`\)|
|`params.enabled`|`true`|Sets the SNMP exporter `params` change to true \(default chart value is `false`\)|
|`params.conf.module`|`if_mib`| SNMP exporter to select which module \(default chart value is `if_mib`\)|
|`params.conf.target`|`10.252.0.2`| Add list of switch targets to SNMP exporter to monitor|

For a complete set of available parameters, consult the `values.yaml` file for the `cray-sysmgmt-health` chart.
