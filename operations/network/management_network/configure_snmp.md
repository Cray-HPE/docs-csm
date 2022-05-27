# Configure SNMP

SNMP configuration is required for hardware discovery of the HPE Cray EX system.

These are examples only; verify SNMP credentials before applying this configuration.

For more information on SNMP credentials, see [Change SNMP Credentials on Leaf-BMC Switches](../../security_and_authentication/Change_SNMP_Credentials_on_Leaf_BMC_Switches.md) and [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](../../security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md).

## Dell SNMP

```console
sw-leaf-bmc-001# conf t
   snmp-server group cray-reds-group 3 noauth read cray-reds-view
   snmp-server user testuser cray-reds-group 3 auth md5 xxxxxxxx priv des xxxxxxx
   snmp-server view cray-reds-view 1.3.6.1.2 included
```

## Aruba SNMP

```console
sw-leaf-bmc-001# conf t
   snmp-server vrf default
   snmpv3 user testuser auth md5 auth-pass plaintext xxxxxx priv des priv-pass plaintext xxxxx
```
