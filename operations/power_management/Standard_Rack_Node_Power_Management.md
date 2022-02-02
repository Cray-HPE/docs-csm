

## Standard Rack Node Power Management

HPE Cray EX standard EIA rack node power management is supported by the server vendor BMC firmware. The BMC exposes the power control API for a node through the node's Redfish ChassisPower schema.

Out-of-band power management data is polled by a collector and published on a Kafka bus for entry into the Power Management Database. The Cray Advanced Platform Management and Control \(CAPMC\) API facilitates power control and enables power aware WLMs such as Slurm to perform power management and power capping tasks.

**Important:** Always use the Boot Orchestration Service \(BOS\) to power off or power on compute nodes.

### Redfish API

The Redfish API for rack-mounted nodes is the node's Chassis Power resource which is presented by the BMC. OEM properties may be used to augment the Power schema and allow for feature parity with previous Cray system power management capabilities. A PowerControl resource presents the various power management capabilities for the node.

Each node has a node power control resource. The power control of the node must be enabled and may require additional licenses to use.

CAPMC does not enable power capping on all standard rack nodes because each server vendor has a different implementation. The `Activate` and `Deactivate` commands that follow apply to Gigabyte nodes only.

**Get Node Power Limit Settings**

```bash
# curl -k -u $login:$pass -H "Content-Type: application/json" \
-X GET https://$BMC_IP/redfish/v1/Chassis/Self/Power 2>/dev/null | python -m json.tool | egrep 'LimitInWatts'
```

Use the Cray CLI to get the node power limit settings:

```bash
# cray capmc get_power_cap create --nids 100006 --format json | jq
```

Example output:

```
{
  "e": 0,
  "err_msg": "",
  "groups": [
    {
      "powerup": 0,
      "host_limit_min": 0,
      "supply": 65535,
      "host_limit_max": 0,
      "controls": [
        {
          "max": 0,
          "min": 0,
          "name": "Chassis Power Control",
          "desc": "Chassis Power Control"
        }
      ],
      "nids": [
        100006
      ],
      "static": 0,
      "desc": "3_AuthenticAMD_64c_244GiB_3200MHz_NoAccel",
      "name": "3_AuthenticAMD_64c_244GiB_3200MHz_NoAccel"
    }
  ]
}

```

**Set Node Power Limit**

```bash
# curl -k -u $login:$pass -H "Content-Type: application/json" \
-H 'If-Match: W/"'${o_data}'"' -X PATCH https://$BMC_IP/redfish/v1/Chassis/Self/Power \
--data '{"PowerControl": [{"PowerLimit": {"LimitInWatts": '$LimitValue'}}]}'
```

Set the node power limit to 600 Watts:

```bash
# cray capmc set_power_cap create --nids 1,2,3 --node 600
```

**Get Node Energy Counter**

```bash
# curl -k -u $login:$pass -H "Content-Type: application/json" \
-X GET https://$BMC_IP/redfish/v1/Chassis/Self/Power 2>/dev/null \
| python -m json.tool | egrep 'PowerConsumedWatts'

```

**Activate Node Power Limit**

```bash
# curl -k -u $login:$pass -H "Content-Type: application/json" \
-X POST https://$BMC_IP/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger \
--data '{"PowerLimitTrigger": "Activate"}'
```

**Deactivate Node Power Limit**

```bash
# curl -k -u $login:$pass -H "Content-Type: application/json" \
-X POST https://$BMC_IP/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger \
--data '{"PowerLimitTrigger": "Deactivate"}'
```





