# CSM Overview

This CSM Overview describes the Cray System Management ecosystem with the hardware, software, network,
 and access to these services and components.

The CSM installation prepares and deploys a distributed system across a group of management nodes organized into a Kubernetes cluster which uses Ceph for utility storage. These nodes perform their function as Kubernetes master nodes, Kubernetes worker nodes, or utility storage nodes with the Ceph storage.

System services on these nodes are provided as containerized microservices packaged for deployment as helm charts. These services are orchestrated by Kubernetes to be scheduled on Kubernetes worker nodes with horizontal scaling to increase or decrease the number of instances of some services as demand for them varies, such as when booting many compute nodes or application nodes.

### Topics: 
   1. [System Nodes and Networks](#system_nodes_and_networks)
   1. [Default IP Address Ranges](#default_ip_address_ranges)
   1. [Resilience of System Management Services](#resilience_of_system_maangement_services)
   1. [Access to System Management Services](#access_to_system_management_services)
   1. [System Management Levels](#system_management_levels)


## Details

<a name="system_nodes_and_networks"></a>
## 1. System Nodes and Networks

The HPE Cray EX system includes two types of nodes:

* Compute Nodes, where high performance computing applications are run, and hostnames in the form of
nidXXXXXX, that is, "nid" followed by six digits.  These six digits will be padded with zeroes at the beginning.
* Non-Compute Nodes (NCNs), which carry out system functions and come in three versions:
   * Master nodes, with names in the form of ncn-mXXX
   * Worker nodes, with names in the form of ncn-wXXX
   * Utility Storage nodes, with names in the form of ncn-sXXX

The HPE Cray EX system includes the following nodes:
* Nine or more non-compute nodes (NCNs) that host system services:
   * ncn-m001, ncn-m002, and ncn-m003 are configured as Kubernetes master nodes.
   * ncn-w001, ncn-w002, and ncn-w003 are configured as Kubernetes worker nodes. Every system
contains three or more worker nodes.
   * ncn-s001, ncn-s002 and ncn-s003 for storage. Every system contains three or more utility storage
node.
* Compute nodes, of the form nidXXXXXX. Commonly starting at nid000001, but this is configurable.

The following system networks connect the devices listed:
* Networks external to the system:
   * Customer Network (Data Center)
      * ncn-m001 BMC is connected by the customer network switch to the customer management network
      * All NCNs (worker, master, and storage) are connected
      * ClusterStor System Management Unit (SMU) interfaces
      * User Access Nodes (UANs)
* System networks:
   * Customer Network (Data Center)
      * ncn-m001 BMC is connected by the customer network switch to the customer management network
      * ClusterStor SMU interfaces
      * User Access Nodes (UANs)
   * Hardware Management Network (HMN)
      * BMCs for Admin tasks
      * Power distribution units (PDU)
      * Keyboard/video/mouse (KVM)
   * Node Management Network (NMN)
      * All NCNs and compute nodes
      * User Access Nodes (UANs)
   * ClusterStor Management Network
      * ClusterStor controller management interfaces of all ClusterStor components (SMU, Metadata
Management Unit (MMU), and Scalable Storage Unit (SSU))
   * High-Speed Network (HSN), which connects the following devices:
      * Kubernetes worker nodes
      * UANs
      * ClusterStor controller data interfaces of all ClusterStor components (SMU, MMU, and SSU)

During initial installation, several of those networks are created with default IP address ranges. See Default IP
Address Ranges on page 15.

The network management system (NMS) data model and REST API enable customer sites to construct their own
"networks" of nodes within the high-speed fabric, where a "network" is a collection of nodes that share a VLAN
and an IP subnet.

The low-level network management components (switch, DHCP service, ARP service) of the NCNs and
ClusterStor interfaces are configured to serve one particular network (the "supported network") on the high-speed
fabric. As part of the initial installation, the supported network is created to include all of the compute nodes,
thereby enabling those compute nodes to access the gateway, user access services, and ClusterStor devices.

A site may create other networks as well, but it is only the supported network that is served by those devices.

TODO Does CSM already have this image?  Is it the right one to use?
Figure 1. Management Network connections - HPE Cray EX System

<a name="default_ip_address_ranges"></a>
## 2. Default IP Address Ranges

<a name="resilience_of_system_maangement_services"></a>
## 3. Resilience of System Management Services

<a name="access_to_system_management_services"></a>
## 4. Access to System Management Services

<a name="system_management_levels"></a>
## 5. System Management Levels

