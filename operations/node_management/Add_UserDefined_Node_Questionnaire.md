# Add User-Defined Node - Information Questionnaire

Please complete this questionnaire before adding a new user-defined node to the system.

## Node Hardware Information

1. **Node Component Name (xname)**: _________________________
   - Format: `xXcCsSbBnN` (e.g., `x3000c0s25b0n0`)
   - Where:
     - `xX`: Cabinet/rack identification number
     - `cC`: Chassis identification number (0 for air-cooled cabinet, 4 for air-cooled chassis in EX2500)
     - `sS`: Lowest slot the node chassis occupies
     - `bB`: Ordinal of the node BMC (typically 0)
     - `nN`: Ordinal of the node (typically 0)

2. **Node Alias/Hostname**: _________________________
   - Example: `special-node-01`

3. **HSM Role and SubRole**:
   - Role: _________________________ (default: `Application`)
   - SubRole: _________________________ (default: `UserDefined`)
   - Note: Custom roles/subroles must be added to HSM before node creation

4. **Cabinet/Rack Number**: _________________________

5. **Rack U Position**: _________________________

## Network Hardware Information

6. **BMC Component Name (xname)**: _________________________
   - Format: `xXcCsSbB` (derived from node xname above)

7. **BMC MAC Address**: _________________________

8. **Management Switch Information**:
   - Management Switch xname: _________________________
   - Switch Port Number connected to BMC: _________________________
   - Switch Vendor/Type: [ ] Aruba
   - VendorName Format:
     - Aruba: `1/1/XX` (where XX is port number)
   - MgmtSwitchConnector xname: _________________________
     - Format: `xXcCwWjJ` (e.g., `x3000c0w14j36`)

9. **Node Network Interfaces**:
   - Primary NIC MAC Address: _________________________
   - Secondary NIC MAC Address (if applicable): _________________________

## Network Configuration

10. **Which management networks should this node have access to?**
    - [ ] NMN (Node Management Network) - Required
    - [ ] HMN (Hardware Management Network) - Required for BMC
    - [ ] CMN (Customer Management Network) - Optional (no DHCP, static IP required)

11. **IP Address Allocation**:
    - NMN and HMN will use DHCP automatically
    - **CMN IP (if CMN access required)**: _________________________ (Static IP, no DHCP available)
    - CMN Subnet Mask: _________________________ (e.g., /25)
    - Other static IPs (if required):
      - NMN IP (if not using DHCP): _________________________

## Node Configuration

12. **Operating System**: 
    - [ ] SLES (SUSE Linux Enterprise Server)
    - [ ] RHEL (Red Hat Enterprise Linux)
    - [ ] Other: _________________________
    - OS Version: _________________________

13. **NIC Configuration**:
    - Will NICs be configured in a bond? [ ] Yes  [ ] No
    - If Yes, bond mode: [ ] 802.3ad (LACP)  [ ] Other: _________________________
    - Primary interface name: _________________________ (e.g., eth0, ens1f0)
    - Secondary interface name (if bonding): _________________________ (e.g., eth1, ens1f1)

14. **External Network Interfaces** (beyond management networks):
    - Does the node have additional unused NICs for direct external network connectivity? [ ] Yes  [ ] No
    - If Yes, list interface names: _________________________
    - Note: Configuration of external interfaces is outside the scope of CSM procedures

15. **MTU Settings**:
    - Bond0 MTU: _________________________ (NCN standard: 9000)
    - VLAN interface MTU: _________________________ (NCN standard: 1500)

16. **VLAN Configuration** (if known from site network documentation):
    - NMN VLAN ID: _________________________
    - HMN VLAN ID: _________________________
    - CMN VLAN ID (if applicable): _________________________

## Additional Configuration

17. **CANU CCJ File**:
    - Path to system CCJ (CANU Custom JSON) file: _________________________
    - Note: Required for CANU switch configuration generation

18. **Special Services or Applications** to be run on this node:
    - ________________________________________________________________
    - ________________________________________________________________

19. **Additional network ports or services** required:
    - ________________________________________________________________

20. **Hostname Resolution**:
    - Should this node be added to DNS? [ ] Yes  [ ] No
    - DNS domain: _________________________

21. **Time Synchronization**:
    - NTP servers: _________________________ (default: NCN masters)

## Site-Specific Network Configuration

22. **Custom switch configuration requirements**:
    - Are there any site-specific network configurations needed? [ ] Yes  [ ] No
    - If Yes, describe:
      - ________________________________________________________________
      - ________________________________________________________________

23. **Network security requirements**:
    - ACL requirements: _________________________
    - Firewall rules needed: _________________________

## Additional Notes

Please provide any additional information or special requirements for this node:

___________________________________________________________________________
___________________________________________________________________________
___________________________________________________________________________
___________________________________________________________________________

---

**Completed by**: _________________________ **Date**: _________________________

**Reviewed by**: _________________________ **Date**: _________________________
