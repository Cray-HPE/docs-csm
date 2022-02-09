# Add Liquid-Cooled Cabinets to SLS

This procedure adds one or more liquid-cooled cabinets and associated CDU management switches to SLS.

**NOTE:** This procedure is intended to be used in conjunction with the top level [Add additional Liquid-Cooled Cabinets to a System](../node_management/Add_additional_Liquid-Cooled_Cabinets_to_a_System.md) procedure. 

## Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   Collect information for the liquid-cooled cabinets being added to the system. For each cabinet collect:
    * Cabinet Xname (eg x1004)
    * Hardware Management Network (HMN) VLAN ID configured on the CEC (eg 3004)
    * Node Management Network (NMN) VLAN ID configured on the CEC (eg 2004)
    * Starting compute node NID (eg 2025)
    * Cabinet Type: Mountain (8 Chassis) or Hill (2 Chassis)

-   Collect information for the CDU Switches (if any) being added to the system. For each CDU Management Switch collect:
    - CDU Switch xname (eg d1w1)
    - CDU Switch brand (eg Dell or Aruba)
    - CDU Switch Alias (eg sw-cdu-004)

## Procedure

1.  Perform a SLS dump state operation:
    ```bash
    ncn-m001# cray sls dumpstate list --format json > sls_dump.json
    ncn-m001# cp sls_dump.json sls_dump.original.json
    ```

2.  **For each** new liquid-cooled cabinet being added to the system collect the following information about each cabinet:
    * Cabinet Xname (eg x1004)
    * Hardware Management Network (HMN) VLAN ID configured on the CEC (eg 3004)
    * Node Management Network (NMN) VLAN ID configured on the CEC (eg 2004)
    * Starting compute node NID (eg 2025)
    * Cabinet Type (Mountain (8 Chassis) or Hill (2 Chassis))

    > The inspect_sls_cabinets.py script can be used to help display information about existing cabinets present in the system:
    > ```bash
    > ncn-m001# /usr/share/doc/csm/scripts/operations/system_layout_service/inspect_sls_cabinets.py sls_dump.json    
    > ```
    > Example Output with a system with 1 Air-cooled cabinet and 4 liquid-cooled cabinets:
    > ```
    > =================================
    > Cabinet NID Allocations
    > =================================
    > Cabinet             | NID Ranges
    > --------------------|---------------------
    > x1000 (Mountain)    | 1000-1255 
    > x1001 (Mountain)    | 1256-1511 
    > x1002 (Mountain)    | 1512-1767 
    > x1003 (Mountain)    | 1768-2023 
    > x3000 (River)       | 100001-100011
    > 
    > =================================
    > Cabinet Subnet & VLAN Allocations
    > =================================
    > Cabinet             | HMN VLAN  | HMN CIDR            | NMN VLAN  | NMN CIDR
    > --------------------|-----------|---------------------|-----------|---------------------
    > x1000 (Mountain)    | 3000      | 10.104.0.0/22       | 2000      | 10.100.0.0/22
    > x1001 (Mountain)    | 3001      | 10.104.4.0/22       | 2001      | 10.100.4.0/22
    > x1002 (Mountain)    | 3002      | 10.104.8.0/22       | 2002      | 10.100.8.0/22
    > x1003 (Mountain)    | 3003      | 10.104.12.0/22      | 2003      | 10.100.12.0/22
    > x3000 (River)       | 1513      | 10.107.0.0/22       | 1770      | 10.106.0.0/22
    > ```

