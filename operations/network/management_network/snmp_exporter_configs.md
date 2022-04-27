# Prometheus SNMP Exporter

The Prometheus SNMP Exporter is deployed by the the `cray-sysmgmt-health` chart to the `sysmgmt-health` namespace as part of the Cray System Management \(CSM\) release.

## Configuration

In order to provide data to the Grafana SNMP dashboards, the SNMP Exporter must be configured with a list of management network switches to scrape metrics from.

This procedure assumes that this is being done as part of a CSM install as part of the
[Prepare Site Init](../../../install/prepare_site_init.md#configure-prometheus-snmp-exporter) procedure.
Specifically, it assumes that the `SYSTEM_NAME` and `PITDATA` variables are set, and that the `PITDATA` mount is
in place.

1. Obtain the list of switches to use as targets using CSM Automatic Network Utility (CANU).

    ```bash
    linux# canu init --sls-file ${PITDATA}/prep/${SYSTEM_NAME}/sls_input_file.json --out -
    ```

    Expected output looks similar to the following:
    ```
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

The most common configuration parameters are specified in the following table. They must be set in the `customizations.yaml` file under the `spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter` service definition.

|Customization|Default|Description|
|-------------|-------|-----------|
|`serviceMonitor.enabled`|`true`|Enables `serviceMonitor` for SNMP exporter \(default chart value is `true`\)|
|`params.enabled`|`false`|Sets the snmp exporter params change to true \(default chart value is `false`\)|
|`params.conf.module`|`if_mib`| SNMP exporter to select which module \(default chart value is `if_mib`\)|
|`params.conf.target`|`127.0.0.1`| Add list of switch targets to SNMP exporter to monitor \(default chart value is `127.0.0.1`\)|

For a complete set of available parameters, consult the `values.yaml` file for the `cray-sysmgmt-health` chart.
