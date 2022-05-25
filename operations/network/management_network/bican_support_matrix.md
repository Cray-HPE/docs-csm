
# BICAN Support Matrix - Shasta Customer Access Networks

## <u>Data Sheet</u>


### <b><u>Shasta Networking</u></b>


### Customer Access Networks

### Overview


Customer Access Networks provide the interface between Shasta System networking and the customer Site network.  Customer Access Networks (CANs) are routed networks with broadcast domain separation.  Customer Access Networks networks provides higher availability and more flexibility in accessing cloud services compared to traditional "bastion hosts", and are more in line with cloud-native architecture of Shasta as whole.

Customer Access Networks (CANs) provide flexible networking at the edge between the Site and Shasta System to

* Perform administrative tasks _on_ the system.
* Run jobs and move jobs data _to and from_ the system.
* Access site resources like DNS and LDAP _from_ the system.

## Feature Access Matrix


For CSM 1.2 the notion of the CAN has been expanded to meet customer requests for increased flexibility and policy control.


* Selection of user access for job control and data movement over the Shasta Management Network (CAN) _or_ the High Speed Network (CHN) is made during system installation or upgrade.

* Creation of the Customer Management Network (CMN) during installation or upgrade is mandatory.


## Network Overview


![](img/tds_can_overview.png)

Internal Networks:

* Node Management Network (NMN) \- Provides the internal control plane for systems management and jobs control.
* Hardware Management Network (HMN) \- Provides internal access to system baseboard management controllers (BMC/iLO) and other lower-level hardware access.

External and Edge Networks:

* Customer Management Network (CMN) \- Provides customer access from the Site to the System for administrators.
  * Customer Access Network (CAN) or Customer High Speed Network (CHN) provide:
  * Customer access from the site to the System for job control and jobs data movement.
* Access from the System to the Site for network services like DNS, LDAP, etc...

## Supported Configurations


# Option A: CMN + CAN (Management Network only - Layer 2 separation)


![](img/cmn_plus_can.png)

# Option B: CMN + CHN (Administration over Management Network, User Access over High Speed Network)


![](img/cmn_plus_chn.png)

Note: During installation the High Speed Network is not configured until relatively late in the install process.  Installation generally requires site access for deployment artifacts, site DNS, etc... To achieve this the Management Network CAN is used during the installation process for system traffic egress until the High Speed Network is available.

## Network Capabilities


# Layer 2


* CMN, CAN and CHN have broadcast boundaries at the System:Site edge.

# Layer 3


* Addressing

* IPv4 supported (default)
* IPv6 roadmap

* Routing

* Static routes (default) exist on the edge router/switches at the edge.
* Dynamic routing (OSPF or BGP) is possible at the edge.

## Network Sizing and Requirements


CMN

* IPv4:

* Site routable
* Contiguous (CIDR block)
* Non-overlapping with internal networks (configurable during installation)
* Size estimate is the sum of:
  * Number of Non-Compute Nodes (NCNs) of type master, worker or storage used by the Kubernetes cluster
  * Number of switches on the Management Network
  * Number of administrative API endpoints
  * Several administrative addresses for switch interfaces and routing. 
  * SWAG:  A /26 block is typically sufficient for systems less than approximately 4000 nodes.

CAN or CHN

* IPv4:

* Site routable
* Contiguous (CIDR block)
* Non-overlapping with internal networks (configurable during installation)
* Size estimate is the sum of:
  * Number of Application Nodes requiring access from the Site:  User Access Node (UAN), Login, etc...
  * Number of User Access Instances (UAI) in Kubernetes (if used).
  * Number of API endpoints
  * Several administrative addresses for switch interfaces and routing
  * NOTE:  CAN or CHN sizing is largely dependent on customer-specific use cases and Application Node hardware.