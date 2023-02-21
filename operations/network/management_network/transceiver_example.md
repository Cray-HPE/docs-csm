# Example of the connections used in Shasta management network

<!-- markdownlint-disable MD013 -->
The intent of this guide is to give you an example of which transceivers would typically be used in Shasta management network. Please note that by this example does ***not*** work in every scenario and is simply made to give you an example of typical management network connections and they may or may not match how your specific setup is specified.

In this example we are going to go over what you would see in typical "full" topology setup where you have the following switches:

* Spine
* Leaf
* CDU
* Leaf-BMC

***Warning***

* The transceivers here may not fit to your specified scenario because of "speed" or "distance" between devices.
* The LLDP neighbor-info examples under the switches are only meant to give you can example of expected connections.

## Helpful links

To see cabling instructions for NCN's please refer to this document:

[Cable management network servers](cable_management_network_servers.md)

To get most up to date of supported transceivers, DAC cables, please go to Aruba support portal and search for "Transceiver guide":

[Aruba support portal](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches)

## Spine

Typically Spine is "JL636A Aruba 8325-32C 32p 100G Switch".

Spine typically only has connections to other switches, such as "spine", "leaf and so on.

Example LLDP neighbor-info output:

```bash
1/1/1       b8:d4:e7:d3:2d:00  1/1/53  sw-spine-001:1<==sw-leaf-002  120      sw-leaf-002
1/1/2       b8:d4:e7:43:62:00  1/1/53  sw-spine-001:2<==sw-leaf-001  120      sw-leaf-001
1/1/3       b8:d4:e7:40:56:00  1/1/53  sw-spine-001:3<==sw-leaf-004  120      sw-leaf-004
1/1/4       b8:d4:e7:43:d3:00  1/1/53  sw-spine-001:4<==sw-leaf-003  120      sw-leaf-003
1/1/15      44:5b:ed:83:f0:80  1/1/49  sw-spine-001:16<==sw-cdu-002  120      sw-cdu-002
1/1/16      44:5b:ed:83:11:00  1/1/49  sw-spine-001:15<==sw-cdu-001  120      sw-cdu-001
1/1/28      94:8e:d3:95:b3:79  1/1/1   sw-spine-001:sw-edge-002      120      sw-edge-002
1/1/29      94:8e:d3:95:af:59  1/1/1   sw-spine-001:sw-edge-001      120      sw-edge-001
1/1/30      54:80:28:ff:07:00  1/1/30  VSX keepalive                 120      sw-spine-002
1/1/31      54:80:28:ff:07:00  1/1/31  vsx isl                       120      sw-spine-002
1/1/32      54:80:28:ff:07:00  1/1/32  vsx isl                       120      sw-spine-002
```

***Most commonly used ports from "Spine" to other devices:***

* Spine to leaf

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE Aruba 100G QSFP28-QSFP28 1m Direct Attach Copper Cable (R0Z25A)

* Spine to CDU

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE JL309A Aruba X151 100G QSFP28 MPO Sr4 Mmf Xcvr (300ft)

* Spine to edge

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE JL307A Aruba 100g QSFP28-QSFP28 3M Direct attach cable.

* VSX and keep-alive connection between VSX pair of Spines

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE R0Z25A Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable

## Leaf

Typically Leaf is "JL635A Aruba 8325-48Y8C 48p 25G 8p 100G Switch".

Leaf typically has connections to other switches, such as "spine" and "Leaf-BMC. Leaf switches also have connections to:

* NCN Master Nodes
* NCN Worker Nodes
* NCN Storage Nodes
* NCN UAN Nodes

Example LLDP neighbor-info output:

