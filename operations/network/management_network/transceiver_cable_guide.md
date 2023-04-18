<!-- markdownlint-disable MD013 -->
# Transceivers and Cables

The intent of this guide is to help administrators choose correct cabling and transceivers for Shasta management network. It is not
intended to be a "how to" guide on system cabling.

NOTE: Networking vendors may change supported devices or required software versions without notification.

## Tips for navigating the cabling guide

The supported transceivers are broken down by vendor and have direct links to vendor sites for more information.

To check what transceivers would typically be used in an installation, see [Transceiver examples guide](transceiver_example.md).

## Vendors

* [Aruba](#aruba)
* [Mellanox](#mellanox)
* [Dell](#dell)

### Aruba

For the most up-to-date information on supported transceivers and DAC cables, search for "Transceiver guide" on the
[Aruba support portal](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches).

While Aruba does support third-party transceivers with the `allow-unsupported-transceiver` command, some
transceivers may not work. For example, it has been reported from the field that transceivers from ENET do not work with Aruba switches.

#### JL635A Aruba 8325-48Y8C 48p 25G 8p 100G Switch

Supports 48 ports of 1G/10G/25GbE (SFP/SFP+/SFP28) and 8 ports of 40G/100GbE (QSFP+/QSFP28) \[optional 1GBASE-T and 10GBASE-T transceivers, 4x10G and 4x25G breakout cables\].

NOTE: In this particular model, the interfaces are organized into interface groups of 12 ports each. The default speed setting is 25Gb.
If there is a mix of devices with different port speeds, then the administrator must choose which port groups will support 10G devices;
all 12 ports in that group will be set with that speed. This means that it is not possible, for example, to put both a 10G device and
a 25Gb device in the same group.

(`sw#`) The port groups and speeds can be displayed by running the following command on the switch.

```text
sh system interface-group
```

Example output:

```text
------------------------------------------------
Group  Speed  Member Ports      Mismatched Ports
------------------------------------------------
1      25g    1/1/1-1/1/12
2      25g    1/1/13-1/1/24
3      25g    1/1/25-1/1/36
4      25g    1/1/37-1/1/48
```

##### JL635A Aruba 8325-48Y8C: 1G Transceivers

* Aruba 1G SFP LC SX 500m MMF Transceiver (J4858D)
* Aruba 1G SFP LC LX 10km SMF Transceiver (J4859D)
* Aruba 1G SFP LC LH 70km SMF Transceiver (J4860D)
* Aruba 1G SFP RJ45 T 100m Cat5e Transceiver (J8177D)

##### JL635A Aruba 8325-48Y8C: 10G Transceivers and cables

* Aruba 10G SFP+ LC SR 300m MMF Transceiver (J9150D)
* Aruba 10G SFP+ LC LR 10km SMF Transceiver (J9151E)
* Aruba 10G SFP+ LC ER 40km SMF Transceiver (J9153D)
* Aruba 10GBASE-T SFP+ RJ-45 30m Cat6A Transceiver (JL563A)
* Aruba 10G SFP+ to SFP+ 1m Direct Attach Copper Cable (J9281D)
* Aruba 10G SFP+ to SFP+ 3m Direct Attach Copper Cable (J9283D)

##### JL635A Aruba 8325-48Y8C: 25G Transceivers and cables

* Aruba 25G SFP28 LC SR 100m MMF Transceiver (JL484A)
* Aruba 25G SFP28 LC eSR 400m MMF Transceiver (JL485A)
* Aruba 25G SFP28 LC LR 10km SMF Transceiver (JL486A)
* Aruba 25G SFP28 to SFP28 0.65m Direct Attach Copper Cable (JL487A)
* Aruba 25G SFP28 to SFP28 3m Direct Attach Copper Cable (JL488A)
* Aruba 25G SFP28 to SFP28 5m Direct Attach Copper Cable (JL489A)
* Aruba 25G SFP28 to SFP28 3m Active Optical Cable (R0M44A)
* Aruba 25G SFP28 to SFP28 7m Active Optical Cable (R0M45A)
* Aruba 25G SFP28 to SFP28 15m Active Optical Cable (R0Z21A)

##### JL635A Aruba 8325-48Y8C: 40G Transceivers and cables

* Aruba 40G QSFP+ LC BiDi 150m MMF Transceiver (JL308A)
* HPE X142 40G QSFP+ MPO SR4 Transceiver (JH231A)
* HPE X142 40G QSFP+ MPO eSR4 300M Transceiver (JH233A)
* HPE X142 40G QSFP+ LC LR4 SM Transceiver (JH232A)
* Aruba 40G QSFP+ LC ER4 40km SMF Transceiver (Q9G82A)
* HPE X242 40G QSFP+ to QSFP+ 1m Direct Attach Copper Cable (JH234A)
* HPE X242 40G QSFP+ to QSFP+ 3m Direct Attach Copper Cable (JH235A)
* HPE X242 40G QSFP+ to QSFP+ 5m Direct Attach Copper Cable (JH236A)
* Aruba 40G QSFP+ to QSFP+ 7m Active Optical Cable (R0Z22A)
* Aruba 40G QSFP+ to QSFP+ 15m Active Optical Cable (R0Z23A)
* Aruba 40G QSFP+ to QSFP+ 30m Active Optical Cable (R0Z24A)
* HPE QSFP+ to 4xSFP+ 3m Breakout Direct Attach Cable (721064-B21)

##### JL635A Aruba 8325-48Y8C: 100G Transceivers and cables

* Aruba 100G QSFP28 MPO SR4 MMF Transceiver (JL309A)
* Aruba 100G QSFP28 LC LR4 SMF Transceiver (JL310A)
* Aruba 100G QSFP28 LC CWDM4 2km SMF Transceiver (R0Z30A)
* Aruba 100G QSFP28 LC ER4L 40km SMF Transceiver (JL743A)
* Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable (R0Z25A)
* Aruba 100G QSFP28 to QSFP28 3m Direct Attach Copper Cable (JL307A)
* Aruba 100G QSFP28 to QSFP28 5m Direct Attach Copper Cable (R0Z26A)
* HPE (HIT) QSFP28 to 4xSFP28 3m Breakout Direct Attach Cable (845416-B21)

#### JL720A 8360-48XT4C Switch

* 48 ports of 100M/1GbE/10GBASE-T
* 4 ports of 40GbE/100GbE (QSFP+/QSFP28)

##### JL720A 8360-48XT4C: 40G Transceivers and cables

* Aruba 40G QSFP+ LC BiDi 150m MMF XCVR (JL308A)
* HPE X142 40G QSFP+ MPO SR4 Transceiver (JH231A)
* HPE X142 40G QSFP+ MPO eSR4 300M XCVR (JH233A)
* HPE X142 40G QSFP+ LC LR4 SM Transceiver (JH232A)
* Aruba 40G QSFP+ LC ER4 40km SMF XCVR (Q9G82A)
* HPE X242 40G QSFP+ to QSFP+ 1m DAC Cable (JH234A)
* HPE X242 40G QSFP+ to QSFP+ 3m DAC Cable (JH235A)
* HPE X242 40G QSFP+ to QSFP+ 5m DAC Cable (JH236A)
* HPE (Compute) QSFP+ to 4xSFP+ 3m Breakout Direct Attach Cable (721064-B21)
* HPE (Compute) HPE BLc QSFP+ to 4x10G SFP+ AOC 15m Opt (721076-B21)

##### JL720A 8360-48XT4C: 100G Transceivers and cables

* Aruba 100G QSFP28 MPO SR4 MMF Transceiver (JL309A)
* Aruba 100G QSFP28 LC LR4 SMF Transceiver (JL310A)
* Aruba 100G QSFP28-QSFP28 1m Direct Attach Copper Cable (R0Z25A)
* Aruba 100G QSFP28-QSFP28 3m Direct Attach Copper Cable (JL307A)
* Aruba 100G QSFP28-QSFP28 5m Direct Attach Copper Cable (R0Z26A)
* Aruba 100G QSFP28 to QSFP28 7m AOC (R0Z27A)
* Aruba 100G QSFP28 to QSFP28 15m AOC (R0Z28A)
* Aruba 100G QSFP28 to QSFP28 30m AOC (R0Z29A)
* HPE (Compute) QSFP28 to 4x25G SFP28 7m AOC (845420-B21)
* HPE (Compute) QSFP28 to 4x25G SFP28 15m AOC (845424-B21)
* HPE (Compute) QSFP28 to 4xSFP28 3m Breakout Direct Attach Cable (845416-B21)23

#### JL762A 6300M 48G 4SFP56 Pwr2Prt Switch

(48) 10/100/1000 BASE-T ports, (4) 1/10/25/50G SFP ports

##### JL762A 6300M: 1G Transceivers and cables

* Aruba 1G SFP LC SX 500m MMF Transceiver (J4858D)
* Aruba 1G SFP LC LX 10km SMF Transceiver (J4859D)
* Aruba 1G SFP LC LH 70km SMF Transceiver (J4860D)
* Aruba 1G SFP RJ45 T 100m Cat5e Transceiver (J8177D)
* Aruba 1G SFP LC SX 500m MMF TAA Transceiver (JL745A)
* Aruba 1G SFP LC LX 10km SMF TAA Transceiver (JL746A)
* Aruba 1G SFP RJ45 T 100m Cat5e TAA Transceiver (JL747A)

##### JL762A 6300M: 10G Transceivers and cables

* Aruba 10G SFP+ LC SR 300m MMF Transceiver (J9150D)
* Aruba 10G SFP+ LC LRM 220m MMF Transceiver (J9152D)
* Aruba 10G SFP+ LC LR 10km SMF Transceiver (J9151E)
* Aruba 10G SFP+ LC ER 40km SMF Transceiver (J9153D)
* Aruba 10GBASE-T SFP+ RJ-45 30m Cat6A Transceiver (JL563B)
* Aruba 10G SFP+ LC SR 300m MMF TAA Transceiver (JL748A)
* Aruba 10G SFP+ LC LR 10km SMF TAA Transceiver (JL749A)

##### JL762A 6300M: 25G Transceivers and cables

* Aruba 25G SFP28 LC SR 100m MMF Transceiver (JL484A)
* Aruba 25G SFP28 LC eSR 400m MMF Transceiver (JL485A)
* Aruba 25G SFP28 LC LR 10km SMF Transceiver (JL486A)

##### JL762A 6300M: 50G Transceivers and cables

* Aruba 50G SFP56 LC SR 100m MMF XCVR (R0M48A)

##### JL762A 6300M: Direct attach cables

* Aruba 10G SFP+ to SFP+ 1m Direct Attach Copper Cable
(J9281D)
* Aruba 10G SFP+ to SFP+ 3m Direct Attach Copper Cable
(J9283D)
* Aruba 25G SFP28 to SFP28 0.65m Direct Attach Copper
Cable (JL487A)
* Aruba 25G SFP28 to SFP28 3m Direct Attach Copper
Cable (JL488A)
* Aruba 25G SFP28 to SFP28 5m Direct Attach Copper
Cable (JL489A)
* Aruba 50G SFP56 to SFP56 0.65m DAC Cable (R0M46A)
* Aruba 50G SFP56 to SFP56 3m DAC Cable (R0M47A

#### JL636A Aruba 8325-32C 32p 100G Switch

32 QSFP+/QSFP28 40/100G Transceivers

##### JL636A Aruba 8325-32C: 40G Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* Aruba 40G QSFP+ LC BiDi 150m MMF Transceiver (JL308A)
* HPE X142 40G QSFP+ MPO SR4 Transceiver (JH231A)
* HPE X142 40G QSFP+ MPO eSR4 300M Transceiver (JH233A)
* HPE X142 40G QSFP+ LC LR4 SM Transceiver (JH232A)
* Aruba 40G QSFP+ LC ER4 40km SMF Transceiver (Q9G82A)
* HPE X242 40G QSFP+ to QSFP+ 1m Direct Attach Copper Cable (JH234A)
* HPE X242 40G QSFP+ to QSFP+ 3m Direct Attach Copper Cable (JH235A)
* HPE X242 40G QSFP+ to QSFP+ 5m Direct Attach Copper Cable (JH236A)
* Aruba 40G QSFP+ to QSFP+ 7m Active Optical Cable (R0Z22A)
* Aruba 40G QSFP+ to QSFP+ 15m Active Optical Cable (R0Z23A)
* Aruba 40G QSFP+ to QSFP+ 30m Active Optical Cable (R0Z24A)
* HPE QSFP+ to 4xSFP+ 3m Breakout Direct Attach Cable (721064-B21)

##### JL636A Aruba 8325-32C: 100G Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* Aruba 100G QSFP28 MPO SR4 MMF Transceiver (JL309A)
* Aruba 100G QSFP28 LC LR4 SMF Transceiver (JL310A)
* Aruba 100G QSFP28 LC CWDM4 2km SMF Transceiver (R0Z30A)
* Aruba 100G QSFP28 LC ER4L 40km SMF Transceiver (JL743A)
* Aruba 100G QSFP28 to QSFP28 1m Direct Attach Copper Cable (R0Z25A)
* Aruba 100G QSFP28 to QSFP28 3m Direct Attach Copper Cable (JL307A)
* Aruba 100G QSFP28 to QSFP28 5m Direct Attach Copper Cable (R0Z26A)
* HPE (HIT) QSFP28 to 4xSFP28 3m Breakout Direct Attach Cable (845416-B21)

#### R8Z96A Aruba 9300-32D 32-port 100/200/400G QSFP-DD 2-port 10G Switch

* 32-ports of 100GbE, 200GbE or 400GbE
* 2-ports of 10GbE

##### R8Z96A Aruba 9300-32D: 100G Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* R9B63A Aruba 100G QSFP28 LC FR1 SMF 2km Transceiver

##### R8Z96A Aruba 9300-32D: 200G Transceivers and cables

* R9B60A Aruba 200G QSFP-DD to 2x QSFP28 100G 3m Active Optical Cable
* R9B58A Aruba 200G QSFP-DD to 2x QSFP28 100G 7m Active Optical Cable
* R9B62A Aruba 200G QSFP-DD to 2x QSFP28 100G 15m Active Optical Cable
* R9B61A Aruba 200G QSFP-DD to 2x QSFP28 100G 30m Active Optical Cable
* R9B59A Aruba 200G QSFP-DD to 2x QSFP28 100G 50m Active Optical Cable

##### R8Z96A Aruba 9300-32D: 400G Transceivers and cables

* R9B45A Aruba 400G QSFP-DD to QSFP-DD 3m Active Optical Cable
* R9B43A Aruba 400G QSFP-DD to QSFP-DD 7m Active Optical Cable
* R9B47A Aruba 400G QSFP-DD to QSFP-DD 15m Active Optical Cable
* R9B46A Aruba 400G QSFP-DD to QSFP-DD 30m Active Optical Cable
* R9B44A Aruba 400G QSFP-DD to QSFP-DD 50m Active Optical Cable
* R9B41A Aruba 400G QSFP-DD MPO-16 SR8 100m MMF Transceiver
* R9B42A Aruba 400G QSFP-DD MPO-12 eDR4 2km SMF Transceiver

##### R8Z96A Aruba 9300-32D: 400G to 200G/100G splitter cables

* R9B55A Aruba 400G QSFP-DD to 2x QSFP56 200G 3m Active Optical Cable
* R9B53A Aruba 400G QSFP-DD to 2x QSFP56 200G 7m Active Optical Cable
* R9B57A Aruba 400G QSFP-DD to 2x QSFP56 200G 15m Active Optical Cable
* R9B56A Aruba 400G QSFP-DD to 2x QSFP56 200G 30m Active Optical Cable
* R9B54A Aruba 400G QSFP-DD to 2x QSFP56 200G 50m Active Optical Cable
* R9B50A Aruba 400G QSFP-DD to 4x QSFP56 100G 3m Active Optical Cable
* R9B48A Aruba 400G QSFP-DD to 4x QSFP56 100G 7m Active Optical Cable
* R9B52A Aruba 400G QSFP-DD to 4x QSFP56 100G 15m Active Optical Cable
* R9B51A Aruba 400G QSFP-DD to 4x QSFP56 100G 30m Active Optical Cable
* R9B49A Aruba 400G QSFP-DD to 4x QSFP56 100G 50m Active Optical Cable

### Mellanox

[Mellanox support portal](https://www.nvidia.com/en-us/support/enterprise/)

#### SN2100

Supports speeds of 1/10/25/40/50 and 100GbE.

* QQSFP28, SFP28 short and long range optics
* QQSFP28 to QSFP28 DAC cable
* QQSFP breakout cables 100GbE to 4x25GbE and 40GbE to 4x10GbE DAC, optical
* QQSFP breakout cables 100GbE to 2x50GbE DAC, optical
* QQSFP AOC
* Q1000BASE-T and 1000BASE-SX/LX/ZX modules

> Systems limited to 10/40GbE will support modules and cables accordingly.

#### SN2700

Supports speeds of 1/10/25/40/50 and 100GbE.

* QSFP28, SFP28 (with QSA) short and long range optics
* QQSFP28 to QSFP28 DAC Cable
* QQSFP breakout cables 100GbE to 4x25GbE DAC, Optical
* QQSFP breakout cables 100GbE to 2x50GbE DAC, Optical
* QQSFP AOC

> Systems limited to 40GbE will support modules and cables accordingly.

### Dell

[Dell support portal](https://www.dell.com/support/home/en-us)

#### Dell S3048-ON switch series

##### Dell S3048-ON: 100m Transceivers and cables

* Transceiver, SFP, 100BASE-FX, 1310nm wavelength, up to 2km reach

##### Dell S3048-ON: 1G Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* Transceiver, SFP, 1000BASE-T
* Transceiver, SFP, 1000BASE-SX, 850nm wavelength, up to 550m reach
* Transceiver, SFP, 1000BASE-LX, 1310nm wavelength, up to 10km reach
* Transceiver, SFP, 1000BASE-ZX, 1550nm wavelength, up to 80km reach

##### Dell S3048-ON: 10G Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* Transceiver, SFP+, 10GbE, LRM, 1310nm wavelength, up to 220m reach
* Transceiver, SFP+, 10GbE, SR, 850nm wavelength, up to 300m reach
* Transceiver, SFP+, 10GbE, LR, 1310nm wavelength, up to 10km reach
* Transceiver, SFP+, 10GbE, ER, 1550nm wavelength, up to 40km reach
* Transceiver, SFP+, 10GbE, ZR, 1550nm wavelength, up to 80km reach

##### Dell S3048-ON: Direct attach cables <!-- markdownlint-disable-line MD024 MD026 -->

* Dell EMC Networking cable, SFP+ to SFP+, 10GbE, copper twinax direct attach cable, 0.5m
* Dell EMC Networking cable, SFP+ to SFP+, 10GbE, copper twinax direct attach cable, 1m
* Dell EMC Networking cable, SFP+ to SFP+, 10GbE, copper twinax direct attach cable, 3m
* Dell EMC Networking cable, SFP+ to SFP+, 10GbE, copper twinax direct attach cable, 5m
* Dell EMC Networking cable, SFP+ to SFP+, 10GbE, copper twinax direct attach cable, 7m
* Dell EMC Networking Cable, SFP+ to SFP+, 10GbE, Active Optical Cable, 15m

#### Dell S4148T-ON switch series

[Dell transceiver guide](https://www.delltechnologies.com/asset/en-us/products/networking/technical-support/Dell_EMC_Networking_Optics_Spec_Sheet.pdf)

* 48xSFP+
* 2xQSFP+
* 4xQSFP28

##### Dell S4148T-ON: 10GG Transceivers and cables

* SFP-10G
* USR SFP-10G
* SR SFP-10G
* LRM SFP-10G-LR
* SFP-10G-ER
* SFP-10G-ZR
* SFP-10G-T
* DWDM SFP-10G-T

##### Dell S4148T-ON: 40GbE Transceivers

* QSFP-40G-SR4
* QSFP-40G-ESR4
* QSFP-40G-LM4
* QSFP-40G-SM4
* QSFP-40G-BIDI
* QSFP-40G-PSM4-LR
* QSFP-40G-LR4
* QSFP-40G-ER4

##### Dell S4148T-ON: 100G Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* Q28-100G-FR
* Q28-100G-SR4
* Q28-100G-ESR4
* Q28-100G-BIDI
* Q28-100G-SWDM4
* Q28-100G-CWDM4
* Q28-100G-LR4
* Q28-100G-ER4-lite
* Q28-100G-DWDM2

#### Dell S4148F-ON switch series

[Dell transceiver guide](https://www.delltechnologies.com/asset/en-us/products/networking/technical-support/Dell_EMC_Networking_Optics_Spec_Sheet.pdf)

* 48xSFP+
* 2xQSFP+
* 4xQSFP28

##### Dell S4148F-ON: 10GG Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* SFP-10G
* USR SFP-10G
* SR SFP-10G
* LRM SFP-10G-LR
* SFP-10G-ER
* SFP-10G-ZR
* SFP-10G-T
* DWDM SFP-10G-T

##### Dell S4148F-ON: 40GbE transceivers <!-- markdownlint-disable-line MD024 MD026 -->

* QSFP-40G-SR4
* QSFP-40G-ESR4
* QSFP-40G-LM4
* QSFP-40G-SM4
* QSFP-40G-BIDI
* QSFP-40G-PSM4-LR
* QSFP-40G-LR4
* QSFP-40G-ER4

##### Dell S4148F-ON: 100G Transceivers and cables <!-- markdownlint-disable-line MD024 MD026 -->

* Q28-100G-FR
* Q28-100G-SR4
* Q28-100G-ESR4
* Q28-100G-BIDI
* Q28-100G-SWDM4
* Q28-100G-CWDM4
* Q28-100G-LR4
* Q28-100G-ER4-lite
* Q28-100G-DWDM2
