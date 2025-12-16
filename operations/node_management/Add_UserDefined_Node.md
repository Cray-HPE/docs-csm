# Add a User-Defined Node to the System

This procedure adds a user-defined node to the HPE Cray System Management (CSM) infrastructure. This is intended for custom node types that need to be integrated into the system with similar network configuration as Non-Compute Nodes (NCNs).

**IMPORTANT**: This procedure is for adding nodes with no configuration changes to CSM. The node will be added to SLS with `Application/UserDefined` role and subrole.

## Prerequisites

- The Cray command line interface (CLI) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
- CANU (CSM Automated Network Utility) is installed.
- Node hardware is physically installed and cabled to the management network switches.
- BMC is connected to a leaf-BMC switch port.
- Node information questionnaire is completed. See [Add User-Defined Node Questionnaire](Add_UserDefined_Node_Questionnaire.md).
- System Layout Service (SLS) has been backed up. See [Create a Backup of the SLS Postgres Database](../system_layout_service/Create_a_Backup_of_the_SLS_Postgres_Database.md).
- The management network is configured and operational.
- Knowledge of the node's network interface card (NIC) configuration.

## Procedure

This procedure consists of three main steps:

1. [Add the node to SLS](#step-1-add-node-to-sls)
2. [Generate and apply network switch configuration](#step-2-generate-and-apply-switch-configuration)
3. [Configure networking on the node](#step-3-configure-node-networking)

### Step 1: Add Node to SLS

#### 1.1: Set Environment Variables

1. (`ncn-mw#`) Set environment variables for the node information.

   Replace the example values with the information from your completed questionnaire.

   ```bash
   NODE_XNAME=x3000c0s25b0n0
   NODE_ALIAS=special-node-01
   BMC_XNAME=x3000c0s25b0
   MGMT_SWITCH_CONNECTOR_XNAME=x3000c0w14j36
   SWITCH_PORT_VENDOR_NAME="1/1/36"  # Aruba format: 1/1/<port_number>
   ```

#### 1.2: Verify or Create Custom HSM Role and SubRole (Optional)

The Hardware State Manager (HSM) maintains a list of valid roles and subroles. By default, this procedure uses the `Application` role with the `UserDefined` subrole. However, if you want to use different custom role or subrole names, you must add them to HSM first.

1. (`ncn-mw#`) Check the current list of valid roles and subroles in HSM.

   ```bash
   cray hsm service values role list --format toml
   cray hsm service values subrole list --format toml
   ```

   Expected output:

   ```toml
   Role = [ "Compute", "System", "Application", "Storage", "Management",]
   SubRole = [ "Visualization", "UserDefined", "Master", "Worker", "Storage", "UAN", "Gateway", "LNETRouter",]
   ```

2. (`ncn-mw#`) If you are using the default `Application` role and `UserDefined` subrole, skip to [Create Node Object in SLS](#13-create-node-object-in-sls).

3. (`ncn-mw#`) To add a custom role or subrole, follow the procedure in [Add Custom Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md#add-custom-roles-and-subroles).

   **Example: Adding a custom role:**

   ```bash
   # Get current roles
   CURRENT_ROLES=$(cray hsm service values role list --format json | jq -r '.Role | join(",")')
   
   # Add new custom role
   NEW_ROLE="CustomRole"
   cray hsm service values role update --role "${CURRENT_ROLES},${NEW_ROLE}"
   
   # Verify the new role was added
   cray hsm service values role list --format toml
   ```

   **Example: Adding a custom subrole:**

   ```bash
   # Get current subroles
   CURRENT_SUBROLES=$(cray hsm service values subrole list --format json | jq -r '.SubRole | join(",")')
   
   # Add new custom subrole
   NEW_SUBROLE="CustomApp"
   cray hsm service values subrole update --subrole "${CURRENT_SUBROLES},${NEW_SUBROLE}"
   
   # Verify the new subrole was added
   cray hsm service values subrole list --format toml
   ```

   **IMPORTANT**: When adding custom roles or subroles to HSM, you must also update the corresponding configmap to ensure the custom values persist across HSM pod restarts. The configmap `cray-hms-hmcollector-ingress-config` contains the role and subrole definitions. Refer to the [Add Custom Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md#add-custom-roles-and-subroles) procedure for complete instructions on updating the configmap.

4. Once custom roles or subroles are added to HSM, set the environment variables for your configuration:

   ```bash
   # For custom role and subrole
   NODE_ROLE="CustomRole"
   NODE_SUBROLE="CustomApp"
   
   # Or use the defaults
   NODE_ROLE="Application"
   NODE_SUBROLE="UserDefined"
   ```

#### 1.3: Create Node Object in SLS

1. (`ncn-mw#`) Create the extra properties JSON for the node.

   ```bash
   # Set role and subrole (use custom values or defaults)
   NODE_ROLE="Application"
   NODE_SUBROLE="UserDefined"
   
   jq -n --arg ALIAS "${NODE_ALIAS}" --arg ROLE "${NODE_ROLE}" --arg SUBROLE "${NODE_SUBROLE}" '{
       Aliases:[$ALIAS],
       Role: $ROLE,
       SubRole: $SUBROLE
   }' | tee node_extraproperties.json
   ```

   Expected output:

   ```json
   {
     "Aliases": [
       "special-node-01"
     ],
     "Role": "Application",
     "SubRole": "UserDefined"
   }
   ```

2. (`ncn-mw#`) Create the new node object in SLS.

   ```bash
   cray sls hardware create --xname "${NODE_XNAME}" --class River --extra-properties "$(cat node_extraproperties.json)"
   ```

3. (`ncn-mw#`) Verify the node was created.

   ```bash
   cray sls hardware describe "${NODE_XNAME}" --format json
   ```

   Expected output should show the node with the correct xname, role, and subrole.

#### 1.4: Create BMC MgmtSwitchConnector Object in SLS

The `MgmtSwitchConnector` object is used by the `hms-discovery` job to determine which management switch port is connected to the node's BMC.

1. (`ncn-mw#`) Create the extra properties JSON for the management switch connector.

   ```bash
   jq -n --arg BMC_XNAME "${BMC_XNAME}" --arg VENDOR_NAME "${SWITCH_PORT_VENDOR_NAME}" '{
       NodeNics: [$BMC_XNAME],
       VendorName: $VENDOR_NAME
   }' | tee mgmt_switch_connector_extraproperties.json
   ```

   Expected output:

   ```json
   {
     "NodeNics": [
       "x3000c0s25b0"
     ],
     "VendorName": "1/1/36"
   }
   ```

2. (`ncn-mw#`) Create the management switch connector object in SLS.

   ```bash
   cray sls hardware create --xname "${MGMT_SWITCH_CONNECTOR_XNAME}" --class River --extra-properties "$(cat mgmt_switch_connector_extraproperties.json)"
   ```

3. (`ncn-mw#`) Verify the connector was created.

   ```bash
   cray sls hardware describe "${MGMT_SWITCH_CONNECTOR_XNAME}" --format json
   ```

#### 1.5: Allocate CMN IP Address in SLS (If CMN Access Required)

**IMPORTANT**: The Customer Management Network (CMN) does not have a DHCP service enabled. If your node requires access to the CMN, an IP address from this network must be assigned manually in SLS before configuring the node.

For the NMN and HMN networks, the node will automatically obtain IP addresses via DHCP. Do not manually allocate IP reservations for these networks in SLS, as adjusting the DHCPStart and DHCPEnd ranges can impact existing devices.

**Skip this section if the node does not require CMN access.**

1. (`ncn-mw#`) Dump the current SLS state.

   ```bash
   cray sls dumpstate list --format json > sls_dump.json
   cp -v sls_dump.json sls_dump.original.json
   ```

2. (`ncn-mw#`) Edit the `sls_dump.json` file to add a CMN IP reservation.

   This requires manual editing of the JSON file to add an IP reservation in the CMN network definition. Locate the CMN network section and add an entry to the IPReservations array within the appropriate subnet.

   Example CMN IP reservation to add:

   ```json
   {
     "Name": "special-node-01",
     "IPAddress": "10.102.3.100",
     "Comment": "x3000c0s25b0n0"
   }
   ```

   The IP reservation should be added to: `Networks -> CMN -> ExtraProperties -> Subnets -> bootstrap_dhcp -> IPReservations`

   **Note**: Choose an available IP address from the CMN subnet that is not already reserved. Consult your site's IP allocation plan.

3. (`ncn-mw#`) Record the CMN IP address for later use in node configuration.

   ```bash
   export CMN_IP="10.102.3.100"
   export CMN_SUBNET_MASK="/25"  # Adjust to your CMN subnet mask
   ```

4. (`ncn-mw#`) Reload SLS with the updated configuration.

   ```bash
   cray sls loadstate create sls_dump.json
   ```

5. (`ncn-mw#`) Verify the CMN IP reservation was added.

   ```bash
   cray sls networks describe CMN --format json | jq '.ExtraProperties.Subnets[] | select(.Name=="bootstrap_dhcp") | .IPReservations[] | select(.Name=="'${NODE_ALIAS}'")'
   ```

### Step 2: Generate and Apply Switch Configuration

This step uses CANU to generate switch configuration that includes the new node, treating it with the same network configuration as an NCN.

#### 2.1: Prepare CANU Custom Configuration (if needed)

If your site has custom network configurations (such as site interconnects, custom VLANs, or specific port configurations), create a CANU custom configuration file.

##### Configuration Options

There are two primary configuration scenarios for user-defined nodes:

1. **Bonded Interface Configuration** - Node uses two NICs in a LAG (Link Aggregation Group) connected to spine switches (recommended for redundancy)
2. **Single Port Configuration** - Node uses a single NIC connected to a leaf-BMC switch (simpler but no redundancy)

##### Option 1: Bonded Interface Configuration (Spine Switches)

This configuration provides redundancy by bonding two interfaces across spine switches, similar to NCN networking.

1. (`ncn-mw#`) Create a custom configuration file for spine switch LAG configuration.

   Example custom configuration file `custom_config.yaml` for bonded interfaces:

   ```yaml
   sw-spine-001:  |
       interface lag 24 
           description sms01
           no shutdown
           no routing
           vlan trunk native 1
           vlan trunk allowed 2,4,7
           lacp mode active
           spanning-tree bpdu-guard
           spanning-tree port-type admin-edge
       interface 1/1/24
           no shutdown
           mtu 9198
           description to_sms01-ocp2
           lag 24
   
   sw-spine-002:  |
       interface lag 24 
           description sms01
           no shutdown
           no routing
           vlan trunk native 1
           vlan trunk allowed 2,4,7
           lacp mode active
           spanning-tree bpdu-guard
           spanning-tree port-type admin-edge
       interface 1/1/24
           no shutdown
           mtu 9198
           description to_sms01-ocp2
           lag 24
   ```

   **Configuration Details:**
   - **LAG 24**: Link Aggregation Group number (adjust as needed for your environment)
   - **VLAN trunk allowed 2,4,7**: Adjust VLAN IDs based on your network design:
     - VLAN 2: NMN (Node Management Network)
     - VLAN 4: HMN (Hardware Management Network)
     - VLAN 7: CMN (Customer Management Network) if needed
   - **mtu 9198**: Jumbo frames for management network (9000 for bond, 9198 for switch port overhead)
   - **lacp mode active**: Active LACP for bonding
   - **Interface 1/1/24**: Physical port on spine switch (adjust to your actual port)

##### Option 2: Single Port Configuration (Leaf-BMC Switch)

This configuration connects the node via a single interface to a leaf-BMC switch.

1. (`ncn-mw#`) Create a custom configuration file for leaf-BMC switch port configuration.

   Example custom configuration file `custom_config.yaml` for single port:

   ```yaml
   sw-leaf-bmc-001:  |
       interface 1/1/39
           description to_sms01
           no shutdown
           mtu 9198
           no routing
           vlan access 4
           spanning-tree bpdu-guard
           spanning-tree port-type admin-edge
   ```

   **Configuration Details:**
   - **Interface 1/1/39**: Physical port on leaf-BMC switch (adjust to your actual port)
   - **vlan access 4**: Access mode with VLAN 4 (HMN) - adjust if using different VLAN
   - **mtu 9198**: Jumbo frames for management network
   - **no routing**: Layer 2 switching only
   - **spanning-tree bpdu-guard**: Prevents switching loops

##### Choosing the Right Configuration

**Use Bonded Interface Configuration when:**
- High availability is required
- Node is critical to system operation
- Following NCN networking standards
- Two NICs are available on the node

**Use Single Port Configuration when:**
- Node has limited hardware (single NIC)
- Simplicity is preferred over redundancy
- Node is not critical to system operation
- BMC-only management is sufficient

   For more information on CANU custom configurations, see [Generate Switch Configs Including Custom Configurations](../network/management_network/canu/custom_config.md).

#### 2.2: Generate Switch Configuration with CANU

1. (`ncn-mw#`) Set environment variables for CANU configuration generation.

   ```bash
   CSM_VERSION="1.7"  # Adjust to your CSM version
   ARCHITECTURE="full"  # Options: full, tds, v1
   CCJ_FILE="/path/to/system_ccj.json"  # Path to your system's CCJ file
   ```

   **Note**: The CCJ (CANU Custom JSON) file contains system-specific switch and port mapping information derived from your SHCD (Shasta Cabling Diagram). To generate or validate your CCJ file, consult the [CANU documentation for validating SHCD](https://cray-hpe.github.io/canu/). The CCJ file is required for CANU to generate accurate switch configurations for your specific hardware layout.

2. (`ncn-mw#`) Generate switch configurations for the network.

   **Without custom configuration:**

   ```bash
   canu generate network config \
       --csm ${CSM_VERSION} \
       -a ${ARCHITECTURE} \
       --ccj-file ${CCJ_FILE} \
       --sls-file sls_dump.json \
       --folder generated_switch_configs
   ```

   **With custom configuration:**

   ```bash
   canu generate network config \
       --csm ${CSM_VERSION} \
       -a ${ARCHITECTURE} \
       --ccj-file ${CCJ_FILE} \
       --sls-file sls_dump.json \
       --custom-config custom_config.yaml \
       --folder generated_switch_configs
   ```

   Expected output:

   ```text
   sw-spine-001 Config Generated
   sw-spine-002 Config Generated
   sw-leaf-001 Config Generated
   sw-leaf-002 Config Generated
   sw-leaf-bmc-001 Config Generated
   ```

#### 2.3: Review Generated Switch Configurations

1. (`ncn-mw#`) Review the generated switch configurations to verify the new node is included.

   ```bash
   ls -la generated_switch_configs/
   ```

2. (`ncn-mw#`) Check the switch configuration for the new node's port(s).

   **For bonded interface configuration (spine switches):**

   ```bash
   # Check spine switch configurations for LAG
   grep -A 15 "lag 24" generated_switch_configs/sw-spine-*.cfg
   ```

   Expected output should include:
   - LAG interface configuration with VLAN trunk settings
   - Physical port assignment to LAG
   - LACP mode active
   - Proper MTU (9198)

   **For single port configuration (leaf-BMC switch):**

   ```bash
   grep -A 10 "${SWITCH_PORT_VENDOR_NAME}" generated_switch_configs/sw-leaf-bmc-*.cfg
   ```

   Expected output should include:
   - Port description
   - VLAN access assignment
   - MTU setting (9198)

3. Verify the configuration includes:
   - **For bonded interfaces**: VLAN trunk with allowed VLANs (2,4,7 or as needed)
   - **For single port**: Correct VLAN access assignment (typically VLAN 4 for HMN)
   - Appropriate MTU settings (9198)
   - Port descriptions
   - Spanning-tree settings (bpdu-guard, port-type admin-edge)

#### 2.4: Validate Switch Configurations

1. (`ncn-mw#`) Use CANU to validate the generated configurations against running configurations.

   ```bash
   canu validate network config \
       --csm ${CSM_VERSION} \
       --running ./running_configs \
       --generated ./generated_switch_configs
   ```

   **Note**: This assumes you have previously captured running switch configurations. See [Validate Switch Configurations](../network/management_network/validate_switch_configs.md) for details.

#### 2.5: Apply Switch Configurations

**WARNING**: Applying switch configurations can cause brief network disruptions. Coordinate with your network team and schedule during a maintenance window if possible.

##### For Bonded Interface Configuration (Spine Switches)

1. (`ncn-mw#`) Apply the configuration to both spine switches.

   The method for applying configuration varies by switch vendor:

   **For Aruba switches:**

   ```bash
   # SSH to the first spine switch
   ssh admin@sw-spine-001
   ```

   On the switch:

   ```bash
   configure
   
   # Configure the LAG interface
   interface lag 24
       description sms01
       no shutdown
       no routing
       vlan trunk native 1
       vlan trunk allowed 2,4,7
       lacp mode active
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
   
   # Assign physical port to LAG
   interface 1/1/24
       no shutdown
       mtu 9198
       description to_sms01-ocp2
       lag 24
       exit
   
   # Save configuration
   write memory
   exit
   ```

   Repeat for the second spine switch (sw-spine-002).

2. (`ncn-mw#`) Verify LAG status on both spine switches.

   ```bash
   ssh admin@sw-spine-001 "show lacp interfaces lag 24"
   ssh admin@sw-spine-002 "show lacp interfaces lag 24"
   ```

   Verify both sides show LACP as "up" and "active".

##### For Single Port Configuration (Leaf-BMC Switch)

1. (`ncn-mw#`) Apply the configuration to the leaf-BMC switch connected to the node.

   **For Aruba switches:**

   ```bash
   # SSH to the switch and apply configuration
   ssh admin@sw-leaf-bmc-001
   ```

   On the switch:

   ```bash
   configure
   
   # Configure the port
   interface 1/1/39
       description to_sms01
       no shutdown
       mtu 9198
       no routing
       vlan access 4
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
   
   # Save configuration
   write memory
   exit
   ```

2. (`ncn-mw#`) Verify the switch port(s) are up and configured correctly.

   **For bonded interface configuration (Aruba spine switches):**

   ```bash
   # Check LAG status
   ssh admin@sw-spine-001 "show lacp interfaces lag 24"
   ssh admin@sw-spine-002 "show lacp interfaces lag 24"
   
   # Check individual port status
   ssh admin@sw-spine-001 "show interface 1/1/24"
   ssh admin@sw-spine-002 "show interface 1/1/24"
   
   # Verify VLAN configuration on LAG
   ssh admin@sw-spine-001 "show interface lag 24"
   ```

   **For single port configuration (Aruba leaf-BMC switch):**

   ```bash
   ssh admin@sw-leaf-bmc-001 "show interface 1/1/39"
   ```

3. Verify:
   - Port(s) are in "up" state
   - **For bonded**: LAG is active with both member ports up
   - **For bonded**: VLAN trunk is configured with correct allowed VLANs
   - **For single port**: VLAN access assignment is correct
   - MTU is set to 9198
   - No errors on the interface(s)

#### 2.6: Discover the Node BMC

1. (`ncn-mw#`) Wait for HMS discovery to find the new BMC.

   The `hms-discovery` job runs periodically to discover new hardware. Wait 5-10 minutes for the discovery cycle to complete.

   ```bash
   # Wait for discovery cycle
   sleep 300
   
   # Check if BMC is discovered in HSM
   cray hsm inventory redfishEndpoints describe "${BMC_XNAME}" --format json
   ```

2. (`ncn-mw#`) Verify the node BMC is accessible.

   ```bash
   # Check the BMC's IP address from SLS or HSM
   BMC_IP=$(cray hsm inventory ethernetInterfaces list --component-id "${BMC_XNAME}" --format json | jq -r '.[0].IPAddresses[0].IPAddress')
   
   echo "BMC IP: ${BMC_IP}"
   
   # Test BMC accessibility
   ping -c 3 ${BMC_IP}
   ```

### Step 3: Configure Node Networking

This step configures the network interfaces on the node itself. The following procedure assumes a SLES-based system with similar networking requirements as NCNs.

#### 3.1: Power On the Node

1. (`ncn-mw#`) Power on the node via its BMC.

   ```bash
   # Set BMC credentials if needed
   BMC_USERNAME="root"
   BMC_PASSWORD="<password>"
   
   # Power on the node
   ipmitool -I lanplus -H ${BMC_IP} -U ${BMC_USERNAME} -P ${BMC_PASSWORD} chassis power on
   ```

2. Verify the node is powered on and boots successfully.

   Monitor the console or use BMC console access to verify boot progress.

#### 3.2: Access the Node

1. Access the node via console or SSH once the operating system is running.

   If the node has a base OS installed:

   ```bash
   ssh root@${NODE_ALIAS}
   ```

   Or access via BMC console redirection.

#### 3.3: Configure Network Interfaces

The network configuration on this node should mirror NCN networking, using bonding for redundancy and VLANs for network segregation.

**Alternative External Network Connectivity**: If your node has additional unused network interfaces beyond those required for management network connectivity, these interfaces can be directly connected to external networks instead of using the Customer Management Network (CMN). This approach can provide dedicated bandwidth and simplified network architecture for external connectivity. However, configuring such interfaces is outside the scope of this document. Refer to your operating system's networking documentation for instructions on configuring additional network interfaces. This procedure focuses solely on management network configuration.

##### 3.3.1: Identify Network Interfaces

1. (`node#`) Identify the physical network interface names.

   ```bash
   ip link show
   ```

   Look for interfaces like `eth0`, `eth1`, `ens1f0`, `ens1f1`, etc.

   Example output:

   ```text
   1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
   2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
   3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
   ```

2. (`node#`) Record the MAC addresses of the interfaces.

   ```bash
   ip link show eth0 | grep link/ether
   ip link show eth1 | grep link/ether
   ```

##### 3.3.2: Configure Bond Interface

This procedure configures a bonded interface (`bond0`) similar to NCN networking, using LACP for redundancy.

**Note**: This section applies if you configured bonded interfaces on the spine switches. If you configured a single port on a leaf-BMC switch, skip to section 3.3.3 and configure the interface directly without bonding.

1. (`node#`) Create the bond interface configuration file.

   ```bash
   cat > /etc/sysconfig/network/ifcfg-bond0 <<'EOF'
   BONDING_MASTER='yes'
   BONDING_MODULE_OPTS='mode=802.3ad miimon=100 lacp_rate=fast xmit_hash_policy=layer2+3'
   BONDING_SLAVE0='eth0'
   BONDING_SLAVE1='eth1'
   MTU='9000'
   STARTMODE='auto'
   BOOTPROTO='static'
   EOF
   ```

   **Note**: Replace `eth0` and `eth1` with your actual interface names. These should correspond to the two ports connected to the spine switches.

2. (`node#`) Create configuration files for the slave interfaces.

   **Interface eth0:**

   ```bash
   cat > /etc/sysconfig/network/ifcfg-eth0 <<'EOF'
   STARTMODE='auto'
   BOOTPROTO='none'
   MTU='9000'
   EOF
   ```

   **Interface eth1:**

   ```bash
   cat > /etc/sysconfig/network/ifcfg-eth1 <<'EOF'
   STARTMODE='auto'
   BOOTPROTO='none'
   MTU='9000'
   EOF
   ```

##### 3.3.3: Configure VLAN Interfaces

Create VLAN interfaces for each management network. The VLAN IDs should match the network configuration in SLS.

**Determine VLAN IDs from SLS:**

The VLAN IDs are defined in SLS for each network subnet. Common values:
- NMN: VLAN 2 (bootstrap_dhcp subnet)
- HMN: VLAN 4 (bootstrap_dhcp subnet)

1. (`node#`) Create NMN VLAN interface configuration.

   ```bash
   cat > /etc/sysconfig/network/ifcfg-bond0.nmn0 <<'EOF'
   STARTMODE='auto'
   BOOTPROTO='dhcp'
   ETHERDEVICE='bond0'
   VLAN_ID='2'
   MTU='1500'
   EOF
   ```

   **Note**: Adjust `VLAN_ID` to match your NMN VLAN from SLS if different.

2. (`node#`) Create HMN VLAN interface configuration (optional, for management access).

   ```bash
   cat > /etc/sysconfig/network/ifcfg-bond0.hmn0 <<'EOF'
   STARTMODE='auto'
   BOOTPROTO='dhcp'
   ETHERDEVICE='bond0'
   VLAN_ID='4'
   MTU='1500'
   EOF
   ```

   **Note**: Adjust `VLAN_ID` to match your HMN VLAN from SLS if different.

3. (`node#`) Create CMN VLAN interface configuration (if CMN network access is required).

   **IMPORTANT**: CMN does not have DHCP service, so static IP configuration is required. Use the IP address that was allocated in SLS (step 1.5).

   ```bash
   cat > /etc/sysconfig/network/ifcfg-bond0.cmn0 <<'EOF'
   STARTMODE='auto'
   BOOTPROTO='static'
   IPADDR='10.102.3.100/25'
   ETHERDEVICE='bond0'
   VLAN_ID='7'
   MTU='1500'
   EOF
   ```

   **Note**: 
   - Replace `10.102.3.100/25` with the IP address and netmask assigned in SLS for the CMN network.
   - Adjust `VLAN_ID` to match your CMN VLAN from SLS if different (commonly VLAN 7).

4. (`node#`) If static IP addresses are required for other networks, modify the VLAN configurations.

   Example for static IP on NMN:

   ```bash
   cat > /etc/sysconfig/network/ifcfg-bond0.nmn0 <<'EOF'
   STARTMODE='auto'
   BOOTPROTO='static'
   IPADDR='10.252.1.100/17'
   ETHERDEVICE='bond0'
   VLAN_ID='2'
   MTU='1500'
   EOF
   ```

##### 3.3.4: Configure Routing

1. (`node#`) Create routing configuration for bond0.

   ```bash
   cat > /etc/sysconfig/network/ifroute-bond0 <<'EOF'
   # Default route via NMN gateway
   default 10.252.1.1 - bond0.nmn0
   
   # Route to DNS services via NMN
   10.92.100.0/24 via 10.252.0.1 dev bond0.nmn0
   
   # Route to NTP services via HMN
   10.94.100.0/24 via 10.254.0.1 dev bond0.hmn0
   EOF
   ```

   **Note**: 
   - Replace `10.252.1.1` with the actual NMN gateway IP from your SLS configuration.
   - The routes `10.92.100.0/24` and `10.94.100.0/24` provide access to DNS and NTP services respectively.
   - These routes must be configured manually as they are not provided via DHCP.

2. (`ncn-mw#`) **For systems with Olympus hardware**: Check if additional HMN routes are needed for Slingshot switch access.

   These routes can be imported from `ncn-m001`:

   ```bash
   ssh ncn-m001 cat /etc/sysconfig/network/ifroute-bond0.hmn0
   ```

   Example output for Olympus systems:

   ```text
   10.104.0.0/22 10.254.0.1 - bond0.hmn0
   10.107.0.0/22 10.254.0.1 - bond0.hmn0
   10.107.4.0/22 10.254.0.1 - bond0.hmn0
   10.107.8.0/22 10.254.0.1 - bond0.hmn0
   10.94.100.0/24 10.254.0.1 - bond0.hmn0
   ```

   If these routes exist on `ncn-m001`, they should be added to the node for Slingshot switch management.

3. (`node#`) **If HMN routes exist on ncn-m001**, create HMN-specific routing configuration.

   ```bash
   cat > /etc/sysconfig/network/ifroute-bond0.hmn0 <<'EOF'
   # Routes for Slingshot switch access (Olympus hardware)
   10.104.0.0/22 10.254.0.1 - bond0.hmn0
   10.107.0.0/22 10.254.0.1 - bond0.hmn0
   10.107.4.0/22 10.254.0.1 - bond0.hmn0
   10.107.8.0/22 10.254.0.1 - bond0.hmn0
   
   # Route to NTP services via HMN
   10.94.100.0/24 10.254.0.1 - bond0.hmn0
   EOF
   ```

   **Note**: 
   - These routes are required on systems with Olympus hardware to access Slingshot switches via the HMN.
   - The `10.94.100.0/24` route provides access to NTP services and may already be defined in `/etc/sysconfig/network/ifroute-bond0`.
   - Route definitions in interface-specific files (e.g., `ifroute-bond0.hmn0`) take precedence over those in `ifroute-bond0`.
   - If you create `ifroute-bond0.hmn0`, you may want to remove the `10.94.100.0/24` route from `ifroute-bond0` to avoid duplication.

5. (`node#`) Create routing rules for bond0.

   ```bash
   cat > /etc/sysconfig/network/ifrule-bond0 <<'EOF'
   # Routing rules for management networks
   EOF
   ```

##### 3.3.5: Apply Network Configuration

1. (`node#`) Bring up the bond and VLAN interfaces.

   ```bash
   # Load the bonding module
   modprobe bonding
   
   # Restart the network service to apply configurations
   systemctl restart wicked
   ```

2. (`node#`) Verify bond0 is up and operational.

   ```bash
   wicked ifstatus bond0
   ```

   Expected output should show `bond0` in "up" state with both slave interfaces.

   ```text
   bond0           up
         link:     #6, state up, mtu 9000
         type:     bond, mode ieee802-3ad, hwaddr 52:54:00:xx:xx:xx
         config:   compat:suse:/etc/sysconfig/network/ifcfg-bond0
         leases:   ipv4 static granted
         addr:     ipv6 fe80::xxxx:xxxx:xxxx:xxxx/64 scope link
   ```

3. (`node#`) Verify VLAN interfaces are up and have IP addresses.

   ```bash
   wicked ifstatus bond0.nmn0
   ip addr show bond0.nmn0
   ```

   Expected output should show an IP address assigned (either via DHCP or static configuration).

   ```text
   bond0.nmn0      up
         link:     #7, state up, mtu 1500
         type:     vlan bond0[2], hwaddr 52:54:00:xx:xx:xx
         addr:     ipv4 10.252.1.100/17 [dhcp]
         addr:     ipv6 fe80::xxxx:xxxx:xxxx:xxxx/64 scope link
   ```

4. (`node#`) Verify connectivity to management network.

   ```bash
   # Test connectivity to NMN gateway
   ping -c 3 10.252.1.1
   
   # Test DNS resolution
   ping -c 3 api-gw-service-nmn.local
   ```

##### 3.3.6: Configure Hostname and DNS

1. (`node#`) Set the hostname.

   ```bash
   hostnamectl set-hostname ${NODE_ALIAS}
   ```

2. (`node#`) Configure DNS resolution.

   Edit `/etc/resolv.conf` or use the network manager's DNS configuration:

   ```bash
   cat > /etc/resolv.conf <<'EOF'
   # DNS servers from NMN
   nameserver 10.92.100.225
   search nmn hmn
   EOF
   ```

   **Note**: DNS server IPs should match your system's configuration. Check existing NCNs for reference.

3. (`node#`) Verify DNS resolution.

   ```bash
   nslookup api-gw-service-nmn.local
   host api-gw-service-nmn.local
   ```

##### 3.3.7: Configure NTP

1. (`node#`) Configure NTP to use NCN masters as time sources.

   Edit `/etc/chrony.conf`:

   ```bash
   # Backup original
   cp /etc/chrony.conf /etc/chrony.conf.backup
   
   # Add NCN masters as time sources
   cat >> /etc/chrony.conf <<'EOF'
   # NCN masters as NTP servers
   server ncn-m001 iburst
   server ncn-m002 iburst
   server ncn-m003 iburst
   
   # Allow time synchronization
   makestep 1.0 3
   EOF
   ```

2. (`node#`) Restart chrony service.

   ```bash
   systemctl restart chronyd
   systemctl enable chronyd
   ```

3. (`node#`) Verify time synchronization.

   ```bash
   chronyc sources
   chronyc tracking
   ```

##### 3.3.8: Configure Network Persistence

1. (`node#`) Ensure network configuration persists across reboots.

   ```bash
   systemctl enable wicked
   systemctl enable wickedd
   ```

2. (`node#`) Test by rebooting the node.

   ```bash
   reboot
   ```

3. After reboot, verify all network interfaces are up and configured correctly.

   ```bash
   # Check bond status
   wicked ifstatus bond0
   
   # Check VLAN interfaces
   wicked ifstatus bond0.nmn0
   
   # Verify connectivity
   ping -c 3 api-gw-service-nmn.local
   ```

## Verification

### Verify Node in SLS

1. (`ncn-mw#`) Verify the node exists in SLS.

   ```bash
   cray sls hardware describe ${NODE_XNAME} --format json
   ```

### Verify BMC Discovery

1. (`ncn-mw#`) Verify the BMC is discovered in HSM.

   ```bash
   cray hsm inventory redfishEndpoints describe ${BMC_XNAME} --format json
   ```

### Verify Network Configuration

1. (`ncn-mw#`) Verify switch port configuration.

   ```bash
   # Check port status on the switch
   ssh admin@sw-leaf-bmc-001 "show interface ${SWITCH_PORT_VENDOR_NAME}"
   ```

2. (`node#`) On the node, verify network connectivity.

   ```bash
   # Check all interfaces
   wicked ifstatus all
   
   # Test connectivity to key services
   ping -c 3 api-gw-service-nmn.local
   curl -k https://api-gw-service-nmn.local
   
   # Check routing
   ip route
   ```

### Verify Node Accessibility

1. (`ncn-mw#`) Verify the node is accessible from management NCNs.

   ```bash
   ssh root@${NODE_ALIAS}
   ping -c 3 ${NODE_ALIAS}
   ```

2. (`ncn-mw#`) Verify the node's IP address is correctly registered.

   ```bash
   host ${NODE_ALIAS}
   ```
