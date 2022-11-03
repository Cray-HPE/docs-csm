# Gigabyte BMC Missing Redfish Data

Follow this procedure if you notice data from Gigabyte nodes is missing from Hardware State Manager (HSM) or other CSM tools.

If data from Gigabyte nodes is missing from HSM or other CSM tools, check the Redfish endpoint on the BMC to see if the data is present.

If the data is not present in the Redfish, then a cold reset of the BMC is needed to refresh the Redfish values.

If the data is present in the Redfish, a rediscovery of the BMC may populate the values in HSM.

**Prerequisite:**
* Make sure the firmware and BIOS of the Gigabyte node is at the latest supported level.

## Reset the Gigabyte BMC

Run the command: `ipmitool -I lanplus -U admin -P password -H <target bmc ip> mc reset cold`
* `password` is the admin password
* `<target bmc ip>` is the IP address of the BMC

After 5 minutes, check to Redfish endpoint once again to verify the data is present.
Rediscover the BMC.

## Rediscover the Gigabyte BMC

To rediscover the BMC run the command: `cray hsm inventory discover create --xnames <xname of BMC> --force true`
* `<xname of BMC>` is the BMC xname, example: `x3000c0s1b0`
