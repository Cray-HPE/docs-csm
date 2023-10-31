# Network

There are several different networks supported by the HPE Cray EX system. This page outlines the available internal and external networks, as well as the devices that connect to each network.

- [External networks](#external-networks)
  - [Customer network \(data center\)](#customer-network-data-center)
- [System networks](#system-networks)
  - [Hardware Management Network \(HMN\)](#hardware-management-network-hmn)
  - [Node Management Network \(NMN\)](#node-management-network-nmn)
  - [ClusterStor Management Network](#clusterstor-management-network)
  - [High Speed Network \(HSN\)](#high-speed-network-hsn)
- [IP address ranges](#ip-address-ranges)
- [Access Control Lists \(ACLs\)](#access-control-lists-acls)

## External networks

### Customer network \(data center\)

The following devices are connected to this network:

- The `ncn-m001` [BMC](../../glossary.md#baseboard-management-controller-bmc) is connected by the customer network switch to the customer **management** network
- All [management nodes](../../glossary.md#management-nodes) \(worker, master, and storage\)
- ClusterStor System Management Unit \(SMU\) interfaces
- [User Access Nodes (UANs)](../../glossary.md#user-access-node-uan)

## System networks

### Hardware Management Network \(HMN\)

The following devices are connected to the [HMN](../../glossary.md#hardware-management-network-hmn):

- BMCs for administrative tasks
- [Power Distribution Units (PDUs)](../../glossary.md#power-distribution-unit-pdu)
- Keyboard/video/mouse \(KVM\)

### Node Management Network \(NMN\)

The following devices are connected to the [NMN](../../glossary.md#node-management-network-nmn):

- All [NCNs](../../glossary.md#non-compute-node-ncn) and [compute nodes](../../glossary.md#compute-node-cn).
- UANs

### ClusterStor Management Network

The following devices are connected to this network:

- ClusterStor controller management interfaces of all ClusterStor components \(SMU, Metadata Management Unit \(MMU\), and Scalable Storage Unit \(SSU\)\)

### High Speed Network \(HSN\)

The following devices are connected to the [HSN](../../glossary.md#high-speed-network-hsn):

- Kubernetes worker nodes
- UANs
- ClusterStor controller data interfaces of all ClusterStor components \(SMU, MMU, and SSU\)
- At least two NCNs whose BMCs are on the HMN. If these are not present, there cannot be multiple [DVS](../../glossary.md#data-virtualization-service-dvs)
  servers that function correctly, which will have an adverse effect on compute node root file system and [CPE](../../glossary.md#cray-programming-environment-cpe)
  scaling, performance, and reliability.

## IP address ranges

During initial installation, several of those networks are created with default IP address ranges. See [Default IP Address Ranges](Default_IP_Address_Ranges.md).

## Access Control Lists \(ACLs\)

A default configuration of ACLs is also set when the system is installed. The default configuration of ACLs between the NMN and HMN are described below:

The network management system \(NMS\) data model and REST API enable customer sites to construct their own "networks" of nodes within the high-speed fabric, where a "network"
is a collection of nodes that share a VLAN and an IP subnet.

The low-level network management components \(switch, DHCP service, ARP service\) of the NCNs and ClusterStor interfaces are configured to serve one particular network
\(the "supported network"\) on the high-speed fabric. The supported network includes all of the compute nodes, thereby enabling those compute nodes to access the gateway,
user access services, and ClusterStor devices. A site may create other networks as well, but it is only the supported network that is served by those devices.

![Management Network Connections - Liquid Cooled](../../img/Management_Network_Connections_Liquid_Cooled.png "Management Network Connections - Liquid Cooled")
