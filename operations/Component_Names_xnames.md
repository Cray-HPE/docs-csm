# Component Names \(xnames\)

Component names \(xnames\) identify the geolocation for hardware components in the HPE Cray EX system. Every component is uniquely identified by these component names. Some, like the system cabinet number or the CDU number, can be changed by site needs. There is no geolocation encoded within the cabinet number, such as an X-Y coordinate system to relate to the floor layout of the cabinets. Other component names refer to the location within a cabinet and go down to the port on a card or switch or the socket holding a processor or a memory DIMM location.

|Name Pattern|Range|Description|
|------------|-----|-----------|
|s0|n/a|Wildcard: Specifies all of a given type of component in the system. Can be used for "all nodes", or to refer to the management system NCN cluster by a single logical name.|
|ncnN|N: 1-n|Non-compute Node \(NCN\): A management node in the management plane. Management NCNs are located in standard EIA racks.|
|all|n/a|Wildcard: Similar to s0 and can be used to specify all components in a system.|
|all\_comp|n/a|Wildcard: Specifies all compute nodes.|
|all\_svc|n/a|Wildcard: Specifies all service or management nodes.|
|pH.S|H: 0-n S: 0-n|Partition: A hardware or software partition \(hard or soft partition\). H specifies a hardware partition; HSN cabling, switches, and so on. The S specifies a software partition. A hard partition can have more than 1 soft partition. A soft partition cannot have more than 1 hard partition. Example: p1.2 is soft partition 2 of hard partition 1.|
|dD|D: 0-999|Coolant Distribution Unit \(CDU\): 1 CDU for up to 6 cabinets. Example: d3 \(CDU 3\).|
|dDwW|W: 0-31|Management Switch in a CDU: Example: d3w1 is switch 1 in CDU 3.|
|xX|X: 0-9999|Liquid-cooled Cabinet or Standard Rack: Liquid-cooled cabinets include 8 chassis and do not have a cabinet-level controller; only chassis-level controllers. A standard rack is always considered chassis 0. Examples: x3000 is rack number 3000.|
|xXdD|D: 0-1|Rack-mounted CDU: Example: x1000d0 is CDU 0 for cabinet 1000.|
|xXmM|M: 0-3|Rack PDU Controller \(BMC\): Controller or BMC for one or more rack PDUs. A primary PDU controller many manage other PDUs. Example: x3000m0 is PDU controller 0, cabinet 3000.|
|xXmMpP|P: 0-7|Rack PDU: managed by a controller. Example: x3000m0p0 is PDU 0, PDU controller 0, cabinet 3000.|
|xXmMpPjJ|J: 1-32|Rack PDU Outlet: Example: x3000m0p0j12 is power outlet 12 on PDU 0, PDU controller 0, rack 3000.|
|xXmMiI|I: 1-3|PDU NIC: The NIC associated with the PDU management controller, not a specific PDU. Example: x3000m0i1 is management NIC 1 of PDU controller 0, cabinet 3000.|
|xXm0pPvV|V: 1-64|PDU Power Connector: Power connectors are connected to node cards or enclosures and also control and monitor power. Example: x3000m0p0v32 is power plug/outlet 32 of cabinet PDU 0, under cab PDU controller 0, rack 3000.|
|xXeE|E: 0-1|CEC: There are Cabinet Environmental Controllers \(CEC\) per liquid-cooled cabinet. CEC 0 \(right\) and CEC 1 \(left\). Example: x1016e0 is the CEC on the right side of cabinet 1016.|
|xXcC|C: 0-7|Chassis: An enclosure within a liquid-cooled cabinet. Standard EIA racks are always considered a single chassis \(chassis 0\). This component name is used as a component group or prefix and not a single component. Example: x1016c3 is chassis 3 of cabinet 1016.|
|xXcCbB|B: 0|Chassis BMC: Liquid-cooled cabinet chassis management module \(CMM\) controller \(cC\). A standard EIA rack is always chassis 0. Example: x1016c4b0 is BMC 0 \(cC\) for chassis 4, cabinet 1016.|
|xXcCbBiI|I: 0|Chassis BMC NIC: CMM BMC Ethernet NIC. Example: x1000c1b0i0 is NIC 0 of BMC 0, chassis 1, cabinet 1000.|
|xXcCtT|T: 0-2|PSU: Power rectifier \(PSU\) in the a liquid-cooled chassis rectifier shelf. Three PSUs support a chassis \(n+1\). Example: x1016c3t2 is PSU 2 for chassis 3, cabinet 1016.|
|xXcCfF|F: 0|CMM FPGA: CMM FPGA. Example: x1016c1f0 is FPGA 0 in chassis 1 CMM, cabinet 1016.|
|xXcCwW|W: 1-48|Management Network Switch: Specifies bottom U-position for the switch. Example: x3000c0w47 is management switch in U47, chassis 0, rack 3000.|
|xXcCwWjJ|J: 1-32|Management Network Switch Connector: Cable connector \(port\) on a management switch. Example: x3000c0w47j31 is cable connector 31 of switch in U47, chassis 0, rack 3000.|
|xXcChH|H: 1-48|High-level Management Switch Enclosure: Typically spine switch. Example: x3000c0h47 is U47, chassis 0, in rack 3000.|
|xXcChHsS|S: 1-4|High-level Management Network Switch: Typically a spine switch. May be a half-width device specified with a rack U position H and a horizontal space number S. Horizontal space numbers are assigned arbitrarily to physical locations. Example: x3000c0h47s1 is space 1 of U47, chassis 0, rack 3000.|
|xXcCrR|R: 0-64|HSN Switch: Liquid-cooled blade switch slot number or ToR switch bottom U position. Switch blades are numbered 0-7 in a chassis. ToR HSN switches are numbered by bottom U position. Example: x1016c3r6 is switch blade 6 in chassis 3, cabinet 1016. Example: x3000c0r31 is ToR switch in U31, chassis 0, rack 3000.|
|xXcCrRaA|A: 0|HSN Switch ASIC: Example: x3000c0r1a0 is ASIC 0 of ToR switch in U1, chassis 0, of rack 3000. Example: x1016c3r7a0 \(ASIC 0 of liquid-cooled switch blade 7, chassis 3, cabinet 1016\).|
|xXcCrRaAlL|L: 0-N|HSN Switch ASIC Link: The decimal number for the maximum number of links is network-dependent. Example: x1016c0r1a0l25 is link 25 of ASIC 0, switch 1, chassis 0, cabinet 1016\).|
|xXcCrReE|E: 0|HSN Switch Submodule: Example: x3000c0r2e0 is HSN switch submodule of ToR switch 2, chassis 0, rack 3000.|
|xXcCrRbB|B: 0|HSN Switch Controller \(sC\) or BMC: A BMC or embedded controller of a switch blade. Example: x1000c3r4b0 is BMC 0 of switch 4, chassis 3, cabinet 1000. Example: x3000c0r1b0 is BMC 0 of ToR switch in U1, chassis 0, rack 3000.|
|xXcCrRbBiI|I: 0-3|HSN Switch Management NIC: Example: x1016c2r3b0i0 is NIC 0 of controller 0, switch 3, of chassis 2, cabinet 1016.|
|xXcCrRfF|F: 0|HSN Switch Card FPGA: Example: x1016c3r2f0 is FPGA 0 of blade switch 2, chassis 3, cabinet 1016.|
|xXcCrRtT|T: 0|ToR component in a ToR Switch. Example: x3000c0r1t0 ToR switch 0 in U1, chassis 0, cabinet 3000.|
|xXcCrRjJ|J: 1-32|HSN Switch Cable Connector: Example: x1016c3r4j7 is HSN connector 7 in, switch 4, chassis 3, cabinet 1016.|
|xXcCrRjJpP|P: 0-1|HSN Switch Cable Connector Port: Example: x1016c3r4j7p0 is port 0 of HSN connector 7, switch blade 4, chassis 3, cabinet 1016.|
|xXcCsS|S: 0-64|Node Slot or U Position: Liquid-cooled blades are numbered 0-7 in each chassis; a rack system U position specifies the bottom-most U number for the enclosure. An EIA rack is always chassis 0. Example: x1016c1s7 is compute blade 7 in chassis 1, cabinet 1016. Example: x3000c0s24 is node enclosure in U24, chassis 0, of rack 3000.|
|xXcCsSvV|V: 1-2|Power Connector for Rack Node Enclosure: Power connector for an air-cooled node enclosure/blade. There may be one or two power connectors per node. Example: x3000c0s4v1 is power connector 1, server in U4, chassis 0, rack 3000.|
|xXcCrRvV|V: 1-2|Power Connector for ToR HSN Switch: There may be one or two power connectors per ToR HSN switch. Example: x3000c0r4v1 is power connector 1 of ToR switch in U4, chassis 0, rack 3000.|
|xXcCsSbB|B: 0-1|Node Controller or BMC: Liquid-cooled compute blade node card controller \(nC\), or rack node card BMC. Example: x1016c3s1b0 \(node card 0 controller \(nC\) of compute blade 1, chassis 3, cabinet 1016\).|
|xXcCsSbBiI|I: 0-3|Node controller or BMC NIC: NIC associated with a node controller or BMC. Liquid-cooled nC NIC numbers start with 0. Standard rack node card BMC NICs are numbered according to the OEM hardware. Example: x1016c2s1b0i0 is NIC 0 of node card 0 controller \(nC\), compute blade in slot 1, chassis 3, cabinet 16. Example: x3000c0s24b1i1 is NIC 1 of BMC 1, compute node in rack U-position 24, chassis 0, cabinet 3000.|
|xXcCsSbBnN|N: 0-7|Node: Liquid-cooled node or rack server node. Nodes are numbered 0-N and are children of the parent node controller or BMC. Node names have a bB component which specifies the node controller or BMC number. Component names can support one BMC for several nodes, multiple BMCs for one node, or one BMC per node. Example: x1016c2s3b0n1 is node 1 of node card 0, compute blade in slot 3, chassis 2, cabinet 1016.|
|xXcCsSeE|E: 0|Node Enclosure: Liquid-cooled nodes are located on a node card which includes node card controller \(nC\). The node card is considered an enclosure. There may be 1 or more node cards in a rack system server or liquid-cooled blade. Rack node enclosures can include multiple subslots inside of a multi-U enclosure. Example: x3000c0s16e0 is node enclosure 0, at U16, chassis 0, cabinet 3000.|
|xXcCsSbBnNpPx|P: 0-3|Node Processor Socket: Example: x1016c2s3b0n1p1 is processor socket 1 of node 1, of node card 0, compute blade in slot 3, chassis 2, cabinet 1016.|
|xXcCsSbBnNdD|D: 0-15|Node DIMM Example: x1016c3s0b0n1d3 is DIMM 3 of node 1, node card 0, compute blade 0, chassis 3, cabinet 1016\).|
|xXcCsSbBnNhH|H: 0-3|Node HSN NIC: Example: x1016c3s0b0n1h1 is HSN NIC 1, node 1, node card 0, compute blade in slot 0, chassis 3, cabinet 1016.|
|xXcCsSbBnNiI|I: 1-3|Node Management NIC: Example: x1016c3s0b0n1i1 is node management NIC 1 of node 1, node card 0, compute blade in slot 0, chassis 3, of cabinet 1016.|
|xXcCsSbBfF|F: 0-7|Node Controller FPGA: Node card controller FPGA \(FPGA\). Example: x16c3s4b1f0 is FPGA 0 of node card 1, compute blade in slot 4, chassis 3, cabinet 1016.|
|xXcCsSbBnNaA|A: 0-7|GPU: Accelerator \(GPU\) associated with a node. Example: x16c3s0b1n0a1 is accelerator 1, node 0, of node card 1, compute blade 0, of chassis 3, of cabinet 1016.|
|xXcCsSbBnNgG|G: 0-63|Storage Group or Group of Disk Drives for a Node: Example: x1016c3s0b0n1g3 is storage group 3 of node 1, node card 0, compute blade in slot 0, chassis 3, cabinet 1016.|
|xXcCsSbBnNgGkK|K: 0-63|Storage Group Disk: Example: x1016c3s0b0n1g3k1 is disk 1 of storage group 3, node 1, node card 0, of compute blade in slot 0, chassis 3, cabinet 1016.|

