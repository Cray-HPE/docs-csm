# Typical configuration of MLAG link connecting to NCN

The intent here is to show case very basic MLAG link configuration and your configuration may differ. This is what defines the LAG to be able to peer both to Spine-01 and Spine-02.

<table>

<td>
<pre>
interface mlag-port-channel 1
interface mlag-port-channel 1 mtu 9216 force
interface ethernet 1/1 mlag-channel-group 1 mode active
interface mlag-port-channel 1 switchport mode hybrid
interface mlag-port-channel 1
interface mlag-port-channel 1-11 lacp-individual enable force
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 2
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 4
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 7
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 10
</td>
</pre>

<td>
<pre>
interface mlag-port-channel 1
interface mlag-port-channel 1 mtu 9216 force
interface ethernet 1/1 mlag-channel-group 1 mode active
interface mlag-port-channel 1 switchport mode hybrid
interface mlag-port-channel 1
interface mlag-port-channel 1-11 lacp-individual enable force
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 2
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 4
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 7
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 10</td>
</pre>
</table>

[Back to Index](../index.md)

