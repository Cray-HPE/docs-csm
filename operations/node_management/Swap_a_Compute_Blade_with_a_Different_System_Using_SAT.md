# Swap a Compute Blade with a Different System Using SAT

Swap an HPE Cray EX liquid-cooled [compute][cn] blade between two systems.

- The two systems in this example are:
    - Source system - Cray EX TDS cabinet `x9000` with a healthy `EX425` blade (Windom dual-injection) in chassis 3, slot 0
    - Destination system - Cray EX cabinet `x1005` with a defective `EX425` blade (Windom dual-injection) in chassis 3, slot 0
- Substitute the correct component names ([xnames][xname]) or other parameters in the command examples that follow.

## Prerequisites

- The [Cray command line interface (CLI)][cli] tool is initialized and configured on the system.
    - See [Configure the Cray Command Line Interface](../configure_cray_cli.md).
- The [Slingshot][slingshot] fabric must be configured with the desired topology for both blades.
- The [System Layout Service (SLS)][sls] must have the desired [high-speed network (HSN)][hsn] configuration.
- The blade that is removed from the source system must be installed in the empty slot left by the blade removed from destination system, and vice-versa.
- Check the status of the HSN and record link status before the procedure.
- The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
    - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
    - Review the *HPE Cray EX Hand Pump User Guide H-6200*
- The [System Admin Toolkit (SAT)][sat] is installed and configured on the system.

## Remove blade from source system

### Source: Prepare the blade for removal

1. Using the workload manager (WLM), drain running jobs from the affected nodes on the blade.
   Refer to the vendor documentation for the specific WLM for more information.

1. (`ncn-mw#`) Determine which [Boot Orchestration Service (BOS)][bos]
   [session templates](../boot_orchestration/Session_Templates.md) to use to shut down nodes
   on the target blade.

   There will be separate session templates for [UANs][uan] and [computes nodes][cn].

   1. List all the session templates.

      If it is unclear which session template is in use, then proceed to the next substep.

      ```bash
      cray bos v2 sessiontemplates list
      ```

   1. Find the node [xnames][xname] with `sat status`.

      In this example, the target blade is in slot `x9000c3s0`.

      ```bash
      sat status --filter 'xname=x9000c3s0*'
      ```

      Example output:

      ```text
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      | xname         | Type | NID      | State | Flag | Enabled | Arch | Class | Role        | Net      |
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      | x9000c3s0b1n0 | Node | 1        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b2n0 | Node | 2        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b3n0 | Node | 3        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b4n0 | Node | 4        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      ```

   1. Find the [`bos_session`](../boot_orchestration/Sessions.md) value for each node via
      the [Configuration Framework Service (CFS)][cfs].

      ```bash
      cray cfs v3 components describe x9000c3s0b1n0 --format toml | grep bos_session
      ```

      Example output:

      ```toml
      bos_session = "e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f"
      ```

   1. Find the required `template_name` value with BOS.

      ```bash
      cray bos v2 sessions describe BOS_SESSION --format toml | grep template_name
      ```

      Example output:

      ```toml
      template_name = "compute-nid1-4-sessiontemplate"
      ```

   1. Determine the list of [xnames][xname] associated with the desired boot session template.

      ```bash
      cray bos v2 sessiontemplates describe SESSION_TEMPLATE_NAME --format toml | grep node_list
      ```

      Example output:

      ```toml
      node_list = [ "x9000c3s0b1n0", "x9000c3s0b2n0", "x9000c3s0b3n0", "x9000c3s0b4n0",]
      ```

1. (`ncn-mw#`) Shut down the nodes on the target blade.

   Use the `sat bootsys` command to shut down the nodes on the target blade. Specify the appropriate component
   name (xname) for the slot, and a comma-separated list of the BOS session templates determined in the previous step.

   ```bash
   BOS_TEMPLATES=uss-4809
   sat bootsys shutdown --stage bos-operations --bos-limit x9000c3s0 --recursive --bos-templates $BOS_TEMPLATES
   ```

### Source: Use SAT to remove the blade from hardware management

