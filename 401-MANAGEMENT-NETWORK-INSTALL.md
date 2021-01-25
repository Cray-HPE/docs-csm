# Overview
1. [Shasta v1.3 to v1.4 Upgrades](#shasta-v1.3-to-v1.4-changes)
1. Firmware - to get 8325 100G
1. Base config incl OSPFv3
1. Access to m001 and iLO
1. CSI tool
1. enable sw-leaf-001 access from m001
  1. Serial connection to sw-leaf-01 connected to m001 
  1. config leaf VSX and MC-LAG to enable m001 connection via IPv6 VLAN1
1. Config all switches via IPv6 connection from m001
  1. Layer 2 config: VLANs, VSX pairs, MTU, BMC access ports, switch uplink ports
  1. Create the CAN
  1. Layer 3 config: L3 interfaces, static CAN routes, ACLs.
  1. Layer 3 dynamic routing: OSPFv2


  TODO:  
  * links to json templates and json configs
  * focus on the manual steps
  * all links need to be resolvable by customers or pulled in locally
  ** switch matrix of model and purpose **
  * make links to other install docs

 # Shasta v1.3 to v1.4 Changes
 ### Overview - Management Network Changes from v1.3.2 to v1.4

The Network architecture and configuration from 1.3 to 1.4 is fairly small, the biggest change is the introduction of HPE/Aruba switches, as well as CSI generating switch IPs. Most of the configuration changes to get a system from 1.3 to 1.4 are covered in the [1.3.2](https://connect.us.cray.com/confluence/display/SSI/Management+Network+Changes+for+Shasta+1.3.2) doc.

### New for v1.4

*   The IP-Helper will reside on the switches where the default gateway for the servers, such as bmcs and computes, is configured.
*   IP-Helper applied on vlan 1 and vlan 7, this will point to 10.92.100.222.
*   Make sure 1.3.2 changes are applied, this includes flow-control and MAGP changes.
*   Remove BPDUfilter on the Dell access ports.
    
*   Add BPDUguard to the Dell access ports.
    
*   Aruba/HPE switches.
*   Moving Site connection from ncn-w001 to ncn-m001
*   OSPFv3 Base config for manufacturing.
*   ACL configuration

### Recommended Mellanox Changes

*   MLAG-VIP, this requires an additional cable wired between the mgmt ports of the mellanox switches.
    *   This is the recommended configuration by mellanox.
    *   We have this running on internal systems without any issues.
*   Turn off spanning-tree, no testing is done on this. This is the recommended configuration when using MAGP on mellanox.
    *   [https://community.mellanox.com/s/article/how-to-configure-mlag-on-mellanox-switches](https://community.mellanox.com/s/article/how-to-configure-mlag-on-mellanox-switches)

  


 ### Improvements for Redundant Spines

In Shasta V1.3 the Shasta Management Network (SMNet) enabled a redundant spine configuration. The release of v1.3 enabled redundancy on layers 1 and 2 of the OSI model. In the v1.3.2 patch the SMNet enables the dual spine configuration on the IP/Routing of OSI layer 3. This added capability will allow for a redundant next-hop gateway for the following networks: NMN, HMN and CAN. This will ensure that routing between these networks will not fail when a single spine fails as the that is the failure scenario on v1.3.

In Shasta v1.3.2 the SMNet will enable Mellanox’s Multi-active gateway protocol to achieve load balanced redundant gateways. The following steps are done to achieve this:

If not already present, enable MAGP on the spine switches:

protocol magp

NMN (VLAN 2):

HMN (VLAN 4):

CAN (VLAN 7):

**If you are making changes to VLAN 7, please update the Confluence page below to ensure that the information does not go out of sync!**  
[https://connect.us.cray.com/confluence/pages/viewpage.action?spaceKey=CASMPET&title=CAN-BGP+status+on+Shasta+systems](https://connect.us.cray.com/confluence/pages/viewpage.action?spaceKey=CASMPET&title=CAN-BGP+status+on+Shasta+systems)

You will need to choose an IP address in the same subnet that is already configured on VLAN7.

To see this information run:

/ primary\]\]>

You will have to choose an IP address that is not used by another host.

Then you will have to unset the IP address on spine01 for vlan 7 and set it to the new IP address and network.

/ primary\]\]>

To configure MAGP

interface vlan 7 magp 7 ip virtual-router mac-address 00:00:5E:00:01:07\]\]>

Do these steps to verify the MAGP configuration:

You should see that each side has the state of “Master”.

To test connectivity to the new virtual address that is configured run an icmp ping against it:

ping -c 1 ping -c 1 \]\]>

### Changes to 'flowcontrol' Settings

Since the Shasta 1.3 release, we have received guidance from our switch vendors on configuration changes which have addressed issues we've hit in-house and with some customer systems. The following directions cover how to modify your switch configurations to apply the recommendations we have. Our testing strongly suggests that these changes can be made at any point, but we still recommend using a time during which little production activity is happening.

There are 2 groups of changes for the flowcontrol settings: the switch-to-switch connections; and node connections to leaf switches. We will cover the latter group first.

#### Leaf Switch Node Connections

For the node connections to a leaf switch, we want the transmit flowcontrol disabled, and receive flowcontrol enabled. The following commands will accomplish this.

**NOTE:** If you have a TDS system involving a Hill cabinet, make sure to confirm that no CMM nor CEC components are connected to any leaf switches in your system. If these components are connected to the leaf, confirm to which ports they are connected, and modify the commands below to _avoid_ modifying the flowcontrol settings of those ports.

