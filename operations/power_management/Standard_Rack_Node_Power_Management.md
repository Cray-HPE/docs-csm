# Standard Rack Node Power Management

HPE Cray EX standard EIA rack node power management is supported by the server
vendor BMC firmware. The BMC exposes the power control API for a node through
the node's Redfish Power schema.

Out-of-band power management data is polled by a collector and published on a
Kafka bus for entry into the Power Management Database (PMDB). Access to the
data stored in the PMDB is available through the System Monitoring Application
(SMA) Grafana instance.

Power limiting of a node must be enabled and may require additional licenses to
use. Refer to vendor documentation for instructions on how to enable power
limiting and what licenses, if any, are needed.

CAPMC only handles power limiting of one hardware type at a time. Each vendor and
server model has their own power limiting capabilities. Therefore a different
power limit request will be needed for each vendor and model that needs to have
its power limited.

## Requirements

* Hardware State Manager (`cray-hms-smd`) >= `v1.30.16`
* CAPMC (`cray-hms-capmc`) >= `1.31.0`
* Cray CLI >= `0.44.0`

## Deprecated Interfaces

See the [CAPMC Deprecation Notice](../../introduction/deprecated_features/CAPMC_Deprecation_Notice.md) for
more information.

* `get_node_energy` (Deprecated)
* `get_node_energy_stats` (Deprecated)
* `get_system_power` (Deprecated)

## Redfish API

The Redfish API for rack-mounted nodes is the node's Power resource which is
presented by the BMC. OEM properties may be used to augment the Power schema to
provide additional power management capabilities.

## Power Limiting

CAPMC power limiting controls for compute nodes can query component capabilities
and manipulate the node power constraints. This functionality enables external
software to establish an upper bound, or estimate a minimum bound, on the amount
of power a system or a select subset of the system may consume.

CAPMC API calls provide means for third party software to implement advanced
power management strategies using JSON data structures.

The rack-mounted compute nodes support these power limiting and monitoring API
calls:

* `get_power_cap_capabilities`
* `get_power_cap`
* `set_power_cap`

In general, rack-mounted compute nodes do not allow for power limiting of any
installed accelerators separately from the node limit.

Power limit control will only be valid on a compute node when power limiting is
enabled, the node is booted, and the node is in the Ready state as seen via the
Hardware State Manager (HSM).

## Cray CLI Examples for Standard Rack Compute Node Power Management

* **Get Node Power Control and Limit Settings**

    ```bash
    cray capmc get_power_cap create –-nids NID_LIST --format json
    ```

    Return the current power limit settings for a node and any accelerators that
    are installed. Valid settings are only returned if power limiting is enabled
    on the target nodes.

    ```bash
    cray capmc get_power_cap create --nids 4
     ```
  
    ```json
    {
        "e": 0,
        "err_msg": "",
        "nids": [
            {
                "nid": 4,
                "controls": [
                    {
                        "name": "Chassis Power Control",
                        "val": 500
                    }
                ]
            }
        ]
    }
    ```

* **Get Power Limiting Capabilities**

    ```bash
    cray capmc get_power_cap_capabilities create –-nids NID_LIST --format json
    ```

    Return the min and max power limit settings for the node list and any
    accelerators that are installed.

    ```bash
    cray capmc get_power_cap_capabilities create --nids 4 --format json
    ```

    ```json
    {
        "e": 0,
        "err_msg": "",
        "groups": [
            {
                "name": "3_AuthenticAMD_64c_244GiB_3200MHz_NoAccel",
                "desc": "3_AuthenticAMD_64c_244GiB_3200MHz_NoAccel",
                "host_limit_max": 0,
                "host_limit_min": 0,
                "static": 0,
                "supply": 900,
                "powerup": 0,
                "nids": [
                    4
                ],
                "controls": [
                    {
                        "name": "Chassis Power Control",
                        "desc": "Chassis Power Control",
                        "max": 900,
                        "min": 61
                    }
                ]
            }
        ]
    }
    ```

* **Set Node Power Limit**

    ```bash
     cray capmc set_power_cap create --nids NID_LIST --control CONTROL_NAME VALUE --format json
    ```

    Set the total power limit of the node by using the name of the node control.
    The power provided to the host CPU and memory is the total node power limit
    minus the power limits of each of the accelerators installed on the node.

    ```bash
    cray capmc set_power_cap create --nids 4 --control "Chassis Power Control" 600
    ```

    ```json
    {
        "e": 0,
        "err_msg": "",
        "nids": [
            {
                "nid": 4,
                "e": 0,
                "err_msg": ""
            }
        ]
    }
    ```

    Multiple controls can be set at the same time on multiple nodes, but all
    target nodes must have the same set of controls available, otherwise the
    call will fail.

    ```bash
    cray capmc set_power_cap create \
    --nids [1-4] --control "Chassis Power Control" 600
    ```
  
    ```json
    {
        "e": 0,
        "err_msg": "",
        "nids": [
            {
                "nid": 1,
                "e": 0,
                "err_msg": ""
            },
            {
                "nid": 2,
                "e": 0,
                "err_msg": ""
            },
            {
                "nid": 3,
                "e": 0,
                "err_msg": ""
            },
            {
                "nid": 4,
                "e": 0,
                "err_msg": ""
            }
        ]
    }
    ```

* **Remove Node Power Limit (Set to Default)**

    ```bash
    cray capmc set_power_cap create --nids NID_LIST --control CONTROL_NAME 0 --format json
    ```

    Reset the power limit to the default maximum. Alternatively, using the max
    value returned from `get_power_cap_capabilities` may also be used. Multiple
    controls can be set at the same time on multiple nodes, but all target nodes
    must have the same set of controls available, otherwise the call will fail.

    ```bash
    cray capmc set_power_cap create --nids 4 --control "Node Power Limit" 0
    ```
  
    ```json
    {
        "e": 0,
        "err_msg": "",
        "nids": [
            {
                "nid": 4,
                "e": 0,
                "err_msg": ""
            }
        ]
    }
    ```

## Enable and Disable Power Limiting

### Gigabyte

* **Enable Power Limiting**

    ```bash
    curl -k -u $login:$pass -H "Content-Type: application/json" \
    -X POST https://${BMC}/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger \
    --data '{"PowerLimitTrigger": "Activate"}'
    ```

* **Deactivate Node Power Limit**

    ```bash
    curl -k -u $login:$pass -H "Content-Type: application/json" \
    -X POST https://${BMC}/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger \
    --data '{"PowerLimitTrigger": "Deactivate"}'
    ```
