# Multi-Chassis Link Aggregation Group (MCLAG)

Multi-Chassis Link Aggregation Group (MCLAG) is a link aggregation technique where two or more links across
two switches are aggregated together to form a trunk.

## Configuration commands

### Creating an MLAG interface

(`switch (config)#`) Create an MLAG interface for the host. Run:

```console
interface mlag-port-channel 1
```

The MPO interfaces should be configured in the same sequence on both switches of MLAG cluster.

Example:

On switch 1:

```console
interface mlag-port-channel 1-10
interface mlag-port-channel 30-40
```

On switch 2:

```console
interface mlag-port-channel 1-10
interface mlag-port-channel 30-40
```

(`switch (config interface ethernet 1/1)#`) Bind an Ethernet port to the MLAG interface:

```console
mlag-channel-group 1 mode on
```

(`switch (config interface mlag-port-channel 1)#`) Create and enable the MLAG interface:

```console
no shutdown
```

### Enabling MLAG

(`switch (config mlag)#`) Enable MLAG:

```console
no shutdown
```

When running MLAG as L2/L3 border point, MAGP VIP must be deployed as the default gateway for MPOs.

## Show commands to validate functionality

(`switch (config)#`) Examine MLAG configuration and status. Run `show mlag` on the switch:

```console
show mlag
```

Example output:

```text
Admin status: Enabled
Operational status: Up
Reload-delay: 1 sec
Keepalive-interval: 30 sec
Upgrade-timeout: 60 min
System-mac: 00:00:5e:00:01:5d

MLAG Ports Configuration Summary:
Configured:  1
 Disabled:   0
 Enabled:    1

MLAG Ports Status Summary:
Inactive:        0
 Active-partial: 0
 Active-full:    1

MLAG IPLs Summary:
ID   Group         Vlan       Operational    Local        Peer        Up Time     Toggle Counter
     Port-Channel  Interface  State          IP address   IP address
----------------------------------------------------------------------------------------------
1    Po1           1          Up             1.1.1.1      1.1.1.2     0 days      00:00:09 5
Peers state Summary:
System-id          State   Hostname
-----------------------------------
F4:52:14:2D:9B:88  Up      <Switch 1>
F4:52:14:2D:9B:08  Up       Switch 2
```

(`switch (config)#`) Examine the MLAG summary table:

```console
show interfaces mlag-port-channel summary
```

Example output:

```text
MLAG Port-Channel Flags: D-Down, U-Up, P-Partial UP, S-suspended by MLAG

Port Flags:
  D: Down
  P: Up in port-channel (members)
  S: Suspend in port-channel (members)
  I: Individual

MLAG Port-Channel Summary:
  ------------------------------------------------------------------------------
  Group              Type     Local                     Peer
  Port-Channel                Ports                     Ports
  (D/U/P/S)                   (D/P/S/I)                 (D/P/S/I)
  ------------------------------------------------------------------------------
  1 Mpo2(U)          Static   Eth1/2(P)                 Eth1/2(P)
```

(`switch (config)#`) Examine the MLAG statistics. Run:

```console
show mlag statistics
```

Example output:

```text
IPL 1
  Rx Heartbeat           : 516
  Tx Heartbeat           : 516
  Rx IGMP tunnel         : 0
  Tx IGMP tunnel         : 0
  RX XSTP tunnel         : 0
  TX XSTP tunnel         : 0
  RX mlag-notification   : 0
  TX mlag-notification   : 0
  Rx port-notification   : 0
  Tx port-notification   : 0
  Rx FDB sync            : 0
  Tx FDB sync            : 0
  RX LACP manager        : 1
  TX LACP manager        : 0
```

(`switch (config)#`) (Optional) In case `MLAG-VIP` was configured, its functionality can be examined using `show mlag-vip` command.

```console
show mlag-vip
```

Example output if `MLAG-VIP` is configured (no output will appear if it is not configured):

```text
MLAG VIP
========
MLAG group name: my-mlag-group
MLAG VIP address: 10.234.23.254 /24
Active nodes: 2

Hostname             VIP-State            IP Address
----------------------------------------------------
Switch 1              master               10.234.23.1
Switch 2              standby              10.234.23.2
```

## Expected results

* Administrators can configure MCLAG.
* Administrators can create an MCLAG interface.
* Administrators can add ports to the MCLAG interface.
* The output of the `show` commands is correct.

[Back to Index](../README.md)