3.  **For each** new liquid-cooled cabinet add it to the previously taken SLS state dump in __ascending order__:
    
    Command line flags for `add_liquid_cooled_cabinet.py`:
    | Argument             | Description                                                       | Example value        |
    | -------------------- | ----------------------------------------------------------------- | -------------------- |
    | `--cabinet`          | Xname of the liquid-cooled cabinet to add                         | `x1000`              |
    | `--cabinet-type`     | Type of liquid-cooled cabinet to add                              | `Mountain` or `Hill` |
    | `--cabinet-vlan-hmn` | Hardware Management Network (HMN) VLAN ID configured on the CEC   | `3004`               |
    | `--cabinet-vlan-nmn` | Node Management Network (NMN) VLAN ID configured on the CEC       | `2004`               |
    | `--starting-nid`     | Starting NID for new cabinet. Each cabinet is allocated 256 NIDs. | `2024`               |

    ```bash
    ncn-m001# /usr/share/doc/csm/scripts/operations/system_layout_service/add_liquid_cooled_cabinet.py sls_dump.json \
        --cabinet x1004  \
        --cabinet-type Mountain \
        --cabinet-vlan-hmn 3004 \
        --cabinet-vlan-nmn 2004 \
        --starting-nid 2024
    ```

    Example output:
    ```
    ========================
    Configuration
    ========================
    SLS State File:    sls_dump.json
    Starting NID:      2024
    Cabinet:           x1004
    Cabinet Type:      Mountain
    Cabinet VLAN HMN:  3004
    Cabinet VLAN NMN:  2004

    ========================
    Network Configuration
    ========================
    Selecting subnet for x1004 cabinet in HMN_MTN network
      Found existing subnet cabinet_1000 with CIDR 10.104.0.0/22
      Found existing subnet cabinet_1001 with CIDR 10.104.4.0/22
      Found existing subnet cabinet_1002 with CIDR 10.104.8.0/22
      Found existing subnet cabinet_1003 with CIDR 10.104.12.0/22
      10.104.16.0/22 Available for use.
    Selecting subnet for x1004 cabinet in NMN_MTN network
      Found existing subnet cabinet_1000 with CIDR 10.100.0.0/22
      Found existing subnet cabinet_1001 with CIDR 10.100.4.0/22
      Found existing subnet cabinet_1002 with CIDR 10.100.8.0/22
      Found existing subnet cabinet_1003 with CIDR 10.100.12.0/22
      10.100.16.0/22 Available for use.

    HMN_MTN Subnet
      VlanID:      3004
      CIDR:        10.104.16.0/22
      Gateway:     10.104.16.1
      DHCP Start:  10.104.16.10
      DHCP End:    10.104.19.254
    NMN_MTN Subnet
      VlanID:      2004
      CIDR:        10.100.16.0/22
      Gateway:     10.100.16.1
      DHCP Start:  10.100.16.10
      DHCP End:    10.100.19.254

    Next available NID 2280
    Writing updated SLS state to sls_dump.json
    ```

    **Note** if adding more than one cabinet and contiguous NIDs are desired the value of the `Next available NID 2280` can be used as the value to the `--start-nid` argument when adding the next cabinet.

    Possible Errors:
    | Problem                        | Error Message                                                         | Resolution |
    | ------------------------------ | --------------------------------------------------------------------- | ---------- |
    | Duplicate Cabinet Xname        | `Error x1000 already exists in sls_dump.json!`                        | The cabinet has already present in SLS. Ensure the new cabinet has a unique xname, or the cabinet is already present in SLS. |
    | Duplicate NID values           | `Error found duplicate NID 3000`                                      | Need to choose a different starting NID value for the cabinet that does not overlap with existing nodes. |
    | Duplicate Cabinet HMN VLAN ID: | `Error found duplicate VLAN 3022 with subnet cabinet_1001 in HMN_MTN` | Ensure that the this new cabinet has an unique HMN VLAN ID. |
    | Duplicate Cabinet NMN VLAN ID  | `Error found duplicate VLAN 3023 with subnet cabinet_1001 in NMN_MTN` | Ensure that the this new cabinet has an unique NMN VLAN ID. | 

4.  Inspect cabinet subnet and VLAN allocations in the system after adding the new cabinets cabinets:
    ```bash
    ncn-m001# /usr/share/doc/csm/scripts/operations/system_layout_service/inspect_sls_cabinets.py sls_dump.json 
    ```

    Example output:
    ```
    =================================
    Cabinet NID Allocations
    =================================
    Cabinet             | NID Ranges
    --------------------|---------------------
    x1000 (Mountain)    | 1000-1255 
    x1001 (Mountain)    | 1256-1511 
    x1002 (Mountain)    | 1512-1767 
    x1003 (Mountain)    | 1768-2023 
    x1004 (Mountain)    | 2024-2279 
    x3000 (River)       | 100001-100011

    =================================
    Cabinet Subnet & VLAN Allocations
    =================================
    Cabinet             | HMN VLAN  | HMN CIDR            | NMN VLAN  | NMN CIDR
    --------------------|-----------|---------------------|-----------|---------------------
    x1000 (Mountain)    | 3000      | 10.104.0.0/22       | 2000      | 10.100.0.0/22
    x1001 (Mountain)    | 3001      | 10.104.4.0/22       | 2001      | 10.100.4.0/22
    x1002 (Mountain)    | 3002      | 10.104.8.0/22       | 2002      | 10.100.8.0/22
    x1003 (Mountain)    | 3003      | 10.104.12.0/22      | 2003      | 10.100.12.0/22
    x1004 (Mountain)    | 3004      | 10.104.16.0/22      | 2004      | 10.100.16.0/22
    x3000 (River)       | 1513      | 10.107.0.0/22       | 1770      | 10.106.0.0/22
    ```

