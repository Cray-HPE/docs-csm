## Cray Advanced Platform Monitoring and Control \(CAPMC\)

CAPMC provides remote monitoring and hardware on/off control.

The Cray Advanced Platform Monitoring and Control \(CAPMC\) API enables direct hardware control of power on/off, power monitoring, or system-wide power telemetry and configuration parameters from Redfish. CAPMC implements a simple interface for powering on/off compute nodes, querying node state information, and querying site-specific service usage rules. These controls enable external software to more intelligently manage system-wide power consumption or configuration parameters.

Refer to the CAPMC API documentation for detailed API information.

The current release of CAPMC supports the following power control features:

-   Retrieve Redfish power status and power management capabilities of components
-   Control single components via NID or xname
-   Control grouped components
-   Control the entire system \(all or s0\)
-   Can specify ancestors \(`--prereq`\) and descendants \(`--recursive`\) of single component
-   Provide a `--force` option for immediate power off
-   Power capping

Power sequencing using CAPMC assumes that all cabinets and PDUs have been plugged in, breakers are on, and PDU controllers, BMCs, and other embedded controllers are on and available. CAPMC provides a default order for components to powering on, but the power sequence can be configured.

Power management strategies may vary and can be simple or complex using 3rd party software. A simple power management strategy is to power off idle compute nodes, then power on nodes when demand increases.

The `cray` CLI can be used from any system that has HTTPS access to [System Management Services](../network/Access_to_System_Management_Services.md). Refer to the CAPMC API documentation for detailed information about API options and features.

The `cray capmc` command \(see `--help`\) can be used to control power to specific components by specifying the component NID, xname, or group.

### Components that Can be Controlled with CAPMC

**Air Cooled Cabinets**

-   Compute Nodes

**Liquid Cooled Cabinets**

-   Chassis
-   Slingshot Switch blades
-   Compute blades
-   Compute nodes

### Component Groups

CAPMC uses xnames to specify entire cabinets or specific components throughout the system. By default, CAPMC controls power to only one component at a time. A `--recursive` option can be passed to CAPMC using the `cray` CLI. When the `--recursive` option is included in a request, all of the sub-components of the target component are included in the power command.

The cabinet naming convention assigns a number to each cabinet in the system. Cabinets can be located anywhere on the computer room floor, although manufacturing typically follows a sequential cabinet numbering scheme:

-   Liquid Cooled cabinet numbers: x1000–x2999
-   Air Cooled cabinet numbers: x3000–x4999
-   Liquid Cooled TDS cabinet numbers: x5000–5999

Cabinet numbers can range from 0-9999 and contain from 1–4 digits only.

**Full system**: s0, all

**Cabinet numbers**: x1000, x3000, x5000

**Chassis numbers 0-7**: x1000c7, x3500c0 \(Air Cooled cabinets are always chassis 0\)

**Compute Blade Slots**:x1000c7s3, x3500c0s15 \(U15\)

### Power Capping

CAPMC power capping controls for compute nodes can query component capabilities and manipulate the node power constraints. This functionality enables external software to establish an upper bound, or estimate a minimum bound, on the amount of power a system may consume.

CAPMC API calls provide means for third party software to implement advanced power management strategies and JSON functionality can send and receive customized JSON data structures.

Air Cooled nodes support these power capping and monitoring API calls:

-   get\_power\_cap\_capabilities
-   get\_power\_cap
-   set\_power\_cap
-   get\_node\_energy
-   get\_node\_energy\_stats
-   get\_system\_power

### Examples for Compute Node Power Management

**Get Node Energy**

```bash
ncn-m001# cray capmc get\_node\_energy create --nids NID\_LIST --start-time '2020-03-04 12:00:00' \\
--end-time '2020-03-04 12:10:00' --format json
```

**Get Node Energy Stats**

```bash
ncn-m001# cray capmc get\_node\_energy\_stats create --nids NID\_LIST --start-time \\
'2020-03-04 12:00:00' --end-time '2020-03-04 12:10:00' --format json
```

**Get Node Power Control and Limit Settings**

```bash
ncn-m001# cray capmc get\_power\_cap create –-nids NID\_LIST --format json
```

**Get System Power**

```bash
ncn-m001# cray capmc get\_system\_power create --start-time \\
'2020-03-04 12:00:00' --window-len 30 --format json
```

**Get Power Capping Capabilities**

The supply field contains the Max limit for the node.

```bash
ncn-m001# cray capmc get\_power\_cap\_capabilities create –-nids NID\_LIST --format json
```

**Set Node Power Limit**

```bash
ncn-m001# cray capmc set\_power\_cap create –-nids NID\_LIST --node 225 --format json
```

**Remove Node Power Limit \(Set to Default\)**

```bash
ncn-m001# cray capmc set\_power\_cap create –-nids NID\_LIST --node 0 --format json
```

**Activate Node Power Limit**

```bash
# curl -k -u $login:$pass -H "Content-Type: application/json" \\
-X POST https://$BMC\_IP/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger --date
'\{"PowerLimitTrigger": "Activate"\}'
```

**Deactivate Node Power Limit**

```bash
# curl -k -u $login:$pass -H "Content-Type: application/json" \\
-X POST https://$BMC\_IP/redfish/v1/Chassis/Self/Power/Actions/LimitTrigger --data '\{"PowerLimitTrigger": "Deactivate"\}'
```

## Power On/Off Examples

**Power Off a Cabinet**

```bash
ncn-m001# cray capmc xname\_off create --xnames x1000 --recursive --format json
```

**Power Off a Chassis 0 and Its Descendents**

```bash
ncn-m001# cray capmc xname\_off create --xnames x1000c0 --recursive --format json
```

**Power Off Node 0 in Cabinet 1000, Chassis, 0, Slot 0, Node Card 0**

```bash
ncn-m001# cray capmc xname\_off create --xnames x1000c0s0b0n0 --format json
```

**Emergency Power Off \(EPO\) CLI Command**

```bash
ncn-m001#  cray capmc emergency\_power\_off –-xnames LIST\_OF\_CHASSIS --force --format json
```

To recover or "reset" the components after a software EPO, set the chassis to a known hardware state \(off\). The cabinet\(s\) can then be powered on normally after the EPO is cleared. For a complete procedure, see [Recover from a Liquid Cooled Cabinet EPO Event](Recover_from_a_Liquid_Cooled_Cabinet_EPO_Event.md).

```bash
ncn-m001# cray capmc xname\_off create --xnames LIST\_OF\_CHASSIS --force true
e = 0
err_msg = ""
```