Repeat the above commands for each leaf switch in your system. These changes can be peformed before the switch-to-switch connections, or concurrent with those changes.

#### Switch-to-Switch Connections

We want to disable flowcontrol in both directions for all switch-to-switch connections: spine-to-leaf; spine-to-CDU; spine-to-aggregate; and aggregate-to-leaf. (It is unlikely that any system has every type of connection.) We will first cover how to identify which ports are part of a switch-to-switch connection, and then we will provide the commands to make the changes. We will provide the commands for each switch group separately, but it is **strongly recommended** to make the configuration changes for each end of the connection in short order; for example, for a spine-leaf connection, do not make the changes on the spine side, if you cannot also make the changes to the leaf switch end of the connection within a couple minutes.

#### Recommended Order of Flow Control Changes for Switch-to-Switch Connections

1.  Make change on spine01 side of leaf/aggregate/CDU ISL connections.
2.  Make change on spine02 side of leaf/aggregate/CDU ISL connections.
3.  Make change on leaf/aggregate/CDU side of spine ISL connections.
4.  Make change on aggregate01/CDU01 side of VLT ISL connections.
5.  Make change on aggregate02/CDU02 side of VLT ISL connections.
6.  Repeat Steps 4 and 5 for each aggregate/CDU switch pair.
7.  Make change on aggregate side of leaf ISL connections.
8.  Make change on leaf side of aggregate ISL connections.

  

##### Identify Switch-to-Switch Connections

###### Leaf Switches

Our standard for the configuration uses 'port-channel 100' for the connection to the spine or aggregate switch. To get what ports are part of this composite interface, use this command:

Based on this example, we see that the physical ports are '1/1/51' and '1/1/52'. Record this information for each leaf switch.

###### CDU Switches

In order to get the ports involved in the connection to the spine switches, you can use the command shared for the leaf switch, above.

In addition to this, we also need the ports which connect the pair of CDU switches together. The best way to determine the ports involved is to run the following command:

Here, we can see ports 1/1/25 and 1/1/29 are being used as connections between the CDU switches. As with the connection to the spine, record the ports involved.

NOTE: It is very important that the flowcontrol settings for the CMM and CEC devices connected to the CDU switches NOT be modified.

###### Aggregate Switches

On large River systems, aggregate switches are situated between the leaf and spine switches. In general, we'd expect every port which is up on these switches to either be a connection to the spine (as 'port-channel 100'), a connection to a leaf, or a connection to its peer aggregate switch. To see which ports are currently up, run this:

From this output, we can see that ports 1/1/1 through 1/1/9, 1/1/25, and 1/1/27 through 1/1/29 are up. Record this information.

###### Spine Switches

The convenient way to identify the ports involved with connections to other switches is to look at the output from '`show interface status`'.

  

  

The links between the 2 spines should be port-channel 100 ('Po100'). The 'mlag-port-channel' interfaces which are connections to leaf, aggregate or CDU switches would be 'Mpo' interfaces with indices greater than 100. So here, 'Mpo1'-'Mpo11' and 'Mpo17' are connections to NCN's, whereas 'Mpo113', 'Mpo151' and 'Mpo152' are connections to other switches. So identifying the port-channel and mlag-port-channel devices, we look for the "Eth" rows which have one of these labels in parentheses next to it. In the example above, these are:

*   Eth1/12
*   Eth1/13
*   Eth1/14
*   Eth1/15/1
*   Eth1/15/2
*   Eth1/18

Record these ports AND the port-channel and mlag-port-channel interfaces, as we will need all of them.

##### Spine Switch 'flowcontrol' Configuration Change

On the Mellanox spine switches, we need to modify the flowcontrol settings on the port-channel, mlag-port-channel, and ethernet interfaces. The general form looks like this:

flowcontrol receive off force sw-spine01 \[standalone: master\] (config) # interface port-channel flowcontrol send off force sw-spine01 \[standalone: master\] (config) # interface mlag-port-channel flowcontrol receive off force sw-spine01 \[standalone: master\] (config) # interface mlag-port-channel flowcontrol send off force sw-spine01 \[standalone: master\] (config) # interface ethernet flowcontrol receive off force sw-spine01 \[standalone: master\] (config) # interface ethernet flowcontrol send off force sw-spine01 \[standalone: master\] (config) # exit sw-spine01 \[standalone: master\] # write memory\]\]>

"<index>" would just be the number after "Po" or "Mpo", so "113" or "151". "<port>" would be the value after "Eth", so "1/14" or "1/15/2". Make sure to run the 'flowcontrol' commands for each mlag-port-channel and Ethernet port.

##### Leaf, CDU, and Aggregate Switch 'flowcontrol' Configuration Change

On the Dell switches, we only need to modify the Ethernet interface configurations. The general form looks like this:

sw-leaf01(conf-if-eth)# flowcontrol receive off sw-leaf01(conf-if-eth)# flowcontrol transmit off sw-leaf01(conf-if-eth)# end sw-leaf01# write memory\]\]>

One would need to do this for each port. Alternatively, you can set it up to do multiple ports as one command. For instance, the common leaf switch would have ports 51 and 52 as connections to the spine. So in that case, these commands would work:

Alternatively, a typical CDU switch would have ports 27 and 28 as uplinks to the spine, with ports 25 and 29 as connections to the peer CDU switch. So in that case, we'd use these commands:

#### Disable iSCSI on Dell Switches (Leaf, CDU, and Aggregate)

The final configuration change needed on the Dell switches is to disable iSCSI in the configuration. This change insures that all of the flowcontrol changes made above will persist through a reboot of the switch.

Run the following commands on all Dell switches in your system: