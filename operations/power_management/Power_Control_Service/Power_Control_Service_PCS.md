# Power Control Service (PCS)

The Power Control Service (PCS) enables direct hardware control of nodes,
compute blades, router modules, and liquid cooled chassis. PCS talks to
BMCs via Redfish to control power, query status, and manage power capping
on target components. These controls enable an administrator and 3rd party
software to more intelligently manage state and system-wide power consumption.

Administrators can use the `cray` CLI for power operations from any system that
has HTTPS access to the
[System Management Services](../../network/Access_to_System_Management_Services.md).

Third party software can access the API directly. Refer to the
[PCS API](https://github.com/Cray-HPE/hms-power-control/blob/v1.4.0/api/swagger.yaml)
documentation for detailed information about API options and features.

The `cray power` command (see `--help`) can be used to control power to
specific components by specifying the component xname.

## Power Control and Query by xname

* transitions
* power-status

PCS power control assumes that all cabinets and PDUs have been plugged in,
breakers are on, and PDU controllers, BMCs, and other embedded controllers are
on, available, and have been discovered. Components have their power controlled
in a pre-defined order to properly handle requests of dependent components.

**Important:** It is recommended to use the Boot Orchestration Service (BOS) to
boot (power On), shutdown, and reboot compute nodes.

### Controllable Components

#### Air Cooled Cabinets ####

* Compute Nodes
* NCNs

#### Liquid Cooled Cabinets ####

* Chassis
* Slingshot Switch modules
* Compute blades
* Compute nodes

#TODO: update this paragraph for PCS
CAPMC uses xnames to specify entire cabinets or specific components throughout
the system. By default, CAPMC controls power to only one component at a time. A
`--recursive true` option can be passed to CAPMC using the `cray` CLI. When the
`--recursive true` option is included in a request, all of the sub-components of
the target component are included in the power command.

By the cabinet naming convention, each cabinet in the system is assigned a
unique number. Cabinet numbers can range from 0-9999 and contain from 1-4 digits
only.

Manufacturing typically follows a sequential cabinet numbering scheme:
* Liquid Cooled cabinet numbers: x1000–x2999
* Air Cooled cabinet numbers: x3000–x4999
* Liquid Cooled TDS cabinet numbers: x5000–5999

Examples of valid xnames:
* Full system: s0, all
* Cabinet numbers: x1000, x3000, x5000
* Chassis numbers 0-7: x1000c7, x3500c0 (Air Cooled cabinets are always
chassis 0)
* Compute Blade Slots 0-7: x1000c7s3, x3500c0s15 (U15)
* Compute Nodes: x1000c7s3b0n0, x3500c0s15b1n0
* NCN Slots: x3200c0s9 (U9)
* NCN Nodes: x3200c0s9b0n0

## Power Capping

* power-cap

PCS is capable of setting node power limits on all supported compute node
hardware in both liquid cooled cabinets and air cooled cabinets. This
functionality enables external software to establish an upper bound, or estimate
a minimum bound, on the amount of power a system may consume. Separate PCS
calls are required to power cap different compute node types as each compute
node type has its own power capping capabilities.

`NOTE` Power capping is not supported for liquid cooled chassis, switch
modules, compute blades, and any non-compute nodes (NCNs) in air cooled
cabinets.
