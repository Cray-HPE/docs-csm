# Use CANU to Verify, Generate, or Compare Switch Configurations

* [Common CANU Arguments](#common-canu-arguments)
  * [SHCD-Related Arguments](#shcd-related-arguments)
  * [CSI and SLS API Input to CANU](#csi-and-sls-api-input-to-canu)
    * [CSI Input](#csi-input)
    * [SLS API Input](#sls-api-input)
* [Check Single Switch Firmware](#check-single-switch-firmware)
* [Check Firmware of Multiple Switches](#check-firmware-of-multiple-switches)
* [JSON Output](#json-output)
* [Check Single Switch Cabling](#check-single-switch-cabling)
* [Check Cabling of Multiple Switches](#check-cabling-of-multiple-switches)
* [Validate SHCD](#validate-shcd)
* [Validate Cabling](#validate-cabling)
* [Validate SHCD and Cabling](#validate-shcd-and-cabling)
* [Validate BGP](#validate-bgp)
* [Configuration Creation For BGP](#configuration-creation-for-bgp)
* [Generate Switch Configurations](#generate-switch-configurations)

## Common CANU Arguments

The following CANU flags are used for multiple different actions.

* In order to have CANU output to a file, specify the desired output file with the `--out` flag.
* IPv4 addresses can be read from a file or specified in a comma-separated list with the `--ips` flag. When passing in the IP addresses
  in a file, the file must have one IP address per line, and the filename is specified with the `--ips-file` flag.
* The `--architecture` / `-a` flag is used to set the architecture of the system: `TDS` or `Full`.

### SHCD-Related Arguments

Some of the CANU flags are specific to SHCD (Shasta Cabling Diagram) input files.

* The `--shcd` flag specifies the path to the SHCD file.
* The `--tabs` flag selects which tabs on the SHCD spreadsheet will be included.
* The `--corners` flag is used to input the upper left and lower right corners of the table on each tab of the SHCD. The table
  should contain the 11 headers: `Source`, `Rack`, `Location`, `Slot`, Blank, `Port`, `Destination`, `Rack`, `Location`, Blank, `Port`.
  If the corners are not specified, CANU will prompt for the columns for each tab.

### CSI and SLS API Input to CANU

In some cases, CANU accepts input from a CSI-generated file or from the SLS API. The following two sections go over these options.

#### CSI Input

In order for CANU to parse CSI output, use the `--csi-folder` flag specify the directory containing the CSI-generated `sls_input_file.json` file.

The `sls_input_file.json` file is generally stored in one of two places, depending on how far the system is in the install process.

* Early in the install process, when running off of the LiveCD, the `sls_input_file.json` file is normally found on the PIT node in the `/var/www/ephemeral/prep/SYSTEMNAME/` directory.
* Later in the install process, after the PIT node has been redeployed, the `sls_input_file.json` file is generally found on
`ncn-m001` or `ncn-m003` in the `/metal/bootstrap/prep/SYSTEMNAME/` directory.

#### SLS API Input

In order for CANU to get input from the SLS API, the CSM install must be completed at least to the point where the CSM Services have been
successfully deployed.

In order to have CANU use the SLS API as the source, the path to a token file must be passed in using the `--auth-token` flag. Tokens are typically stored in the `~./config/cray/tokens/` directory.

Instead of passing in a token file, the environment variable `SLS_TOKEN` can be used.

The SLS address is by default set to `api-gw-service-nmn.local`. If needed, a different SLS address can be specified using the `--sls-address` flag.

## Check Single Switch Firmware

To check the firmware of a single switch, run the following:

```ShellSession
canu --shasta 1.4 switch firmware --ip 192.168.1.1 --username USERNAME --password PASSWORD
```

Expected output:

```text
🛶 - Pass - IP: 192.168.1.1 Hostname:test-switch-spine01 Firmware: GL.10.06.0130
```

## Check Firmware of Multiple Switches

Multiple Aruba switches on a network can be checked for their firmware versions. An example of checking the firmware of multiple switches:

```ShellSession
canu --shasta 1.4 network firmware --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

```ShellSession
canu --shasta 1.4 network firmware --ips 192.168.1.1,192.168.1.2,192.168.1.3,192.168.1.4 --username USERNAME --password PASSWORD
```

Expected Output

```text
    ------------------------------------------------------------------
    STATUS  IP              HOSTNAME            FIRMWARE
    ------------------------------------------------------------------
     🛶 Pass    192.168.1.1     test-switch-spine01 GL.10.06.0010
     🛶 Pass    192.168.1.2     test-switch-leaf01  FL.10.06.0010
     ❌ Fail    192.168.1.3     test-wrong-version  FL.10.05.0001   Firmware should be in range ['FL.10.06.0001']
     🔺 Error   192.168.1.4'

    Errors
    ------------------------------------------------------------------
    192.168.1.4     - HTTP Error. Check that this IP is an Aruba switch, or check the username and password

    Summary
    ------------------------------------------------------------------
    🛶 Pass - 2 switches
    ❌ Fail - 1 switches
    🔺 Error - 1 switches
    GL.10.06.0010 - 1 switches
    FL.10.06.0010 - 1 switches
    FL.10.05.0010 - 1 switches
```

When using the `network firmware` commands, the table will show either: `🛶 Pass`, `❌ Fail`, or `🔺 Error`. The switch will `pass` or `fail` based on whether or not the switch firmware matches the `canu.yaml` file.

## JSON Output

To get the JSON output from a single switch, or from multiple switches, make sure to use the `--json` flag. An example JSON output is below.

```ShellSession
canu --shasta 1.4 network firmware --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD –json
```

```json
    {
    "192.168.1.1": {
        "status": "Pass",
        "hostname": "test-switch-spine01",
        "platform_name": "8325",
        "firmware": {
            "current_version": "GL.10.06.0010",
            "primary_version": "GL.10.06.0010",
            "secondary_version": "GL.10.05.0020",
            "default_image": "primary",
            "booted_image": "primary",
        },
    },
    "192.168.1.2": {
        "status": "Pass",
        "hostname": "test-switch-leaf01",
        "platform_name": "6300",
        "firmware": {
            "current_version": "FL.10.06.0010",
            "primary_version": "FL.10.06.0010",
            "secondary_version": "FL.10.05.0020",
            "default_image": "primary",
            "booted_image": "primary",
        },
    },
    }
```

## Check Single Switch Cabling

CANU can also use LLDP to check the cabling status of a switch. To check the cabling of a single switch, run the following:

```ShellSession
canu --shasta 1.5 switch cabling --ip 192.168.1.1 --username USERNAME --password PASSWORD
```

Expected results:

```text
    Switch: test-switch-spine01 (192.168.1.1)
    Aruba 8325
    ------------------------------------------------------------------------------------------- -----------------------------------------------
    PORT        NEIGHBOR       NEIGHBOR PORT      PORT DESCRIPTION                                      DESCRIPTION
    ------------------------------------------------------------------------------------------- -----------------------------------------------
    1/1/1   ==>                00:00:00:00:00:01  No LLDP data, check ARP vlan info.                        192.168.1.20:vlan1, 192.168.2.12:vlan2
    1/1/3   ==> ncn-test2      00:00:00:00:00:02  mgmt0                                                     Linux ncn-test2
    1/1/5   ==> ncn-test3      00:00:00:00:00:03  mgmt0                                                     Linux ncn-test3
    1/1/7   ==>                00:00:00:00:00:04  No LLDP data, check ARP vlan info.                        192.168.1.10:vlan1, 192.168.2.9:vlan2
    1/1/51  ==> test-spine02   1/1/51                                                                       Aruba JL635A  GL.10.06.0010
    1/1/52  ==> test-spine02   1/1/52                                                                       Aruba JL635A  GL.10.06.0010
```

Sometimes when checking cabling using LLDP, the neighbor does not return any information except a MAC address. When that is the case,
CANU looks up the MAC address in the ARP table, and displays the IP addresses and VLAN information associated with that MAC.

Entries in the table will be colored based on what they are. For example: Neighbors that have `ncn` in their name will be colored
blue. Neighbors that have a port labeled (not a MAC address) are generally switches and are labeled green. Ports that are duplicated
will be bright white.

## Check Cabling of Multiple Switches

The cabling of multiple Aruba switches on a network can be checked at the same time using LLDP.

An example of checking the cabling of multiple switches:

```ShellSession
canu --shasta 1.5 network cabling --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

There are two different `--view` options: `switch` and `equipment`:

* `--view switch` option: Displays a table for every switch IP address passed in showing connections. This is the same view as shown in the above example of checking single switch cabling.
* `--view equipment` option: Displays a table for each MAC address connection. This means that servers and switches will both display incoming and outgoing connections.

An example of checking the cabling of multiple switches and displaying with the equipment view:

```ShellSession
canu --shasta 1.5 network cabling --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD --view equipment`
```

```ShellSession
canu --shasta 1.4 network cabling --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD --view equipment
```

Expected results:

```text
    sw-spine01 Aruba JL635A  GL.10.06.0010
    aa:aa:aa:aa:aa:aa
    -------------------------------------------------------------------------------------------
    1/1/1                     <==> sw-spine02      1/1/1  Aruba JL635A  GL.10.06.0010
    1/1/3                     ===>                 00:00:00:00:00:00 mgmt1
    1/1/4                     ===> ncn-test        bb:bb:bb:bb:bb:bb mgmt1 Linux ncn-test

    sw-spine02 Aruba JL635A  GL.10.06.0010 bb:bb:bb:bb:bb:bb
    -------------------------------------------------------------------------------------------
    1/1/1                     <==> sw-spine01      1/1/1  Aruba JL635A  GL.10.06.0010 00:00:00:00:00:00 192.168.2.2:vlan3, 192.168.1.2:vlan1
```

## Validate SHCD

CANU can be used to perform basic validation of an SHCD (Shasta Cabling Diagram) file.

In order to check an SHCD, run the following:

```ShellSession
canu -s 1.5 validate shcd -a tds --shcd FILENAME.xlsx --tabs 25G_10G,NMN,HMN --corners I14,S25,I16,S22,J20,T39
```

Expected results:

```text
    SHCD Node Connections
    ------------------------------------------------------------
    0: sw-spine-001 connects to 6 nodes: [1, 2, 3, 4, 5, 6]
    1: sw-spine-002 connects to 6 nodes: [0, 2, 3, 4, 5, 6]
    2: sw-leaf-bmc-001 connects to 2 nodes: [0, 1]
    3: uan001 connects to 2 nodes: [0, 1]
    4: ncn-s001 connects to 2 nodes: [0, 1]
    5: ncn-w001 connects to 2 nodes: [0, 1]
    6: ncn-m001 connects to 2 nodes: [0, 1]

    Warnings

    Node type could not be determined for the following
    ------------------------------------------------------------
    CAN switch
```

## Validate Cabling

CANU can be used to perform basic validation of network cabling.

In order to validate the cabling, run the following:

```ShellSession
canu -s 1.4 validate cabling -a tds --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

```ShellSession
canu -s 1.4 validate cabling -a tds --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

Expected results:

```text
    Cabling Node Connections
    ------------------------------------------------------------
    0: sw-spine-001 connects to 10 nodes: [1, 2, 3, 4]
    1: ncn-m001 connects to 2 nodes: [0, 4]
    2: ncn-w001 connects to 2 nodes: [0, 4]
    3: ncn-s001 connects to 2 nodes: [0, 4]
    4: sw-spine-002 connects to 10 nodes: [0, 1, 2, 3 ]

    Warnings

    Node type could not be determined for the following
    ------------------------------------------------------------
    sw-leaf-001
    sw-spine-001     1/1/1     ===> aa:aa:aa:aa:aa:aa
    sw-spine-001     1/1/2     ===> 1/1/1 CFCANB4S1 Aruba JL479A  TL.10.03.0081
    sw-spine-001     1/1/3     ===> 1/1/3 sw-leaf-001 Aruba JL663A  FL.10.06.0010
    sw-spine-002     1/1/4     ===> bb:bb:bb:bb:bb:bb
    sw-spine-002     1/1/5     ===> 1/1/2 CFCANB4S1 Aruba JL479A  TL.10.03.0081
    sw-spine-002     1/1/6     ===> 1/1/6 sw-leaf-001 Aruba JL663A  FL.10.06.0010
    Nodes that show up as MAC addresses might need to have LLDP enabled.

    The following nodes should be renamed
    ------------------------------------------------------------
    sw-leaf01 should be renamed (could not identify node)
    sw-spine01 should be renamed sw-spine-001
    sw-spine02 should be renamed sw-spine-002
```

If there are any nodes that cannot be determined or should be renamed, there will be warning tables that show the details.

## Validate SHCD and Cabling

CANU can be used to validate an SHCD against the current network cabling.

In order to validate an SHCD against the cabling, run the following:

```ShellSession
canu -s 1.5 validate shcd-cabling -a tds --shcd FILENAME.xlsx --tabs 25G_10G,NMN --corners I14,S49,I16,S22 --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD`
```

```ShellSession
canu -s 1.5 validate shcd-cabling -a tds --shcd FILENAME.xlsx --tabs 25G_10G,NMN --corners I14,S49,I16,S22 --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

Expected results:

```text
    ====================================================================================================
    SHCD
    ====================================================================================================

    SHCD Node Connections
    ------------------------------------------------------------
    0: sw-spine-001 connects to 6 nodes: [1, 2, 3, 4, 5, 6]
    1: sw-spine-002 connects to 6 nodes: [0, 2, 3, 4, 5, 6]
    2: sw-leaf-bmc-001 connects to 2 nodes: [0, 1]
    3: uan001 connects to 2 nodes: [0, 1]
    4: ncn-s001 connects to 2 nodes: [0, 1]
    5: ncn-w001 connects to 2 nodes: [0, 1]
    6: ncn-m001 connects to 2 nodes: [0, 1]

    Warnings

    Node type could not be determined for the following
    ------------------------------------------------------------
    CAN switch

        ====================================================================================================
    Cabling
    ====================================================================================================

    Cabling Node Connections
    ------------------------------------------------------------
    0: sw-spine-001 connects to 10 nodes: [1, 2, 3, 4]
    1: ncn-m001 connects to 2 nodes: [0, 4]
    2: ncn-w001 connects to 2 nodes: [0, 4]
    3: ncn-s001 connects to 2 nodes: [0, 4]
    4: sw-spine-002 connects to 10 nodes: [0, 1, 2, 3 ]

    Warnings

    Node type could not be determined for the following
    ------------------------------------------------------------
    sw-leaf-001
    sw-spine-001     1/1/1     ===> aa:aa:aa:aa:aa:aa
    sw-spine-001     1/1/2     ===> 1/1/1 CFCANB4S1 Aruba JL479A  TL.10.03.0081
    sw-spine-001     1/1/3     ===> 1/1/3 sw-leaf-001 Aruba JL663A  FL.10.06.0010
    sw-spine-002     1/1/4     ===> bb:bb:bb:bb:bb:bb
    sw-spine-002     1/1/5     ===> 1/1/2 CFCANB4S1 Aruba JL479A  TL.10.03.0081
    sw-spine-002     1/1/6     ===> 1/1/6 sw-leaf-001 Aruba JL663A  FL.10.06.0010
    Nodes that show up as MAC addresses might need to have LLDP enabled.

    The following nodes should be renamed
    ------------------------------------------------------------
    sw-leaf01 should be renamed (could not identify node)
    sw-spine01 should be renamed sw-spine-001
    sw-spine02 should be renamed sw-spine-002

    ====================================================================================================
    SHCD vs Cabling
    ====================================================================================================

    SHCD / Cabling Comparison
    ------------------------------------------------------------
    sw-spine-001    : Found in SHCD and on the network, but missing the following connections on the network that were found in the SHCD:
                ['sw-leaf-bmc-001', 'uan001']
    sw-spine-002    : Found in SHCD and on the network, but missing the following connections on the network that were found in the SHCD:
                ['sw-leaf-bmc-001', 'uan001']
    sw-leaf-bmc-001 : Found in SHCD but not found on the network.
    uan001          : Found in SHCD but not found on the network.
```

The output of the `validate shcd-cabling` command will show the results for `validate shcd`, `validate cabling`, and a comparison of the two results.
A node will be displayed in blue if it is found in the SHCD but not the network, or vice versa. If a node is found on both the network and in the SHCD,
but the connections are not the same, that node will be shown in green, and the missing connections will be shown.

## Validate BGP

CANU can be used to validate BGP neighbors. All neighbors of a switch must return status `Established` or the verification will fail.

The default `asn` is set to `65533`. If needed, use the `--asn` flag to set a different number.

In order to see the individual status of all the neighbors of a switch, use the `--verbose` flag.

In order to validate BGP, run the following command:

```ShellSession
canu -s 1.5 validate bgp --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

```ShellSession
canu -s 1.4 validate bgp --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

Expected results:

```text
    BGP Neighbors Established
    --------------------------------------------------
    PASS - IP: 192.168.1.1 Hostname: sw-spine01
    PASS - IP: 192.168.1.2 Hostname: sw-spine01
```

If any of the spine switch neighbors for a connection other than `Established`, the switch will fail validation.

If a switch that is not a **spine** switch is tested, it will show in the results table as `SKIP`.

## Configuration Creation For BGP

CANU can be used to configure BGP for a pair of switches.

**WARNING:** This command will remove the previous configuration (BGP, prefix lists, route maps), then add prefix lists,
create route maps, update BGP neighbors, and write it all to the switch memory.

The network and NCN data can be read from one of two sources: the SLS API or a file generated by CSI.
See [CSI and SLS API Input to CANU](#csi-and-sls-api-input-to-canu).

In order to configure BGP, run the following:

```ShellSession
canu -s 1.5 config bgp --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

```ShellSession
canu -s 1.4 config bgp --ips 192.168.1.1,192.168.1.2 --username USERNAME --password PASSWORD
```

Expected. Results:

```text
    BGP Updated
    --------------------------------------------------
    192.168.1.1
    192.168.1.2
```

To print extra details (prefixes, NCN names, IP addresses), add the `--verbose` flag.

## Generate Switch Configurations

CANU can be used to generate switch configurations.

In order to generate a switch configuration, a valid SHCD must be passed in and system variables must be read in from either CSI output or the SLS API.
See [CSI and SLS API Input to CANU](#csi-and-sls-api-input-to-canu).

In order to generate a configuration for a specific switch, a hostname must  be passed in using the `--name` flag.

In order to generate a switch configuration, run the following:

```ShellSession
canu -s 1.5 switch config -a full --shcd FILENAME.xlsx --tabs 'INTER_SWITCH_LINKS,NON_COMPUTE_NODES,HARDWARE_MANAGEMENT,COMPUTE_NODES' --corners 'J14,T44,J14,T48,J14,T24,J14,T23' --csi-folder /CSI/OUTPUT/FOLDER/ADDRESS --name SWITCH_HOSTNAME --out FILENAME
```

```ShellSession
canu -s 1.4 switch config -a full --shcd FILENAME.xlsx --tabs INTER_SWITCH_LINKS,NON_COMPUTE_NODES,HARDWARE_MANAGEMENT,COMPUTE_NODES --corners J14,T44,J14,T48,J14,T24,J14,T23 --csi-folder /CSI/OUTPUT/FOLDER/ADDRESS --name sw-spine-001
```

```text
Expected results:

    <snippet>
    hostname sw-spine-001
    user admin group administrators password plaintext
    bfd
    no ip icmp redirect
    vrf CAN
    vrf keepalive
    ...
    ..
    </Snippet>
```