```bash
1/1/1       14:02:ec:da:d4:38  lag 1  ncn-m001:ocp:1<==s...        120      ncn-m001
1/1/2       14:02:ec:d9:7a:60  lag 2  ncn-m002:ocp:1<==s...        120      ncn-m002
1/1/3       14:02:ec:da:d4:f8  lag 3  ncn-w001:ocp:1<==s...        120      ncn-w001
1/1/4       14:02:ec:d9:78:c8  lag 4  ncn-w002:ocp:1<==s...        120      ncn-w002
1/1/5       14:02:ec:da:d4:68  lag 5  ncn-w003:ocp:1<==s...        120      ncn-w003
1/1/6       14:02:ec:da:bc:51  lag 6  ncn-s001:ocp:2<==s...        120      ncn-s001
1/1/7       14:02:ec:da:bd:10  lag 7  ncn-s002:ocp:1<==s...        120      ncn-s002
1/1/13      14:02:ec:da:d5:71  lag 8  uan001:ocp:1<==sw-...        120      uan001
1/1/14      14:02:ec:da:d5:71  lag 8  uan002:ocp:1<==sw-...        120      uan002
1/1/47      b8:d4:e7:d3:2d:00  1/1/47 VSX keepalive                120      sw-leaf-002
1/1/48      88:3a:30:a9:69:80  1/1/52 sw-leaf-001:48<==sw-leaf...  120      sw-leaf-bmc-001
1/1/53      54:80:28:ff:a8:00  1/1/2  sw-leaf-001:53<==sw-spin...  120      sw-spine-001
1/1/54      54:80:28:ff:07:00  1/1/2  sw-leaf-001:54<==sw-spin...  120      sw-spine-002
1/1/55      b8:d4:e7:d3:2d:00  1/1/55 vsx isl                      120      sw-leaf-002
1/1/56      b8:d4:e7:d3:2d:00  1/1/56 vsx isl                      120      sw-leaf-002
```

***Most commonly used ports from "LEAF" to other devices:***

* Spine to leaf

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE Aruba 100G QSFP28-QSFP28 1m Direct Attach Copper Cable (R0Z25A)

* Leaf to Leaf-BMC

    Typically 25G connection.

    ***Example of transceiver used:*** HPE JL487A Aruba 25G SFP28 TO SFP28 0.65M DAC cable.

* Leaf to NCN-Master

    Typically 25G connection.

    ***Example of transceiver used:*** HP JL488A 25g SFP28 to SFP28 3M Direct attach cable.

* Leaf to NCN-Worker

    Typically 25G connection.

    ***Example of transceiver used:*** HP JL488A 25g SFP28 to SFP28 3M Direct attach cable.

* Leaf to NCN-Storage

    Typically 25G connection.

    ***Example of transceiver used:*** HP JL488A 25g SFP28 to SFP28 3M Direct attach cable.

* Leaf to NCN-UAN

    Typically 25G connection.

    ***Example of transceiver used:*** HP JL488A 25g SFP28 to SFP28 3M Direct attach cable.

* VSX connection between VSX pair of leaf switches

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE R0Z25A Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable

* Keep-alive connection between pair of Leaf switches.

    25G or 10G depending on system configuration.

    ***Example of transceiver used:*** HPE J9150D Aruba - SFP+ transceiver module - 10 GigE

## CDU

Typically CDU is "JL720C 8360-48XT4C v2 Switch".

CDU typically has connection Leaf switches and they also have connections to:

* Mountain management
  * CMM (Chassis Management Module)
  * CEC (Cabinet Environment Controller)

Example LLDP neighbor-info output:

