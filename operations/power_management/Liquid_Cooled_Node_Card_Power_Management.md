# Liquid-cooled Node Power Management

Liquid-cooled AMD EPYC compute blade node card power capabilities and limits.

Liquid-cooled cabinet node card power features are supported by the node
controller (nC) firmware and CPU vendor. The nC exposes the power control API
for each node via the node's Redfish Control schema. Out-of-band power
management data is produced and collected by the nC hardware and firmware. This
data can be published to a collector using the Redfish `EventService`, or
retrieved on-demand from the Redfish `ChassisSensors` resource.

* [Requirements](#requirements)
* [Deprecated interfaces](#deprecated-interfaces)
* [Redfish API](#redfish-api)
* [Power limiting](#power-limiting)
  * [Cray CLI examples](#cray-cli-examples)
    * [Get node power control and limit settings](#get-node-power-control-and-limit-settings)
    * [Get power limit capabilities](#get-power-limit-capabilities)
    * [Set node power limit](#set-node-power-limit)
    * [Remove node power limit (set to default)](#remove-node-power-limit-set-to-default)
    * [Enable and disable power limiting](#enable-and-disable-power-limiting)
      * [Enable power limiting](#enable-power-limiting)
      * [Disable power limiting](#disable-power-limiting)

## Requirements

* Hardware State Manager (`cray-hms-smd`) at least `v1.30.16`
* CAPMC (`cray-hms-capmc`) at least `1.31.0`
* Cray CLI at least `0.44.0`

## Deprecated interfaces

Set the [CAPMC Deprecation Notice](../../introduction/deprecated_features/CAPMC_Deprecation_Notice.md) for
more information.

* `get_node_energy`
* `get_node_energy_stats`
* `get_system_power`

## Redfish API

The Redfish API for liquid-cooled compute blades is the node's Control resource
which is presented by the nC. The Control resource presents the various power
management capabilities for the node and any associated accelerator cards.

Each node has one or more power control resource that can be modified:

* Node power control (host CPU and memory)
* Accelerator power control (one resource per accelerator connected to the node)

The Control resources will only manifest in the nC's Redfish endpoint after
a node has been powered on and background processes have discovered the node's
power management capabilities.

## Power limiting

CAPMC power limit controls for compute nodes can query component capabilities
and manipulate the node power constraints. This functionality enables external
software to establish an upper bound, or estimate a minimum bound, on the amount
of power a system or a select subset of the system may consume.

CAPMC API calls provide means for third party software to implement advanced
power management strategies using JSON data structures.

The AMD EPYC node card supports these power limiting and monitoring API calls:

* `get_power_cap_capabilities`
* `get_power_cap`
* `set_power_cap`

Power limit control will only be valid on a compute node when power limiting is
enabled, the node is booted, and the node is in the `Ready` state as seen via the
Hardware State Manager.

### Cray CLI examples

#### Get node power control and limit settings

```console
cray capmc get_power_cap create –-nids NID_LIST --format json
```

Return the current power cap settings for a node and any accelerators that
are installed. Valid settings are only returned if power limiting is enabled
on the target nodes, those nodes are booted, and the nodes are in the `Ready`
state.

```console
cray capmc get_power_cap create --nids 1160 --format json
```

Example output:

```json
{
    "e": 0,
    "err_msg": "",
    "nids": [
        {
            "nid": 1160,
            "controls": [
                {
                    "name": "Node Power Limit",
                    "val": 1000
                },
                {
                    "name": "Accelerator3 Power Limit",
                    "val": 200
                },
                {
                    "name": "Accelerator2 Power Limit",
                    "val": 200
                },
                {
                    "name": "Accelerator0 Power Limit",
                    "val": 200
                },
                {
                    "name": "Accelerator1 Power Limit",
                    "val": 200
                }
            ]
        }
    ]
}
```

#### Get power limit capabilities

```console
cray capmc get_power_cap_capabilities create –-nids NID_LIST --format json
```

Return the `min` and `max` power cap settings for the node list and any
accelerators that are installed.

```console
cray capmc get_power_cap_capabilities create --nids 1160 --format json
```

Example output:

```json
{
    "e": 0,
    "err_msg": "",
    "groups": [
        {
            "name": "3_AuthenticAMD_64c_256GiB_3200MHz_NodeAccel.NVIDIA.6922G5060202000.1321020042737",
            "desc": "3_AuthenticAMD_64c_256GiB_3200MHz_NodeAccel.NVIDIA.6922G5060202000.1321020042737",
            "host_limit_max": 1985,
            "host_limit_min": 595,
            "static": 0,
            "supply": 1985,
            "powerup": 0,
            "nids": [
                1160
            ],
            "controls": [
                {
                    "name": "Node Power Limit",
                    "desc": "Node Power Limit",
                    "max": 1985,
                    "min": 595
                },
                {
                    "name": "Accelerator0 Power Limit",
                    "desc": "Accelerator0 Power Limit",
                    "max": 400,
                    "min": 100
                },
                {
                    "name": "Accelerator1 Power Limit",
                    "desc": "Accelerator1 Power Limit",
                    "max": 400,
                    "min": 100
                },
                {
                    "name": "Accelerator2 Power Limit",
                    "desc": "Accelerator2 Power Limit",
                    "max": 400,
                    "min": 100
                },
                {
                    "name": "Accelerator3 Power Limit",
                    "desc": "Accelerator3 Power Limit",
                    "max": 400,
                    "min": 100
                }
            ]
        }
    ]
}
```

#### Set node power limit

```console
cray capmc set_power_cap create --nids NID_LIST --control CONTROL_NAME VALUE --format json
```

Set the total power limit of the node by using the name of the node control.
The power provided to the host CPU and memory is the total node power limit
minus the power limits of each of the accelerators installed on the node.

```console
cray capmc set_power_cap create --nids 1160 --control "Node Power Limit" 1785
```

Example output:

```json
{
    "e": 0,
    "err_msg": "",
    "nids": [
        {
            "nid": 1160,
            "e": 0,
            "err_msg": ""
        }
    ]
}
```

Multiple controls can be set at the same time on multiple nodes, but all
target nodes must have the same set of controls available, otherwise the
call will fail.

```console
cray capmc set_power_cap create \
            --nids [1160-1163] \
            --control "Node Power Limit" 1785 \
            --control "Accelerator0 Power Limit" 300 \
            --control "Accelerator1 Power Limit" 300 \
            --control "Accelerator2 Power Limit" 300 \
            --control "Accelerator3 Power Limit" 300 \
            --format json
```

Example output:

```json
{
    "e": 0,
    "err_msg": "",
    "nids": [
        {
            "nid": 1160,
            "e": 0,
            "err_msg": ""
        },
        {
            "nid": 1161,
            "e": 0,
            "err_msg": ""
        },
        {
            "nid": 1162,
            "e": 0,
            "err_msg": ""
        },
        {
            "nid": 1163,
            "e": 0,
            "err_msg": ""
        }
    ]
}
```

#### Remove node power limit (set to default)

```console
cray capmc set_power_cap create --nids NID_LIST --control CONTROL_NAME 0 --format json
```

Reset the power limit to the default maximum. Alternatively, the `max`
value returned from `get_power_cap_capabilities` may be used. Multiple
controls can be set at the same time on multiple nodes, but all target nodes
must have the same set of controls available, otherwise the call will fail.

```console
cray capmc set_power_cap create --nids 1160 --control "Node Power Limit" 0 --format json
```

Example output:

```json
{
    "e": 0,
    "err_msg": "",
    "nids": [
        {
            "nid": 1160,
            "e": 0,
            "err_msg": ""
        }
    ]
}
```

#### Enable and disable power limiting

##### Enable power limiting

Determine the valid power limit range for the target control by using the
`get_power_cap_capabilities` Cray CLI option.

```console
cray capmc get_power_cap_capabilities create –-nids NID_LIST --format json
```

For example:

```console
cray capmc get_power_cap_capabilities create --nids 1160 --format json
```

Example output:

```json
{
    "e": 0,
    "err_msg": "",
    "groups": [
        {
            "name": "3_AuthenticAMD_64c_256GiB_3200MHz_NodeAccel.NVIDIA.6922G5060202000.1321020042737",
            "desc": "3_AuthenticAMD_64c_256GiB_3200MHz_NodeAccel.NVIDIA.6922G5060202000.1321020042737",
            "host_limit_max": 1985,
            "host_limit_min": 595,
            "static": 0,
            "supply": 1985,
            "powerup": 0,
            "nids": [
                1160
            ],
            "controls": [
                {
                    "name": "Node Power Limit",
                    "desc": "Node Power Limit",
                    "max": 1985,
                    "min": 595
                },
                {
                    "name": "Accelerator0 Power Limit",
                    "desc": "Accelerator0 Power Limit",
                    "max": 400,
                    "min": 100
                },
                {
                    "name": "Accelerator1 Power Limit",
                    "desc": "Accelerator1 Power Limit",
                    "max": 400,
                    "min": 100
                },
                {
                    "name": "Accelerator2 Power Limit",
                    "desc": "Accelerator2 Power Limit",
                    "max": 400,
                    "min": 100
                },
                {
                    "name": "Accelerator3 Power Limit",
                    "desc": "Accelerator3 Power Limit",
                    "max": 400,
                    "min": 100
                }
            ]
        }
    ]
}
```

Selecting a value that is in the `min` to `max` range, make a `curl` call to the
Redfish endpoint to enable power limiting for each control. Be aware that
the power limit for accelerators will be much lower than the power limit for
the node.

```console
limit=1985
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/NodePowerLimit \
        -d '{"ControlMode":"Automatic","SetPoint":'${limit}'}'
```

If there are accelerators installed, then enable power limiting on those as well.

```console
limit=400
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator0PowerLimit \
        -d '{"ControlMode":"Automatic","SetPoint":'${limit}'}'
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator1PowerLimit \
        -d '{"ControlMode":"Automatic","SetPoint":'${limit}'}'
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator2PowerLimit \
        -d '{"ControlMode":"Automatic","SetPoint":'${limit}'}'
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator3PowerLimit \
        -d '{"ControlMode":"Automatic","SetPoint":'${limit}'}'
```

##### Disable power limiting

Each control at the Redfish endpoint needs to be disabled.

```console
curl -k -u $login:$pass -H "Content-Type: application/json" \
        -X PATCH https://${BMC}/redfish/v1/Chassis/${node}/Controls/NodePowerLimit \
        -d '{"ControlMode":"Disabled"}'
```

If there are accelerators installed, then disable power limiting on those as well.

```console
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator0PowerLimit \
        -d '{"ControlMode":"Disabled"}'
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator1PowerLimit \
        -d '{"ControlMode":"Disabled"}'
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator2PowerLimit \
        -d '{"ControlMode":"Disabled"}'
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/Accelerator3PowerLimit \
        -d '{"ControlMode":"Disabled"}'
```
