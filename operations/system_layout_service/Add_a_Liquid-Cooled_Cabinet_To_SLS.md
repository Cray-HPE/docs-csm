# Add a Liquid-Cooled Cabinet to SLS

TODO This will add the new cabinet to the hardware part of SLS....

## Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   TODO Need information about what Liquid Cooled cabinets are being added to the system
-   TODO Need information about what CDU Switches (if any are being added to the system)

## Procedure

1.  Perform a SLS dumpstate operation:
    ```bash
    ncn-m001# cray sls dumpstate list --format json > sls_dump.json
    ncn-m001# cp sls_dump.json sls_dump.original.json
    ```

2.  **For each** new liquid-cooled cabinet being added to the system collect the following information about each cabinet:
    > TODO Make this a table
    * Cabinet Xname (eg x1004)
    * HMN VLAN ID configured on the CEC (eg 3004)
    * NMN VLAN ID configured on the CEC (eg 2004)
    * Starting compute node NID (eg 2025)
    * Cabinet Type (Mountain (8 Chassis) or Hill (2 Chassis))

    > The inspect_nid_allocations.py script can be used to help determine the existing NID allocations in use by the system:
    > ```bash
    > ncn-m001# ./inspect_nid_alloacations.py sls_dump.json    
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

3.  **For each** new liquid-cooled add it to the SLS state dump taken in step 1:
    ```bash
    ncn-m001# ./add_liquid_cooled_cabinet.py sls_dump.json \
        --cabinet x1004  \
        --cabinet-type Mountain \
        --cabinet-vlan-hmn 3004 \
        --cabinet-vlan-nmn 3005 \
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
    Cabinet VLAN NMN:  3005

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
      CIDR:        10.104.16.0/22
      Gateway:     10.104.16.1
      DHCP Start:  10.104.16.10
      DHCP End:    10.104.19.254
    NMN_MTN Subnet
      CIDR:        10.100.16.0/22
      Gateway:     10.100.16.1
      DHCP Start:  10.100.16.10
      DHCP End:    10.100.19.254

    Writing updated SLS state to sls_dump.json
    ```

    Possible Errors:
    -   **Error**: Duplicate Cabinet:
        ```
        Error x1000 already exists in sls_dump.json!
        ```

        **Resolution**: TODO

    -   **Error**: Duplicate NID values:
        ```
        Error found duplicate NID 3000
        ``` 

        **Resolution**: Need to choose a different starting NID value for the cabinet.

    -   **Error**: Duplicate Cabinet HMN VLAN ID:
        ```
        Error found duplicate VLAN 3022 with subnet cabinet_1001 in HMN_MTN
        ```

        **Resolution**: Ensure that the this new cabinet gets an unique HMN VLAN ID. 
    
    -   **Error**: Duplicate Cabinet NMN VLAN ID:
        ```
        Error found duplicate VLAN 3023 with subnet cabinet_1001 in NMN_MTN
        ```

        **Resolution**: Ensure that the this new cabinet gets an unique NMN VLAN ID. 

4.  Inspect cabinet subnet and VLAN allocations in the system after adding the new cabinets cabinets:
    ```bash
    ncn-m001# ./inspect_sls_cabinets.py sls_dump.json 
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
    x1004 (Mountain)    | 3004      | 10.104.16.0/22      | 3005      | 10.100.16.0/22
    x3000 (River)       | 1513      | 10.107.0.0/22       | 1770      | 10.106.0.0/22
    ```

5.  **For each** new CDU Switch being added to the system collect the following information about each switch:
    - CDU Switch xname (eg d1w1)
    - CDU Switch brand (eg Dell or Aruba)
    - CDU Switch Alias (eg sw-cdu-004 )


6.  **For each** new CDU Switch add it to the SLS state dump taken in step 1:
    > TODO Add each switch in ascending alias order
    ```bash
    ncn-m001# ./add_cdu_switch.py sls_dump.json \
        --cdu-switch d1w1 \
        --alias sw-spine-cdu-003 \
        --brand Dell
    ```


7.  Perform a SLS load state operation to replace the contents of SLS with the data from the `sls_dump.json` file.
    
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

8.  MEDS will automatically start looking for potential hardware in the newly added liquid-cooled cabinets. 

    **Note**: No hardware in these new cabinets until the management network has been reconfigured to add the new cabinets, and routes has been added to teh management NCNs in the system.
    <!-- TODO Need to add links to these 2 procedures --/>