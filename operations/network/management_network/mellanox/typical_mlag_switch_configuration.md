# Typical configuration of MLAG between switches

The intent here is to show case very basic mlag configuration between two spine switches.

<table>

<td>
<pre>
mlag-vip cray-mlag-domain ip 192.168.255.242 /29 force
no mlag shutdown
mlag system-mac 00:00:5E:00:01:01
interface port-channel 100 ipl 1
interface vlan 4000 ipl 1 peer-address 192.168.255.253
</td>
</pre>

<td>
<pre>
mlag-vip cray-mlag-domain ip 192.168.255.242 /29 force
no mlag shutdown
mlag system-mac 00:00:5E:00:01:5D
interface port-channel 100 ipl 1
interface vlan 4000 ipl 1 peer-address 192.168.255.254
</td>
</pre>
</table>

[Back to Index](../index.md)
