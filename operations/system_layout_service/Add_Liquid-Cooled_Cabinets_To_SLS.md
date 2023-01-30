# Add Liquid-Cooled Cabinets to SLS

This procedure adds one or more liquid-cooled cabinets and associated CDU management switches to SLS.

**`NOTES`**

- This procedure is intended to be used in conjunction with the top level [Add additional Liquid-Cooled Cabinets to a System](../node_management/Add_additional_Liquid-Cooled_Cabinets_to_a_System.md) procedure.
- This procedure will only add the liquid-cooled hardware present in an EX2500 cabinet with a single liquid-cooled chassis and a single air-cooled chassis.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation is installed on the system. See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).
- Collect information for the liquid-cooled cabinets being added to the system. For each cabinet collect:
  - Cabinet component name (xname) (for example `x1004`)
  - Hardware Management Network (HMN) VLAN ID configured on the CEC (for example `3004`)
  - Node Management Network (NMN) VLAN ID configured on the CEC (for example `2004`)
  - Starting compute node ID (NID) (for example `2025`)
  - Cabinet type: Mountain (8 chassis) or Hill (2 chassis)

- Collect information for the CDU switches (if any) being added to the system. For each CDU management switch, collect:
  - CDU switch component name (xname) (for example `d1w1`)
  - CDU switch brand (for example Dell or Aruba)
  - CDU switch alias (for example `sw-cdu-004`)

## Procedure

1. (`ncn-m#`) Perform an SLS dump state operation:

    ```bash
    cray sls dumpstate list --format json > sls_dump.json
    cp -v sls_dump.json sls_dump.original.json
    ```

