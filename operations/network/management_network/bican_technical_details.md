# Bifurcating the CAN - CSM 1.2 Feature Details

- [1 CAN New Features Overview](#1-can-new-features-overview)
- [2 High Speed CAN (CHN)](#2-high-speed-can-chn)
  - [2.1 CHN system ingress endpoints accessible in CSM 1.2](#21-chn-system-ingress-endpoints-accessible-in-CSM-12)
  - [2.2 CHN system egress endpoints accessible in CSM 1.2](#22-chn-system-egress-endpoints-accessible-in-CSM-12)
  - [2.3 Endpoint Naming](#23-endpoint-naming)
    - [2.3.1 Touchpoints: effects and changes](#231-touchpoints-effects-and-changes)
    - [2.3.2 When naming occurs](#232-when-naming-occurs)
    - [2.3.3 Ability to change post-install](#233-ability-to-change-post-install)
  - [2.4 Endpoint Addressing](#24-endpoint-addressing)
    - [2.4.1 Touchpoints: effects and changes](#241-touchpoints-effects-and-changes)
    - [2.4.2 When addressing occurs](#242-when-addressing-occurs)
    - [2.4.3 Ability to change post-install](#243-ability-to-change-post-install)
  - [2.5 Traffic Separation and Routing](#25-traffic-separation-and-routing)
    - [2.5.1 Touchpoints: effects and changes](#251-touchpoints-effects-and-changes)
    - [2.5.2 When configuration occurs](#252-when-configuration-occurs)
    - [2.5.3 Ability to change post install](#253-ability-to-change-post-install)
- [3 Management CAN(CMN)](#3-management-cancmn)
  - [3.1 Traffic Separation and Routing](#31-traffic-separation-and-routing)
  - [3.2 Endpoint Naming](#32-endpoint-naming)
  - [3.3 Endpoint Addressing](#33-endpoint-addressing)
  - [3.4 Changes](#34-changes)
    - [3.4.1 Touchpoints: effects and changes](#341-touchpoints-effects-and-changes)
    - [3.4.2 When configuration occurs](#342-when-configuration-occurs)
    - [3.4.3 Ability to change post install](#343-ability-to-change-post-install)
- [4 CAN External/Site Access (site DNS, LDAP, etc...)](#4-can-externalsite-access-site-dns-ldap-etc)
  - [4.1 Traffic Separation and Routing](#41-traffic-separation-and-routing)
  - [4.2 Changes](#42-changes)
    - [4.2.1 Touchpoints: effects and changes](#421-touchpoints-effects-and-changes)
    - [4.2.2 When configuration occurs](#422-when-configuration-occurs)
    - [4.2.3 Ability to change post install](#423-ability-to-change-post-install)

## 1 CAN New Features Overview

Bifurcation or splitting of the Customer Access Network (CAN) enables customization of customer traffic to and from the system.
Customization will be performed during installation.
For CSM 1.2 there are two new CAN networks being introduced as part of the process to split the existing monolithic CAN:

1. **High Speed CAN - CHN** : This feature adds the ability to connect to Application Nodes (UAN), UAI, Compute Nodes
and Kubernetes API endpoints from the customer site via the High Speed Network (HSN).
2. **Management CAN - CMN** :  Using a new VLAN on the Management Network, this feature allows system administrative access from the customer site.
Administrative access was previously available on the original CAN and this feature provides a traffic path and access split.

Enabling BICAN will remove the original CAN.

**During installation the opportunity to enable the new features will be presented.**

At this time, the customers must accept:

- External management to admin endpoints moves to the Customer Management Network (CMN).
- External user access to user endpoints moves to the Customer High-speed Network (CHN).
- The CHN is now the default ingress network.
- Customer access over the legacy CAN is disabled by default.

### Reverting or changing any decisions will be manual

The feature matrix of the CAN is described [here](bican_support_matrix.md).
Details of the High Speed CAN (CHN) and the Management CAN (CMN) are described below.

![Customer Access Overview](img/customer_access_overview.png)

## 2 High Speed CAN (CHN)

Access to system resources from the customer site over the High Speed Network is provided by the High Speed CAN (CHN).
As can be seen in the diagram above, traffic ingress from the site for the CHN is over the Edge Routers
(typically a pair of Arista Switches which provide other HSN access - for ClusterStor for instance).

NOTE:  Arista routing configurations as a virtual routing instance are in-scope for CSM 1.2 CHN work.
Other Edge Routers, including Juniper are out of scope.

### 2.1 CHN system ingress endpoints accessible in CSM 1.2

- Designated Application Nodes, particularly **UAN, over SSH**.
- Designated **Compute Nodes (CN)**, including those used for Compute as UAN, **over SSH**.
- Kubernetes **API endpoints over https**.

### 2.2 CHN system egress endpoints accessible in CSM 1.2

- System access to **site external resources** , including LDAP(s) and DNS.

### 2.3 Endpoint Naming

A ".CHN" DNS suffix will be used for all endpoints accessed over the High Speed CAN.
Endpoints naming will be resolved and maintained in the system Authoritative DNS (another CSM 1.2 feature).
As part of the introduction of authoritative DNS endpoints will also have a top-level-domain appended, creating a fully qualified domain system.

Examples:

- `uan01.chn.tld` as resolved externally.
- `uan01.chn` can be resolved internal to the system (maintained via local `resolv.conf`).
- `nid000001.chn.tld`
- `api-gateway-service.chn.tld`

Where `tld` is configurable at installation and can be a subdomain of the site domain system.
Exchange of system DNS with the site may be via delegation (preferred) or zone transfer (AXFR).

Once added to CSI, names and IP's will use the standard CSM data flow and end up in SLS and be available for use via both DNS and DHCP services.

#### 2.3.1 Touchpoints: effects and changes

- Will require installation and administration document changes.
- The CHN requires a small change in CSI to add this network.
- Will (automatically) use the DNS infrastructure from previous CSM install.
- Name aliases can be added/changed/removed via the API to SLS and become available in DNS automatically.
DNS tooling for this was released in Shasta v1.4 with [SLS](../../index.md#system-layout-service-sls)

#### 2.3.2 When naming occurs

- Installation as part of Cray Site Initialization (CSI) data.
- During site customizations.

#### 2.3.3 Ability to change post-install

- YES - Add/Remove/Change Aliases
- NO - Changing FQDN and domain suffixes because of the number of touchpoints.
Chiefly Kubernetes limitations introduced at install time and sheer number of touchpoints.

### 2.4 Endpoint Addressing

For the CSM 1.2 release CHN endpoints will have **IPv4 addressing only** , with IPv6 introduction in a future release.
The current limitation to system introduction of IPv6 is Kubernetes Weave as well as a vast amount of system configuration
and testing required to certify IPv6 system-wide.

The CHN will, by default, have a private IPv4 address block.
This is intended to be changed during installation to a **customer-supplied IPv4 address block**.

#### 2.4.1 Touchpoints: effects and changes

- Installer and documentation changes to support new network and path as part of configuration.
- CSI for network generation and initial configuration.
- NCN images to support additional **subnets and routing.**
- CFS images for CN and UAN **addressing and routing.**
- UAI to support changes to **addressing and routing.**
- MetalLB to create new API endpoints and peer with Edge Router.
- Arista switch pair to create new or add to existing virtual routing instance for path and access control.
- HSN required for transport of application traffic so new procedures need to be developed for troubleshooting and support.

#### 2.4.2 When addressing occurs

- Installation as part of CSI data.

#### 2.4.3 Ability to change post-install

- NO - There are dozens of touchpoints throughout the system.

### 2.5 Traffic Separation and Routing

In CSM 1.2, there will be Layer 3 separation internal to the system but co-mingled Layer 2 between the CHN IPv4 addressing and the internal HSN private IPv4 addresses.
Isolation will be within the Slingshot network as well as separated at the Edge Router.

#### 2.5.1 Touchpoints: effects and changes

- Edge Router provides all **routing and access controls** in CSM 1.2 (via a virtual routing instance if Arista switch pair is used).
As noted above, non-Arista router configurations are out of scope for CSM 1.2 work.
- Internal to the system CHN traffic will exist in the same Layer 2 domain with internal HSN traffic until the Slingshot network supports VLAN separation.
- Compute (CN) and Application Node (UAN in this case) configuration or IPv4 addressing and routing will be via CFS.
  - When multiple HSN interfaces exists the CHN can be configured to load balance TCP/UDP traffic &quot;flows&quot; across interfaces via ECMP Layer 3 routing in Linux.
- UAI addressing and routing over the HSN interfaces for the NCN workers is required.
- API endpoints in MetalLB for the CHN will be accessible over NCN worker HSN interfaces (via ECMP Layer 3 routing).
  - MetalLB will peer with the Edge Routers to supply load balanced API access.

#### 2.5.2 When configuration occurs

- Installation as part of a virtual routing instance on the Edge Routers.

#### 2.5.3 Ability to change post install

- NOT RECOMMENDED - Edge Router controls external access so change scope is limited.
- NO - Node images could be changed but routing and IP changes to CFS images would need extensive testing to certify.

## 3 Management CAN(CMN)

The original CAN released in Shasta 1.1 contained the ability to access NCN workers, masters and storage directly via SSH for administrative purposes.
This administrative traffic was co-mingled with general user traffic for jobs.
Based on customer requests a new mechanism for administrative access to workers, masters and storage nodes will be added in CSM 1.2.
The new Customer Management Network (CMN) will be created as **a separate-and-distinct VLAN and Subnet on the Management Network** and uplink at the edge to the Customer network.
This new CMN network will allow SSH into the NCNs and CAN access will be disallowed.
NOTE this is generally for ingress access for administrative purposes.

### 3.1 Traffic Separation and Routing

Enabling the CMN at installation time will have the following effects:

- Adding uplinks to the Customer Site similar to the original CAN.
- Creating of a new VLAN on the Management Network.
- Adding a new subnet and routing to the Management Network and NCNs.

### 3.2 Endpoint Naming

If enabled during installation a ".CMN" suffix will be generated by CSI and used in SLS and Authoritative DNS.
The "plumbing" of this will occur as previously described in the CHN.

Examples:

- SSH `ncn-w001.cmn.tld`

### 3.3 Endpoint Addressing

For the CSM 1.2 release the CMN will only be available via customer-supplied IPv4 addressing.

### 3.4 Changes

#### 3.4.1 Touchpoints: effects and changes

- CMN required beginning with this release.
  - Customer will supply a subnet similar to the way the CAN is deployed.
  Sizing is Number of NCNs plus a couple more addresses (TBD).
- Edge access to the CMN will need to be configured with the customer site.
  - ACL development.
- The Management network will require the following changes:
  - Addition of the new CMN VLAN.  This should be similar to the existing CAN configuration.
  - Termination of the new CMN VLAN on ports supporting NCNs.
  - Addition of Customer-supplied CMN IP&#39;s to the management switches to support routing.
- NCN workers, masters and storage will require the following changes:
  - Image support for CMN VLAN, addressing and routing.
- CSI changes to support the new network and naming.

#### 3.4.2 When configuration occurs

- During installation as part of CSI data generation.
- During installation as part of Management Network configuration.
- During installation as part of NCN deployment.

#### 3.4.3 Ability to change post install

- NOT RECOMMENDED and would be manual.

## 4 CAN External/Site Access (site DNS, LDAP, etc...)

System access to site or external resources, like the Internet, site DNS and site LDAP were previously provided over the CAN.
By default this CAN access path will remain, but for the CSM 1.2 release it will be possible during installation to select system-to-site access over the CHN or CMN.

### 4.1 Traffic Separation and Routing

At installation time one of the following egress routes from the system to the site may be selected: CAN (default), CHN, CMN.

### 4.2 Changes

#### 4.2.1 Touchpoints: effects and changes

- Installer customizations changes:
  - Management Network changes possibly for routing, but new ACLs may be necessary.
  - NCNs will require specific site routes to prioritize selected path over the system default (CAN).
- Dependent on CHN and CMN work.

#### 4.2.2 When configuration occurs

- During installation as part of site configuration.

#### 4.2.3 Ability to change post install

- NO
