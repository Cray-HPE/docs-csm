# Glossary

Glossary of terms used in CSM documentation.

### Application Node (AN)

An application node (AN) is an NCN which is not providing management fuctions for the Cray EX system.
The AN is not part of the Kubernetes cluster to which management nodes belong.  One special type of AN
is the UAN (User Access Node), but different systems may have need for other types of AN, such as nodes
which provide a Lustre routing function (LNet router), or gateway between HSN and Infiniband, or data 
mover between two different network file systems, or visualization servers, or some other special purpose
node. 

### Baseboard Management Controller (BMC)

Air-Cooled cabinet COTS servers include a Redfish-enabled baseboard management
controller (BMC) and REST endpoint for API control and management. Either IPMI
commands or REST API calls can be used to manage a COTS sever.

### Blade Switch Controller (sC)

The Slingshot blade switch embedded controller (sC) provides a hardware management
REST endpoint to monitor environmental conditions and manage the blade power, switch
ASIC, FPGA buffer/interfaces, and firmware.

### Cabinet Cooling Group
A cabinet cooling group is a group of cabinets that are connected to a floor-standing coolant
distribution unit (CDU). Management network CDU switches in the CDU aggregate all the
node management network (NMN) and hardware management network (HMN) connections
for the cabinet group.

### Customer Access Network

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

These nodes and services need an IP address that routes to the customer’s network in order to be accessed from
outside the network.

### Cabinet Environmental Controller (CEC)

The Liquid-Cooled cabinet environmental controller (CEC) sets the cabinet's geolocation,
monitors environmental sensors, and communicates status to the cooling distribution unit
(CDU). The CEC microcontroller (eC) signals the cooling distribution unit (CDU) to start
liquid cooling and then enables the DC rectifiers so that a chassis can be powered on. The
CEC does not provide a REST endpoint on SMNet, it simply provides the cabinet
environmental and CDU status to the CMM for evaluation or action; the CEC takes no
action. The CEC firmware is flashed automatically when the CMM firmware is flashed. If
there are momentary erroneous signals due to a CEC reset or cable disconnection, the
system can ride through these events without issuing an EPO.

### Chassis Management Module (CMM)

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

### Compute Node (CN)

The compute node (CN) is where high performance computing application are run.  These have
hostnames that are of the form "nidXXXXXX", that is, "nid" followed by six digits.
where the XXXXXX is a six digit number starting with zero padding.

### Cray Site Init (CSI)

The Cray Site Init (CSI) program creates, validates, installs, and upgrades a Cray EX system.
CSI can prepare the LiveCD for booting the PIT node and then is used from a booted PIT node
to do its other functions during an installation.  During an upgrade, CSI is installed on
one of the nodes to facilitate the CSM software upgrade.

### Cray System Management (CSM)

Cray System Management (CSM) refers to the product stream which provides the infrastructure to 
manage a Cray EX system using Kubernetes to manage the containerized workload of layered
microservices with well-defined REST APIs which provide the ability to discover and control the
hardware platform, manage configuration of the system, configure the network, boot nodes, gather
log and telemetry data, connect API access and user level access to Identity Providers (IdPs),
and provide a method for system administrators and end-users to access the Cray EX system.

### eC

The CEC microcontroller (eC) sets the cabinet's geolocation, monitors the cabinet
environmental sensors, and communicates cabinet status to the cooling distribution unit
(CDU). The eC does not provide a REST endpoint on SMNet as do other embedded
controllers, but simply monitors the cabinet sensors and provides the cabinet environmental
and CDU status to the CMMs for evaluation and/or action.

### EX Compute Cabinet

A Liquid-Cooled cabinet is a dense compute cabinet that supports 64 compute blades and 64
high-speed network (HSN) switches.

### EX TDS Cabinet

A Liquid-Cooled TDS cabinet is a dense compute cabinet that supports 2-chassis, 16
compute blades and 16 high-speed network (HSN) switches, and includes a rack-mounted
4U coolant distribution unit (MCDU-4U).

