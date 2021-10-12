# Bluetooth capabilities 

The Bluetooth feature allows Bluetooth enabled devices to connect to and manage the switch on a wireless Bluetooth Personal Area Network (PAN). The user needs a supported USB Bluetooth dongle and to enable both the USB port and Bluetooth on the switch to use this feature. Bluetooth and REST write permissions for Bluetooth clients are both enabled by default. 

Relevant Configuration 

Turn on the USB port 

```
switch# usb mount
```

Enable Bluetooth 

```
switch# bluetooth enable
```

Show Commands to Validate Functionality 

```
switch# show bluetooth

Example Output 
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

Switch# no Bluetooth enable
Switch# show bluetooth
Enabled             : No
```

Expected Results 

* Step 1: The USB mounts properly
* Step 2: You can see and connect to the Bluetooth PAN
* Step 3: You can edit the configuration via the Bluetooth connection 
* Step 4: The output of the show commands looks correct


[[Back to Index](./index.md)