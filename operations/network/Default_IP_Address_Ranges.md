# Default IP Address Ranges

The initial installation of the system creates default networks with default settings and with no external exposure. These IP address default ranges ensure that no nodes in the system attempt to use the same
IP address as a Kubernetes service or pod, which would result in undefined behavior that is extremely difficult to reproduce or debug.

- [Default ranges](#default-ranges)
    - [Kubernetes ranges](#kubernetes-ranges)
    - [Mountain NMN range](#mountain-nmn-range)
    - [Mountain HMN range](#mountain-hmn-range)
- [Customizable network values](#customizable-network-values)

## Default ranges

The following table shows the default IP address ranges:

| *Network*                                          | *Address range*  |
|----------------------------------------------------|------------------|
| Kubernetes service network [*](#kubernetes-ranges) | `10.16.0.0/12`   |
| Kubernetes pod network [*](#kubernetes-ranges)     | `10.32.0.0/12`   |
| Install network (MTL)                              | `10.1.0.0/16`    |
| Node Management Network (NMN)                      | `10.252.0.0/17`  |
| High Speed Network (HSN)                           | `10.253.0.0/16`  |
| Hardware Management Network (HMN)                  | `10.254.0.0/17`  |
| Mountain NMN [**](#mountain-nmn-range)             | `10.100.0.0/17`  |
| Mountain HMN [***](#mountain-hmn-range)            | `10.104.0.0/17`  |
| River NMN                                          | `10.106.0.0/17`  |
| River HMN                                          | `10.107.0.0/17`  |
| Load balanced NMN                                  | `10.92.100.0/24` |
| Load balanced HMN                                  | `10.94.100.0/24` |

The values in the table could be modified prior to install if there is a need to
ensure that there are no conflicts with site resources, such as LDAP or license
servers. If a site has more than one HPE Cray EX system, these values can be safely
reused across them all.

### Kubernetes ranges

Contact customer support for this site if it is required to change the IP address
range for Kubernetes services or pods; for example, if the IP addresses within those
ranges must be used for something else. The cluster must be fully reinstalled if
either of those ranges are changed.

### Mountain NMN range

Allocate a `/22` IP subnet from this range for each liquid-cooled cabinet.
For example, the following cabinets would be given the following IP addresses in the
allocated ranges:

- cabinet 1 = `10.100.0.0/22`
- cabinet 2 = `10.100.4.0/22`
- cabinet 3 = `10.100.8.0/22`
- ...

### Mountain HMN range

Allocate a `/22` IP subnet from this range for each liquid-cooled cabinet.
For example, the following cabinets would be given the following IP addresses in the
allocated ranges:

- cabinet 1 = `10.104.0.0/22`
- cabinet 2 = `10.104.4.0/22`
- cabinet 3 = `10.104.8.0/22`
- ...

## Customizable network values

There are several network values and other pieces of system information that must be
unique to the system.

- The IP address values and the network, for `ncn-m001` and the BMC on `ncn-m001`.
- The main Customer Management Network (CMN) subnet.
    - The following two address pools must be part of this subnet:
        - Subnet for the MetalLB static address pool (`cmn-static-pool`), which is
          used for services that need to be pinned to the same IP address, such as
          the system DNS service.
        - Subnet for the MetalLB dynamic address pool (`cmn-dynamic-pool`), which is
          used for services such as Prometheus and Nexus that can be reached by DNS.
    - For more information on the CMN, see [Customer Accessible Networks](customer_accessible_networks/Customer_Accessible_Networks.md).
- The value of the HPE Cray EX Domain, which is the subdomain that is used to access externally exposed services.
    - For example, if the system is named `TestSystem`, and the site is `example.com`,
      the HPE Cray EX domain would be `testsystem.example.com`. Central DNS must be
      configured to delegate requests for addresses in this domain to the HPE Cray EX
      DNS IP address for resolution.
- The HPE Cray EX DNS IP address, which is the IP address used for the HPE Cray EX
  DNS service.
    - Central DNS delegates the resolution for addresses in the HPE Cray EX Domain to
      this server. The IP address must be in the `cmn-static-pool` subnet.
- The CMN gateway IP address, which is the IP address assigned to a specific port on
  the spine switch, which will act as the gateway between the CMN and the rest of the
  site's internal networks.
    - This address would be the last-hop route to the CMN network.
    - This will default to the first IP address in the main CMN subnet, if it is not
      specified otherwise.
- The User Network subnet, which will be either the Customer Access Network (CAN) or
  the Customer High-speed Network (CHN).
    - The following address pool must be part of this subnet:
        - Subnet for the MetalLB dynamic address pool (`can-dynamic-pool`) or
          (`chn-dynamic-pool`) that can be reached by DNS.
    - For more information on the CAN and CHN, see [Customer Accessible Networks](customer_accessible_networks/Customer_Accessible_Networks.md).
