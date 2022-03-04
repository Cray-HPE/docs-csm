## Prometheus SNMP Exporter Deployment
Prometheus SNMP Exporter is deployed with the `cray-sysmgmt-health` chart to the `sysmgmt-health` namespace as part of the Cray System Management \(CSM\) release.

### Customizations

For a complete set of available settings, consult the values.yaml file for the `cray-sysmgmt-health` chart. The most common customizations to set are specified in the following table. They must be set in the customizations.yaml file under the `prometheus-snmp-exporter:` setting.

|Customization|Default|Description|
|-------------|-------|-----------|
|`serviceMonitor.enabled`|`true`|Enables serviceMonitor for snmp exporter \(default chart value is `true`\)|
|`params.enabled`|`false`|Sets the snmp exporter params change to true \(default chart value is `false`\)|
|`params.conf.module`|`if_mib`| snmp exporter to select which module \(default chart value is `if_mib`\)|
|`params.conf.target`|`127.0.0.1`| add list of switch targets to snmp exporter to monitor \(default chart value is `127.0.0.1`\)|

The prometheus-snmp-exporter block in the customizations.yaml file will look similar to the following:

      cray-sysmgmt-health:
	    prometheus-snmp-exporter:
          serviceMonitor:
            enabled: true
            params:
              enabled: true
              conf:
                module:
                - if_mib
                target:
                - 127.0.0.1

#### Obtain the list of switches to use as targets

From the command line to run:
Example:

```
ncn-m001-pit:~ # canu init --sls-file /var/www/ephemeral/prep/wasp/sls_input_file.json --out -
10.252.0.2
10.252.0.3
10.252.0.4
10.252.0.5
4 IP addresses saved to <stdout>
```