1. (`ncn-mw#`) Power off the slot and delete blade information from the [HSM][hsm].

   Use the `sat swap` command to power off the slot and delete the blade's Ethernet
   interfaces and Redfish endpoints from the HSM.

   ```bash
   sat swap blade --action disable x9000c3s0
   ```

   This command will save the MAC addresses, IP addresses, and node xnames from the blade to a JSON document.
   The document is stored in a file with the following naming convention:

   ```text
   ethernet-interface-mappings-<blade_xname>-<current_year>-<current_month>-<current_day>.json
   ```

   If a mapping file already exists with the above name, then a numeric suffix will be appended to the file
   name in front of the `.json` extension.

   The mapping file should be copied to the [NCN][ncn] on the destination system that is being used for the
   swap procedure, if necessary. In this example, the filename is changed to `ethernet-interface-mappings-src.json`
   on the destination system for clarity.

   ```bash
   scp ethernet-interface-mappings-x3000c3s0-2022-01-01.json <dest>-ncn-m001:ethernet-interface-mappings-src.json
   ```

### Source: Remove the blade

1. Remove the blade from the source system.
   Review the *Remove a Compute Blade Using the Lift* procedure in
   *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled
   blades ([HPE Support](https://internal.support.hpe.com/)).
1. Drain the coolant from the blade and fill with fresh coolant to minimize cross-contamination of cooling systems.
   Review *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the
   *HPE Cray EX Hand Pump User Guide H-6200* ([HPE Support](https://internal.support.hpe.com/)).
1. Install the blade from the source system in a storage rack or leave it on the cart.

## Remove blade from destination system

### Destination: Prepare blade for removal

1. Using the workload manager (WLM), drain running jobs from the affected nodes on the blade.

   Refer to the vendor documentation for the specific WLM for more information.

1. (`ncn-mw#`) Shut down the nodes on the target blade.

   Use the `sat bootsys` command to shut down the nodes on the target blade. Specify the appropriate component
   name ([xname][xname]) for the slot and a comma-separated list of the appropriate [BOS][bos]
   [session templates](../boot_orchestration/Session_Templates.md) for the nodes on the blade.

   The appropriate BOS session templates should be determined using the same procedure as was used to
   [determine the appropriate BOS session templates on the source system](#source-prepare-the-blade-for-removal).

   ```bash
   BOS_TEMPLATES=uss-2.0.30-slurm-healthy-compute
   sat bootsys shutdown --stage bos-operations --bos-limit x1005c0s3 --recursive --bos-templates $BOS_TEMPLATES
   ```

### Destination: Use SAT to remove the blade from hardware management

1. (`ncn-mw#`) Power off the slot and delete blade information from the [HSM][hsm].

   Use the `sat swap` command to power off the slot and delete the blade's Ethernet interfaces
   and Redfish endpoints from the HSM.

   ```bash
   sat swap blade --action disable x1005c0s3
   ```

   The mapping file should be copied to the [NCN][ncn] on the destination system that is being used for the swap
   procedure, if necessary. In this example, the filename is changed to `ethernet-interface-mappings-src.json` on
   the destination system for clarity.

   ```bash
   scp ethernet-interface-mappings-x1005c0s3-2022-01-01.json <src>-ncn-m001:ethernet-interface-mappings-dest.json
   ```

## Swap the blade hardware on the destination system

1. Remove the blade from destination system install it in a storage cart.

1. Install the blade from the source system into the destination system.

## Bring up the blade in the destination system

### Destination: Use SAT to add the blade to hardware management

1. (`ncn-mw#`) Begin discovery for the blade.

   Use the `sat swap` command to map the nodes' Ethernet interface MAC addresses to the appropriate IP
   addresses and component names ([xnames][xname]), and begin discovery for the blade.

   The `--src-mapping` and `--dst-mapping` arguments should be used to pass in the Ethernet interface mapping
   files created during the previous steps.

   ```bash
   sat swap blade --action enable --src-mapping ethernet-interface-mappings-src.json --dst-mapping ethernet-interface-mappings-x1005c0s3-2022-01-01.json x10005c0s3
   ```

### Destination: Power on and boot the nodes

1. (`ncn-mw#`) Power on and boot the nodes.

   Use `sat bootsys` to power on and boot the nodes. Specify the appropriate [BOS][bos] template for the node type.

   ```bash
   BOS_TEMPLATE=uss-2.0.30-slurm-healthy-compute
   sat bootsys boot --stage bos-operations --bos-limit x1005c0s3 --recursive --bos-templates $BOS_TEMPLATE
   ```

### Destination: Check firmware

1. Validate the firmware.

   Verify that the correct firmware versions are present for the node BIOS, [node controller (nC)][nc],
   NIC mezzanine card (NMC), GPUs, and so on.

1. (`ncn-mw#`) If necessary, update the firmware with [FAS][fas].

   Review the [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md) and
   [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) procedure.

   ```bash
   cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
   ```

### Destination: Check the HSN for the affected nodes

1. (`ncn-mw#`) Determine the pod name for the [Slingshot][slingshot] fabric manager pod and check the status of the fabric.

   ```bash
   kubectl exec -it -n services \
       $(kubectl get pods --all-namespaces |grep slingshot | awk '{print $2}') \
       -- fmn_status
   ```

### Destination: Check DNS

1. (`ncn-mw#`) Check for duplicate IP address entries in the [State Management Database (SMD)][smd].

   Duplicate entries will cause DNS operations to fail.

   ```bash
   ssh uan01
   ```

   Example output:

   ```text
   ssh: Could not resolve hostname uan01: Temporary failure in name resolution
   ```

   ```bash
   ssh x3000c0s14b0n0
   ```

   Example output:

   ```text
   ssh: Could not resolve hostname x3000c0s14b0n0: Temporary failure in name resolution
   ```

   ```bash
   ssh x1000c1s1b0n1
   ```

   Example output:

   ```text
   ssh: Could not resolve hostname x1000c1s1b0n1: Temporary failure in name resolution
   ```

   The Kea configuration error will display a message similar to the message below.
   This message indicates a duplicate IP address (`10.100.0.105`) in the SMD:

   ```text
   Config reload failed
   [{'result': 1, 'text': "Config reload failed: configuration error using file '/usr/local/kea/cray-dhcp-kea-dhcp4.conf':
   failed to add new host using the HW address '00:40:a6:83:50:a4 and DUID '(null)' to the IPv4 subnet id '0' for the address 10.100.0.105: There's already a reservation for this address"}]
   ```

1. (`ncn-mw#`) Check Kea for active DHCP leases.

   Use the following example `curl` command to check for active DHCP leases.
   If there are zero DHCP leases, then there is a configuration error.

   In this example, an authentication token for the API gateway is stored in the `TOKEN` shell variable.
   See [Retrieve an Authentication Token](../security_and_authentication/Retrieve_an_Authentication_Token.md)
   for more information.

   ```bash
   curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
       -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
   ```

   Example output in the case of a configuration error:

   ```json
   [
     {
       "arguments": {
         "leases": []
       },
       "result": 3,
       "text": "0 IPv4 lease(s) found."
     }
   ]
   ```

1. (`ncn-mw#`) Delete the duplicate entries, if there are any.

   If there are duplicate entries in the [HSM][hsm] as a result of this procedure,
   then delete the duplicate entries (`10.100.0.105` in this example).

   1. Show the `EthernetInterfaces` for the duplicate IP address:

      ```bash
      cray hsm inventory ethernetInterfaces list --ip-address 10.100.0.105 --format json | jq
      ```

      Example output:

      ```json
      [
        {
          "ID": "0040a68350a4",
          "Description": "Node Maintenance Network",
          "MACAddress": "00:40:a6:83:50:a4",
          "IPAddresses": [
            {
              "IPAddress": "10.100.0.105"
            }
          ],
          "LastUpdate": "2021-08-24T20:24:23.214023Z",
          "ComponentID": "x1000c7s7b0n1",
          "Type": "Node"
        },
        {
          "ID": "0040a683639a",
          "Description": "Node Maintenance Network",
          "MACAddress": "00:40:a6:83:63:9a",
          "IPAddresses": [
            {
              "IPAddress": "10.100.0.105"
            }
          ],
          "LastUpdate": "2021-08-27T19:15:53.697459Z",
          "ComponentID": "x1000c7s7b0n1",
          "Type": "Node"
        }
      ]
      ```

   1. Delete the older entry.

      ```bash
      cray hsm inventory ethernetInterfaces delete 0040a68350a4
      ```

1. (`ncn-mw#`) Check DNS using `dnslookup`.

   ```bash
   nslookup 10.252.1.29
   ```

   Example output:

   ```text
   1.1.252.10.in-addr.arpa name = uan01.
   1.1.252.10.in-addr.arpa name = uan01.local.
   1.1.252.10.in-addr.arpa name = x3000c0s14b0n0.
   1.1.252.10.in-addr.arpa name = x3000c0s14b0n0.local.
   1.1.252.10.in-addr.arpa name = uan01-nmn.
   1.1.252.10.in-addr.arpa name = uan01-nmn.local.
   ```

   ```console
   nslookup uan01
   ```

   Example output:

   ```text
   Server:     10.92.100.225
   Address:    10.92.100.225#53

   Name:   uan01
   Address: 10.252.1.29
   ```

   ```console
   nslookup x3000c0s14b0n0
   ```

   Example output:

   ```text
   Server:     10.92.100.225
   Address:    10.92.100.225#53

   Name:   x3000c0s14b0n0
   Address: 10.252.1.29
   ```

1. (`ncn-mw#`) Verify the ability to connect using SSH.

   ```bash
   ssh x3000c0s14b0n0
   ```

   Example output:

   ```text
   The authenticity of host 'x3000c0s14b0n0 (10.252.1.29)' can't be established.
   ECDSA key fingerprint is SHA256:wttHXF5CaJcQGPTIq4zWp0whx3JTwT/tpx1dJNyyXkA.
   Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
   Warning: Permanently added 'x3000c0s14b0n0' (ECDSA) to the list of known hosts.
   Last login: Tue Aug 31 10:45:49 2021 from 10.252.1.9
   ```

## Bring up the blade in the source system

1. To minimize cross-contamination of cooling systems, drain the coolant from the blade
   removed from destination system and fill with fresh coolant.

   Review the *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump,
   review procedures in the *HPE Cray EX Hand Pump User Guide H-6200*
   ([HPE Support](https://internal.support.hpe.com/)).

1. Install the blade from the destination system into source system.

   Review the *Remove a Compute Blade Using the Lift* procedure in
   *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for
   replacing liquid-cooled blades ([HPE Support](https://internal.support.hpe.com/)).

1. Power on the nodes in the source system by repeating the steps starting in the
   [Bring up the blade in the destination system](#bring-up-the-blade-in-the-destination-system) section,
   and going up through the [Check DNS](#destination-check-dns) section.

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../configure_cray_cli.md
[check-latest-docs]: ../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../glossary.md#ansible-execution-environment-aee
[an]: ../../glossary.md#application-node-an
[ara]: ../../glossary.md#ara-records-ansible-ara
[bmc]: ../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../glossary.md#boot-orchestration-service-bos
[bss]: ../../glossary.md#boot-script-service-bss
[can]: ../../glossary.md#customer-access-network-can
[canu]: ../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../glossary.md#configuration-framework-service-cfs
[chn]: ../../glossary.md#customer-high-speed-network-chn
[cli]: ../../glossary.md#cray-cli-cray
[cmn]: ../../glossary.md#customer-management-network-cmn
[cn]: ../../glossary.md#compute-node-cn
[csi]: ../../glossary.md#cray-site-init-csi
[fas]: ../../glossary.md#firmware-action-service-fas
[hbtd]: ../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../glossary.md#hardware-management-network-hmn
[hmnfd]: ../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd
[hsm]: ../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../glossary.md#high-speed-network-hsn
[ims]: ../../glossary.md#image-management-service-ims
[iuf]: ../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../glossary.md#management-nodes
[mountain]: ../../glossary.md#mountain-cabinet
[nc]: ../../glossary.md#node-controller-nc
[ncn]: ../../glossary.md#non-compute-node-ncn
[nid]: ../../glossary.md#node-id-nid
[nmn]: ../../glossary.md#node-management-network-nmn
[pcs]: ../../glossary.md#power-control-service-pcs
[pdu]: ../../glossary.md#power-distribution-unit-pdu
[pit]: ../../glossary.md#pre-install-toolkit-pit
[river]: ../../glossary.md#river-cabinet
[rts]: ../../glossary.md#redfish-translation-service-rts
[s3]: ../../glossary.md#simple-storage-service-s3
[sat]: ../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../glossary.md#system-configuration-service-scsd
[shcd]: ../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../glossary.md#slingshot
[sls]: ../../glossary.md#system-layout-service-sls
[sma]: ../../glossary.md#system-monitoring-application-sma
[smd]: ../../glossary.md#hardware-state-manager-smd
[sops]: ../../glossary.md#secrets-operations-sops
[tapms]: ../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../glossary.md#user-access-node-uan
[uss]: ../../glossary.md#user-services-software-uss
[vcs]: ../../glossary.md#version-control-service-vcs
[vnid]: ../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../glossary.md#xname

<!-- markdownlint-restore -->
