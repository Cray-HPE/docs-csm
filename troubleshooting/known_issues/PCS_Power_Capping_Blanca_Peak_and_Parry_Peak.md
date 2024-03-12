# PCS Power Capping Blanca Peak and Parry Peak

The Power Control Service (PCS) is unable to place power caps on Blanca Peak (ex254n) and Parry Peak (ex255a) compute nodes in the CSM 1.5.0 release

This issue is fixed in the CSM 1.5.1 release.

To work around this issue in CSM 1.5.0, use CAPMC on these platforms rather than PCS.

Example equivalents of PCS and CAPMC commands are given below.

## Snapshots

### PCS:

* `cray power cap snapshot --xnames $XNAME`
* `cray power cap describe $POWERCAPID`

XNAME is the compute node xname you want to snapshot.

POWERCAPID comes from the `cray power cap snapshot --xnames $XNAME` output.

### CAPMC: 

* `cray capmc get_power_cap_capabilities create --nids $NID`
* `cray capmc get_power_cap create --nids $NID`

NID is the NID of the compute node you want to snapshot.

## Power Capping

### PCS:

* `cray power cap set --xnames $XNAME --control "${CONTROLNAME}" $VALUE`

XNAME is the compute node xname you want to set a power cap on.

CONTROLNAME is the power cap control name you want to target.

VALUE is the new power cap value you want to set.

### CAPMC:

* `cray capmc set_power_cap create --nids NID --control "${CONTROLNAME}" $VALUE`

NID is the NID of the compute node you want to set a power cap on.

CONTROLNAME is the power cap control name you want to target.

VALUE is the new power cap value you want to set.

