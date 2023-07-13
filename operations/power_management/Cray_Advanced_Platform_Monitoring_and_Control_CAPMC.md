# Cray Advanced Platform Monitoring and Control (CAPMC)

The Cray Advanced Platform Monitoring and Control (CAPMC) service enables
direct hardware control of nodes, compute blades, router modules, and liquid
cooled chassis. CAPMC talks to BMCs via Redfish to control power, query status,
and manage power capping on target components. These controls enable an
administrator and 3rd party software to more intelligently manage state and
system-wide power consumption.

Administrators can use the `cray` CLI for power operations from any system that
has HTTPS access to the
[System Management Services](../network/Access_to_System_Management_Services.md).

Third party software can access the API directly. Refer to the
[CAPMC API](https://github.com/Cray-HPE/hms-capmc/blob/release/csm-1.0/api/swagger.yaml)
documentation for detailed information about API options and features.

The `cray capmc` command (see `--help`) can be used to control power to
specific components by specifying the component NID, xname, or group.

- [Power control and query by xname](#power-control-and-query-by-xname)
  - [Controllable components](#controllable-components)
    - [Air-cooled cabinets](#air-cooled-cabinets)
    - [Liquid-cooled cabinets](#liquid-cooled-cabinets)
    - [Naming convention](#naming-convention)
      - [Examples of valid xnames](#examples-of-valid-xnames)
- [Power capping](#power-capping)
- [Deprecated interfaces](#deprecated-interfaces)
  - [Power control and query by NID](#power-control-and-query-by-nid)
  - [Power control and query by group](#power-control-and-query-by-group)
  - [Node energy](#node-energy)
  - [System monitor](#system-monitor)
  - [Others](#others)

## Power control and query by xname

- `xname_on`
- `xname_off`
- `xname_reinit`
- `get_xname_status`

CAPMC power control assumes that all cabinets and PDUs have been plugged in,
breakers are on, and PDU controllers, BMCs, and other embedded controller are
on, available, and have been discovered. Components have their power controlled
in a pre-defined order to properly handle requests of dependent components.

**Important:** It is recommended to use the Boot Orchestration Service (BOS) to
boot (power On), shutdown, and reboot compute nodes.

### Controllable components

#### Air-Cooled cabinets

- Compute Nodes
- NCNs

#### Liquid-cooled cabinets

- Chassis
- Slingshot Switch modules
- Compute blades
- Compute nodes

#### Naming convention

CAPMC uses xnames to specify entire cabinets or specific components throughout
the system. By default, CAPMC controls power to only one component at a time. A
`--recursive true` option can be passed to CAPMC using the `cray` CLI. When the
`--recursive true` option is included in a request, all of the sub-components of
the target component are included in the power command.

By the cabinet naming convention, each cabinet in the system is assigned a
unique number. Cabinet numbers can range from 0-9999 and contain from 1-4 digits
only.

Although manufacturing typically follows a sequential cabinet numbering scheme:

- Liquid-cooled cabinet numbers: `x1000`–`x2999`
- Air-cooled cabinet numbers: `x3000`–`x4999`
- Liquid-cooled TDS cabinet numbers: `x5000`–`x5999`

##### Examples of valid xnames

- Full system: `s0`, `all`
- Cabinet numbers: `x1000`, `x3000`, `x5000`
- Chassis numbers 0-7: `x1000c7`, `x3500c0` (Air-cooled cabinets are always chassis 0)
- Compute blade slots 0-7: `x1000c7s3`, `x3500c0s15` (`U15`)
- Compute nodes: `x1000c7s3b0n0`, `x3500c0s15b1n0`
- NCN slots: `x3200c0s9` (`U9`)
- NCNs: `x3200c0s9b0n0`

## Power capping

- `get_power_cap_capabilities`
- `get_power_cap`
- `set_power_cap`

CAPMC is capable of setting node power limits on all supported compute node
hardware in both liquid cooled cabinets and air cooled cabinets. This
functionality enables external software to establish an upper bound, or estimate
a minimum bound, on the amount of power a system may consume. Separate CAPMC
calls are required to power cap different compute node types as each compute
node type has its own power capping capabilities.

**NOTE:** Power capping is not supported for liquid cooled chassis, switch
modules, compute blades, and any non-compute nodes (NCNs) in air cooled
cabinets.

## Deprecated interfaces

See the [CAPMC Deprecation Notice](../../introduction/CAPMC_deprecation.md) for
more information

### Power control and query by NID

Use the interfaces from [Power control and query by xname](#power-control-and-query-by-xname):

- `node_on`
- `node_off`
- `node_reinit`
- `get_node_status`

### Power control and query by group

Use the interfaces from [Power control and query by xname](#power-control-and-query-by-xname):

- `group_on`
- `group_off`
- `group_reinit`
- `get_group_status`

### Node energy

Use the System Monitoring Application (SMA) Grafana instance:

- `get_node_energy`
- `get_node_energy_stats`
- `get_node_energy_counters`

### System monitor

Use the System Monitoring Application (SMA) Grafana instance:

- `get_system_parameters`
- `get_system_power`
- `get_system_power_details`

### Others

- `get_node_rules`
- `emergency_power_off`
- `get_nid_map`
