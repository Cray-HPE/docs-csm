### Gigabyte BMC Missing Redfish Data

If data from Gigabyte nodes are missing from Hardware State Manager (HSM) or other CSM tools, check the redfish endpoint on the BMC to see if the data is present.
If the data is not present, then a reboot of the BMC is needed to refresh the Redfish values.

###### Rebooting the Gigabyte BMC

Run the command: `ipmitool -I lanplus -U admin -P password -H <target bmc ip> mc reset cold`
* `password` is the admin password
* `<target bmc ip>` is the IP address of the BMC

After 5 minutes, check to redfish endpoint once again to verify the data is present.
Rediscover the BMC following the procedure below.

###### Rediscovery of BMC

To rediscover the BMC run the command: `cray hsm inventory discover create --xnames <xname of BMC> --force true`
* `<xname of BMC>` is the BMC xname, example: `x3000c0s1b0`
