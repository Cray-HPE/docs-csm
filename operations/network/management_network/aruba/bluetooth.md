# Bluetooth Capabilities

The Bluetooth feature allows Bluetooth enabled devices to connect to and manage
the switch on a wireless Bluetooth Personal Area Network (PAN). The user needs a
supported USB Bluetooth dongle and to enable both the USB port and Bluetooth on
the switch to use this feature. Bluetooth and REST write permissions for Bluetooth
clients are both enabled by default.

## Configuration commands

Turn on the USB port:

```console
usb mount
```

Enable Bluetooth:

```console
bluetooth enable
```

## Show commands to validate functionality

```console
show bluetooth
```

Example output:

(`Switch(config)#`) Bluetooth enabled:

```console
bluetooth enable
```

Output:

```text
Enabled
```

```console
show bluetooth
```

Output:

```text
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

(`Switch(config)#`) Bluetooth not enabled:

```console
no Bluetooth enable
show bluetooth
```

Output:

```text
Enabled             : No
```

## Expected results

* The USB mounts properly
* Administrators can see and connect to the Bluetooth PAN
* Administrators can edit the configuration via the Bluetooth connection
* The output of the show commands looks correct

[Back to Index](../README.md)
