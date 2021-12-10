
# Typical Edge Port Configuration

The following is a very basic configuration for devices that are single homed to the network. For instance, network ILO cards, BMCs, PDUs, and so on.

<table>

<td>
<pre>
Leaf-01
interface 1/1/47
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
</td>
</pre>

<td>
<pre>
Leaf-02
interface 1/1/47
    no shutdown
    mtu 9198
    description BMC
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
</td>
</pre>
</table>

[Back to Index](../index_aruba.md)
