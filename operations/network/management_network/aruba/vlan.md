# Virtual Local Access Networks (VLANs)

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network.


## Configuration Commands

Create VLAN:

```text
switch(config)# vlan <VLAN>
```

Configure an interface to associate it with a VLAN:

```text
switch(config)# interface <IFACE>
switch(config-if)# no shutdown
switch(config-if)# no routing
```

Configure an interface as an access port:

```text
switch(config-if)# vlan access VLAN
```

Configure an interface as a trunk port:

```text
switch(config-if)# vlan trunk native <VLAN>
switch(config-if)# vlan trunk allowed <VLAN>
```

Configure VLAN as Voice:

> **NOTE:** To give a specific VLAN a voice designation and adding the proper hooks, you need to add the `voice` command in the VLAN context.
> This configuration is the same for all CX-series switches.

```text
switch(config)# vlan <VLAN>
switch(config-vlan-100)# voice
```

Show commands to validate functionality:

```text
switch# show vlan [VLAN]
```

## Example Output

```text
switch# show vlan
--------------------------------------------------------------------------------------
VLAN  Name                              Status  Reason          Type      Interfaces
--------------------------------------------------------------------------------------
1     DEFAULT_VLAN_1                    up      no_member_port  static    1/1/2
10    VLAN10                            up      ok              static    1/1/1-1/1/2
```

## Expected Results

1. Administrators can create a VLAN
1. Administrators can assign a VLAN to the physical interface


[Back to Index](../index.md)
