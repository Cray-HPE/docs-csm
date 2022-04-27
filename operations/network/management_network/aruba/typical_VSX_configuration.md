# Typical Configuration of VSX

The following is a very basic VSX configuration between two spine switches. Do note that the inter-switch-link (ISL) between the two spine switches is configured as regular lag, not a multi-chassis lag like a connected server would.

<table>

<td>
<pre>
Spine-01
vrf keepalive

interface lag 254
    no shutdown
    description ISL link
    no routing
    vlan trunk native 1 tag
    vlan trunk allowed all
    lacp mode active

interface 1/1/51
    no shutdown
    mtu 9198
    lag 254
interface 1/1/52
    no shutdown
    mtu 9198
    lag 254

vsx
    system-mac 02:01:00:00:01:00
    inter-switch-link lag 254
    role primary
    keepalive peer 192.168.255.1 source 192.168.255.0 vrf keepalive
    linkup-delay-timer 600
    vsx-sync vsx-global

interface 1/1/47
    no shutdown
    mtu 9198
    vrf attach keepalive
    description VSX keepalive
    ip address 192.168.255.0/31
</td>
</pre>

<td>
<pre>
Spine-02
vrf keepalive


interface lag 254
    no shutdown
    description ISL link
    no routing
    vlan trunk native 1 tag
    vlan trunk allowed all
    lacp mode active

interface 1/1/51
    no shutdown
    mtu 9198
    lag 254
interface 1/1/52
    no shutdown
    mtu 9198
    lag 254

vsx
    system-mac 02:01:00:00:01:00
    inter-switch-link lag 254
    role secondary
    keepalive peer 192.168.255.0 source 192.168.255.1 vrf keepalive
    linkup-delay-timer 600
    vsx-sync vsx-global

interface 1/1/47
    no shutdown
    mtu 9198
    vrf attach keepalive
    description VSX keepalive
    ip address 192.168.255.1/31
</td>
</pre>
</table>

[Back to Index](../index.md)