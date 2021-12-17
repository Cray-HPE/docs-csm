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

CAPMC only handles power capping of one hardware type at a time. Each vendor and
server model has their own power capping capabilities. Therefore a different
power cap request will be needed for each vendor and model that needs to have
its power limited.

## Interfaces
-   get_power_cap_capabilities
-   get_power_cap
-   set_power_cap

## Deprecated interfaces
[CAPMC Deprecation Notice](../../introduction/CAPMC_deprecation.md)
-   get_node_energy \(Deprecated\)
-   get_node_energy_stats \(Deprecated\)
-   get_system_power \(Deprecated\)

## Redfish API

The Redfish API for rack-mounted nodes is the node's Power resource which is
presented by the BMC. OEM properties may be used to augment the Power schema and
allow for feature parity with previous Cray system power management
capabilities.

## CrayCLI Examples
### Get Node Power Limit Capabilities
Query the power capping control bounds, grouped by node type. Control values
which are returned as zero indicate the respective control is unconstrained or
not enabled. 
#### Example of a node with 4 GPUs
```
ncn-m001# cray capmc get_power_cap_capabilities create --nids 1995 --format json
{
  "e": 0,
  "err_msg": "",
  "groups": [
    {
      "name": "3_AuthenticAMD_64c_256GiB_3200MHz_NodeAccel.NVIDIA",
      "desc": "3_AuthenticAMD_64c_256GiB_3200MHz_NodeAccel.NVIDIA",
      "host_limit_max": 1985,
      "host_limit_min": 595,
      "static": 0,
      "supply": 0,
      "powerup": 250,
      "nids": [
        1995
      ],
      "controls": [
        {
          "name": "Node Power Control",
          "desc": "Node Power Control",
          "max": 1985,
          "min": 595
        },
        {
          "name": "Accelerator 0 Power Control",
          "desc": "Accelerator 0 Power Control",
          "max": 400,
          "min": 100
        },
        {
          "name": "Accelerator 1 Power Control",
          "desc": "Accelerator 1 Power Control",
          "max": 400,
          "min": 100
        },
        {
          "name": "Accelerator 1 Power Control",
          "desc": "Accelerator 1 Power Control",
          "max": 400,
          "min": 100
        },
        {
          "name": "Accelerator 1 Power Control",
          "desc": "Accelerator 1 Power Control",
          "max": 400,
          "min": 100
        }
      ]
    }
  ]
}
```
The maximum power draw for a node is the host_limit_max. The host_limit_max
minus the power limit of the 4 GPUs is the power remaining for the host CPU and
memory. If all 4 GPUs are set to 400 watt limit, there would be 385 watts left
for the host CPU and memory. The node power control limit controls the host
CPU and memory power as well as the aceelerator power. If the node power limit
is set to 1000 watts, and the accelerators max limit was set to 200 watts, that
would leave 200 watts for the host CPU and memory. The minumum power draw is the
sum of the GPU minimums and the host CPU and memory minimums. The minumum power
draw for the host CPU and memory is 195 watts.
### Get Node Power Limit
Query the nodes for their currently set power limits. CAPMC will only return
power limit informaiton for computes nodes that are in the Ready state. This
guarnatees that the power limiting infrastructure has been properly configured
on the node.
#### No limits set, unconstrained
ncn-m001:~ # cray capmc get_power_cap create --nids 9
{
  "e": 0,
  "err_msg": "",
  "nids": [
    {
      "nid": 9,
      "controls": [
        {
          "name": "node",
          "val": 0
        }
      ]
    }
  ]
}
This shows there is no power limit set on the node, which means there is no
power constraint on the node and it can use up to the host_limit_max power.
#### Limits set
ncn-m001:~ # cray capmc get_power_cap create --nids 1995
{
  "e": 0,
  "err_msg": "",
  "nids": [
    {
      "nid": 1995,
      "controls": [
        {
          "name": "node",
          "val": 1985
        },
        {
          "name": "Accelerator 0 Power Control",
          "val": 400
        },
        {
          "name": "Accelerator 1 Power Control",
          "val": 400
        },
        {
          "name": "Accelerator 2 Power Control",
          "val": 400
        },
        {
          "name": "Accelerator 3 Power Control",
          "val": 400
        }
      ]
    }
  ]
}
Related to the get_power_cap_capabilities above, this node is set to allow the
accelerators to use the maximum 400 watts of power per GPU. The host CPU and
memory can use up to 385 watts.
### Set Node Power Limit

Set the node power limit to 600 Watts:

```
# cray capmc set_power_cap create --nids 1,2,3 --node 600
```

## Hardware Specific Information
### Gigabyte
#### Enable power limiting
```
ncn-m001# curl -k -u $login:$pass -H "Content-Type: application/json" \
-X POST https://$BMC/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger \
--data '{"PowerLimitTrigger": "Activate"}'
```

#### Deactivate Node Power Limit
```
ncn-m001# curl -k -u $login:$pass -H "Content-Type: application/json" \
-X POST https://$BMC/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger \
--data '{"PowerLimitTrigger": "Deactivate"}'
```
