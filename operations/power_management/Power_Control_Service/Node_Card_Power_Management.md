# Node Card Power Management

Node power management is supported by the server vendor BMC firmware. The BMC
exposes the power control API for a node through the node's Redfish Power schema.

Out-of-band power management data is polled by a collector and published on a
Kafka bus for entry into the Power Management Database (PMDB). Access to the
data stored in the PMDB is available through the System Monitoring Application
(SMA) Grafana instance.

Power limiting of a node must be enabled and may require additional licenses to
use. Refer to vendor documentation for instructions on how to enable power
limiting and what licenses, if any, are needed.

## Requirements

* Hardware State Manager (`cray-hms-smd`) at least `v2.0.0`
* PCS (`cray-power-control`) at least `v1.0.0`
* Cray CLI at least `v0.61.0`

## Redfish API

The Redfish API for rack-mounted nodes is the node's Power resource which is
presented by the BMC. OEM properties may be used to augment the Power schema to
provide additional power management capabilities.

The Redfish API for Liquid Cooled compute blades is the node's Control resource
which is presented by the nC. The Control resource presents the various power
management capabilities for the node and any associated accelerator cards.

Each node has one or more power control resources that can be modified:

* Node power control (host CPU and memory)
* Accelerator power control (one resource per accelerator connected to the node)

The Control resources will only manifest in the nC's Redfish endpoint after
a node has been powered on and background processes have discovered the node's
power management capabilities.

## Power Limiting

PCS power limit controls for compute nodes can query component capabilities
and manipulate the node power constraints. This functionality enables external
software to establish an upper bound, or estimate a minimum bound, on the amount
of power a system or a select subset of the system may consume.

PCS API calls provide means for third party software to implement advanced
power management strategies using JSON data structures.

The node card supports these power limiting and monitoring API calls:

* `power-cap`
* `power-cap/snapshot`

In general, rack-mounted compute nodes do not allow for power limiting of any
installed accelerators separately from the node limit.

Power limit control will only be valid on a compute node when power limiting is
enabled, the node is booted, and the node is in the Ready state as seen via the
Hardware State Manager.

## Cray CLI Examples for Liquid Cooled Compute Node Power Management

### Get Node Power Control and Limit Settings

```console
cray power cap snapshot --xnames XNAME_LIST --format json
cray power cap describe TASK_ID --format json
```

Return the current power cap settings and limits for nodes and any accelerators
that are installed. Valid settings are only returned if power limiting is enabled
on the target nodes, those nodes are booted, and the nodes are in the Ready state.

```console
cray power cap snapshot --xnames x1000c0s2b0n0 --format json
cray power cap describe e63c08a5-4ee6-40e4-97fd-eb1eaaf5231b --format json
```

Example output:

```json
{
  "taskID": "e63c08a5-4ee6-40e4-97fd-eb1eaaf5231b",
  "type": "snapshot",
  "taskCreateTime": "2023-02-08T23:42:32.047885871Z",
  "automaticExpirationTime": "2023-02-09T23:42:32.047885951Z",
  "taskStatus": "completed",
  "taskCounts": {
    "total": 5,
    "new": 0,
    "in-progress": 0,
    "failed": 0,
    "succeeded": 5,
    "un-supported": 0
  },
  "components": [
    {
      "xname": "x1000c0s2b0n0",
      "powerCapLimits": [
        {
          "name": "Accelerator0 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Node Power Limit",
          "currentValue": 0,
          "maximumValue": 2754,
          "minimumValue": 764
        },
        {
          "name": "Accelerator1 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator3 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator2 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        }
      ]
    }
  ]
}
```

### Set Node Power Limit

```console
cray power cap set --xnames XNAME_LIST --control CONTROL_NAME VALUE --format json
cray power cap describe TASK_ID --format json
```

Set the total power limit of the node by using the name of the node control.
The power provided to the host CPU and memory is the total node power limit
minus the power limits of each accelerator installed on the node.

```console
cray power cap set --xnames x1000c0s2b0n0 --control "Node Power Limit" 1785 --format json
cray power cap describe 1059c5d3-770e-4cc0-85ca-ef0e8c79cd5f --format json
```

Example output:

```json
{
  "taskID": "1059c5d3-770e-4cc0-85ca-ef0e8c79cd5f",
  "type": "patch",
  "taskCreateTime": "2023-02-08T23:46:26.192294723Z",
  "automaticExpirationTime": "2023-02-09T23:46:26.192294778Z",
  "taskStatus": "completed",
  "taskCounts": {
    "total": 1,
    "new": 0,
    "in-progress": 0,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  },
  "components": [
    {
      "xname": "x1000c0s2b0n0",
      "powerCapLimits": [
        {
          "name": "Node Power Limit",
          "currentValue": 1785,
          "maximumValue": 2754,
          "minimumValue": 764
        }
      ]
    }
  ]
}
```

Multiple controls can be set at the same time on multiple nodes, but all
target nodes must have the same set of controls available, otherwise the
call will fail.

```console
cray power cap set \
            --xnames "x1000c0s2b[0-1]n0" \
            --control "Node Power Limit" 1500 \
            --control "Accelerator0 Power Limit" 300 \
            --control "Accelerator1 Power Limit" 300 \
            --control "Accelerator2 Power Limit" 300 \
            --control "Accelerator3 Power Limit" 300 \
            --format json

cray power cap describe a9e44f13-6633-4d3c-9091-59073e75430b --format json
```

