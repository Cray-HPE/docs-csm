# Bifurcating the CAN - CSM-1.2 Feature Details

- [CAN New Features Overview](#can-new-features-overview)
- [High Speed CAN (CHN)](#high-speed-can-(chn))
  - [CHN system ingress endpoints accessible in CSM-1.2](#chn-system-ingress-endpoints-accessible-in-csm-1.2)
  - [CHN system egress endpoints accessible in CSM-1.2](#chn-system-egress-endpoints-accessible-in-csm-1.2)
  - [Endpoint Naming](#endpoint-naming)
    - [Touchpoints: effects and changes](#touchpoints:-effects-and-changes)
    - [When naming occurs](#when-naming-occurs)
    - [Ability to change post-install](#ability-to-change-post-install)
  - [Endpoint Addressing](#endpoint-addressing)
    - [Touchpoints: effects and changes](#touchpoints:-effects-and-changes)
    - [When addressing occurs](#when-addressing-occurs)
    - [Ability to change post-install](#ability-to-change-post-install)
  - [Traffic Separation and Routing](#traffic-separation-and-routing)
    - [Touchpoints: effects and changes](#touchpoints:-effects-and-changes)
    - [When configuration occurs](#when-configuration-occurs)
    - [Ability to change post install](#ability-to-change-post-install)
- [Management CAN(CMN)](#management-can(cmn))
  - [Traffic Separation and Routing](#traffic-separation-and-routing)
  - [Endpoint Naming](#endpoint-naming)
  - [Endpoint Addressing](#endpoint-addressing)
  - [Changes](#changes)
    - [Touchpoints: effects and changes](#touchpoints:-effects-and-changes)
    - [When configuration occurs](#when-configuration-occurs)
    - [Ability to change post install](#ability-to-change-post-install)
- [CAN External/Site Access (site DNS, LDAP, etc...)](#can-external/site-access-(site-dns,-ldap,-etc...))
  - [Traffic Separation and Routing](#traffic-separation-and-routing)
  - [Changes](#changes)
    - [Touchpoints: effects and changes](#touchpoints:-effects-and-changes)
    - [When configuration occurs](#when-configuration-occurs)
    - [Ability to change post install](#ability-to-change-post-install)

<a name="can-new-features-overview"></a>

## CAN New Features Overview

Bifurcation or splitting of the Customer Access Network (CAN) enables customization of customer traffic to and from the system.
Customization will be performed during installation.
For CSM-1.2 there are two new CAN networks being introduced as part of the process to split the existing monolithic CAN:

1. **High Speed CAN - CHN** : This feature adds the ability to connect to Application Nodes (UAN), UAI, Compute Nodes
and Kubernetes API endpoints from the customer site via the High Speed Network (HSN).
2. **Management CAN - CMN** :  Using a new VLAN on the Management Network, this feature allows system administrative access from the customer site.
Administrative access was previously available on the original CAN and this feature provides a traffic path and access split.

The existing and original CAN will remain as-is. **During installation the opportunity to enable these new features will be presented.**
At this time customers may choose to:

1. **Add** High Speed CAN (CHN) access in addition to the existing CAN.
2. **Move** system access to site external resources (LDAP, DNS, etc...) from the CAN to either the CMN or CHN.
3. **Move** administrative traffic from the existing CAN to the Management CAN (CMN).

The feature matrix of the CAN is described [here](bican_support_matrix.md).
Details of the High Speed CAN (CHN) and the Management CAN (CMN) are described below.

![Customer Access Overview](img/customer_access_overview.png) 

<a name="high-speed-can-(chn)"></a>

## High Speed CAN (CHN)

Access to system resources from the customer site over the High Speed Network is provided by the High Speed CAN (CHN).
As can be seen in the diagram above, traffic ingress from the site for the CHN is over the Edge Routers
(typically a pair of Arista Switches which provide other HSN access - for ClusterStor for instance).

NOTE:  Arista routing configurations as a virtual routing instance are in-scope for CSM-1.2 CHN work.
Other Edge Routers, including Juniper are out of scope.

<a name="chn-system-ingress-endpoints-accessible-in-csm-1.2"></a>

## CHN system ingress endpoints accessible in CSM-1.2

- Designated Application Nodes, particularly **UAN, over ssh**.
- Designated **Compute Nodes (CN)**, including those used for Compute-as-UAN, **over ssh**.
- Kubernetes **API endpoints over https**.

<a name="chn-system-egress-endpoints-accessible-in-csm-1.2"></a>

## CHN system egress endpoints accessible in CSM-1.2

- System access to **site external resources** , including LDAP(s) and DNS.

<a name="endpoint-naming"></a>

## Endpoint Naming

A ".chn" DNS suffix will be used for all endpoints accessed over the High Speed CAN.
Endpoints naming will be resolved and maintained in the system Authoritative DNS (another CSM-1.2 feature).
As part of the introduction of authoritative DNS endpoints will also have a top-level-domain appended, creating a fully qualified domain system.

Examples:

- uan01.chn.*tld* as resolved externally.
- uan01.chn can be resolved internal to the system (maintained via local resolv.conf).
- nid000001.chn.*tld*
- api-gateway-service.chn.*tld*

Where *tld* is configurable at installation and can be a subdomain of the site domain system.
Exchange of system DNS with the site may be via delegation (preferred) or zone transfer (AXFR).

Once added to CSI, names and IP's will use the standard CSM data flow and end up in SLS and be available for use via both DNS and DHCP services.

<a name="touchpoints:-effects-and-changes"></a>

### Touchpoints: effects and changes

- Will require installation and admininistration document changes.
- The CHN requires a small change in CSI to add this network.
- Will (automatically) use the DNS infrastructure from previous CSM install.
- Name aliases can be added/changed/removed via the API to SLS and become available in DNS automatically.
DNS tooling for this was released in Shasta v1.4 with [SLS](../../index.md#system-layout-service-sls)

<a name="when-naming-occurs"></a>

### When naming occurs

- Installation as part of Cray Site Initialization (CSI) data.
- During site customizations.

<a name="ability-to-change-post-install"></a>

### Ability to change post-install

- YES - Add/Remove/Change Aliases
- NO Change FQDN and domain suffixes because of the number of touchpoints.
Chiefly Kubernetes limitations introduced at install time and sheer number of touchpoints.

<a name="endpoint-addressing"></a>

## Endpoint Addressing

For the CSM-1.2 release CHN endpoints will have **IPv4 addressing only** , with IPv6 introduction in a future release.
The current limitation to system introduction of IPv6 is Kubernetes Weave as well as a vast amount of system configuration
and testing required to certify IPv6 system-wide.

The CHN will, by default, have a private IPv4 address block.
This is intended to be changed during installation to a **customer-supplied IPv4 address block**.

<a name="touchpoints:-effects-and-changes"></a>

### Touchpoints: effects and changes

- Installer and documentation changes to support new network and pathing as part of configuration.
- CSI for network generation and initial configuration.
- NCN images to support additional **subnets and routing.**
- CFS images for CN and UAN **addressing and routing.**
- UAI to support changes to **addressing and routing.**
- MetalLB to create new API endpoints and peer with Edge Router.
- Arista switch pair to create new or add to existing virtual routing instance for pathing and access control.
- HSN required for transport of application traffic so new procedures need to be developed for troubleshooting and support.

<a name="when-addressing-occurs"></a>

### When addressing occurs

- Installation as part of CSI data.

<a name="ability-to-change-post-install"></a>

### Ability to change post-install

- NO - There are dozens of touchpoints throughout the system.

<a name="traffic-separation-and-routing"></a>

## Traffic Separation and Routing

In CSM 1.2, there will be Layer 3 separation internal to the system but co-mingled Layer 2 between the CHN IPv4 addressing and the internal HSN private IPv4 addresses.
Isolation will be within the Slingshot network as well as separated at the Edge Router.

<a name="touchpoings:-effects-and-changes"></a>

### Touchpoints: effects and changes

- Edge Router provides all **routing and access controls** in CSM-1.2 (via a virtual routing instance if Arista switch pair is used).
As noted above, non-Arista router configurations are out of scope for CSM-1.2 work.
- Internal to the system CHN traffic will exist in the same Layer 2 domain with internal HSN traffic until the Slingshot network supports VLAN separation.
- Compute (CN) and Application Node (UAN in this case) configuration or IPv4 addressing and routing will be via CFS.
  - When multiple hsn interfaces exists the CHN can be configured to load balance TCP/UDP traffic &quot;flows&quot; across interfaces via ECMP Layer 3 routing in Linux.
- UAI addressing and routing over the hsn interfaces for the NCN workers is required.
- API endpoints in MetalLB for the CHN will be accessible over NCN worker hsn interfaces (via ECMP Layer 3 routing).
  - MetalLB will peer with the Edge Routers to supply load balanced API access.

<a name="when-configuration-occurs"></a>

### When configuration occurs

- Installation as part of a virtual routing instance on the Edge Routers.

<a name="ability-to-change-post-install"></a>

### Ability to change post install

- NOT RECOMMENDED - Edge Router controls external access so change scope is limited.
- NO - Node images could be changed but routing and IP changes to CFS images would need extensive testing to certify.

<a name="management-can(cmn)"></a>

## Management CAN(CMN)

The original CAN released in Shasta v1.1 contained the ability to access NCN workers, masters and storage directly via ssh for administrative purposes.
This administrative traffic was co-mingled with general user traffic for jobs.
Based on customer requests a new mechanism for administrative access to workers, masters and storage nodes will be added in CSM-1.2.
The new Customer Management Network (CMN) will be created as **a separate-and-distinct VLAN and Subnet on the Management Network** and uplink at the edge to the Customer network.
This new CMN network will allow ssh into the NCNs and CAN access will be disallowed.
NOTE this is generally for ingress access for administrative purposes.

<a name="traffic-separation-and-routing"></a>

## Traffic Separation and Routing

Enabling the CMN at installation time will have the following effects:

- Adding uplinks to the Customer Site similar to the original CAN.
- Creating of a new VLAN on the Management Network.
- Adding a new subnet and routing to the Management Network and NCNs.

<a name="endpoint-naming"></a>

## Endpoint Naming

If enabled during installation a &quot;.cmn&quot; suffix will be generated by CSI and used in SLS and Authoritative DNS.
The "plumbing" of this will occur as previously described in the CHN.

Examples:

- ssh ncn-w001.cmn.tld

<a name="endpoint-addressing"></a>

## Endpoint Addressing

For the CSM-1.2 release the CMN will only be available via customer-supplied IPv4 addressing.

<a name="changes"></a>

## Changes

<a name="touchpoints:-effects-and-changes"></a>

### Touchpoints: effects and changes

- CMN required beginning with this release.
  - Customer will supply a subnet similar to the way the CAN is deployed.
  Sizing is Number of NCNs plus a couple more addresses (TBD).
- Edge access to the CMN will need to be configured with the customer site.
  - ACL development.
- The Management network will require the following changes:
  - Addition of the new CMN VLAN.  This should be similar to the existing CAN configuration.
  - Termination of the new CMN VLAN on ports supporting NCNs.
  - Addition of Customer-supplied CMN IP&#39;s to the managment switches to support routing.
- NCN workers, masters and storage will require the following changes:
  - Image support for CMN VLAN, addressing and routing.
- CSI changes to support the new network and naming.

<a name="when-configuration-occurs"></a>

### When configuration occurs

- During installation as part of CSI data generation.
- During installation as part of Management Network configuration.
- During installation as part of NCN deployment.

<a name="ability-to-change-post-install"></a>

### Ability to change post install

- NOT RECOMMENDED and would be manual.

<a name="can-external/site-access-(site-dns,-ldap,-etc...)"></a>

## CAN External/Site Access (site DNS, LDAP, etc...)

System access to site or external resources, like the Internet, site DNS and site LDAP were previously provided over the CAN.
By default this CAN access path will remain, but for the CSM-1.2 release it will be possible during installation to select system-to-site access over the CHN or CMN.

<a name="traffic-separation-and-routing"></a>

## Traffic Separation and Routing

At installation time one of the following egress routes from the system to the site may be selected: CAN (default), CHN, CMN.

<a name="changes"></a>

## Changes

<a name="touchpoints:-effects-and-changes"></a>

### Touchpoints: effects and changes

- Installer customizations changes:
  - Management Network changes possibly for routing, but new ACLs may be necessary.
  - NCNs will require specific site routes to prioritize selected pathing over the system default (CAN).
- Dependent on CHN and CMN work.

<a name="when-configuration-occurs"></a>

### When configuration occurs

- During installation as part of site configuration.

<a name="ability-to-change-post-install"></a>

### Ability to change post install

- NO
