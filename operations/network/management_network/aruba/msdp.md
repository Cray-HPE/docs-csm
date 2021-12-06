# MSDP

The Multicast Source Discovery Protocol (MSDP) describes a mechanism to connect multiple IP Version 4 Protocol Independent Multicast Sparse-Mode (PIM-SM) domains together. Each PIM-SM domain uses its own independent Rendezvous Point (RP) and does not have to depend on RPs in other domains. When an RP in a PIM-SM domain first learns of a new sender, e.g., via PIM register messages, it constructs a “Source-Active” (SA) message and sends it to its MSDP peers. The SA message contains the following fields:

* The source address of the data source.
* The group address the data source sends to.
* The IP IP address of the RP.

–rfc3618

Relevant Configuration

MSDP is typically run on an IP address bound to a loopback interface. In order for two devices to establish an MSDP neighbor relationship, L3 connectivity must already be established.

```
switch(config)# router msdp
switch(config-msdp)# enable
switch(config-msdp)# ip msdp peer <IP>
switch(config-msdp-peer)# enable
switch(config-msdp-peer)# connect-source <IFNAME>
```

Show Commands to Validate Functionality

```
switch# show ip msdp peer
switch# show ip msdp count
switch# show ip msdp sa-cache
```

Test Steps:
1.	Configure a loopback interface on both 8325 that are acting as core devices.
2.	Enable PIM on loopback interface
3.	Configure MSDP and create a peer relationship between 8325’s using a loopback as the source.
Expected Results.
1.	Verify MSDP session is Up and it is using loopback interface as source.

[Back to Index](./index.md)