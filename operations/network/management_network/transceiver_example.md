# Example of the Connections Used in Shasta Management Network

The intent of this guide is to give an example of which transceivers would typically be used in Shasta management network.
Note that this example does ***not*** work in every scenario and is simply made to give an example of typical management network connections;
they may or may not match how any specific setup.

This example covers a typical "full" topology setup with the following switches:

* [Spine](#spine)
* [Leaf](#leaf)
* [CDU](#cdu)
* [Leaf-BMC](#leaf-bmc)

***Warning***

* The transceivers here may not fit all scenarios because of speed or distance between devices.
* The LLDP neighbor-info examples under the switches are only meant to give an example of expected connections.

## Helpful links

To see cabling instructions for NCNs, see [Cable Management Network Servers](cable_management_network_servers.md).

To get most up to date information on supported transceivers and DAC cables, go to the
[Aruba support portal](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches) and search for "Transceiver guide".

## Spine

A typical spine switch is `JL636A Aruba 8325-32C 32p 100G Switch`.

The spine typically only has connections to other switches, such as other spines, leaf switches, and so on.

Example LLDP `neighbor-info` output:

```text
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

### Spine: Most commonly used ports to other devices

| *Port type* | *Port description* | *Example of transceiver used* |
|-------------|--------------------|-------------------------------|
| Spine to leaf | 100G or 25G depending on system configuration | HPE Aruba `100G QSFP28-QSFP28 1m Direct Attach Copper Cable (R0Z25A)` |
| Spine to CDU | 100G or 25G depending on system configuration | HPE `JL309A Aruba X151 100G QSFP28 MPO Sr4 Mmf Xcvr (300ft)` |
| Spine to edge | 100G or 25G depending on system configuration | HPE `JL307A Aruba 100g QSFP28-QSFP28 3M` direct attach cable |
| VSX and `keep-alive` connection between VSX pair of spines | 100G or 25G depending on system configuration | HPE `R0Z25A Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable` |

## Leaf

A typical leaf switch is `JL635A Aruba 8325-48Y8C 48p 25G 8p 100G Switch`.

A leaf switch typically has connections to other switches, such as spines and `Leaf-BMC`.
Leaf switches also have connections to NCNs (masters, workers, storage, and UANs).

Example LLDP `neighbor-info` output:

```text
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

### Leaf: Most commonly used ports to other devices

| *Port type* | *Port description* | *Example of transceiver used* |
|-------------|--------------------|-------------------------------|
| Spine to leaf | 100G or 25G depending on system configuration | HPE Aruba `100G QSFP28-QSFP28 1m Direct Attach Copper Cable (R0Z25A)` |
| Leaf to `Leaf-BMC` | Typically 25G connection | HPE `JL487A Aruba 25G SFP28 TO SFP28 0.65M DAC cable` |
| Leaf to NCN | Typically 25G connection | HPE `JL488A 25g SFP28 to SFP28 3M Direct attach cable` |
| VSX connection between VSX pair of leaf switches | 100G or 25G depending on system configuration | HPE `R0Z25A Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable` |
| `Keep-alive` connection between pair of leaf switches | 25G or 10G depending on system configuration | HPE `J9150D Aruba - SFP+ transceiver module - 10 GigE` |

## CDU

A typical CDU switch is `JL720C 8360-48XT4C v2 Switch`.

A CDU switch typically has connections to leaf switches, and they also have connections to:

* Mountain management
  * CMM (Chassis Management Module)
  * CEC (Cabinet Environment Controller)

Example LLDP `neighbor-info` output:

```text
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

### CDU: Most commonly used ports to other devices

| *Port type* | *Port description* | *Example of transceiver used* |
|-------------|--------------------|-------------------------------|
| CDU to spine | 100G or 25G depending on system configuration | HPE `JL309A Aruba X151 100G QSFP28 MPO Sr4 Mmf Xcvr (300ft)` |
| CDU to CEC | Typically 10G connection | No transceiver used; typically a 10G copper connection |
| CDU to CMM | Typically 10G connection | No transceiver used; typically a 10G copper connection |
| VSX connection between VSX pair of CDU switches | 100G or 25G depending on system configuration | HPE `R0Z25A Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable` |
| `Keep-alive` connection between pair of CDU switches | Typically 10G connection | No transceiver used, typically a 10G copper connection |

## `Leaf-BMC`

A typical `Leaf-BMC` switch is `JL663A 6300M 48G 4SFP56 Switch`.

A `Leaf-BMC` switch typically has connections to leaf switches, and they also have connections to:

* NCN (master, worker, storage, and UAN) ILO
* PDU (power strip)

Example LLDP `neighbor-info` output:

```text
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

### `Leaf-BMC`: Most commonly used ports to other devices

| *Port type* | *Port description* | *Example of transceiver used* |
|-------------|--------------------|-------------------------------|
| `Leaf-BMC` to leaf | Typically 25G connection | HPE `JL487A Aruba 25G SFP28 TO SFP28 0.65M DAC cable` |
| `Leaf-BMC` to NCN ILO | Typically 1G connection | No transceiver used, typically a 1G copper connection |
