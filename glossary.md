# Glossary

Glossary of terms used in CSM documentation.

* [Application Node (AN)](#application-node)
* [Baseboard Management Controller (BMC)](#baseboard-management-controller)
* [Blade Switch Controller (sC)](#blade-switch-controller)
* [Boot Script Service (BSS)](#boot-script-service)
* [Boot Orchestration Service (BOS)](#boot-orchestration-service)
* [Cabinet Cooling Group](#cabinet-cooling-group)
* [Cabinet Environmental Controller (CEC)](#cabinet-environmental-controller)
* [CEC microcontroller (eC)](#cec-microcontroller)
* [Cray Advanced Platform Monitoring and Control (CAPMC)](#cray-advanced-platform-monitoring-and-control)
* [Customer Access Network](#customer-access-network)
* [Chassis Management Module (CMM)](#chassis-management-module)
* [Compute Node (CN)](#compute-node)
* [Configuration Framework Service (CFS)](#configuration-framework-service)
* [Content Projection Service (CPS)](#content-projection-service)
* [Cray CLI (cray)](#cray-cli)
* [Cray Site Init (CSI)](#cray-site-init)
* [Cray System Management (CSM)](#cray-system-management)
* [Data Virtualization Service (DVS)](#data-virtualization-service)
* [EX Compute Cabinet](#ex-compute-cabinet)
* [EX TDS Cabinet](#ex-tds-cabinet)
* [Fabric](#fabric)
* [Floor Standing CDU](#floor-standing-cdu)
* [Hardware Management Network (HMN)](#hardware-management-network)
* [Hardware Management Notification Fanout Daemon (HMNFD)](#hardware-management-notification-fanout-daemon)
* [Hardware State Manager (HSM)](#hardware-state-manager)
* [Heartbeat Tracker Daemon (HBTD)](#heartbeat-tracker-daemon)
* [High Speed Network (HSN)](#high-speed-network)
* [Image Management Service (IMS)](#image-management-service)
* [Kubernetes NCNs](#kubernetes-ncns)
* [LiveCD](#livecd)
* [Management Cabinet](#management-cabinet)
* [Management Nodes](#management-nodes)
* [Mountain Endpoint Discovery Service (MEDS)](#mountain-endpoint-discovery-service)
* [NIC Mezzanine Card (NMC)](#nic-mezzanine-card)
* [Node Controller (nC)](#node-controller)
* [Node Management Network](#node-management-network)
* [Non-Compute Node (NCN)](#non-compute-node)
* [Olympus Cabinet](#olympus-cabinet)
* [Power Distribution Unit (PDU)](#power-distribution-unit)
* [Pre-Install Toolkit (PIT) node](#pre-install-toolkit-node)
* [Rack-Mounted CDU](#rack-mounted-cdu)
* [Rack System Compute Cabinet](#rack-system-compute-cabinet)
* [Redfish Translation Service (RTS)](#redfish-translation-service)
* [River Cabinet](#river-cabinet)
* [River Endpoint Discovery Service (REDS)](#river-endpoint-discovery-service)
* [Rosetta ASIC](#rosetta-asic)
* [Service/IO Cabinet](#service-io-cabinet)
* [Slingshot](#slingshot)
* [Slingshot Blade Switch](#slingshot-blade-switch)
* [Slingshot Top of Rack (ToR) Switch](#slingshot-top-of-rack-switch)
* [Shasta Cabling Diagram (SHCD)](#shasta-cabling-diagram)
* [Supply/Return Cutoff Valves](#supply-return-cutoff-valves)
* [System Admin Toolkit (SAT)](#system-admin-toolkit)
* [System Layout Service (SLS)](#system-layout-service)
* [System Management Network (SMNet)](#system-management-network)
* [System Management Services (SMS)](#system-management-services-sms)
* [System Management Services (SMS) nodes](#system-management-services-nodes)
* [Top of Rack Switch Controller (sC-ToR)](#top-of-rack-switch-controller)
* [User Access Instance (UAI)](#user-access-instance)
* [User Access Node (UAN)](#user-access-node)
* [User Access Service (UAS)](#user-access-service)
* [Version Control Service (VCS)](#version-control-service)
* [xname](#xname)

<a name="application-node"></a>
## Application Node (AN)

An application node (AN) is an NCN which is not providing management functions for the HPE Cray EX system.
The AN is not part of the Kubernetes cluster to which management nodes belong. One special type of AN
is the UAN (User Access Node), but different systems may have need for other types of ANs, such as:
* nodes which provide a Lustre routing function (LNet router)
* gateways between HSN and Infiniband
* data movers between two different network file systems
* visualization servers
* other special-purpose nodes

<a name="baseboard-management-controller"></a>
## Baseboard Management Controller (BMC)

Air-Cooled cabinet COTS servers that include a Redfish-enabled baseboard management
controller (BMC) and REST endpoint for API control and management. Either IPMI
commands or REST API calls can be used to manage a BMC.

<a name="blade-switch-controller"></a>
## Blade Switch Controller (sC)

The Slingshot blade switch embedded controller (sC) provides a hardware management
REST endpoint to monitor environmental conditions and manage the blade power, switch
ASIC, FPGA buffer/interfaces, and firmware.

<a name="boot-script-service"></a>
## Boot Script Service (BSS)

The Boot Script Service stores the configuration information that is used to boot each hardware component. Nodes consult BSS for their boot artifacts and boot parameters when nodes boot or reboot.

<a name="boot-orchestration-service"></a>
## Boot Orchestration Service (BOS)

The Boot Orchestration Service (BOS) is responsible for booting, configuring, and shutting down collections of nodes. This is accomplished using BOS components, such as boot orchestration session templates and sessions, as well as launching a Boot Orchestration Agent (BOA) that fulfills boot requests. BOS uses other services which provide boot artifact configuration (BSS), power control (CAPMC), node status (HSM), and configuration (CFS).

<a name="cabinet-cooling-group"></a>
## Cabinet Cooling Group
A cabinet cooling group is a group of Olympus cabinets that are connected to a floor-standing coolant
distribution unit (CDU). Management network CDU switches in the CDU aggregate all the
node management network (NMN) and hardware management network (HMN) connections
for the cabinet group.

<a name="cabinet-environmental-controller"></a>
## Cabinet Environmental Controller (CEC)

The Liquid-Cooled Olympus cabinet environmental controller (CEC) sets the cabinet's geolocation,
monitors environmental sensors, and communicates status to the cooling distribution unit
(CDU). The CEC microcontroller (eC) signals the cooling distribution unit (CDU) to start
liquid cooling and then enables the DC rectifiers so that a chassis can be powered on. The
CEC does not provide a REST endpoint on SMNet, it simply provides the cabinet
environmental and CDU status to the CMM for evaluation or action; the CEC takes no
action. The CEC firmware is flashed automatically when the CMM firmware is flashed. If
there are momentary erroneous signals because of a CEC reset or cable disconnection, the
system can ride through these events without issuing an EPO.

<a name="cec-microcontroller"></a>
## CEC microcontroller (eC)

The CEC microcontroller (eC) sets the cabinet's geolocation, monitors the cabinet
environmental sensors, and communicates cabinet status to the cooling distribution unit
(CDU). The eC does not provide a REST endpoint on SMNet as do other embedded
controllers, but simply monitors the cabinet sensors and provides the cabinet environmental
and CDU status to the CMMs for evaluation and/or action.

<a name="cray-advanced-platform-monitoring-and-control"></a>
## Cray Advanced Platform Monitoring and Control (CAPMC)

The Cray Advanced Platform Monitoring and Control (CAPMC) service enables direct hardware control of power on/off, power monitoring, or system-wide power telemetry and configuration parameters from Redfish. CAPMC implements a simple interface for powering on/off compute nodes and application nodes, querying node state information, and querying site-specific service usage rules. These controls enable external software to more intelligently manage system-wide power consumption or configuration parameters.

<a name="cray-cli"></a>
## Cray CLI (cray)

The `cray` command line interface (CLI) is a framework created to integrate all of the system management REST APIs into easily usable commands.

<a name="customer-access-network"></a>
## Customer Access Network

The Customer Access Network (CAN) provides access from outside the customer network to services, noncompute
nodes (NCNs), and User Access Nodes (UANs) in the system. This allows for the following:
   * Clients outside of the system:
      * Log in to each of the NCNs and UANs.
      * Access web UIs within the system (e.g. Prometheus, Grafana, and more).
      * Access the Rest APIs within the system.
      * Access a DNS server within the system for resolution of names for the webUI and REST API services.
      * Run Cray CLI commands from outside the system.
      * Access the User Access Instances (UAI).
   *  NCNs and UANs to access systems outside the cluster (e.g. LDAP, license servers, and more).
   *  Services within the cluster to access systems outside the cluster.

These nodes and services need an IP address that routes to the customer's network in order to be accessed from
outside the network.

<a name="chassis-management-module"></a>
## Chassis Management Module (CMM)

The cabinet chassis management module (CMM) provides a REST endpoint via its chassis
controller (cC). The CMM is an embedded controller that monitors and controls all the
blades in a chassis. Each chassis supports 8 compute blades and 8 switches and
associated rectifiers/PSUs in the rectifier shelf.
Power Considerations - Two CMMs in adjacent chassis share power from the rectifier
shelf (a shelf connects two adjacent chassis - 0/1, 2/3, 4/5, 6/7). If both CMMs sharing shelf
power are both enabling the rectifiers, one of the CMMs can be removed (but only one at a
time) without the rectifier shelf powering off. Removing a CMM will shutdown all compute
blades and switches in the chassis.
Cooling Considerations - Any single CMM in any cabinet can enable CDU cooling. Note
that the CDU "enable path" has vertical control which means CMMs 0/2/4/6 and CEC0 are
in a path (half of the cabinet), and CMMs 1/3/5/7 and CEC1 are in another path. Any CMM
or CEC in the same half-cabinet path can be removed and CDU cooling will stay enabled as
long as the other CMMs/CEC enables CDU cooling.

<a name="compute-node"></a>
## Compute Node (CN)

The compute node (CN) is where high performance computing application are run. These have
hostnames that are of the form "nidXXXXXX", that is, "nid" followed by six digits.
where the XXXXXX is a six digit number starting with zero padding.

<a name="configuration-framework-service"></a>
## Configuration Framework Service (CFS)

The Configuration Framework Service (CFS) is available on systems for remote execution and
configuration management of nodes and boot images. This includes nodes available in the
Hardware State Manager (HSM) service inventory (compute, management, and application nodes),
and boot images hosted by the Image Management Service (IMS).

CFS configures nodes and images via a gitops methodology. All configuration content is stored in a version control service \(VCS\), and is managed by authorized system administrators. CFS provides a scalable Ansible Execution Environment \(AEE\) for the configuration to be applied with flexible inventory and node targeting options.

<a name="content-projection-service"></a>
## Content Projection Service (CPS)

The Content Projection Service (CPS) provides the root filesystem for compute nodes and application nodes in conjunction with the Data Virtualization Service (DVS). Using CPS and DVS, the Cray Programming Environment (CPE) and Analytics products are provided as separately mounted filesystems to compute nodes, application nodes (such as UANs), and worker nodes hosting UAI pods.

<a name="cray-site-init"></a>
## Cray Site Init (CSI)

The Cray Site Init (CSI) program creates, validates, installs, and upgrades an HPE Cray EX system.
CSI can prepare the LiveCD for booting the PIT node and then is used from a booted PIT node
to do its other functions during an installation. During an upgrade, CSI is installed on
one of the nodes to facilitate the CSM software upgrade.

<a name="cray-system-management"></a>
## Cray System Management (CSM)

Cray System Management (CSM) refers to the product stream which provides the infrastructure to
manage an HPE Cray EX system using Kubernetes to manage the containerized workload of layered
micro-services with well-defined REST APIs which provide the ability to discover and control the
hardware platform, manage configuration of the system, configure the network, boot nodes, gather
log and telemetry data, connect API access and user level access to Identity Providers (IdPs),
and provide a method for system administrators and end-users to access the HPE Cray EX system.

<a name="data-virtualization-service"></a>
## Data Virtualization Service (DVS)

The Data Virtualization Service (DVS) is a distributed network service that projects file systems
mounted on non-compute nodes (NCN) to other nodes within the HPE Cray EX system. Projecting is
the process of making a file system available on nodes where it does not physically reside.
DVS-specific configuration settings enable clients to access a file system projected by DVS
servers. These clients include compute nodes, User Access Nodes (UANs), and other management
nodes running User Access Instances (UAIs). Thus DVS, while not a file system, represents a
software layer that provides scalable transport for file system services. DVS is integrated
with the Content Projection Service (CPS).

<a name="ex-compute-cabinet"></a>
## EX Compute Cabinet

A Liquid-Cooled Olympus cabinet is a dense compute cabinet that supports 64 compute blades and 64
high-speed network (HSN) switches.

<a name="image-management-service"></a>
## Image Management Service (IMS)

The Image Management Service (IMS) uses the open source Kiwi-NG tool to build image roots from
recipes. IMS also uses CFS to apply image customization for pre-boot configuration of the image root.
These images are bootable on compute nodes and application nodes.

<a name="ex-tds-cabinet"></a>
## EX TDS Cabinet

A Liquid-Cooled TDS cabinet is a dense compute cabinet that supports 2-chassis, 16
compute blades and 16 high-speed network (HSN) switches, and includes a rack-mounted
4U coolant distribution unit (MCDU-4U).

<a name="fabric"></a>
## Fabric

The Slingshot fabric consists of the switches, cables, ports, topology policy, and
configuration settings for the Slingshot high-speed network.

<a name="floor-standing-cdu"></a>
## Floor Standing CDU

A floor-standing coolant distribution unit (CDU) pumps liquid coolant through a cabinet
group or cabinet chilled doors.

<a name="hardware-management-network"></a>
## Hardware Management Network (HMN)

The hardware management network (HMN) includes HMS embedded controllers. This
includes chassis controllers (cC), node controllers (nC) and switch controllers (sC), for
Liquid-Cooled TDS and Liquid-Cooled Olympus systems. For standard rack systems, this includes
iPDUs, COTS server BMCs, or any other equipment that requires hardware-management
with Redfish. The hardware management network is isolated from all other node
management networks. An out-of-band Ethernet management switch and hardware
management VLAN is used for customer access and administration of hardware.

<a name="hardware-management-notification-fanout-daemon"></a>
## Hardware Management Notification Fanout Daemon (HMNFD)

The Hardware Management Notification Fanout Daemon (HMNFD) service receives component state change notifications from the HSM. It fans notifications out to subscribers (typically compute nodes).

<a name="hardware-state-manager"></a>
## Hardware State Manager (HSM)

Hardware State Manager (HSM) service monitors and interrogates hardware components in an HPE Cray EX system, tracking hardware state and inventory information, and making it available via REST queries and message bus events when changes occur.

<a name="heartbeat-tracker-daemon"></a>
## Heartbeat Tracker Daemon (HBTD)

The Heartbeat Tracker Daemon (HBTD) service listens for heartbeats from components (mainly compute nodes). It tracks changes in heartbeats and conveys changes to HSM.

<a name="high-speed-network"></a>
## High Speed Network (HSN)

The High Speed Network (HSN) in an HPE Cray EX system is based on the Slingshot switches.

<a name="kubernetes-ncns"></a>
## Kubernetes NCNs

The Kubernetes NCNs are the management nodes which are known as Kubernetes master nodes
(ncn-mXXX) or Kubernetes worker nodes (ncn-wXXX). The only type of management node which is
excluded from this is the utility storage node (ncn-sXXX).

<a name="livecd"></a>
## LiveCD

The LiveCD has a complete bootable Linux operating system that can be run from a read-only CD or
DVD, a writable USB flash drive, or a hard disk. It is used to bootstrap the installation
process for CSM software. It contains the Pre-Install Toolkit (PIT). The node which boots
from it during the install is known as the [PIT node](#pre-install-toolkit-node).

<a name="management-cabinet"></a>
## Management Cabinet

At least one 19 inch IEA management cabinet is required for every HPE Cray EX system to
support the management non-compute nodes (NCN), system management network, utility
storage, and other support equipment. This cabinet serves as the primary customer access
point for managing the system.

<a name="management-nodes"></a>
## Management Nodes

The management nodes are one grouping of NCNs. The management nodes include the master nodes
with hostnames of the form of ncn-mXXX, the worker nodes with hostnames of the form ncn-wXXX,
and utility storage nodes, with hostnames of the form ncn-sXXX, where the XXX is a three
digit number starting with zero padding. The utility storage nodes provide Ceph storage for use
by the management nodes. The master nodes provide Kubernetes master functions and have the
etcd cluster which provides a datastore for Kubernetes. The worker nodes provide Kubernetes
worker functions where most of the containerized workload is scheduled by Kubernetes.

<a name="mountain-cabinet"></a>
## Mountain Cabinet

See Olympus cabinet. Some software and documentation refers to the Olympus cabinet as a Mountain cabinet.

<a name="mountain-endpoint-discovery-service"></a>
## Mountain Endpoint Discovery Service (MEDS)

The Mountain Endpoint Discovery Service (MEDS) manages initial discovery, configuration, and geolocation of Redfish-enabled BMCs in liquid-cooled Olympus cabinets. It periodically makes Redfish requests to determine if hardware is present or missing.

<a name="nic-mezzanine-card"></a>
## NIC Mezzanine Card (NMC)

The NIC mezzanine card (NMC) attaches to two host port connections on a liquid-cooled
compute blade node card and provides the high-speed network (HSN) controllers (NICs).
There are typically two or four NICs on each node card. NMCs connect to the rear panel
EXAMAX connectors on the compute blade through an internal L0 cable assembly in a
single-, dual-, or quad-injection bandwidth configuration depending on the design of the
node card.

<a name="node-controller"></a>
## Node Controller (nC)

Each compute blade node card includes an embedded node controller (nC) and REST
endpoint to manage the node environmental conditions, power, HMS nFPGA interface, and
firmware.

<a name="node-management-network"></a>
## Node Management Network

The node management network (NMN) communicates with motherboard PCH-style hosts,
typically 10GbE Ethernet LAN-on-motherboard (LOM) interfaces. This network supports
node boot protocols (DHCP/TFTP/HTTP), in-band telemetry and event exchange, and
general access to management REST APIs.

<a name="non-compute-node"></a>
## Non-Compute Node (NCN)

Any node which is not a compute node may be called a Non-Compute Node (NCN). The NCNs include
management nodes and application nodes.

<a name="olympus-cabinet"></a>
## Olympus Cabinet

The Olympus cabinet is a liquid-cooled dense compute cabinet that supports 64 compute
blades and 64 high-speed network (HSN) switches. Every HPE Cray EX system with Olympus
cabinets will also have at least one River cabinet to house non-compute node components
such as management nodes, management network switches, storage nodes, application nodes,
and possibly other air-cooled compute nodes. Some software and documentation refers to
the Olympus cabinet as a Mountain cabinet.

<a name="power-distribution-unit"></a>
## Power Distribution Unit (PDU)

The cabinet PDU receives 480VAC 3-phase facility power and
provides circuit breaker, fuse protection, and EMI filtered power to the rectifier/power
supplies that distribute ±190VDC (HVDC) to a chassis. PDUs are passive devices that do
not connect to the SMNet.

<a name="pre-install-toolkit-node"></a>
## Pre-Install Toolkit (PIT) node

The Pre-Install Toolkit is installed onto the initial node used as the inception node during software
installation which is booted from a [LiveCD](#livecd). This is the node that will eventually become `ncn-m001`.
The node running the Pre-Install Toolkit is known as the PIT node during the installation process
until it reboots from a normal management node image like the other master nodes.

Early in the install process, before the Pre-Install Toolkit has been installed or booted, the
documents may still refer to the PIT node. In this case, they are referring to the node which
will eventually become the PIT node.

In this documentation, PIT node and LiveCD are sometimes used interchangeably.

<a name="rack-mounted-cdu"></a>
## Rack-Mounted CDU

The rack-mounted coolant distribution unit (MCDU-4U) pumps liquid coolant through the
Liquid-Cooled TDS cabinet coolant manifolds.

<a name="rack-system-compute-cabinet"></a>
## Rack System Compute Cabinet

Air-Cooled compute cabinets house a cluster of compute nodes, Slingshot ToR switches,
and SMNet ToR switches.

<a name="redfish-translation-service"></a>
## Redfish Translation Service (RTS)

The Redfish Translation Service (RTS) aids in management of any hardware components which are not managed by Redfish, such as a ServerTech PDU in a River Cabinet.

<a name="river-cabinet"></a>
## River Cabinet

At least one 19 inch IEA management cabinet is required for every HPE Cray EX system to
support the management non-compute nodes (NCN), system management network, utility
storage, and other support equipment. Additional River cabinets may be included to
house storage storage or compute nodes which are not in an Olympus liquid-cooled cabinet.

<a name="river-endpoint-discovery-services"></a>
## River Endpoint Discovery Service (REDS)

The River Endpoint Discovery Service (REDS) manages initial discovery, configuration, and geolocation of Redfish-enabled BMCs in air-cooled River cabinets. It periodically makes Redfish requests to determine if hardware is present or missing.

<a name="rosetta-asic"></a>
## Rosetta ASIC

The Rosetta ASIC is a 64-port switch chip that forms the foundation for the Slingshot
network. Each port can operate at either 100G or 200G. Each network edge port supports
IEEE 802.3 Ethernet, optimized-IP based protocols, and portals (an enhanced frame format
that supports higher rates of small messages).

<a name="service-io-cabinet"></a>
## Service/IO Cabinet

An Air-Cooled service/IO cabinet houses a cluster of NCN servers, Slingshot ToR switches,
and management network ToR switches to support the managed ecosystem storage,
network, user access services (UAS), and other IO services such as LNet and gateways.

## Slingshot

Slingshot supports L1 and L2 network connectivity between 200Gbs switch ports and L0
connectivity from a single 200Gbs port to two 100Gbs Mellanox ConnectX-5 NICs. Slingshot
also supports edge ports and link aggregation groups (LAG) to external storage systems or
networks.

   * IEEE 802.3cd/bs (200 Gbps) Ethernet over 4 x 50
   * Gb/s (PAM-4) lanes 200GBASE-DR4, 500m singlemode fiber
   * 200GBASE-SR4, 100m multi-mode fiber
   * 200GBASE-CR4, 3m copper cable
   * IEEE 802.3cd (100 Gbps) Ethernet over 2 x 50
   * Gb/s (PAM-4) lanes 100GBASE-SR2, 100m multimode fiber
   * 100GBASE-CR2, 3m copper cable
   * IEEE 802.3 2018 100 Gbps Ethernet over 4 x 25
   * Gb/s (NRZ) lanes
   * 100GBASE-CR4, 5m copper cable
   * 100GBASE-SR4, 100m multi-mode fiber
   * Optimized Ethernet and HPC fabric formats
   * Lossy and lossless delivery
   * Flow control, 802.1x (PAUSE), 802.1p (PFC), credit based flow control on fabric links, fine-grain flow control on host links and edge ports, Link level retry, low latency FEC, Ethernet physical interfaces:

<a name="slingshot-blade-switch"></a>
## Slingshot Blade Switch

The Liquid-Cooled Olympus cabinet blade switch supports one switch ASIC and 48 fabric ports. Eight
connectors on the rear panel connect orthogonally to each compute blade then to NIC
mezzanine cards (NMCs) inside the compute blade. Each rear panel EXAMAX connector
supports two switch ports (a total of 16 fabric ports per blade). Twelve QSFP-DD cages on
the front panel (4 fabric ports per QSFP-DD cage), fan out 48 external fabric ports to other
switches. The front-panel top ports support passive electrical cables (PEC) or active optical
cables (AOC). The front-panel bottom ports support only PECs for proper cooling in the
blade enclosure.

<a name="slingshot-top-of-rack-switch"></a>
## Slingshot Top of Rack (ToR) Switch

A standard River cabinet can support one, two, or four, rack-mounted Slingshot ToR switches.
Each switch supports a total of 64 fabric ports. 32 QSFP-DD connectors on the front panel
connect 64 ports to the fabric. All front-panel connectors support either passive electrical
cables (PEC) or active optical cables (AOC).

<a name="shasta-cabling-diagram"></a>
## Shasta Cabling Diagram (SHCD)

The Shasta Cabling Diagram (SHCD) is a multiple tab spreadsheet prepared by HPE Cray Manufacturing with information about the components
in an HPE Cray EX system. This document has much information about the system. Included in the SHCD are a configuration summary with
revision history, floor layout plan, type and location of components in the air-cooled cabinets, type and location of components in the
liquid-cooled cabinets, device diagrams for switches and nodes in the cabinets, list of source and destination of every HSN cable,
list of source and destination of every cable connected to the spine switches, list of source and destination of every cable connected
to the NMN, list of source and destination of every cable connected to the HMN. list of cabling for the KVM, and routing of power to the PDUs.

<a name="supply-return-cutoff-valves"></a>
## Supply/Return Cutoff Valves

Manual coolant supply and return shutoff valves at the top of each cabinet can be closed to
isolate a single cabinet from the other cabinets in the cooling group for maintenance. If the
valves are closed during operation, the action automatically causes the CMMs to remove
±190VDC from each chassis in the cabinet because of the loss of coolant pressure.

<a name="system-admin-toolkit"></a>
## System Admin Toolkit (SAT)

The System Admin Toolkit (SAT) product provides the `sat` command line interface which interacts with the REST APIs of many services to perform more complex system management tasks.

<a name="system-layout-service"></a>
## System Layout Service (SLS)

The System Layout Service (SLS) serves as a "single source of truth" for the system design. It details the physical locations of network hardware, management nodes, application nodes, compute nodes, and cabinets. It also stores information about the network, such as which port on which switch should be connected to each node.

<a name="system-management-network"></a>
## System Management Network (SMNet)

The system management network (SMNet) is a dedicated out-of-band (OOB) spine-leaf
topology Ethernet network that interconnects all the nodes in the system to management
services.

<a name="system-management-services-sms"></a>
## System Management Services (SMS)

System Management Services (SMS) leverages open REST APIs, Kubernetes container
orchestration, and a pool of commercial off-the-shelf (COTS) servers to manage the system.
The management server pool, custom Redfish-enabled embedded controllers, iPDU
controllers, and server BMCs are unified under a common software platform that provides 3
levels of management: Level 1 HaaS, Level 2 IaaS, and Level 3 PaaS.

<a name="system-management-services-nodes"></a>
## System Management Services (SMS) nodes

System Management Services (SMS) nodes provide access to the entire management
cluster and Kubernetes container orchestration.

<a name="top-of-rack-switch-controller"></a>
## Top of Rack Switch Controller (sC-ToR)

The Air-Cooled cabinet HSN ToR switch embedded controller (sC-ToR) provides a hardware
management REST endpoint to monitor the ToR switch environmental conditions and
manage the switch power, HSN ASIC, and FPGA interfaces.

<a name="user-access-instance"></a>
## User Access Instance (UAI)

The User Access Instance (UAI) is a lightweight, disposable platform that runs under Kubernetes orchestration
on worker nodes. The UAI provides a single user containerized environment for users on a Cray Ex system to
develop, build, and execute their applications on the HPE Cray EX compute node. See UAN for another
way for users to gain access.

<a name="user-access-node"></a>
## User Access Node (UAN)

The User Access Node (UAN) is an NCN, but is really one of the special types of application nodes.
The UAN provides a traditional multi-user Linux environment for users on a Cray Ex system to
develop, build, and execute their applications on the HPE Cray EX compute node. See UAI for another
way for users to gain access. Some sites refer to their UANs as Login nodes.

<a name="user-access-service"></a>
## User Access Service (UAS)

The User Access Service (UAS) is a containerized service managed by Kubernetes that enables users to
create and run user applications inside a UAI. UAS runs on a management node that is acting as a
Kubernetes worker node. When a user requests a new UAI, the UAS service returns status and connection
information to the newly created UAI. External access to UAS is routed through a node that hosts
gateway services.

<a name="version-control-service"></a>
## Version Control Service (VCS)

The Version Control Service (VCS) provides configuration content to CFS via a gitops methodology
based on a `git` server (`gitea`) that can be accessed by the `git` command but also includes a
web interface for repository management, pull requests, and a visual view of all repositories
and organizations.

<a name="xname"></a>
## xname

Component names (xnames) identify the geolocation for hardware components in the HPE Cray EX system. Every
component is uniquely identified by these component names. Some, like the system cabinet number or the CDU
number, can be changed by site needs. There is no geolocation encoded within the cabinet number, such as an
X-Y coordinate system to relate to the floor layout of the cabinets. Other component names refer to the location
within a cabinet and go down to the port on a card or switch or the socket holding a processor or a memory DIMM
location. See [Component Names (xnames)](operations/Component_Names_xnames.md).
