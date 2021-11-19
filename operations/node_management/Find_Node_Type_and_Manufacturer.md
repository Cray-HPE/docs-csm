## Find Node Type and Manufacturer

There are three different vendors providing nodes for air-cooled cabinets, which are Gigabyte, Intel, and HPE. The Hardware State Manager \(HSM\) contains the information required to determine which type of air-cooled node is installed. The endpoint returned in the HSM command can be used to determine the manufacturer.

HPE nodes contain the /redfish/v1/Systems/1 endpoint:

```
ncn-m001# cray hsm inventory componentEndpoints describe XNAME --format json | jq '.RedfishURL'
"x3000c0s18b0/redfish/v1/Systems/1"
```

Gigabyte nodes contain the /redfish/v1/Systems/Self endpoint:

```
ncn-m001# cray hsm inventory componentEndpoints describe XNAME --format json | jq '.RedfishURL'
"x3000c0s7b0/redfish/v1/Systems/Self"
```

Intel nodes contain the /redfish/v1/Systems/SERIAL\_NUMBER endpoint:

```
ncn-m001# cray hsm inventory componentEndpoints describe XNAME --format json | jq '.RedfishURL'
"x3000c0s15b0/redfish/v1/Systems/BQWT92000021"
```