1. **For each** new liquid-cooled cabinet being added to the system, collect the following information about each cabinet:

    - Cabinet component name (xname) (for example `x1004`)
    - Hardware Management Network (HMN) VLAN ID configured on the CEC (for example `3004`)
    - Node Management Network (NMN) VLAN ID configured on the CEC (for example `2004`)
    - Starting compute node ID (NID) (for example `2025`)
    - Cabinet type: Mountain (8 chassis) or Hill (2 chassis)

    > The `inspect_sls_cabinets.py` script can be used to help display information about existing cabinets present in the system:
    >
    > ```bash
    > /usr/share/doc/csm/scripts/operations/system_layout_service/inspect_sls_cabinets.py sls_dump.json
    > ```
    >
    > Example output on a system with 1 air-cooled cabinet and 4 liquid-cooled cabinets:
    >
    > ```text
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

1. **For each** new liquid-cooled cabinet, add it to the previously taken SLS state dump in **ascending order**:

    Command line flags for `add_liquid_cooled_cabinet.py`:
    | Argument                        | Description                                                       | Example value                   |
    | ------------------------------- | ----------------------------------------------------------------- | ------------------------------- |
    | `--cabinet`                     | Component name (xname) of the liquid-cooled cabinet to add        | `x1000`                         |
    | `--cabinet-type`                | Type of liquid-cooled cabinet to add                              | `Mountain`, `Hill`, or `EX2500` |
    | `--cabinet-vlan-hmn`            | Hardware Management Network (HMN) VLAN ID configured on the CEC   | `3004`                          |
    | `--cabinet-vlan-nmn`            | Node Management Network (NMN) VLAN ID configured on the CEC       | `2004`                          |
    | `--starting-nid`                | Starting NID for new cabinet. Each cabinet is allocated 256 NIDs  | `2024`                          |
    | `--liquid-cooled-chassis-count` | Number of liquid-cooled chassis present in EX2500 cabinet. The value range is 1 to 3. This option is unused for `Mountain` or `Hill` | `3` |

    - (`ncn-m#`) For `Mountain` or `Hill` cabinets:

        ```bash
        /usr/share/doc/csm/scripts/operations/system_layout_service/add_liquid_cooled_cabinet.py sls_dump.json \
            --cabinet x1004  \
            --cabinet-type Mountain \
            --cabinet-vlan-hmn 3004 \
            --cabinet-vlan-nmn 2004 \
            --starting-nid 2024
        ```

    - (`ncn-m#`) For `EX2500` cabinets:

        ```bash
        /usr/share/doc/csm/scripts/operations/system_layout_service/add_liquid_cooled_cabinet.py sls_dump.json \
            --cabinet x8000  \
            --cabinet-type EX2500 \
            --cabinet-vlan-hmn 3004 \
            --cabinet-vlan-nmn 2004 \
            --liquid-cooled-chassis-count 3 \
            --starting-nid 2024
        ```

    Example output:

    ```text
    ========================
    Configuration
    ========================
    SLS State File:    sls_dump.json
    Starting NID:      2024
    Cabinet:           x1004
    Cabinet Type:      Mountain
    Cabinet VLAN HMN:  3004
    Cabinet VLAN NMN:  2004
    Chassis List:      [c0,c1,c2,c3,c4,c5,c6,c7]

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
      10.100.4.0/22 Available for use.

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

   > **`NOTE`**: If adding more than one cabinet and contiguous NIDs are desired, the value of the `Next available NID 2280` can be used as the value for the `--start-nid` argument when adding the next cabinet.

    Possible Errors:
    | Problem                        | Error Message                                                         | Resolution |
    | ------------------------------ | --------------------------------------------------------------------- | ---------- |
    | Duplicate Cabinet Xname        | `Error x1000 already exists in sls_dump.json!`                        | The cabinet has already present in SLS. Ensure the new cabinet has a unique component name (xname), or the cabinet is already present in SLS. |
    | Duplicate NID values           | `Error found duplicate NID 3000`                                      | Need to choose a different starting NID value for the cabinet that does not overlap with existing nodes. |
    | Duplicate Cabinet HMN VLAN ID: | `Error found duplicate VLAN 3022 with subnet cabinet_1001 in HMN_MTN` | Ensure that the this new cabinet has an unique HMN VLAN ID. |
    | Duplicate Cabinet NMN VLAN ID  | `Error found duplicate VLAN 3023 with subnet cabinet_1001 in NMN_MTN` | Ensure that the this new cabinet has an unique NMN VLAN ID. |

1. (`ncn-m#`) Inspect cabinet subnet and VLAN allocations in the system after adding the new cabinets.

    ```bash
    /usr/share/doc/csm/scripts/operations/system_layout_service/inspect_sls_cabinets.py sls_dump.json
    ```

    Example output:

    ```text
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

1. **For each** new CDU switch being added to the system, collect the following information about it:

    - CDU switch component name (xname)
      - If within a CDU: `dDwW`
            - `dD` : where `D` is the Coolant Distribution Unit (CDU).
            - `wW` : where `W` is the management switch in a CDU.
      - If within a standard rack: `xXcChHsS`
        - `xX` : where `X` is the River cabinet identification number (the figure above is `3000`).
        - `cC` : where `C` is the chassis identification number.
          - If the switch is within an air-cooled cabinet, then this should be `0`.
          - If the switch is within an air-cooled chassis in an EX2500 cabinet, then this should be `4`.
        - `hH` : where `H` is the slot number in the cabinet (height).
        - `sS` : where `S` is the horizontal space number.
    - CDU switch brand (for example Dell or Aruba)
    - CDU switch alias (for example `sw-cdu-004` )

1. (`ncn-m#`) **For each** new CDU switch, add it to the SLS state dump taken in step 1 in **ascending order** based on the switch alias:

    ```bash
    /usr/share/doc/csm/scripts/operations/system_layout_service/add_cdu_switch.py sls_dump.json \
        --cdu-switch d1w1 \
        --alias sw-cdu-003 \
        --brand Dell
    ```

    Example output:

    ```text
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
      Found existing IP reservation sw-leaf-bmc-001 with IP 10.254.0.4
      Found existing IP reservation sw-leaf-bmc-002 with IP 10.254.0.5
      Found existing IP reservation sw-cdu-001 with IP 10.254.0.6
      Found existing IP reservation sw-cdu-002 with IP 10.254.0.7
      10.254.0.8 Available for use.
    Selecting IP Reservation for d1w1 CDU Switch in NMN's network_hardware subnet
      Found existing IP reservation sw-spine-001 with IP 10.252.0.2
      Found existing IP reservation sw-spine-002 with IP 10.252.0.3
      Found existing IP reservation sw-leaf-bmc-001 with IP 10.252.0.4
      Found existing IP reservation sw-leaf-bmc-002 with IP 10.252.0.5
      Found existing IP reservation sw-cdu-001 with IP 10.252.0.6
      Found existing IP reservation sw-cdu-002 with IP 10.252.0.7
      10.252.0.8 Available for use.
    Selecting IP Reservation for d1w1 CDU Switch in MTL's network_hardware subnet
      Found existing IP reservation sw-spine-001 with IP 10.1.0.2
      Found existing IP reservation sw-spine-002 with IP 10.1.0.3
      Found existing IP reservation sw-leaf-bmc-001 with IP 10.1.0.4
      Found existing IP reservation sw-leaf-bmc-002 with IP 10.1.0.5
      Found existing IP reservation sw-cdu-001 with IP 10.1.0.6
      Found existing IP reservation sw-cdu-002 with IP 10.1.0.7
      10.1.0.8 Available for use.

    HMN IP: 10.254.0.8
    NMN IP: 10.252.0.8
    MTL IP: 10.1.0.8

    Writing updated SLS state to sls_dump.json
    ```

1. (`ncn-m#`) Inspect the differences between the original SLS state file and the modified one.

    ```bash
    diff sls_dump.original.json sls_dump.json
    ```

1. (`ncn-m#`) Perform a SLS load state operation to replace the contents of SLS with the data from the `sls_dump.json` file.

    ```bash
    cray sls loadstate create sls_dump.json
    ```

1. MEDS will automatically start looking for potential hardware in the newly added liquid-cooled cabinets.

   > **`NOTE`**: No hardware in these new cabinets will be discovered until the management network has been reconfigured to support the new cabinets, and routes have been added to the management NCNs in the system.
