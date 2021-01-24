# Firmware

## NCNs

Firmware is not updated during fresh-install. The bootstrap environment has capacity to upgrade, but it is more imperitive to standup services for a autonomy from the liveCD.

NCN firmware is updated following install by various firmware update services in the management plane (i.e. FAS). This can be done after the platform is online, after rebooting from the LiveCD.

Firmware upgrades while the LiveCD is in flight can be done, but are not part of the normal install flow. This is seen as triage, or recovery

## CNs (compute)

Firmware needs to be updated prior to install through the same services used for NCNs.

## Management Switches

Firmware needs to be updated prior to install.

| Vendor | Model | Version	|
| --- | --- | ---| --- | --- | --- | --- |
| Aruba | 6300 | ArubaOS-CX_6400-6300_10.05.0040 |
| Aruba | 8320 | ArubaOS-CX_8320_10.05.0040 |
| Aruba | 8325 | ArubaOS-CX_8325_10.05.0040 |
| Dell | S3048-ON | 10.5.0.2P1 |
| Dell | S4148F-ON | 10.5.0.2P1 |
| Dell | S4148T-ON | 10.5.0.2P1 |
| Mellanox | MSN2100 | 3.9.1014 |
| Mellanox | MSN2700 | 3.9.1014 |