```bash
1/1/1       33:22:11:00:11:22  cmm-x1000-000:1<==...               120      cmm-x1000-000
1/1/2       33:22:11:00:11:22  cmm-x1000-001:1<==...               120      cmm-x1000-001
1/1/3       33:22:11:00:11:22  cmm-x1000-002:1<==...               120      cmm-x1000-002
1/1/4       33:22:11:00:11:22  cmm-x1000-003:1<==...               120      cmm-x1000-003
1/1/5       33:22:11:00:11:22  cmm-x1000-004:1<==...               120      cmm-x1000-004
1/1/6       33:22:11:00:11:22  cmm-x1000-005:1<==...               120      cmm-x1000-005
1/1/47      44:5b:ed:83:f0:80  1/1/47 VSX keepalive                120      sw-cdu-002
1/1/48      44:5b:ed:81:ee:80         cec-x1000-000:1<==...        120      cec-x1000-000
1/1/49      54:80:28:ff:a8:00  1/1/16 sw-cdu-002:49<==sw-spine...  120      sw-spine-001
1/1/50      54:80:28:ff:a8:00  1/1/16 sw-cdu-001:49<==sw-spine...  120      sw-spine-002
1/1/51      44:5b:ed:83:f0:80  1/1/51 vsx isl                      120      sw-cdu-002
1/1/52      44:5b:ed:83:f0:80  1/1/52 vsx isl                      120      sw-cdu-002
```

***Most commonly used ports from "UAN" to other devices:***

* CDU to Spine

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE JL309A Aruba X151 100G QSFP28 MPO Sr4 Mmf Xcvr (300ft)

* CDU to CEC

    Typically 10G connection.

    ***Example of transceiver used:*** No transceiver used, typically a 10G copper connection.

* CDU to CMM

    Typically 10G connection.

    ***Example of transceiver used:*** No transceiver used, typically a 10G copper connection.

* VSX connection between VSX pair of CDU switches

    100G or 25G depending on system configuration.

    ***Example of transceiver used:*** HPE R0Z25A Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable

* Keep-alive connection between pair of Leaf switches.

    Typically 10G connection

    ***Example of transceiver used:*** No transceiver used, typically a 10G copper connection.

## Leaf-BMC

Typically Leaf-BMC is "JL663A 6300M 48G 4SFP56 Switch".

Leaf typically has connection Leaf switches and they also have connections to:

* NCN Master ILO
* NCN Worker ILO
* NCN Storage ILO
* NCN UAN ILO
* PDU (power strip)

Example LLDP neighbor-info output:

```bash
1/1/34                         1/1/48  ncn-m002:bmc:1<==s...        120      ncn-m002
1/1/35                         1/1/48  ncn-w001:bmc:1<==s...        120      ncn-w001
1/1/36                         1/1/48  ncn-w002:bmc:1<==s...        120      ncn-w002
1/1/37                         1/1/48  ncn-w003:bmc:1<==s...        120      ncn-w003
1/1/38                         1/1/48  ncn-s001:bmc:1<==s...        120      ncn-s001
1/1/39                         1/1/48  ncn-s002:bmc:1<==s...        120      ncn-s002
1/1/40                         1/1/48  uan001:bmc:1<==sw-...        120      uan001
1/1/41                         1/1/48  uan002:bmc:1<==sw-...        120      uan002
1/1/51      b8:d4:e7:d3:2d:00  1/1/48  sw-leaf-bmc-001:51<==sw-...  120      sw-leaf-002
1/1/52      b8:d4:e7:43:62:00  1/1/48  sw-leaf-bmc-001:52<==sw-...  120      sw-leaf-001
```

***Most commonly used port speeds from "Leaf-BMC" to other devices:***

* Leaf-BMC to Leaf

    Typically 25G connection.

    ***Example of transceiver used:*** HPE JL487A Aruba 25G SFP28 TO SFP28 0.65M DAC cable.

* Leaf to NCN-Master

    Typically 1G connection.

    ***Example of transceiver used:*** No transceiver used, typically a 1G copper connection.

* Leaf to NCN-Worker

    Typically 1G connection.

    ***Example of transceiver used:*** No transceiver used, typically a 1G copper connection.

* Leaf to NCN-Storage

    Typically 1G connection.

    ***Example of transceiver used:*** No transceiver used, typically a 1G copper connection.

* Leaf to NCN-UAN

    Typically 1G connection.

    ***Example of transceiver used:*** No transceiver used, typically a 1G copper connection.
