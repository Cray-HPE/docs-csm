
# System Management Network Functions

The following is a description of the system management network functions:

* **Edge** - Any interactions with the Customer network or Internet
	* Customer Jobs - Customer Access Network (CAN)
	* User-facing cloud APIs
		* User Access Instances (UAIs)
	* Customer Administration - Customer Management Network (CMN)
		* Administrative Access to the system by Customer Admins
		* Access from the system to external services:
			* Customer/Internet DNS
			* LDAP authentication
			* System installation and upgrade media (e.g. Nexus)
	* System - Access by the machine to external (Customer and/or Internet) resources. E.g. Internal DNS lookups may resolve to an external DNS
	
* **Internal** - Node-to-node communication inside the system
	* Administrative
		* Hardware - Hardware Management Network (HMN)
			* Direct BMC/iLOM access
			* Hardware Discovery
			* Firmware Updates
	* Cloud Control Plane - Node Management Network (NMN)
		* Job Control Plane - Node Management Network (NMN)
* **Services**
	* Traditional network services (e.g. TFTP, DHCP, DNS)
	* Cloud API and control
	* Cloud-based System Services
	* Jobs
	* Traditional UAN
	* New UAI
* **Storage**
	* Ceph (IP-based storage)


[Back to Index](index_aruba.md)