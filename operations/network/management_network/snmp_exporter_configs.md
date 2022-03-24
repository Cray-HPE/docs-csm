# Prometheus SNMP Exporter 
The Prometheus SNMP Exporter is deployed by the the `cray-sysmgmt-health` chart to the `sysmgmt-health` namespace as part of the Cray System Management \(CSM\) release.

### Configuration

In order to provide data to the Grafana SNMP dashboards the SNMP Exporter must be configured with a list of management network switches to scrape metrics from.

1. Set the `SYSTEM_NAME` variable if not already set.

```bash
linux# SYSTEM_NAME=eniac
```

1. Obtain the list of switches to use as targets using CSM Automatic Network Utility (CANU).

```bash
linux# canu init --sls-file /var/www/ephemeral/prep/${SYSTEM_NAME}/sls_input_file.json --out -
10.252.0.2
10.252.0.3
10.252.0.4
10.252.0.5
4 IP addresses saved to <stdout>
```

1. Update customizations.yaml with the list of switches.

```bash
linux# yq write -s - -i /mnt/pitdata/prep/site-init/customizations.yaml <<EOF
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
linux# yq r /mnt/pitdata/prep/site-init/customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter
```

The expected output looks similar to

```
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

The most common configuration parameters are specified in the following table. They must be set in the customizations.yaml file under the `spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter` service definition.

|Customization|Default|Description|
|-------------|-------|-----------|
|`serviceMonitor.enabled`|`true`|Enables serviceMonitor for snmp exporter \(default chart value is `true`\)|
|`params.enabled`|`false`|Sets the snmp exporter params change to true \(default chart value is `false`\)|
|`params.conf.module`|`if_mib`| snmp exporter to select which module \(default chart value is `if_mib`\)|
|`params.conf.target`|`127.0.0.1`| add list of switch targets to snmp exporter to monitor \(default chart value is `127.0.0.1`\)|

For a complete set of available parameters, consult the values.yaml file for the `cray-sysmgmt-health` chart.
