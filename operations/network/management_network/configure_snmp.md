<!-- markdownlint-disable MD013 -->
<!-- snmp-authentication-tag -->
<!-- When updating this information, search the docs for the snmp-authentication-tag to find related content -->
<!-- These comments can be removed once we adopt HTTP/lw-dita/Generated docs with re-usable snippets -->
# Configure SNMP

## A Note About SNMP

SNMP configuration is required for hardware discovery of the HPE Cray EX system.  It is also used for configuration of the Prometheus SNMP Exporter.  

A good summary of all of the SNMP touchpoints and procedures can be found on the [SNMP Exporter Configs](./snmp_exporter_configs.md) page, including

* Updating Vault with the SNMP credentials
* Updating customizations.yaml with SNMP sealed secrets
* Updating the SNMP configuration on the management network switches

 If the REDS Hardware Discovery or the Prometheus SNMP Exporter are not working correctly, the [SNMP Exporter Configs](./snmp_exporter_configs.md) page should be reviewed.  The various SNMP use cases in the system depend on SNMP being properly configured on the management network switches and the stored credentials matching configuration stored in both Vault and customizations.yaml.

## Examples

 The following are examples only; verify SNMP credentials before applying this configuration.

### Dell SNMP

Find Dell specific documentation in the [Dell Management Docs](./dell/README.md)

```console
conf t
   snmp-server group cray-reds-group 3 noauth read cray-reds-view
   snmp-server user testuser cray-reds-group 3 auth md5 xxxxxxxx priv des xxxxxxx
   snmp-server view cray-reds-view 1.3.6.1.2 included
```

### Aruba SNMP

Find Aruba specific documentation in the [Aruba Management Docs](./aruba/README.md).

```console
conf t
   snmp-server vrf default
   snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxx
```

### Mellanox SNMP

Note: REDS Hardware Discovery only scans leaf switches and Mellanox switches are only used as spines.  As such, SNMP on the Mellanox switches is only used by the Prometheus SNMP Exporter.

Find Mellanox specific documentation in the [Mellanox Management Docs](./mellanox/README.md)

```console
    snmp-server user testuser v3 capability admin
    snmp-server user testuser v3 enable
    snmp-server user testuser v3 enable sets
    snmp-server user testuser v3 encrypted auth md5 xxxxxxx priv des xxxxxxx
    snmp-server user testuser v3 require-privacy
```
