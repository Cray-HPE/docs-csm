## Updating Firmware / BIOS for NCN m001

**Run on m001**

**Prerequisite:**
* IP Address of m001 bmc
* IP Address of m001
* Root password for m001 bmc

### Find the Model Name

***On HPE Nodes***

`m001# curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/1 | jq .Model`

***On Gigbyte Nodes***

`m001# curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/Self | jq .Model`

### Get the Firmware Images

`m001# cray fas images list --format json | jq .[] | .[] | select(.models | index("ModelName"))`
where "ModelName" is the name from above

This will give you a list of images stored inside FAS ready to be flashed.  Locate the image you need to flash m001 firmware and/or BIOS.

Look at the s3URL for that command it will look like this:

    "s3URL": "s3:/fw-update/4e5f569a603311eb96b582a8e219a16d/image.RBU"

Using the s3URL path run the following command

`m001# cray artifacts get fw-update 4e5f569a603311eb96b582a8e219a16d/image.RBU image.RBU`

Where 4e5f569a603311eb96b582a8e219a16d/image.RBU is the path in the s3URL
And image.RBU is the name of the file to save the image on local disk

## Flash the Firmware

***For Gigabyte m001***

From the directory with the image you downloaded above, start up a webserver:

`m001# python3 -m http.server 8770`

To update BMC - run from m001:
`m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -d ‘{“ImageURI”:”http://ipaddressOfM001:8770/filename”, ”TransferProtocol”:”HTTP”, ”UpdateComponent”:”BMC”}’`

Where:
* passwd = root password of BMC
* ipaddressOfBMC = ipaddress of BMC
* ipaddressOfM001 = ipaddress of m001 node
* filename = filename of the image you downloaded above.

To update BIOS - run from m001:
`m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -d ‘{“ImageURI”:”http://ipaddressOfM001:8770/filename”, ”TransferProtocol”:”HTTP”, ”UpdateComponent”:”BIOS”}’`

Where:
* passwd = root password of BMC
* ipaddressOfBMC = ipaddress of BMC
* ipaddressOfM001 = ipaddress of m001 node
* filename = filename of the image you downloaded above.

After updating BIOS, m001 will need to be rebooted.  Follow instructions for rebooting m001

***For HPE m001***

We will be using the web interface to update firmware for m001

Copy the files from m001 that you downloaded before using scp or other secure copy tools.

`$ scp root@ipaddressOfM001Node:pathToFile/filename .`

Open a web browser window and type in the name or ipaddress of the iLo device for m001.

Log in with root and the root password for the iLo device

* Click on `“Firmware & OS Software”` on the left menu
* Click on `“Update Firmware”` on the right menu
* Check `“Local File”`
* Click `“Choose File”` and select the iLO firmware file or BIOS file
* Click `“Confirm TPM override”`
* Click `"Flash"`

After updating BIOS, m001 will need to be rebooted.  Follow instructions for rebooting m001