### Fabric

The Slingshot fabric consists of the switches, cables, ports, topology policy, and
configuration settings for the Slingshot high-speed network.

### Floor Standing CDU

A floor-standing coolant distribution unit (CDU) pumps liquid coolant through a cabinet
group or cabinet chilled doors.

### Hardware Management Network

The hardware management network (HMN) includes HMS embedded controllers. This
includes chassis controllers (cC), node controllers (nC) and switch controllers (sC), for
Liquid-Cooled TDS and Liquid-Cooled systems. For standard rack systems, this includes
iPDUs, COTS server BMCs, or any other equipment that requires hardware-management
with Redfish. The hardware management network is isolated from all other node
management networks. An out-of-band Ethernet management switch and hardware
management VLAN is used for customer access and administration of hardware.

### LiveCD

The liveCD has a complete bootable Linux operating system that can be run from a read-only CD or
DVD or from a writable USB flash drive or hard disk.  It is used to bootstrap the installation
process for CSM software.

### Management Cabinet

At least one 19-in IEA management cabinet is required for every HPE Cray EX system to
support the management non-compute nodes (NCN), system management network, utility
storage, and other support equipment. This cabinet serves as the primary customer access
point for managing the system.

### Management Nodes

The management nodes are one grouping of NCNs.  The management nodes include the master nodes
with hostnames of the form of ncn-mXXX, the worker nodes with hostnames of the form ncn-wXXX,
and utility storage nodes, with hostnames of the form ncn-sXXX, where the XXX is a three
digit number starting with zero padding.  The utility storage nodes provide Ceph storage for use
by the management nodes.  The master nodes provide Kubernetes master functions and have the 
etcd cluster which provides a datastore for Kubernetes.  The worker nodes provide Kubernetes
worker functions where most of the containerized workload is scheduled by Kubernetes.

### NIC Mezzanine Card (NMC)

The NIC mezzanine card (NMC) attaches to two host port connections on a liquid-cooled
compute blade node card and provides the high-speed network (HSN) controllers (NICs).
There are typically two or four NICs on each node card. NMCs connect to the rear panel
EXAMAX connectors on the compute blade through an internal L0 cable assembly in a
single-, dual-, or quad-injection bandwidth configuration depending on the design of the
node card.

### Node Controller (nC)

Each compute blade node card includes an embedded node controller (nC) and REST
endpoint to manage the node environmental conditions, power, HMS nFPGA interface, and
firmware.

### Node Management Network

The node management network (NMN) communicates with motherboard PCH-style hosts,
typically 10GbE Ethernet LAN-on-motherboard (LOM) interfaces. This network supports
node boot protocols (DHCP/TFTP/HTTP), in-band telemetry and event exchange, and
general access to management REST APIs.

### Non-Compute Node (NCN)

Any node which is not a compute node may be called a Non-Compute Node (NCN).  The NCNs include
management nodes and application nodes.

### Pre-Install Toolkit (PIT) node

The Pre-Install Toolkit is installed onto the initial node used as the inception node during software
installation which is booted from a LiveCD.  The node running the Pre-Install Toolkit is known
as the PIT node during the installation process until it reboots from a normal management node image
like the other master nodes.

### PDU

The cabinet power distribution unit (PDU) receives 480VAC 3-phase facility power and
provides circuit breaker, fuse protection, and EMI filtered power to the rectifier/power
supplies that distribute ±190VDC (HVDC) to a chassis. PDUs are passive devices that do
not connect to the SMNet.

### Rack-Mounted CDU

The rack-mounted coolant distribution unit (MCDU-4U) pumps liquid coolant through the
Liquid-Cooled TDS cabinet coolant manifolds.

### Rack System Compute Cabinet

Air-Cooled compute cabinets house a cluster of compute nodes, Slingshot ToR switches,
and SMNet ToR switches.

### Rosetta ASIC

