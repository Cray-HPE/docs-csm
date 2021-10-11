# Typical edge port configuration that you would see with BMC, PDUs etc


The intent here is to show case a very basic configuration for devices that are single homed to the network, i.e. network ILO cards etc.



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

[Back to Index](/docs-csm/operations/network/network_management_install_guide/aruba/
index)