5.  **For each** new CDU Switch being added to the system collect the following information about each switch:
    - CDU Switch xname (eg d1w1)
    - CDU Switch brand (eg Dell or Aruba)
    - CDU Switch Alias (eg sw-cdu-004 )


6.  **For each** new CDU Switch add it to the SLS state dump taken in step 1 in __ascending order__ based on the switch alias:
    ```bash
    ncn-m001# /usr/share/doc/csm/scripts/operations/system_layout_service/add_cdu_switch.py sls_dump.json \
        --cdu-switch d1w1 \
        --alias sw-cdu-003 \
        --brand Dell
    ```

    Example output:
    ```
   ========================
    Configuration
    ========================
    SLS State File: sls_dump.json
    CDU Switch:     d1w1
    Brand:          Dell
    Alias:          sw-cdu-003

    ================================
    CDU Switch Network Configuration
    ================================
    Selecting IP Reservation for d1w1 CDU Switch in HMN's network_hardware subnet
      Found existing IP reservation sw-spine-001 with IP 10.254.0.2
      Found existing IP reservation sw-spine-002 with IP 10.254.0.3
      Found existing IP reservation sw-leaf-001 with IP 10.254.0.4
      Found existing IP reservation sw-leaf-002 with IP 10.254.0.5
      Found existing IP reservation sw-cdu-001 with IP 10.254.0.6
      Found existing IP reservation sw-cdu-002 with IP 10.254.0.7
      10.254.0.8 Available for use.
    Selecting IP Reservation for d1w1 CDU Switch in NMN's network_hardware subnet
      Found existing IP reservation sw-spine-001 with IP 10.252.0.2
      Found existing IP reservation sw-spine-002 with IP 10.252.0.3
      Found existing IP reservation sw-leaf-001 with IP 10.252.0.4
      Found existing IP reservation sw-leaf-002 with IP 10.252.0.5
      Found existing IP reservation sw-cdu-001 with IP 10.252.0.6
      Found existing IP reservation sw-cdu-002 with IP 10.252.0.7
      10.252.0.8 Available for use.
    Selecting IP Reservation for d1w1 CDU Switch in MTL's network_hardware subnet
      Found existing IP reservation sw-spine-001 with IP 10.1.0.2
      Found existing IP reservation sw-spine-002 with IP 10.1.0.3
      Found existing IP reservation sw-leaf-001 with IP 10.1.0.4
      Found existing IP reservation sw-leaf-002 with IP 10.1.0.5
      Found existing IP reservation sw-cdu-001 with IP 10.1.0.6
      Found existing IP reservation sw-cdu-002 with IP 10.1.0.7
      10.1.0.8 Available for use.

    HMN IP: 10.254.0.8
    NMN IP: 10.252.0.8
    MTL IP: 10.1.0.8

    Writing updated SLS state to sls_dump.json
    ```

7. Inspect the differences between the original SLS state file and the modified one:
    ```bash
    ncn-m001# diff sls_dump.original.json sls_dump.json
    ```

8.  Perform a SLS load state operation to replace the contents of SLS with the data from the `sls_dump.json` file.
    
    Get an API Token:
    ```bash
    ncn-m001# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                          -d client_id=admin-client \
                          -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

    Perform the load state operation:
    ```bash
    ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -F sls_dump=@sls_input_file.json \
        https://api-gw-service-nmn.local/apis/sls/v1/loadstate
    ```

9.  MEDS will automatically start looking for potential hardware in the newly added liquid-cooled cabinets. 

    **Note**: No hardware in these new cabinets will be discovered until the management network has been reconfigured to support the new cabinets, and routes has been added to the management NCNs in the system.