The Rosetta ASIC is a 64-port switch chip that forms the foundation for the Slingshot
network. Each port can operate at either 100G or 200G. Each network edge port supports
IEEE 802.3 Ethernet, optimized-IP based protocols, and portals (an enhanced frame format
that supports higher rates of small messages).

### Service/IO Cabinet

An Air-Cooled service/IO cabinet houses a cluster of NCN servers, Slingshot ToR switches,
and management network ToR switches to support the managed ecosystem storage,
network, user access services (UAS), and other IO services such as LNet and gateways.

### Slingshot

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

### Slingshot Blade Switch

The Liquid-Cooled cabinet blade switch supports one switch ASIC and 48 fabric ports. Eight
connectors on the rear panel connect orthogonally to each compute blade then to NIC
mezzanine cards (NMCs) inside the compute blade. Each rear panel EXAMAX connector
supports two switch ports (a total of 16 fabric ports per blade). Twelve QSFP-DD cages on
the front panel (4 fabric ports per QSFP-DD cage), fan out 48 external fabric ports to other
switches. The front-panel top ports support passive electrical cables (PEC) or active optical
cables (AOC). The front-panel bottom ports support only PECs for proper cooling in the
blade enclosure.

### Slingshot ToR Switch

A standard cabinet can support one, two, or four, rack-mounted Slingshot ToR switches.
Each switch supports a total of 64 fabric ports. 32 QSFP-DD connectors on the front panel
connect 64 ports to the fabric. All front-panel connectors support either passive electrical
cables (PEC) or active optical cables (AOC).

### SMS Nodes

System management services (SMS) nodes provide access to the entire management
cluster and Kubernetes container orchestration. 

### Supply/Return Cutoff Valves

Manual coolant supply and return shutoff valves at the top of each cabinet can be closed to
isolate a single cabinet from the other cabinets in the cooling group for maintenance. If the
valves are closed during operation, the action automatically causes the CMMs to remove
±190VDC from each chassis in the cabinet due to the loss of coolant pressure.

### System Management Services (SMS)

System Management Services (SMS) leverages open REST APIs, Kubernetes container
orchestration, and a pool of commercial off-the-shelf (COTS) servers to manage the system.
The management server pool, custom Redfish-enabled embedded controllers, iPDU
controllers, and server BMCs are unified under a common software platform that provides 3
levels of management: Level 1 HaaS, Level 2 IaaS, and Level 3 PaaS.

### System Management Network (SMNet)

The system management network (SMNet) is a dedicated out-of-band (OOB) spine-leaf
topology Ethernet network that interconnects all the nodes in the system to management
services.

### ToR Switch Controller (sC-ToR)

The Air-Cooled cabinet HSN ToR switch embedded controller (sC-ToR) provides a hardware
management REST endpoint to monitor the ToR switch environmental conditions and
manage the switch power, HSN ASIC, and FPGA interfaces.

### UAI

The User Access Instance (UAI) is a lightweight, disposable platform that runs under Kubernetes orchestraion
on worker nodes.  The UAI provides a single user containerized environment for users on a Cray Ex system to
develop, build, and execute their applications on the Cray EX compute node.  See UAN for another
way for users to gain access.

### UAN

The User Access Node (UAN) is an NCN, but is really one of the special types of Application nodes.
The UAN provides a traditional multi-user Linux environment for users on a Cray Ex system to
develop, build, and execute their applications on the Cray EX compute node.  See UAI for another
way for users to gain access.  Some sites refer to their UANs as Login nodes.

### xname

Component names (xnames) identify the geolocation for hardware components in the HPE Cray EX system. Every
component is uniquely identified by these component names. Some, like the system cabinet number or the CDU
number, can be changed by site needs. There is no geolocation encoded within the cabinet number, such as an
X-Y coordinate system to relate to the floor layout of the cabinets. Other component names refer to the location
within a cabinet and go down to the port on a card or switch or the socket holding a processor or a memory DIMM
location.  Refer to "Component Names (xnames)" in the _HPE Cray EX Hardware Management Administration Guide 1.5 S-8015_.
