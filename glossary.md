# Glossary

Glossary of terms used in CSM documentation.

* [Ansible Execution Environment (AEE)](#ansible-execution-environment-aee)
* [Application Node (AN)](#application-node-an)
* [Baseboard Management Controller (BMC)](#baseboard-management-controller-bmc)
* [Blade Switch Controller (sC)](#blade-switch-controller-sc)
* [Boot Orchestration Service (BOS)](#boot-orchestration-service-bos)
* [Boot Script Service (BSS)](#boot-script-service-bss)
* [Cabinet Cooling Group](#cabinet-cooling-group)
* [Cabinet Environmental Controller (CEC)](#cabinet-environmental-controller-cec)
* [CEC microcontroller (eC)](#cec-microcontroller-ec)
* [Chassis Management Module (CMM)](#chassis-management-module-cmm)
* [Compute Node (CN)](#compute-node-cn)
* [Compute Rolling Upgrade Service (CRUS)](#compute-rolling-upgrade-service-crus)
* [Configuration Framework Service (CFS)](#configuration-framework-service-cfs)
* [Content Projection Service (CPS)](#content-projection-service-cps)
* [Cray Advanced Platform Monitoring and Control (CAPMC)](#cray-advanced-platform-monitoring-and-control-capmc)
* [Cray CLI (`cray`)](#cray-cli-cray)
* [Cray Security Token Service (STS)](#cray-security-token-service-sts)
* [Cray Site Init (CSI)](#cray-site-init-csi)
* [Cray System Management (CSM)](#cray-system-management-csm)
* [Customer Access Network (CAN)](#customer-access-network-can)
* [Data Virtualization Service (DVS)](#data-virtualization-service-dvs)
* [EX Compute Cabinet](#ex-compute-cabinet)
* [EX TDS Cabinet](#ex-tds-cabinet)
* [Fabric](#fabric)
* [Firmware Action Service (FAS)](#firmware-action-service-fas)
* [Floor Standing CDU](#floor-standing-cdu)
* [Hardware Management Network (HMN)](#hardware-management-network-hmn)
* [Hardware Management Notification Fanout Daemon (HMNFD)](#hardware-management-notification-fanout-daemon-hmnfd)
* [Hardware State Manager (HSM)](#hardware-state-manager-hsm)
* [Heartbeat Tracker Daemon (HBTD)](#heartbeat-tracker-daemon-hbtd)
* [Hierarchical Namespace Controller (HNC)](#hierarchical-namespace-controller-hnc)
* [High Speed Network (HSN)](#high-speed-network-hsn)
* [Image Management Service (IMS)](#image-management-service-ims)
* [Install and Upgrade Framework (IUF)](#install-and-upgrade-framework-iuf)
* [Management Nodes](#management-nodes)
* [Mountain Cabinet](#mountain-cabinet)
* [Mountain Endpoint Discovery Service (MEDS)](#mountain-endpoint-discovery-service-meds)
* [NCN Lifecycle Service (NLS)](#ncn-lifecycle-service-nls)
* [NIC Mezzanine Card (NMC)](#nic-mezzanine-card-nmc)
* [Node Controller (nC)](#node-controller-nc)
* [Node Management Network (NMN)](#node-management-network-nmn)
* [Non-Compute Node (NCN)](#non-compute-node-ncn)
* [Olympus Cabinet](#olympus-cabinet)
* [Power Control Service (PCS)](#power-control-service-pcs)
* [Power Distribution Unit (PDU)](#power-distribution-unit-pdu)
* [Pre-Install Toolkit (PIT)](#pre-install-toolkit-pit)
  * [LiveCD](#livecd)
  * [RemoteISO](#remoteiso)
* [Rack-Mounted CDU](#rack-mounted-cdu)
* [Rack System Compute Cabinet](#rack-system-compute-cabinet)
* [Redfish Translation Service (RTS)](#redfish-translation-service-rts)
* [River Cabinet](#river-cabinet)
* [River Endpoint Discovery Service (REDS)](#river-endpoint-discovery-service-reds)
* [Rosetta ASIC](#rosetta-asic)
* [Service/IO Cabinet](#serviceio-cabinet)
* [Slingshot](#slingshot)
* [Slingshot Blade Switch](#slingshot-blade-switch)
* [Slingshot Top of Rack (ToR) Switch](#slingshot-top-of-rack-tor-switch)
* [Shasta Cabling Diagram (SHCD)](#shasta-cabling-diagram-shcd)
* [Supply/Return Cutoff Valves](#supplyreturn-cutoff-valves)
* [System Admin Toolkit (SAT)](#system-admin-toolkit-sat)
* [System Configuration Service (SCSD)](#system-configuration-service-scsd)
* [System Layout Service (SLS)](#system-layout-service-sls)
* [System Management Network (SMNet)](#system-management-network-smnet)
* [System Management Services (SMS)](#system-management-services-sms)
* [System Management Services (SMS) nodes](#system-management-services-sms-nodes)
* [Tenant and Partition Management System (TAPMS)](#tenant-and-partition-management-system-tapms)
* [Top of Rack Switch Controller (sC-ToR)](#top-of-rack-switch-controller-sc-tor)
* [User Access Instance (UAI)](#user-access-instance-uai)
* [User Access Node (UAN)](#user-access-node-uan)
* [User Access Service (UAS)](#user-access-service-uas)
* [Version Control Service (VCS)](#version-control-service-vcs)
* [xname](#xname)

## Ansible Execution Environment (AEE)

A component used by the [Configuration Framework Service (CFS)](#configuration-framework-service-cfs) to
execute Ansible code from its configuration layers.

For more information, see [Ansible Execution Environments](operations/configuration_management/Ansible_Execution_Environments.md).

## Application Node (AN)

An application node (AN) is an [NCN](#non-compute-node-ncn) which is not providing management functions for the HPE Cray EX system.
The AN is not part of the Kubernetes cluster to which [management nodes](#management-nodes) belong. One special type of AN
is the [User Access Node (UAN)](#user-access-node-uan), but different systems may have need for other types of ANs, such as:

* nodes which provide a Lustre routing function (LNet router)
* gateways between [HSN](#high-speed-network-hsn) and InfiniBand
* data movers between two different network file systems
* visualization servers
* other special-purpose nodes

## Baseboard Management Controller (BMC)

Air-Cooled cabinet COTS servers that include a Redfish-enabled baseboard management
controller (BMC) and REST endpoint for API control and management. Either IPMI
commands or REST API calls can be used to manage a BMC.

## Blade Switch Controller (sC)

The [Slingshot blade switch](#slingshot-blade-switch) embedded controller (sC) provides a hardware management
REST endpoint to monitor environmental conditions and manage the blade power, switch
ASIC, FPGA buffer/interfaces, and firmware.

## Boot Orchestration Service (BOS)

The Boot Orchestration Service (BOS) is responsible for booting, configuring, and shutting down
collections of nodes. This is accomplished using BOS components, such as boot orchestration session
templates and sessions. BOS uses other services which provide
boot artifact configuration ([BSS](#boot-script-service-bss)),
power control ([CAPMC](#cray-advanced-platform-monitoring-and-control-capmc)),
node status ([HSM](#hardware-state-manager-hsm)),
and configuration ([CFS](#configuration-framework-service-cfs)).

* For more information on BOS, see [Boot Orchestration](operations/boot_orchestration/Boot_Orchestration.md).
* For more information on the BOS API, see [BOS API](api/bos.md).

## Boot Script Service (BSS)

The Boot Script Service stores the configuration information that is used to boot each hardware
component. Nodes consult BSS for their boot artifacts and boot parameters when nodes boot or reboot.

For more information on the BSS API, see [BSS API](api/bss.md).

## Cabinet Cooling Group

A cabinet cooling group is a group of [Olympus cabinets](#olympus-cabinet) that are connected to a floor-standing coolant
distribution unit (CDU). Management network CDU switches in the CDU aggregate all the
[Node Management Network (NMN)](#node-management-network-nmn) and
[Hardware Management Network (HMN)](#hardware-management-network-hmn) connections for the cabinet group.

## Cabinet Environmental Controller (CEC)

The Liquid-Cooled [Olympus Cabinet](#olympus-cabinet) Environmental Controller (CEC) sets the cabinet's geolocation,
monitors environmental sensors, and communicates status to the cooling distribution unit
(CDU). The [CEC microcontroller (eC)](#cec-microcontroller-ec) signals the cooling distribution unit (CDU) to start
liquid cooling and then enables the DC rectifiers so that a chassis can be powered on. The
CEC does not provide a REST endpoint on [SMNet](#system-management-network-smnet), it simply provides the cabinet
environmental and CDU status to the [CMM](#chassis-management-module-cmm) for evaluation or action; the CEC takes no
action. The CEC firmware is flashed automatically when the CMM firmware is flashed. If
there are momentary erroneous signals because of a CEC reset or cable disconnection, the
system can ride through these events without issuing an EPO.

## CEC microcontroller (eC)

The CEC microcontroller (eC) sets the cabinet's geolocation, monitors the cabinet
environmental sensors, and communicates cabinet status to the cooling distribution unit
(CDU). The eC does not provide a REST endpoint on [SMNet](#system-management-network-smnet) as do other embedded
controllers, but simply monitors the cabinet sensors and provides the cabinet environmental
and CDU status to the [CMMs](#chassis-management-module-cmm) for evaluation and/or action.

## Chassis Management Module (CMM)

The cabinet chassis management module (CMM) provides a REST endpoint via its chassis
controller (cC). The CMM is an embedded controller that monitors and controls all the
blades in a chassis. Each chassis supports 8 compute blades and 8 switches and
associated rectifiers/PSUs in the rectifier shelf.
Power Considerations - Two CMMs in adjacent chassis share power from the rectifier
shelf (a shelf connects two adjacent chassis - 0 and 1, 2 and 3, 4 and 5, 6 and 7). If
both CMMs sharing shelf power are both enabling the rectifiers, one of the CMMs can be
removed (but only one at a time) without the rectifier shelf powering off. Removing a
CMM will shutdown all compute blades and switches in the chassis.
Cooling Considerations - Any single CMM in any cabinet can enable CDU cooling. Note
that the CDU "enable path" has vertical control which means CMMs 0, 2, 4, and 6 and CEC0 are
in a path (half of the cabinet), and CMMs 1, 3, 5, and 7 and CEC1 are in another path. Any CMM
or CEC in the same half-cabinet path can be removed and CDU cooling will stay enabled as
long as the other CMMs/CEC enables CDU cooling.

## Compute Node (CN)

The compute node (CN) is where high performance computing application are run. These have
hostnames that are of the form `nidXXXXXX`, that is, `nid` followed by six digits.
where the `XXXXXX` is a six digit number starting with zero padding.

## Compute Rolling Upgrade Service (CRUS)

> **`NOTE`** CRUS was deprecated in CSM 1.2.0 and removed in CSM 1.5.0. See [Deprecated Features](introduction/deprecated_features/README.md).

See [Rolling Upgrades using BOS](operations/boot_orchestration/Rolling_Upgrades.md).

## Configuration Framework Service (CFS)

The Configuration Framework Service (CFS) is available on systems for remote execution and
configuration management of nodes and boot images. This includes nodes available in the
[Hardware State Manager (HSM)](#hardware-state-manager-hsm)
service inventory ([compute](#compute-node-cn), [management](#management-nodes), and [application](#application-node-an) nodes),
and boot images hosted by the [Image Management Service (IMS)](#image-management-service-ims).

CFS configures nodes and images via a GitOps methodology. All configuration content is stored in the
[Version Control Service (VCS)](#version-control-service-vcs),
and is managed by authorized system administrators. CFS provides a scalable
[Ansible Execution Environment (AEE)](#ansible-execution-environment-aee) for the configuration to be applied with flexible
inventory and node targeting options.

* For more information on CFS, see [Configuration Management](operations/configuration_management/Configuration_Management.md).
* For more information on the CFS API, see [CFS API](api/cfs.md).

## Content Projection Service (CPS)

The Content Projection Service (CPS) provides the root filesystem for [compute nodes](#compute-node-cn) and [application nodes](#application-node-an)
in conjunction with the [Data Virtualization Service (DVS)](#data-virtualization-service-dvs).
Using CPS and DVS, the HPE Cray Programming Environment (CPE) and Analytics products are provided as separately mounted filesystems
to compute nodes, application nodes (such as [UANs](#user-access-node-uan)), and worker nodes hosting [UAI](#user-access-instance-uai) pods.

## Cray Advanced Platform Monitoring and Control (CAPMC)

The Cray Advanced Platform Monitoring and Control (CAPMC) service enables direct hardware control of
power on/off, power monitoring, or system-wide power telemetry and configuration parameters from Redfish.
CAPMC implements a simple interface for powering on/off [compute nodes](#compute-node-cn) and [application nodes](#application-node-an), querying
node state information, and querying site-specific service usage rules. These controls enable external
software to more intelligently manage system-wide power consumption or configuration parameters. CAPMC is
replaced by [Power Control Service (PCS)](#power-control-service-pcs).

* For more information on CAPMC, see [Cray Advanced Platform Monitoring and Control](operations/power_management/Cray_Advanced_Platform_Monitoring_and_Control_CAPMC.md).
* For more information on the CAPMC API, see [CAPMC API](api/capmc.md).

## Cray CLI (`cray`)

The `cray` command line interface (CLI) is a framework created to integrate all of the system management
REST APIs into easily usable commands.

## Cray Security Token Service (STS)

The Cray Security Token Service (STS) generates short-lived Ceph S3 credentials.

For more information on the STS API, see [STS Token Generator API](api/sts.md).

## Cray Site Init (CSI)

The Cray Site Init (CSI) program creates, validates, installs, and upgrades an HPE Cray EX system.
CSI can prepare the LiveCD for booting the PIT node and then is used from a booted PIT node
to do its other functions during an installation. During an upgrade, CSI is installed on
one of the nodes to facilitate the CSM software upgrade.

## Cray System Management (CSM)

Cray System Management (CSM) refers to the product stream which provides the infrastructure to
manage an HPE Cray EX system using Kubernetes to manage the containerized workload of layered
micro-services with well-defined REST APIs which provide the ability to discover and control the
hardware platform, manage configuration of the system, configure the network, boot nodes, gather
log and telemetry data, connect API access and user level access to Identity Providers (IdPs),
and provide a method for system administrators and end-users to access the HPE Cray EX system.

## Customer Access Network (CAN)

The Customer Access Network (CAN) provides access from outside the customer network to services,
[Non-Compute Nodes (NCNs)](#non-compute-node-ncn),
and [User Access Nodes (UANs)](#user-access-node-uan) in the system. This allows for the following:

* Clients outside of the system:
  * Log in to each of the NCNs and UANs.
  * Access web UIs within the system (e.g. Prometheus, Grafana, and more).
  * Access the Rest APIs within the system.
  * Access a DNS server within the system for resolution of names for the webUI and REST API services.
  * Run Cray CLI commands from outside the system.
  * Access the [User Access Instances (UAIs)](#user-access-instance-uai).
* NCNs and UANs to access systems outside the cluster (e.g. LDAP, license servers, and more).
* Services within the cluster to access systems outside the cluster.

These nodes and services need an IP address that routes to the customer's network in order to be accessed from
outside the network.

For more information, see [Customer Accessible Networks](operations/network/customer_accessible_networks/Customer_Accessible_Networks.md).

## Data Virtualization Service (DVS)

The Data Virtualization Service (DVS) is a distributed network service that projects file systems
mounted on [Non-Compute Nodes (NCNs)](#non-compute-node-ncn) to other nodes within the HPE Cray EX system. Projecting is
the process of making a file system available on nodes where it does not physically reside.
DVS-specific configuration settings enable clients to access a file system projected by DVS
servers. These clients include [compute nodes](#compute-node-cn), [User Access Nodes (UANs)](#user-access-node-uan), and other
[management nodes](#management-nodes) running [User Access Instances (UAIs)](#user-access-instance-uai). Thus DVS, while not a file system, represents a
software layer that provides scalable transport for file system services. DVS is integrated
with the [Content Projection Service (CPS)](#content-projection-service-cps).

## EX Compute Cabinet

This Liquid-Cooled [Olympus cabinet](#olympus-cabinet) is a dense compute cabinet that supports 64 compute blades and 64
[High Speed Network (HSN)](#high-speed-network-hsn) switches.

## EX TDS Cabinet

A Liquid-Cooled TDS cabinet is a dense compute cabinet that supports 2-chassis, 16
compute blades and 16 [High Speed Network (HSN)](#high-speed-network-hsn) switches, and includes a rack-mounted
4U coolant distribution unit (MCDU-4U).

## Fabric

The [Slingshot](#slingshot) fabric consists of the switches, cables, ports, topology policy, and
configuration settings for the Slingshot [High-Speed Network](#high-speed-network-hsn).

## Firmware Action Service (FAS)

The Firmware Action Service (FAS) provides an interface for managing firmware versions of Redfish-enabled hardware in the system.
FAS interacts with the [Hardware State Manager (HSM)](#hardware-state-manager-hsm), device data, and image data in order to update
firmware.

* For more information on FAS, see [Update firmware with FAS](operations/firmware/Update_Firmware_with_FAS.md).
* For more information on the FAS API, see [FAS API](api/firmware-action.md).

## Floor Standing CDU

A floor-standing coolant distribution unit (CDU) pumps liquid coolant through a cabinet
group or cabinet chilled doors.

## Hardware Management Network (HMN)

The hardware management network (HMN) includes HMS embedded controllers. This
includes chassis controllers (cC), node controllers (nC) and switch controllers (sC), for
Liquid-Cooled TDS and Liquid-Cooled [Olympus](#olympus-cabinet) systems. For standard rack systems, this includes
iPDUs, COTS server [BMCs](#baseboard-management-controller-bmc),
or any other equipment that requires hardware-management
with Redfish. The hardware management network is isolated from all other node
management networks. An out-of-band Ethernet management switch and hardware
management VLAN is used for customer access and administration of hardware.

## Hardware Management Notification Fanout Daemon (HMNFD)

The Hardware Management Notification Fanout Daemon (HMNFD) service receives component state change
notifications from the [HSM](#hardware-state-manager-hsm). It fans notifications out to subscribers (typically [compute nodes](#compute-node-cn)).

For more information on the HMNFD API, see [HMNFD API](api/hmnfd.md).

## Hardware State Manager (HSM)

Hardware State Manager (HSM) service monitors and interrogates hardware components in an HPE Cray EX system,
tracking hardware state and inventory information, and making it available via REST queries and message bus
events when changes occur.

* For more information on HSM, see [Hardware State Manager](operations/hardware_state_manager/Hardware_State_Manager.md).
* For more information on the HSM API, see [HSM API](api/smd.md).

## Heartbeat Tracker Daemon (HBTD)

The Heartbeat Tracker Daemon (HBTD) service listens for heartbeats from components (mainly [compute nodes](#compute-node-cn)).
It tracks changes in heartbeats and conveys changes to the [HSM](#hardware-state-manager-hsm).

For more information on the HBTD API, see [HBTD API](api/hbtd.md).

## Hierarchical Namespace Controller (HNC)

One component of multi-tenancy support.

For more information, see [Multi-Tenancy Support](operations/multi-tenancy/Overview.md).

## High Speed Network (HSN)

The High Speed Network (HSN) in an HPE Cray EX system is based on the [Slingshot](#slingshot) switches.

## Image Management Service (IMS)

The Image Management Service (IMS) uses the open source Kiwi-NG tool to build image roots from
recipes. IMS also uses [CFS](#configuration-framework-service-cfs) to apply image customization for pre-boot
configuration of the image root. These images are bootable on [compute nodes](#compute-node-cn) and [application nodes](#application-node-an).

* For more information on IMS, see [Image Management](operations/image_management/Image_Management.md).
* For more information on the IMS API, see [IMS API](api/ims.md).

## Install and Upgrade Framework (IUF)

The Install and Upgrade Framework (IUF) provides a centralized and consistent method installing and upgrading software on CSM
systems. It automates large portions of the install/upgrade processes in order to simplify, optimize, and unify them.

The IUF has an API, but it is only intended to be used by the IUF CLI, not directly by administrators.

## Management Nodes

The management nodes are a type of [Non-Compute Node (NCN)](#non-compute-node-ncn). Management nodes
provide containerization services as well as storage classes.

The management nodes have various roles:

* Masters nodes are Kubernetes masters.
* Worker nodes are Kubernetes workers and have physical connections to the [High Speed Network](#high-speed-network-hsn).
* Storage nodes physically have more local storage for providing storage classes to Kubernetes.

## Mountain Cabinet

See [Olympus cabinet](#olympus-cabinet). Some software and documentation refers to the Olympus cabinet as a Mountain cabinet.

## Mountain Endpoint Discovery Service (MEDS)

The [Mountain](#mountain-cabinet) Endpoint Discovery Service (MEDS) manages initial discovery, configuration, and geolocation
of Redfish-enabled [BMCs](#baseboard-management-controller-bmc) in Liquid-Cooled [Olympus cabinets](#olympus-cabinet). It periodically makes Redfish requests to
determine if hardware is present or missing.

## NCN Lifecycle Service (NLS)

The NCN Lifecycle Service (NLS) and [Install and Upgrade Framework (IUF)](#install-and-upgrade-framework-iuf) services together
provide automation in the areas of installing and upgrading software on a system, as well as rolling out that software onto nodes as
part of rebuild workflows. The APIs interact with Argo to orchestrate these workflows, so administrators can use the Argo UI to
monitor and visualize these automations.

For more information on the NLS API, see [NLS API](api/nls.md).

## NIC Mezzanine Card (NMC)

The NIC mezzanine card (NMC) attaches to two host port connections on a Liquid-Cooled
compute blade node card and provides the [High Speed Network (HSN)](#high-speed-network-hsn) controllers (NICs).
There are typically two or four NICs on each node card. NMCs connect to the rear panel
EXAMAX connectors on the compute blade through an internal L0 cable assembly in a
single-, dual-, or quad-injection bandwidth configuration depending on the design of the
node card.

## Node Controller (nC)

Each compute blade node card includes an embedded node controller (nC) and REST
endpoint to manage the node environmental conditions, power, HMS nFPGA interface, and
firmware.

## Node Management Network (NMN)

The Node Management Network (NMN) communicates with motherboard PCH-style hosts,
typically 10GbE Ethernet LAN-on-motherboard (LOM) interfaces. This network supports
node boot protocols (DHCP/TFTP/HTTP), in-band telemetry and event exchange, and
general access to management REST APIs.

## Non-Compute Node (NCN)

The non-compute nodes are in the management-plane, these nodes serve infrastructure for microservices
(e.g. Kubernetes and storage classes).

For more information, see [Non-Compute Nodes](background/README.md).

## Olympus Cabinet

The Olympus cabinet is a Liquid-Cooled dense compute cabinet that supports 64 compute
blades and 64 [High Speed Network (HSN)](#high-speed-network-hsn) switches. Every HPE Cray EX system with Olympus
cabinets will also have at least one [River cabinet](#river-cabinet) to house [non-compute node](#non-compute-node-ncn) components
such as [management nodes](#management-nodes), management network switches, storage nodes, [application nodes](#application-node-an),
and possibly other air-cooled [compute nodes](#compute-node-cn). Some software and documentation refers to
the Olympus cabinet as a [Mountain cabinet](#mountain-cabinet).

## Power Control Service (PCS)

The Power Control Service (PCS) service enables direct hardware control of power on/off,
power status, power capping via Redfish. PCS implements a simple interface for powering
on/off [compute nodes](#compute-node-cn) and [application nodes](#application-node-an) and setting power caps. These controls enable
external software to more intelligently manage system-wide power consumption. PCS is the
replacement for [CAPMC](#cray-advanced-platform-monitoring-and-control-capmc).

* For more information on PCS, see [Power Control Service](operations/power_management/Power_Control_Service/Power_Control_Service_PCS.md).
* For more information on the PCS API, see [PCS API](api/power-control.md).

## Power Distribution Unit (PDU)

The cabinet PDU receives 480VAC 3-phase facility power and
provides circuit breaker, fuse protection, and EMI filtered power to the rectifier/power
supplies that distribute ±190VDC (HVDC) to a chassis. PDUs are passive devices that do
not connect to the [SMNet](#system-management-network-smnet).

## Pre-Install Toolkit (PIT)

The Pre-Install Toolkit (PIT), also known as the *Cray Pre-Install Toolkit"*, provides a framework installing [Cray Systems Management](#cray-system-management-csm).
The PIT can be used on any node in the system for recovery and bare-metal discovery, the PIT includes tooling
for recovering any [non-compute nodes](#non-compute-node-ncn), and can remotely recover other [NCNs](#non-compute-node-ncn).

Regarding [CSM](#cray-system-management-csm) installations, typically the first Kubernetes master (`ncn-m001`) is chosen for
running the PIT during a CSM installation. After CSM is installed, the node running the PIT will be rebooted and deployed via
CSM services before finally joining the running Kubernetes cluster.

The PIT is delivered as a [LiveCD](#livecd), a disk image that can be used to remotely boot a node (e.g. a [RemoteISO](#remoteiso)) or by a USB stick.

### LiveCD

The term *LiveCD* refers to the literal image file that contains the Pre-Install Toolkit.

### RemoteISO

The term *RemoteISO* refers to a [LiveCD](#livecd) that is remotely mounted on a server. A remotely mounted LiveCD has no persistence,
a reboot of a RemoteISO will lose all data/information from the running session.

## Rack-Mounted CDU

The rack-mounted coolant distribution unit (MCDU-4U) pumps liquid coolant through the
Liquid-Cooled TDS cabinet coolant manifolds.

## Rack System Compute Cabinet

Air-Cooled compute cabinets house a cluster of [compute nodes](#compute-node-cn), [Slingshot ToR switches](#slingshot-top-of-rack-tor-switch),
and [SMNet](#system-management-network-smnet) ToR switches.

## Redfish Translation Service (RTS)

The Redfish Translation Service (RTS) aids in management of any hardware components which are not managed by
Redfish, such as a ServerTech [PDU](#power-distribution-unit-pdu) in a [River cabinet](#river-cabinet).

## River Cabinet

At least one 19 inch IEA management cabinet is required for every HPE Cray EX system to
support the [management nodes](#management-nodes), system management network, utility
storage, and other support equipment. This cabinet serves as the primary customer access
point for managing the system.

## River Endpoint Discovery Service (REDS)

The River Endpoint Discovery Service (REDS) manages initial discovery, configuration, and geolocation of
Redfish-enabled [BMCs](#baseboard-management-controller-bmc) in air-cooled [River cabinets](#river-cabinet). It periodically makes Redfish requests to determine if
hardware is present or missing.

## Rosetta ASIC

The Rosetta ASIC is a 64-port switch chip that forms the foundation for the [Slingshot](#slingshot)
network. Each port can operate at either 100G or 200G. Each network edge port supports
IEEE 802.3 Ethernet, optimized-IP based protocols, and portals (an enhanced frame format
that supports higher rates of small messages).

## Service/IO Cabinet

An Air-Cooled service/IO cabinet houses a cluster of [NCNs](#non-compute-node-ncn), [Slingshot ToR switches](#slingshot-top-of-rack-tor-switch),
and management network ToR switches to support the managed ecosystem storage,
network, user access services (UAS), and other IO services such as LNet and gateways.

## Slingshot

Slingshot supports L1 and L2 network connectivity between 200 Gbs switch ports and L0
connectivity from a single 200 Gbs port to two 100 Gbs Mellanox ConnectX-5 NICs. Slingshot
also supports edge ports and link aggregation groups (LAG) to external storage systems or
networks.

* IEEE 802.3cd/bs (200 Gbps) Ethernet over 4 x 50 Gbs (PAM-4) lanes `200GBASE-DR4`, 500 meter singlemode fiber
* `200GBASE-SR4`, 100 meter multi-mode fiber
* `200GBASE-CR4`, 3 meter copper cable
* IEEE 802.3cd (100 Gbps) Ethernet over 2 x 50 Gbs (PAM-4) lanes `100GBASE-SR2`, 100 meter multimode fiber
* `100GBASE-CR2`, 3 meter copper cable
* IEEE 802.3 2018 100 Gbps Ethernet over 4 x 25 Gbs (NRZ) lanes
* `100GBASE-CR4`, 5 meter copper cable
* `100GBASE-SR4`, 100 meter multi-mode fiber
* Optimized Ethernet and HPC fabric formats
* Lossy and lossless delivery
* Flow control, 802.1x (PAUSE), 802.1p (PFC), credit-based flow control on fabric links, fine-grain flow control on host links and edge ports, link-level retry, low latency FEC, Ethernet physical interfaces.

## Slingshot Blade Switch

The Liquid-Cooled [Olympus cabinet](#olympus-cabinet) blade switch supports one switch ASIC and 48 fabric ports. Eight
connectors on the rear panel connect orthogonally to each compute blade then to
[NIC mezzanine cards (NMCs)](#nic-mezzanine-card-nmc) inside the compute blade. Each rear panel EXAMAX connector
supports two switch ports (a total of 16 fabric ports per blade). Twelve QSFP-DD cages on
the front panel (4 fabric ports per QSFP-DD cage), fan out 48 external fabric ports to other
switches. The front-panel top ports support passive electrical cables (PEC) or active optical
cables (AOC). The front-panel bottom ports support only PECs for proper cooling in the
blade enclosure.

## Slingshot Top of Rack (ToR) Switch

A standard [River cabinet](#river-cabinet) can support one, two, or four, rack-mounted Slingshot ToR switches.
Each switch supports a total of 64 fabric ports. 32 QSFP-DD connectors on the front panel
connect 64 ports to the fabric. All front-panel connectors support either passive electrical
cables (PEC) or active optical cables (AOC).

## Shasta Cabling Diagram (SHCD)

The Shasta Cabling Diagram (SHCD) is a multiple tab spreadsheet prepared by HPE Cray Manufacturing
with information about the components in an HPE Cray EX system. This document has much information
about the system. Included in the SHCD are a configuration summary with revision history, floor layout
plan, type and location of components in the air-cooled cabinets, type and location of components in
the Liquid-Cooled cabinets, device diagrams for switches and nodes in the cabinets, list of source
and destination of every [HSN](#high-speed-network-hsn) cable, list of source and destination of every cable connected to the
spine switches, list of source and destination of every cable connected to the [NMN](#node-management-network-nmn), list of source
and destination of every cable connected to the [HMN](#hardware-management-network-hmn). list of cabling for the KVM, and routing of power to the
[PDUs](#power-distribution-unit-pdu).

## Supply/Return Cutoff Valves

Manual coolant supply and return shutoff valves at the top of each cabinet can be closed to
isolate a single cabinet from the other cabinets in the cooling group for maintenance. If the
valves are closed during operation, the action automatically causes the [CMMs](#chassis-management-module-cmm) to remove
±190VDC from each chassis in the cabinet because of the loss of coolant pressure.

## System Admin Toolkit (SAT)

The System Admin Toolkit (SAT) product provides the `sat` command line interface which interacts with the REST APIs of many services to perform more complex system management tasks.

For more information, see [System Admin Toolkit in CSM](operations/sat/sat_in_csm.md).

## System Configuration Service (SCSD)

The System Configuration Service (SCSD) allows administrators to set various [BMC](#baseboard-management-controller-bmc) and
controller parameters. These parameters are typically set during discovery, but this tool enables parameters to be set before or
after discovery.

For more information on the SCSD API, see [SCSD API](api/scsd.md).

## System Layout Service (SLS)

The System Layout Service (SLS) serves as a "single source of truth" for the system design. It details
the physical locations of network hardware, [management nodes](#management-nodes), [application nodes](#application-node-an), [compute nodes](#compute-node-cn), and
cabinets. It also stores information about the network, such as which port on which switch should be connected to each node.

* For more information on SLS, see [System Layout Service](operations/system_layout_service/System_Layout_Service_SLS.md).
* For more information on the SLS API, see [SLS API](api/sls.md).

## System Management Network (SMNet)

The System Management Network (SMNet) is a dedicated out-of-band (OOB) spine-leaf
topology Ethernet network that interconnects all the nodes in the system to management
services.

## System Management Services (SMS)

System Management Services (SMS) leverages open REST APIs, Kubernetes container
orchestration, and a pool of commercial off-the-shelf (COTS) servers to manage the system.
The management server pool, custom Redfish-enabled embedded controllers, iPDU
controllers, and server [BMCs](#baseboard-management-controller-bmc) are unified under a common software platform that provides 3
levels of management: Level 1 HaaS, Level 2 IaaS, and Level 3 PaaS.

## System Management Services (SMS) nodes

System Management Services (SMS) nodes provide access to the entire management cluster and Kubernetes container orchestration.

## Tenant and Partition Management System (TAPMS)

One component of multi-tenancy support.

* For more information on TAPMS, see [Multi-Tenancy Support](operations/multi-tenancy/Overview.md).
* For more information on the TAPMS API, see [TAPMS Tenant Status API](api/tapms-operator.md).

## Top of Rack Switch Controller (sC-ToR)

The air-Cooled cabinet [HSN](#high-speed-network-hsn) ToR switch embedded controller (sC-ToR) provides a hardware
management REST endpoint to monitor the ToR switch environmental conditions and
manage the switch power, [HSN](#high-speed-network-hsn) ASIC, and FPGA interfaces.

## User Access Instance (UAI)

The User Access Instance (UAI) is a lightweight, disposable platform that runs under Kubernetes orchestration
on worker nodes. The UAI provides a single user containerized environment for users on a Cray Ex system to
develop, build, and execute their applications on the HPE Cray EX [compute node](#compute-node-cn). See [UAN](#user-access-node-uan) for another
way for users to gain access.

For more information, see [User Access Service](operations/UAS_user_and_admin_topics/README.md).

## User Access Node (UAN)

The User Access Node (UAN) is an [NCN](#non-compute-node-ncn), but is really one of the special types of [application nodes](#application-node-an).
The UAN provides a traditional multi-user Linux environment for users on a Cray Ex system to
develop, build, and execute their applications on the HPE Cray EX [compute node](#compute-node-cn). See [UAI](#user-access-instance-uai) for another
way for users to gain access. Some sites refer to their UANs as Login nodes.

## User Access Service (UAS)

The User Access Service (UAS) is a containerized service managed by Kubernetes that enables users to
create and run user applications inside a [UAI](#user-access-instance-uai). UAS runs on a [management node](#management-nodes) that is acting as a
Kubernetes worker node. When a user requests a new UAI, the UAS service returns status and connection
information to the newly created UAI. External access to UAS is routed through a node that hosts
gateway services.

* For more information on UAS, see [User Access Service](operations/UAS_user_and_admin_topics/README.md).
* For more information on the UAS API, see [UAS API](api/uas-mgr.md).

## Version Control Service (VCS)

The Version Control Service (VCS) provides configuration content to [CFS](#configuration-framework-service-cfs) via a GitOps methodology
based on a `git` server (`gitea`) that can be accessed by the `git` command but also includes a
web interface for repository management, pull requests, and a visual view of all repositories
and organizations.

For more information, see [Version Control Service](operations/configuration_management/Version_Control_Service_VCS.md).

## xname

Component names (xnames) identify the geolocation for hardware components in the HPE Cray EX system. Every
component is uniquely identified by these component names. Some, like the system cabinet number or the CDU
number, can be changed by site needs. There is no geolocation encoded within the cabinet number, such as an
X-Y coordinate system to relate to the floor layout of the cabinets. Other component names refer to the location
within a cabinet and go down to the port on a card or switch or the socket holding a processor or a memory DIMM
location.

For more information, see [Component Names (xnames)](operations/Component_Names_xnames.md).
