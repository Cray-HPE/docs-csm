## Prometheus SNMP Exporter Deployment
rometheus SNMP Exporter is deployed with the `cray-sysmgmt-health` chart to the `sysmgmt-health` namespace as part of the Cray System Management \(CSM\) release.

### Customizations

For a complete set of available settings, consult the values.yaml file for the `cray-sysmgmt-health` chart. The most common customizations to set are specified in the following table. They must be set in the customizations.yaml file under the `prometheus-snmp-exporter:` setting.

|Customization|Default|Description|
|-------------|-------|-----------|
|`serviceMonitor.enabled`|`true`|Enables serviceMonitor for snmp exporter \(default chart value is `true`\)|
|`params.enabled`|Sets the snmp exporter params change to true \(default chart value is `false`\)|
|`params.conf.module`| snmp exporter to select which module \(default chart value is `if_mib`\)|
|`params.conf.target`| add list of switch targets to snmp exporter to monitor \(default chart value is `127.0.0.1`\)|

#### Obtain the list of switches to as targets

From the command line on NCN m001 run:

```bash
grep 'sw-' /etc/hosts
```

Example:

```bash
ncn-m001:~ # grep 'sw-' /etc/hosts
10.252.0.2 sw-spine-001
10.252.0.3 sw-spine-002
10.252.0.4 sw-leaf-001
