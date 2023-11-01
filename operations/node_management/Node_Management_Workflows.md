# Node Management Workflows

The following workflows are intended to be high-level overviews of node management tasks. These workflows depict how services interact with each other during node management and help to provide a quicker and deeper understanding of how the system functions.

The workflows and procedures in this section include:

- [Add Nodes](#add-nodes)
- [Remove Nodes](#remove-nodes)
- [Replace Nodes](#replace-nodes)
- [Move Nodes](#move-nodes)

## Add Nodes

- [Add a Standard Rack Node](Add_a_Standard_Rack_Node.md)
- [Adding a Liquid-cooled Blade to a System](Adding_a_Liquid-cooled_blade_to_a_System.md)

**Use Cases:** Administrator permanently adds select compute nodes to expand the system.

**Components:** This workflow is based on the interaction of the System Layout Service \(SLS\) with other hardware management services \(HMS\).

Mentioned in this workflow:

- System Layout Service \(SLS\) serves as a "single source of truth" for the system design. It details the physical locations of network hardware, compute nodes and cabinets. Further, it stores information about the network, such as which port on which
  switch should be connected to each compute node.
- Hardware State Manager \(HSM\) monitors and interrogates hardware components in an HPE Cray EX system, tracking hardware state and inventory information, and making it available via REST queries and message bus events when changes occur.
- HMS Notification Fanout Daemon \(HMNFD\) receives component state change notifications from the HSM. It fans notifications out to subscribers \(typically compute nodes\).
- Endpoint Discovery Service \(HMS Discovery/MEDS\) manages initial discovery, configuration, and geolocation of Redfish-enabled BMCs. It periodically makes Redfish requests to determine if hardware is present or missing.
- Heartbeat Tracker Service \(HBTD\) listens for heartbeats from components \(mainly compute nodes\). It tracks changes in heartbeats and conveys changes to HSM.

![Add Node Workflow](../../img/operations/add-node.gif)

**Workflow Overview:** The following sequence of steps occur during this workflow.

1. **Administrator updates SLS**

    Administrator creates a new hardware entry for the select component names (xnames) in SLS. Enter the node component names (xnames) in the SLS input file.

1. **Administrator adds compute nodes**

    The Administrator physically adds select compute nodes and powers them on. Because the nodes are unknown, the DHCP and TFTP servers give it the special initialization ram disk. The compute nodes performs local configuration.

    The following steps \(3-11\) occur automatically as different APIs interact with each other.

1. **HMS Discovery/MEDS to SLS and HSM**

    For Cray EX hardware:
    1. MEDS reaches out to SLS for Mountain/Hill Chassis that exist in the system.
    1. Calculate Algorithmic MAC address for each possible controller (Chassis Controller, Node Controller, and Switch controller) in the chassis based off the devices xname.
    1. Create Ethernet Interface in HSM for each possible controller.

        For example, MEDS would create the following Ethernet Interface in HSM for the node controller `x1000c0s0b0`:

        ```bash
        cray hsm inventory ethernetInterfaces list --component-id x1000c0s0b0 --format json
        ```

        Example output:

        ```toml
        [[results]]
        ID = "0203e8003000"
        Description = ""
        MACAddress = "02:03:e8:00:30:00"
        LastUpdate = "2022-08-22T12:34:36.1641742Z"
        ComponentID = "x1000c0s0b0"
        Type = "NodeBMC"
        [[results.IPAddresses]]
        IPAddress = ""
        ```

    1. Controller requests an IP address from KEA via DHCP, and KEA's DHCP helper will update the ethernet interface in HSM with a IP Address:

        For example, KEA's DHCP helper will update the node controller `x1000c0s0b0` ethernet interface in HSM a IP:

        ```bash
        cray hsm inventory ethernetInterfaces list --component-id x1000c0s0b0 --format json
        ```

        Example output:

        ```toml
        [[results]]
        ID = "0203e8003000"
        Description = ""
        MACAddress = "02:03:e8:00:30:00"
        LastUpdate = "2022-08-23T14:50:07.188282Z"
        ComponentID = "x1000c0s0b0"
        Type = "NodeBMC"
        [[results.IPAddresses]]
        IPAddress = "10.104.0.19"
        ```

    1. For all possible controllers MEDS is performing a GET request for their Redfish root (`https://x1000c0s0b0/redfish/v1`). Once a 200 status code is received MEDS will configure NTP on the controller.

    For standard 19 inch rack hardware:
    1. HMS Discovery retrieves all Ethernet Interfaces from HSM without a Component ID set.
    1. HMS Discovery queries SLS for MgmtSwith (`sw-leaf-bmc-XXX`) switches present in the system.
    1. HMS Discovery retrieves the MAC address table from each MgmtSwitch via SNMP.
    1. For each Ethernet Interface without a Component ID set:
        1. Search through the retried MAC address tables to identify which switch port the MAC address is connected to.
        1. Query SLS for a corresponding MgmtSwitchConnector to identify what is connected to the switch port.

            For example, determine what node controller is connected to port 35 on leaf-bmc switch x3000c0w35:

            ```bash
            cray sls hardware describe x3000c0w22j35
            ```

            Example output:

            ```toml
            Parent = "x3000c0w22"
            Xname = "x3000c0w22j35"
            Type = "comptype_mgmt_switch_connector"
            Class = "River"
            TypeString = "MgmtSwitchConnector"
            LastUpdated = 1689284887
            LastUpdatedTime = "2023-07-13 21:48:07.146163 +0000 +0000"

            [ExtraProperties]
            NodeNics = [ "x3000c0s19b3",]
            VendorName = "ethernet1/1/35"
            ```

            The node controller x3000c0s19b3 is connected to switch port 35 on switch x3000c0w35.

1. **HMS Discovery/MEDS to HSM**

    Discovery services update HSM about the new Redfish endpoint for the node. Details like component name (xname) and credentials.

1. **HSM to SLS**

    HSM queries SLS for NID and role assignments for the new node.

1. **SLS to HSM**

    HSM updates the node map based on information received from SLS.

1. **Node to KEA**

    Node requests a Node Management Network (NMN) IP via DHCP when it boots.

1. **KEA to HSM**

    KEA's DHCP helper updates the nodes MAC address in HSM Ethernet Interfaces.

1. **Node to Heartbeat Tracker Service**

    The Heartbeat Tracker Service receives heartbeats from the new compute node after the node is powered on.

1. **Heartbeat Tracker Service to HSM**

    The Heartbeat Tracker Service report the heartbeat status to HSM.

1. **HSM to HMNFD**

    HSM sends the new compute node state information with State as ON to HMNFD. HMNFD fans out these notifications to the subscribing compute nodes.

### Remove Nodes

**Use Cases:** Administrator permanently removes select compute nodes to contract the system.

**Components:** This workflow is based on the interaction of the System Layout Service \(SLS\) with other hardware management services \(HMS\).

Mentioned in this workflow:

- System Layout Service \(SLS\) serves as a "single source of truth" for the system design. It details the physical locations of network hardware, compute nodes and cabinets. Further, it stores information about the network, such as which port on which
  switch should be connected to each compute node.
- Hardware State Manager \(HSM\) monitors and interrogates hardware components in an HPE Cray EX system, tracking hardware state and inventory information, and making it available via REST queries and message bus events when changes occur.
- HMS Notification Fanout Daemon \(HMNFD\) receives component state change notifications from the HSM. It fans notifications out to subscribers \(typically compute nodes\).
- Endpoint Discovery Service \(HMS Discovery/MEDS\) manages initial discovery, configuration, and geolocation of Redfish-enabled BMCs. It periodically makes Redfish requests to determine if hardware is present or missing.
- Heartbeat Tracker Service \(HBTD\) listens for heartbeats from components \(mainly compute nodes\). It tracks changes in heartbeats and conveys changes to HSM.

![Remove Node Workflows](../../img/operations/remove-nodes.gif)

**Workflow Overview:** The following sequence of steps occur during this workflow.

1. **Administrator updates SLS**

    Administrator deletes the node entries with the specific component name (xname) from SLS. Note that if deleting a parent object, then the children are also deleted from SLS. If the child object happens to be a parent, then the deletion can cascade
    down levels. If deleting a child object, it does not affect the parent.

1. **Administrator physically removes the compute nodes**

    The Administrator powers off and physically removes the compute nodes.

    The following steps \(3-9\) occur automatically as different APIs interact with each other.

1. **No heartbeats**

    The Heartbeat Tracker Service stops receiving heartbeats and marks the nodes status as `standby` and then `off` as per Redfish event.

    `Standby` status implies that the node is no longer ready and presumed dead. It typically means that the heartbeat is lost. `Off` status implies that the location is not populated with a component.

1. **Administrator to HSM**

    Administrator update HSM that the BMC Redfish endpoints for the nodes were removed by marking it disabled. HSM marks the state of BMCs and the nodes as `empty`.

    `Empty` state implies that the location is not populated with a component.

1. **HSM to HMNFD**

    HSM sends the compute node state information with State as `empty` to HMNFD. HMNFD fans out this notification to the subscribing compute nodes.

1. **Administrator to HSM**

    The following information from HSM is removed:
    1. Redfish Endpoint is deleted.
    2. Corresponding Components are deleted/
    3. Ethernet Interfaces are removed.

### Replace Nodes

- [Replace a Compute Blade](Replace_a_Compute_Blade.md)
- [Swap a Compute Blade with a Different System](Swap_a_Compute_Blade_with_a_Different_System.md)

### Move Nodes

- [Move a Standard Rack Node](Move_a_Standard_Rack_Node.md)
- [Move a Standard Rack Node \(Same HSN Ports\)](Move_a_Standard_Rack_Node_SameRack_SameHSNPorts.md)