Example output:

```json
{
  "taskID": "a9e44f13-6633-4d3c-9091-59073e75430b",
  "type": "patch",
  "taskCreateTime": "2023-02-08T23:53:16.288543057Z",
  "automaticExpirationTime": "2023-02-09T23:53:16.288543155Z",
  "taskStatus": "completed",
  "taskCounts": {
    "total": 2,
    "new": 0,
    "in-progress": 0,
    "failed": 0,
    "succeeded": 2,
    "un-supported": 0
  },
  "components": [
    {
      "xname": "x1000c0s2b0n0",
      "powerCapLimits": [
        {
          "name": "Node Power Limit",
          "currentValue": 1500,
          "maximumValue": 2754,
          "minimumValue": 764
        },
        {
          "name": "Accelerator0 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator1 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator2 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator3 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        }
      ]
    },
    {
      "xname": "x1000c0s2b1n0",
      "powerCapLimits": [
        {
          "name": "Accelerator3 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Node Power Limit",
          "currentValue": 1500,
          "maximumValue": 2754,
          "minimumValue": 764
        },
        {
          "name": "Accelerator0 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator1 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator2 Power Limit",
          "currentValue": 300,
          "maximumValue": 560,
          "minimumValue": 100
        }
      ]
    }
  ]
}
```

### Remove Node Power Limit (Set to Default)

```console
cray power cap set --xnames XNAME_LIST --control CONTROL_NAME 0 --format json
cray power cap describe TASK_ID --format json
```

Reset the power limit to the default maximum. Alternatively, using the max
value returned from power cap snapshot may also be used. Multiple controls
can be set at the same time on multiple nodes, but all target nodes must
have the same set of controls available, otherwise the call will fail.

```console
cray power cap set \
            --xnames x1000c0s2b0n0 \
            --control "Node Power Limit" 0 \
            --control "Accelerator0 Power Limit" 0 \
            --control "Accelerator1 Power Limit" 0 \
            --control "Accelerator2 Power Limit" 0 \
            --control "Accelerator3 Power Limit" 0 \
            --format json

cray power cap describe 75b18ce8-454f-4218-a256-4962666a19a7 --format json
```

Example output:

```json
{
  "taskID": "75b18ce8-454f-4218-a256-4962666a19a7",
  "type": "patch",
  "taskCreateTime": "2023-02-09T00:03:42.757965479Z",
  "automaticExpirationTime": "2023-02-10T00:03:42.757965783Z",
  "taskStatus": "completed",
  "taskCounts": {
    "total": 1,
    "new": 0,
    "in-progress": 0,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  },
  "components": [
    {
      "xname": "x1000c0s2b0n0",
      "powerCapLimits": [
        {
          "name": "Node Power Limit",
          "currentValue": 0,
          "maximumValue": 2754,
          "minimumValue": 764
        },
        {
          "name": "Accelerator0 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator1 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator2 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator3 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        }
      ]
    }
  ]
}
```

## Enable and Disable Power Limiting

### Enable Power Limiting

Determine the valid power limit range for the target control by using the
`power cap snapshot` Cray CLI option.

```console
cray power cap snapshot --xnames XNAME_LIST --format json
cray power cap describe TASK_ID --format json
```

For example:

```console
cray power cap snapshot --xnames x1000c0s2b0n0 --format json
cray power cap describe da00767e-d750-434b-bad9-401ee7a40b46 --format json
```

Example output:

```json
{
  "taskID": "da00767e-d750-434b-bad9-401ee7a40b46",
  "type": "snapshot",
  "taskCreateTime": "2023-02-09T00:07:26.678274873Z",
  "automaticExpirationTime": "2023-02-10T00:07:26.678274959Z",
  "taskStatus": "completed",
  "taskCounts": {
    "total": 5,
    "new": 0,
    "in-progress": 0,
    "failed": 0,
    "succeeded": 5,
    "un-supported": 0
  },
  "components": [
    {
      "xname": "x1000c0s2b0n0",
      "powerCapLimits": [
        {
          "name": "Accelerator2 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator3 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Node Power Limit",
          "currentValue": 0,
          "maximumValue": 2754,
          "minimumValue": 764
        },
        {
          "name": "Accelerator1 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        },
        {
          "name": "Accelerator0 Power Limit",
          "currentValue": 0,
          "maximumValue": 560,
          "minimumValue": 100
        }
      ]
    }
  ]
}
```

Select a value that is in the min to max range and make a `curl` call to the
Redfish endpoint to enable power limiting for each control. Be aware that
the power limit for accelerators will be much lower than the power limit for
the node.

```console
limit=1985
curl -k -u $login:$pass -H "Content-Type: application/json" -X PATCH \
        https://${BMC}/redfish/v1/Chassis/${node}/Controls/NodePowerLimit \
        -d '{"ControlMode":"Automatic","SetPoint":'${limit}'}'
```

If there are accelerators installed, enabled power limiting on those as well.

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

### Disable Power Limiting

Each control at the Redfish endpoint needs to be disabled.

```console
curl -k -u $login:$pass -H "Content-Type: application/json" \
        -X PATCH https://${BMC}/redfish/v1/Chassis/${node}/Controls/NodePowerLimit \
        -d '{"ControlMode":"Disabled"}'
```

If there are accelerators installed, disable power limiting on those as well.

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
