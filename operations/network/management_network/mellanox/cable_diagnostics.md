# Cable diagnostics 

Cable plugin collects various information from the cables attached to the fabric ports.

--get_cable_info	Gets cable info from the fabric ports.
--cable_info_disconnected	Gets cable info on disconnected ports (the cable is attached only to the switch port). This option is applicable with the "get-cable-info" flag.

Relevant Configuration 

Example:

```
ibdiagnet --get-cable-info --cable_info_disconnected

The data is dumped to the ibdiagnet2.cables file in the following format:
-------------------------------------------------------
Port=1 Lid=0x00a4 GUID=0xf45214030046a0a1 Port Name=coral-ufm-001/U1/P1
-------------------------------------------------------

Vendor: Mellanox
OUI: 0x2c9
PN: MCP1600-E002
SN: MT1739VS02126
Rev: A3
Length: 2 m
Type: Copper cable- unequalized
SupportedSpeed: SDR/DDR/QDR/FDR/EDR
Temperature: N/A
PowerClass: 1
NominalBitrate: 0 Gb/s
CDREnableTxRx: N/A N/A
InputEq: N/A
OutputAmp: N/A
OutputEmp: N/A
FW Version: N/A
Attenuation(5,7,12): 7 8 13
RX power type: OMA
RX1 Power: 0.000 mW, -999.999 dBm
RX2 Power: 0.000 mW, -999.999 dBm
RX3 Power: 0.000 mW, -999.999 dBm
RX4 Power: 0.000 mW, -999.999 dBm
TX1 Bias: 0.000 mA
TX2 Bias: 0.000 mA
TX3 Bias: 0.000 mA
TX4 Bias: 0.000 mA
TX1 Power: 0.000 mW, -999.999 dBm
TX2 Power: 0.000 mW, -999.999 dBm
TX3 Power: 0.000 mW, -999.999 dBm
TX4 Power: 0.000 mW, -999.999 dBm
```

Expected Results 

* Step 1: You can enter diagnostics mode successfully
* Step 2: You can test the cable and see the results in the CLI output 

[Back to Index](../index.md)