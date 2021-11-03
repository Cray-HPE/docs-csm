# Validate Management Network Cabling

This page is designed to be a guide on how all nodes in a Shasta system are wired to the management network.

The Shasta Cabling Diagram (SHCD) for this system describes how the cables connect the nodes to the management network switches
and the connections between the different types of management network switches.
Having SHCD data which matches how the physical system is cabled will be needed later when preparing the `hmn_connections.json`
file from the SHCD as part of [Prepare Configuration Payload](index.md#prepare_configuration_payload) procedure and later when
doing the [Configure Management Network Switches](index.md#configure_management_network) procedure.

- Open the SHCD
- Look at the `Device Diagrams` Tab.
   - There you will see what type of hardware is on the system.
   - Take note of the hardware.
- Look at the `25G_10G` or `40G_10G` tab, this will depend on the SHCD.
   - Look at this part of the page. The source is either a node or a switch. The destination is usually a switch.
     The `source label info` and `destination label info` indicate the component name (xname) and the port on that component to which
     the cable is connected. For example, `x3000u01s1-j1`, means the device in cabinet x3000 at location u01 within the cabinet and in slot s1 with port j1.
     The physical cable connecting source to destination should be labelled with `source label info` and `destination label info`.

     See [Component Names (xnames)](../operations/Component_Names_xnames.md).


      | Source | Source Label Info | Destination Label Info | Destination |
      | --- | --- | ---| --- |
      | mn01 | x3000u01s1-j1 | x3000u24L-j1 | sw-25g01 |
      | mn01 | x3000u01s1-j2 | x3000u24R-j1 | sw-25g02 |
      | mn02 | x3000u03s1-j1 | x3000u24L-j2 | sw-25g01 |
      | mn02 | x3000u03s1-j2 | x3000u24R-j2 | sw-25g02 |
      | mn03 | x3000u05s1-j1 | x3000u24L-j3 | sw-25g01 |
      | mn03 | x3000u05s1-j2 | x3000u24R-j3 | sw-25g02 |
      | wn01 | x3000u07s1-j1 | x3000u24L-j4 | sw-25g01 |
      | wn01 | x3000u07s1-j2 | x3000u24R-j4 | sw-25g02 |
      | wn02 | x3000u09s1-j1 | x3000u24L-j5 | sw-25g01 |
      | wn02 | x3000u09s1-j2 | x3000u24R-j5 | sw-25g02 |
      | wn03 | x3000u011s1-j1 | x3000u24L-j6 | sw-25g01 |
      | wn03 | x3000u011s1-j2 | x3000u24R-j6 | sw-25g02 |
      | sn01 | x3000u013s1-j1 | x3000u24L-j7 | sw-25g01 |
      | sn01 | x3000u013s1-j2 | x3000u24R-j7 | sw-25g02 |
      | sn02 | x3000u015s1-j1 | x3000u24L-j8 | sw-25g01 |
      | sn02 | x3000u015s1-j2 | x3000u24R-j8 | sw-25g02 |
      | sn03 | x3000u017s1-j1 | x3000u24L-j9 | sw-25g01 |
      | sn03 | x3000u017s1-j2 | x3000u24R-j9 | sw-25g02 |
      | uan01 | x3000u027s1-j1 | x3000u24L-j10 | sw-25g01 |
      | uan01 | x3000u027s1-j2 | x3000u24R-j10 | sw-25g02 |
      | uan02 | x3000u029s1-j1 | x3000u24L-j13 | sw-25g01 |
      | uan02 | x3000u029s1-j2 | x3000u24R-j13 | sw-25g02 |
      | uan03 | x3000u031s1-j1 | x3000u24L-j14 | sw-25g01 |
      | uan03 | x3000u031s1-j2 | x3000u24R-j14 | sw-25g02 |

    - Based on the vendor of the nodes and the name in the first column, determine how it is supposed to be cabled.
    - We can use `mn01` as an example. This is a master node, and in the `device diagrams` tab it is identified as an HPE DL325 node.
    - Once you have those two pieces of information you can use the [Cable Management Network Servers](cable_management_network_servers.md) for all nodes listed on the SHCD.
      - UANs and Application Nodes
      - Worker nodes
      - Master nodes
      - Storage nodes

## Checklist

| Hardware Type | Step      | Complete?     |
| ----------- | ----------- | ------------- |
| UAN/Application Node         |             |               |
|             | Open the SHCD from the system. |             |
|             | Go to the `Device Diagrams` tab, take note of the type of hardware on the system.        |          |
|             | Depending on the hardware, open either the **25G_10G** tab or the **40G_10G** tab. |        |
|             | Locate the nodes prefixed with `uan` or another prefix for application node. |        |
|             | Based on the vendor of the node and the name in the first column, determine how it is supposed to be cabled.  |         |
|             | Check cabling against the [Cable Management Network Servers](cable_management_network_servers.md). If it is cabled incorrectly, contact the team in charge of cabling and request a change.             |               |
| NCN-Master         |             |               |
|             | Open the SHCD from the system. |             |
|             | Go to the `Device Diagrams` tab, take note of the type of hardware on the system.        |          |
|             | Depending on the hardware, open either the **25G_10G** tab or the **40G_10G** tab. |        |
|             | Locate the nodes named `mnxx`. |        |
|             | Based on the vendor of the node and the name in the first column, determine how it is supposed to be cabled.  |         |
|             | Check cabling against the [Cable Management Network Servers](cable_management_network_servers.md). If it is cabled incorrectly, contact the team in charge of cabling and request a change.             |               |
| NCN-Worker         |             |               |
|             | Open the SHCD from the system. |             |
|             | Go to the `Device Diagrams` tab, take note of the type of hardware on the system.        |          |
|             | Depending on the hardware, open either the **25G_10G** tab or the **40G_10G** tab. |        |
|             | Locate the nodes named `wnxx`. |        |
|             | Based on the vendor of the node and the name in the first column, determine how it is supposed to be cabled.  |         |
|             | Check cabling against the [Cable Management Network Servers](cable_management_network_servers.md). If it is cabled incorrectly, contact the team in charge of cabling and request a change.             |               |
| NCN-Storage         |             |               |
|             | Open the SHCD from the system |             |
|             | Go to the `Device Diagrams` tab, take note of the type of hardware on the system.        |          |
|             | Depending on the hardware, open either the **25G_10G** tab or the **40G_10G** tab. |        |
|             | Locate the nodes named `snxx`. |        |
|             | Based on the vendor of the node and the name in the first column, determine how it is supposed to be cabled.  |         |
|             | Check cabling against the [Cable Management Network Servers](cable_management_network_servers.md). If it is cabled incorrectly, contact the team in charge of cabling and request a change.             |               |


