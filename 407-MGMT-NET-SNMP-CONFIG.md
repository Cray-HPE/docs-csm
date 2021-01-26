# Management Network SNMP configuration

# Requirements
Access to switches

This configuration is required for hardware discovery of the shasta system.
It needs to be applied on all switches that are connected to BMCs

```
sw-smn01(config)# snmp-server vrf default
sw-smn01(config)# snmp-server system-contact "Contact Cray Global Technical Services (C.G.T.S.)"
sw-smn01(config)# snmpv3 user testuser auth md5 auth-pass plaintext testpass1 priv des priv-pass plaintext text
```