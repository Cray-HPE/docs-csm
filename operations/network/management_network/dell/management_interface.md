# Configure Management Interface

The management interface can be used to gain remote management access to the switch. The management interface is accessible using the "mgmt" VRF and is separate from the data plane interfaces, which are in the "default" VRF.

Alternatively, a loopback interface can be configured to be used as management interface.

## Configuration Commands

Configure the Management interface in CONFIGURATION mode:

```
interface mgmt 1/1/1
```

Configure an IP address and mask on the Management interface in INTERFACE mode:

```
ip address A.B.C.D/prefix-length
```

(Optional) Configure DHCP client operations in INTERFACE mode. By default, DHCP client is enabled on the Management interface:

dhcp

Enable the Management interface in INTERFACE mode:

```
no shutdown
```

## Expected Results

1. Administrators can enable/disable the management interface
2. Administrators can assign an IP address to the management interface
3. Administrators can configure a loopback interface to be use for switch management

[Back to Index](index.md)

