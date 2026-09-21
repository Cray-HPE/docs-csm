# Management Interface

The management interface can be used to gain remote management access to the switch.
The management interface is accessible using the `mgmt` VRF and is separate from the
data plane interfaces, which are in the `default` VRF.

Alternatively, a loopback interface can be configured to be used as management interface.

## Configuration commands

(`switch#`) Configure the management interface in configuration mode:

```text
interface mgmt 1/1/1
```

(`switch#`) Configure an IP address and mask on the management interface in interface mode:

```text
ip address A.B.C.D/prefix-length
```

(`switch#`) (Optional) Configure DHCP client operations in interface mode.
By default, the DHCP client is enabled on the management interface:

```text
dhcp
```

(`switch#`) Enable the management interface in interface mode:

```text
no shutdown
```

## Expected results

* Administrators can enable/disable the management interface.
* Administrators can assign an IP address to the management interface.
* Administrators can configure a loopback interface to be use for switch management.

[Back to Index](../README.md)
