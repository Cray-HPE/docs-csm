
## Aruba SNMP Known Issue

### Affected Devices

`8320`/`8325`/`8360` Aruba CX

### Aruba Defect

CR `153440`

### Aruba Public Documentation/Images

Aruba support portal:

> https://asp.arubanetworks.com/

Aruba 8325 release notes 10.06.0120:

> https://www.arubanetworks.com/techdocs/AOS-CX/10.06/RN/5200-8179.pdf

Aruba 8360 release notes 10.06.0120:

> https://www.arubanetworks.com/techdocs/AOS-CX/10.06/RN/5200-8180.pdf

### Where the Issue May Occur During Install

During initial network discovery of Nodes, SNMP may not accurately report MAC-address from Aruba Leaf/Spine switches. This will lead to a situation where not all connected devices are discovered as expected. Further troubleshooting would show that the SNMP walk output would not match 'show mac-address-table' command output from the switch.

### Symptom/Scenario

The SNMP walk output of `OID BRIDGE-MIB::dot1dTpFdbAddress` returns fewer MAC addresses than the show mac-address-table command.

### Workaround

Delete the SNMP configuration from the affected switch and reconfigure the SNMP server. Refer to the "SNMP configuration" section of the [Configure Aruba Leaf Switch](configure_aruba_leaf_switch.md) procedure for more information.

