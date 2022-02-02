

## Liquid Cooled Node Power Management

Liquid Cooled AMD EPYC compute blade node card power capabilities and capping.

Liquid Cooled cabinet node card power features are supported by the node controller \(nC\) firmware and CPU vendor. The nC exposes the power control API for each node via the node's Redfish ChassisPower schema. Out-of-band power management data is produced and collected by the nC hardware and firmware. This data can be published to a collector using the Redfish EventService, or retrieved on-demand from the Redfish ChassisSensors resource.

The Cray Advanced Platform Management and Control \(CAPMC\) API facilitates power control and enables power-aware WLMs such as Slurm to perform power management and power capping tasks.

**Always use the Boot Orchestration Service \(BOS\) to power off or power on compute nodes.**

### Redfish API

The Redfish API for Liquid Cooled compute blades is the node's Chassis Power resource which is presented by the nC. OEM properties are used to augment the Power schema and allow for feature parity with previous Cray system power management capabilities. A PowerControl resource presents the various power management capabilities for the node.

Each node has three or more power control resources:

- Node power control
- CPU power control
- Memory power control
- Accelerator power control \(one resource per accelerator connected to the node\)

The PowerControl resources will only manifest in the nC's Redfish endpoint after a node has been powered on and background processes have discovered the node's power management capabilities.

### Power Capping

CAPMC power capping controls for compute nodes can query component capabilities and manipulate the node power constraints. This functionality enables external software to establish an upper bound, or estimate a minimum bound, on the amount of power a system or a select subset of the system may consume.

CAPMC API calls provide means for third party software to implement advanced power management strategies and JSON functionality can send and receive customized JSON data structures.

The AMD EPYC node card supports these power capping and monitoring API calls:

- get\_power\_cap\_capabilities
- get\_power\_cap
- set\_power\_cap
- get\_node\_energy
- get\_node\_energy\_stats
- get\_node\_energy\_counter
- get\_system\_power
- get\_system\_power\_details

### Cray CLI Examples for Liquid Cooled Compute Node Power Management

-   **Get Node Energy**

    ```bash
    ncn-m001# cray capmc get_node_energy create --nids NID_LIST \
    --start-time '2020-03-04 12:00:00' --end-time '2020-03-04 12:10:00' --format json
    ```

-   **Get Node Energy Stats**

    ```bash
    ncn-m001# cray capmc get_node_energy_stats create --nids NID_LIST \
    --start-time '2020-03-04 12:00:00' --end-time '2020-03-04 12:10:00' --format json
    ```


-   **Get Node Energy Counter**

    ```bash
    ncn-m001# cray capmc get_node_energy_counter create --nids NID_LIST \
    --time '2020-03-04 12:00:00' --format json
    ```

-   **Get Node Power Control and Limit Settings**

    ```bash
    ncn-m001# cray capmc get_power_cap create –-nids NID_LIST \
    --format json
    ```

-   **Get System Power**

    ```bash
    ncn-m001# cray capmc get_system_power create \
    --start-time '2020-03-04 12:00:00' --window-len 30 --format json
    ```

    ```bash
    ncn-m001# cray capmc get_system_power_details create \
    --start-time '2020-03-04 12:00:00' --window-len 30 --format json
    ```

-   **Get Power Capping Capabilities**

    ```bash
    ncn-m001#  cray capmc get_power_cap_capabilities create –-nids NID_LIST \
    --format json
    ```

-   **Set Node Power Limit**

    ```bash
    ncn-m001#  cray capmc set_power_cap create –-nids NID_LIST \
    --node 225 --format json
    ```


-   **Remove Node Power Limit \(Set to Default\)**

    ```bash
    ncn-m001#  cray capmc set_power_cap create –-nids NID_LIST \
    --node 0 --format json
    ```

