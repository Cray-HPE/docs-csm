# Management network functions in detail

* Edge: Any interactions with the customer network or Internet
  * Customer jobs ([Customer Access Network (CAN)](../../../../glossary.md#customer-access-network-can))
  * User-facing cloud APIs
    * [User Access Instances (UAIs)](../../../../glossary.md#user-access-instance-uai)
  * Customer administration (Customer Management Network (CMN))
    * Administrative access to the system by customer administrators
    * Access from the system to external services:
      * Customer/Internet DNS
      * LDAP authentication
      * System installation and upgrade media (e.g. Nexus)
  * System: Access by the machine to external (customer and/or Internet) resources (e.g. Internal DNS lookups may resolve to an external DNS).
* Internal: Node-to-node communication inside the system
  * Administrative
    * Hardware ([Hardware Management Network (HMN)](../../../../glossary.md#hardware-management-network-hmn))
      * Direct [BMC](../../../../glossary.md#baseboard-management-controller-bmc)/iLOM access
      * Hardware discovery
      * Firmware updates
  * Cloud control plane ([Node Management Network (NMN)](../../../../glossary.md#node-management-network-nmn))
  * Job control plane (NMN)
* Services
  * Traditional network services (e.g. TFTP, DHCP, DNS)
  * Cloud API and control
  * Cloud-based system services
  * Jobs
  * Traditional [User Access Node (UAN)](../../../../glossary.md#user-access-node-uan)
  * New UAI
* Storage
  * Ceph (IP-based storage)
