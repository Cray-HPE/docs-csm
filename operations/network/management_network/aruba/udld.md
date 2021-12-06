# Unidirectional link detection (UDLD)

“The purpose of the UDLD protocol is to detect the presence of anomalous conditions in the Layer 2 communication channel, while relying on the mechanisms defined by the IEEE in the 802.3 standard to properly handle conditions inherent to the physical layer.” –rfc5171 

* Compatible with existing HPE products:
	* Forward-then-verify: packets are forwarded until the link is considered unidirectional
	* Verify-then-forward: packets are not forwarded until the link has been determined to be bidirectional 
* Compatible with RFC5171-compliant devices: 
	* Normal: will determine link unidirectionality but will not block the port 
	* Aggressive: once a port has been determined to be bidirectional and then becomes unidirectional, it will be blocked 

Note: The default UDLD mode is forward-then-verify. 

Relevant Configuration 

Enable UDLD 

```
switch(config-if)# udld
```

Show Commands to Validate Functionality 

```
switch# show udld [interface IFACE]
```

Example Output 

```
switch(config)# interface 1/1/1
switch(config-if)# udld
switch(config-if)# exit
switch# show udld interface 1/1/1
Interface 1/1/1
 Config: enabled
 State: inactive
 Substate: uninitialized
 Link: unblock
 Version: aruba os
 Mode: forward then verify
 Interval: 7000 milliseconds
 Retries: 4
 Tx: 0 packets
 Rx: 0 packets, 0 discarded packets, 0 dropped packets
 Port transitions: 0
```

Expected Results 

* Step 1: You can enable UDLD on an interface
* Step 2: UDLD state should be “Unblocked | UDLD determined the link is bidirectional” 

Notes:
With SFP+ XCVERS, Aruba Switches automatically detect a broken bidirectional link, rendering the port into a down state.

[Back to Index](./index.md)


