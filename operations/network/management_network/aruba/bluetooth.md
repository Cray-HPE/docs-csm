# Bluetooth Capabilities

The Bluetooth feature allows Bluetooth enabled devices to connect to and manage the switch on a wireless Bluetooth Personal Area Network (PAN). The user needs a supported USB Bluetooth dongle and to enable both the USB port and Bluetooth on the switch to use this feature. Bluetooth and REST write permissions for Bluetooth clients are both enabled by default.

## Configuration Commands

Turn on the USB port:

```
usb mount
```

Enable Bluetooth:

```
bluetooth enable
```

Show Commands to Validate Functionality:

```
show bluetooth
```

## Example Output

Bluetooth enabled:

```
Switch(config)# bluetooth enable
Switch(config)# show bluetooth
Enabled
Device name
Adapter State
Adapter IP address  : 192.168.0.1
Adapter MAC address : e0x34-60126
: Yes
: 8320-TJ12690890
: Ready
Connected Clients
-----------------
Name                   MAC Address
---------------------- -------------- ---------------- ------------------------
```

Bluetooth not enabled:

```
no Bluetooth enable
show bluetooth
Enabled             : No
```

## Expected Results

1. The USB mounts properly
1. Administrators can see and connect to the Bluetooth PAN
1. Administrators can edit the configuration via the Bluetooth connection
1. The output of the show commands looks correct

[[Back to Index](../README.md)
