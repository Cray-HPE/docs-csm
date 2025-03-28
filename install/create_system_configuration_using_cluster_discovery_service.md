# Create System Configuration Using Cluster Discovery Service

This stage walks the user through creating the configuration payload for the system using Cluster Discovery Service (CDS) to generate seed files and paddle file.

## Topics

1. [Prepare](#1-prepare)
1. [Configure the management network](#2-configure-the-management-network)
1. [Configure auto-discovery](#3-configure-auto-discovery)
    1. [Configure `dnsmasq`](#31-configure-dnsmasq)
    1. [Verify and reset the BMCs](#32-verify-and-reset-the-bmcs)
    1. [Verify the discover status](#33-verify-the-discover-status)
    1. [Collect and compare the inventory data](#34-collect-and-compare-the-inventory-data)
1. [Generate seed files and paddle file](#4-generate-seed-files-and-paddle-file)
1. [Stop discovery](#5-stop-discovery)
1. [Next topic](#next-topic)

## 1. Prepare

1. This document requires that a `system_config.yaml` file is present on the system from [customize `system_config.yaml`](pre-installation.md#31-customize-system_configyaml) in the pre-installation document.

1. (`pit#`) Create the `prep` and `cds` directory.

   ```bash
   mkdir -pv "${PITDATA}/prep/cds"
   ```

1. (`pit#`) Change into the `cds` directory.

   ```bash
   cd "${PITDATA}/prep/cds"
   ```

1. (`pit#`) Set `CVT_PATH` variable.

   ```bash
   CVT_PATH=/opt/src/cluster-config-verification-tool
   ```

## 2. Configure the management network

1. (`pit#`) Change into the `cds` directory.

   ```bash
   cd "${PITDATA}/prep/cds"
   ```

1. (`pit#`) Set up the `bond0` network interface as follows:

   - Configure `bond0` interface for single VLAN:

     ```bash
     "${CVT_PATH}"/cds/network_setup.py -mtl <ipaddr>,<netmask>,<slave0>,<slave1>
     ```

   - Configure `bond0` interface for HMN configured network (VLAN 1, 2, and 4):

     ```bash
     "${CVT_PATH}"/cds/network_setup.py -mtl <ipaddr>,<netmask>,<slave0>,<slave1> -hmn <ipaddr>,<netmask>,<vlanid> -nmn <ipaddr>,<netmask>,<vlanid>
     ```

     The variables and their descriptions are as follows:

     | Variable           | Description        |
     |--------------------|--------------------|
     | `ipaddr`           | IP address         |
     | `netmask`          | netmask value      |
     | `slave0`, `slave1` | network interfaces |
     | `vlanid`           | VLAN ID number     |

     > **NOTE**: The IP address value, netmask value, network interface, and VLAN ID are available in the `system_config.yaml` file in the `prep` directory.

## 3. Configure auto-discovery

### 3.1 Configure Dnsmasq

1. (`pit#`) Configure Dnsmasq and PXE Boot.

   - Configure Dnsmasq for single VLAN:

     > The `<leasetime>` parameter is optional.

     ```bash
     "${CVT_PATH}"/cds/discover_enable.py -ip <dhcp_ip_start>,<dhcp_ip_end>,<subnet>,<leasetime> -i bond0
     ```

     Example command:

     ```bash
     "${CVT_PATH}"/cds/discover_enable.py -ip 10.x.x.x,10.x.x.x,255.x.x.x,24h -i bond0
     ```

   - Configure Dnsmasq for HMN configured network (VLAN 1, 2, and 4):

     ```bash
     "${CVT_PATH}"/cds/discover_enable.py -mtl <admin_node_mtl_ip>,<start_ip>,<end_ip> \
                                          -nmn <admin_node_nmn_ip>,<start_ip>,<end_ip> \
                                          -hmn <admin_node_hmn_ip>,<start_ip>,<end_ip>
     ```

     Example command:

     ```bash
     "${CVT_PATH}"/cds/discover_enable.py -mtl 10.x.x.x,10.x.x.x,10.x.x.x \
                                          -nmn 10.x.x.x,10.x.x.x,10.x.x.x \
                                          -hmn 10.x.x.x,10.x.x.x,10.x.x.x
     ```

     > **NOTE**: The `iprange` for single VLAN or `mtliprange`, `nmniprange`, and `hmniprange` for HMN configured network are available in the `system_config.yaml` file in the `prep` directory.

### 3.2 Verify and reset the BMCs

The following steps will verify if IP addresses are assigned to the BMC nodes and then reset the nodes:

1. (`pit#`) If the fabric switches, PDUs, and CMCs are to be dynamically discovered, then ensure that they are set to DHCP mode.

1. (`pit#`) List the BMC nodes.

   ```bash
   "${CVT_PATH}"/cds/discover_start.py -u <bmc_username> -l
   ```

   > A prompt to enter the password will appear, enter the correct BMC password.

1. Verify that all the required nodes are listed.

    Example output:

    ```text
    ncn-m001:/opt/src/cluster-config-verification-tool/cds # ./discover_start.py -u root -l
    Enter the password:
    File /var/lib/misc/dnsmasq.leases exists and has contents.

    ===== Detected BMC MAC info:
    IP: A.B.C.D BMC_MAC: AA-BB-CC-DD-EE-FF

    ==== Count check:
    No of BMC Detected: 1

    ====================================================================================

    If BMC count matches the expected river node count, proceed with rebooting the nodes
    ./discovery_start.py --bmc_username <username> --bmc_passwprd <password> --reset
    ```

1. (`pit#`) Reset the listed BMC nodes.

   ```bash
   "${CVT_PATH}"/cds/discover_start.py -u <bmc_username> -r
   ```

   > A prompt to enter the password will appear, enter the correct BMC password.

### 3.3 Verify the discover status

> **NOTE**: If the fabric switches, PDUs, and CMCs were not configured to DHCP mode in the step [Verify and reset the BMCs](#32-verify-and-reset-the-bmcs), manually create the `fabricswlist`, `pdulist`, and `cmclist` files in the working directory.

The following steps verify the status and lists the IP addresses of nodes, fabric switches, PDUs, and CMCs:

1. (`pit#`) Verify the status and list the IP addresses of the nodes.

   ```bash
   "${CVT_PATH}"/cds/discover_status.py nodes -o
   ```

   > **NOTE**:
   >
   > - Ensure that all the NCNs and CNs are discovered and listed. If any nodes are not discovered, identify the nodes using the MAC address and verify the switch connectivity of those nodes.
   > - If the discover status step is rerun after a long duration, start the procedure from the beginning of section [Configure the management network](#2-configure-the-management-network).

   1. Create a `bond0` network interface on all the listed nodes.

      ```bash
      pdsh -w^nodelist -x localhost "sh "${CVT_PATH}"/scripts/create_bond0.sh"
      ```

      > **NOTE**: If there is a host-key verification failure, use the `ssh-keygen` command to retrieve the host-key and retry the procedure.
      >
      > `ssh-keygen -R <node_IP> -f /root/.ssh/known_hosts`
      >
      > Where, `<node_IP>` is the IP of the node where the error exist.

   1. Ensure that `bond0` network interface is created on all the nodes listed in the `nodelist`.

      Example output:

        ```text
        pit:/var/www/ephemeral/prep/cds # pdsh -w^nodelist -x localhost "sh "${CVT_PATH}"/scripts/create_bond0.sh"
        ncn-w002: Network restarted successfully
        // more nodes to follow - output truncated
        ```

      > **NOTE**: If there is a failure in creating the `bond0` network on any nodes listed in the `nodelist`, make sure to run the script again on only those particular nodes to create the `bond0` network.

1. (`pit#`) Verify the status and list the IP addresses of the fabric switches.

   ```bash
   "${CVT_PATH}"/cds/discover_status.py fabric -u <fabric_username> -o
   ```

   > A prompt to enter the password will appear, enter the correct fabric switch password.

   Example output:

    ```text
    ncn-m001:/opt/src/cluster-config-verification-tool/cds # ./discover_status.py fabric --username root --out
    Enter the password for fabric:
    File /var/lib/misc/dnsmasq.leases exists and has contents.

    fabricswlist:
    A.B.C.D

    ===== Save list components in a file:
    Created fabricswlist file: /opt/src/cluster-config-verification-tool/cds/fabricswlist
    ```

1. (`pit#`) Verify the status and list the IP addresses of the PDUs.

   ```bash
   "${CVT_PATH}"/cds/discover_status.py pdu -o
   ```

1. (`pit#`) Verify the status and list the IP addresses of the CMCs.

   ```bash
   "${CVT_PATH}"/cds/discover_status.py cmc -u <cmc_username> -o
   ```

   > A prompt to enter the password will appear, enter the correct CMC password.

### 3.4 Collect and compare the inventory data

#### 3.4.1 Dynamic Data Collection

1. (`pit#`) Copy the SSH key to setup passwordless-SSH for the local host.

   ```bash
   ssh-copy-id localhost
   ```

1. (`pit#`) Collect the hardware inventory data.

   ```bash
   "${CVT_PATH}"/system_inventory.py -nf nodelist
   ```

1. (`pit#`) Collect the fabric inventory data.

   ```bash
   "${CVT_PATH}"/fabric_inventory.py -sf fabricswlist -u <switch_username>
   ```

   > A prompt to enter the password will appear, enter the correct fabric password.

1. (`pit#`) Collect the management network inventory.

   1. Manually, create a `mgmtswlist` file in the working directory listing the IP addresses of management switches.

   1. Collect the management network inventory data.

      ```bash
      "${CVT_PATH}"/management_inventory.py  -u <username> -sf mgmtswlist
      ```

      > A prompt to enter the password will appear, enter the correct fabric password.

1. (`pit#`) Collect the PDU inventory data.

   ```bash
   "${CVT_PATH}"/cds/pdu_cmc_inventory.py -pf pdulist
   ```

1. (`pit#`) Collect the CMC inventory data.

   ```bash
   "${CVT_PATH}"/cds/pdu_cmc_inventory.py -cf cmclist
   ```

#### 3.4.2 SHCD data population

1. Copy the SHCD files to the present working directory.

1. (`pit#`) Create a JSON file using the CANU tool.

   See [Validate the SHCD](../operations/network/management_network/validate_shcd.md#validate-the-shcd).

   Example command:

   ```bash
   canu validate shcd --shcd SHCD.xlsx --architecture V1 --tabs 40G_10G,NMN,HMN --corners I12,Q38,I13,Q21,J20,U38 --json --out cabling.json
   ```

1. (`pit#`) Store the SHCD data in the CVT database.

   ```bash
   "${CVT_PATH}"/parse_shcd.py -c cabling.json
   ```

#### 3.4.3 Server classification

(`pit#`) Classify the servers.

> In the following command, replace `<N>` with the number of worker NCNs in the system.

```bash
"${CVT_PATH}"/scripts/server_classification.py -n <N>
```

#### 3.4.4 Compare the SHCD data with CVT inventory data

1. (`pit#`) List the snapshot IDs of the SHCD and the CVT inventory data.

   ```bash
   "${CVT_PATH}"/shcd_compare.py -l
   ```

1. (`pit#`) Compare the SHCD data with the CVT inventory data.

   ```bash
   "${CVT_PATH}"/shcd_compare.py -s <SnapshotID_SHCD> -c <SnapshotID_CVT>
   ```

   Example command:

   ```bash
   "${CVT_PATH}"/shcd_compare.py -s 4ea86f99-47ca-4cd9-b142-ea572d0566bf -c 326a6edd-adce-4d1f-9f30-ae9539284733
   ```

## 4. Generate seed files and paddle file

1. (`pit#`) Generate the following seed files: `switch_metadata.csv`, `application_node_config.yaml`, `hmn_connections.json`, and `ncn_metadata.csv`.

   ```bash
   "${CVT_PATH}"/create_seedfile.py
   ```

   > **NOTE**: The generated seed files will be stored in the `seedfiles` folder in the working directory.

1. (`pit#`) Generate paddle file: `cvt-ccj.json`.

   > In the following command, replace `<arch_type>` with the type of architecture (`Full`, `V1`, or `Tds`).
   > See [Generate configuration files](../operations/network/management_network/generate_switch_configs.md#generate-configuration-files) for the characteristics of the architecture.

   ```bash
   "${CVT_PATH}"/create_paddle_file.py --architecture <arch_type>
   ```

1. Copy the generated paddle file and seed files to the `prep` directory.

   ```bash
   cp -rv ${PITDATA}/prep/cds/cvt-ccj.json ${PITDATA}/prep/cds/seedfiles/* ${PITDATA}/prep/
   ```

1. Create `cabinets.yaml` file in the `prep` directory, see [Create `cabinets.yaml`](create_cabinets_yaml.md).

## 5. Stop discovery

(`pit#`) Clean and reset the modified files to their original default state.

```bash
"${CVT_PATH}"/cds/discover_stop.py -u <bmc_username>
```

> A prompt to enter the password will appear, enter the correct BMC password.

## Next topic

After completing this procedure, return to the pre-installation document to [generate system configuration](pre-installation.md#33-generate-system-configuration).
