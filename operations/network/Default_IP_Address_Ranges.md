# Default IP Address Ranges

The initial installation of the system creates default networks with default settings and with no external exposure. These IP address default ranges ensure that no nodes in the system attempt to use the same
IP address as a Kubernetes service or pod, which would result in undefined behavior that is extremely difficult to reproduce or debug.

The following table shows the default IP address ranges:

|Network|IP Address Range|
|-------|----------------|
|Kubernetes service network|10.16.0.0/12|
|Kubernetes pod network|10.32.0.0/12|
|Install Network \(MTL\)|10.1.0.0/16|
|Node Management Network \(NMN\)|10.252.0.0/17|
|High Speed Network \(HSN\)|10.253.0.0/16|
|Hardware Management Network \(HMN\)|10.254.0.0/17|
|Mountain NMN **(see note below table)**|10.100.0.0/17|
|Mountain HMN **(see note below table)**|10.104.0.0/17|
|River NMN|10.106.0.0/17|
|River HMN|10.107.0.0/17|
|Load Balanced NMN|10.92.100.0/24|
|Load Balanced HMN|10.94.100.0/24|

For the Mountain NMN:

Allocate a `/22` from this range per liquid-cooled cabinet. For example, the following cabinets would be given the following IP addresses in the allocated ranges:

- cabinet 1 = 10.100.0.0/22
- cabinet 2 = 10.100.4.0/22
- cabinet 3 =  10.100.8.0/22
- ...

For the Mountain HMN:

Allocate a `/22` from this range per liquid-cooled cabinet. For example, the following cabinets would be given the following IP addresses in the allocated ranges:

- cabinet 1 = 10.104.0.0/22
- cabinet 2 = 10.104.4.0/22
- cabinet 3 = 10.104.8.0/22
- ...

The values in the table could be modified prior to install if there is a need to ensure that there are no conflicts with customer resources, such as LDAP or license servers. If a customer has more than one
HPE Cray EX system, these values can be safely reused across them all.

Contact customer support for this site if it is required to change the IP address range for Kubernetes services or pods; for example, if the IP addresses within those ranges must be used for something else.
The cluster must be fully reinstalled if either of those ranges are changed.

## Customizable network values

There are several network values and other pieces of system information that must be unique to the customer system.

- IP address values and the network for `ncn-m001` and the BMC on `ncn-m001`.
- The main Customer Management Network \(CMN\) subnet. The two address pools mentioned below need to be part of this subnet.

  For more information on the CMN, see [Customer Accessible Networks](customer_accessible_networks/Customer_Accessible_Networks.md).

  - Subnet for the MetalLB static address pool \(`cmn-static-pool`\), which is used for services that need to be pinned to the same IP address, such as the system DNS service.
  - Subnet for the MetalLB dynamic address pool \(`cmn-dynamic-pool`\), which is used for services such as Prometheus and Nexus that can be reached by DNS.

- HPE Cray EX Domain: The value of the subdomain that is used to access externally exposed services.

  For example, if the system is named `TestSystem`, and the site is `example.com`, the HPE Cray EX domain would be `testsystem.example.com`. Central DNS would need to be configured to delegate requests for
  addresses in this domain to the HPE Cray EX DNS IP address for resolution.

- HPE Cray EX DNS IP: The IP address used for the HPE Cray EX DNS service. Central DNS delegates the resolution for addresses in the HPE Cray EX Domain to this server. The IP address must be in the `cmn-static-pool` subnet.
- CMN gateway IP address: The IP address assigned to a specific port on the spine switch, which will act as the gateway between the CMN and the rest of the customer's internal networks. This address would be the
  last-hop route to the CMN network. This will default to the first IP address in the main CMN subnet if it is not specified otherwise.

- The User Network subnet which will be either the Customer Access Network \(CAN\) or Customer High-speed Network \(CHN\). The address pool mentioned below needs to be part of this subnet.

  For more information on the CAN and CHN, see [Customer Accessible Networks](customer_accessible_networks/Customer_Accessible_Networks.md).

  - Subnet for the MetalLB dynamic address pool \(`can-dynamic-pool`\) or \(`chn-dynamic-pool`\), which is used for services such as User Access Instances \(UAIs\) that can be reached by DNS.
