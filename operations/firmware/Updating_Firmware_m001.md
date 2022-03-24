# Updating BMC Firmware and BIOS for ncn-m001

**NOTE:** On HPE nodes, the BMC Firmware is iLO 5 and BIOS is System ROM

**The commands in the procedure must be run on ncn-m001**

**Prerequisite:**

The following information is needed:
* IP Address of ncn-m001 bmc
* IP Address of ncn-m001
* Root password for ncn-m001 bmc

### Find the Model Name
Use one of the following commands to find the model name for the node type in use.

HPE Nodes:

  `m001# curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/1 | jq .Model`

Gigabyte Nodes:

  `m001# curl -k -u root:password https://ipaddressOfBMC/redfish/v1/Systems/Self | jq .Model`

### Get the Firmware Images
1. View a list of images stored in FAS tart are ready to be flashed:
    where "ModelName" is the name from the previous command

    `m001# cray fas images list --format json | jq '.[] | .[] | select(.models | index("ModelName"))'`

    Locate the image in the returned output that is required to ncn-m001 firmware and/or BIOS.

    Look for the returned s3URL. For example:

    `"s3URL": "s3:/fw-update/4e5f569a603311eb96b582a8e219a16d/image.RBU"`

2. Get the firmware images using the s3URL path from the previous step.

    `m001# cray artifacts get fw-update 4e5f569a603311eb96b582a8e219a16d/image.RBU image.RBU`

    `4e5f569a603311eb96b582a8e219a16d/image.RBU` is the path in the s3URL, `image.RBU` is the name of the file to save the image on local disk.

## Flash the Firmware

Gigabyte ncn-m001:

1. From the directory with the image you downloaded above, start up a webserver:

    `m001# python3 -m http.server 8770`

    a. To update BMC:

    `m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BMC"}'`

    * `passwd` = root password of BMC
    * `ipaddressOfBMC` = ipaddress of BMC
    * `ipaddressOfM001` = ipaddress of ncn-m001 node
    * `filename` = filename of the image you downloaded above.

    b. To update BIOS:

    `m001# curl -k -u root:passwd https://ipaddressOfBMC/redfish/v1/UpdateService/Actions/SimpleUpdate -d '{"ImageURI":"http://ipaddressOfM001:8770/filename", "TransferProtocol":"HTTP", "UpdateComponent":"BIOS"}'`


    * `passwd` = root password of BMC
    * `ipaddressOfBMC` = ipaddress of BMC
    * `ipaddressOfM001` = ipaddress of ncn-m001 node
    * `filename` = filename of the image you downloaded above.

    After updating BIOS, ncn-m001 will need to be rebooted. Follow instructions [Reboot NCNs](../node_management/Reboot_NCNs.md) for rebooting ncn-m001.

HPE ncn-m001:

The web interface will be used to update iLO 5 (BMC) firmware and/or System ROM (BIOS) on the HPE ncn-m001 node.

1. Copy the iLO 5 firmware and/or System ROM file(s) to your local computer from ncn-m001 using `scp` or other secure copy tools.

    `$ scp root@ipaddressOfM001Node:pathToFile/filename .`

2. Open a web browser window and type in the name or ipaddress of the iLO device for ncn-m001.

3. Log in with root and the root password for the iLO device

    1. Click on `"Firmware & OS Software"` on the left menu
    2. Click on `"Update Firmware"` on the right menu
    3. Check `"Local File"`
    4. Click `"Choose File"` and select the iLO firmware file or System ROM file
    5. Click `"Confirm TPM override"`
    6. Click `"Flash"`

  After updating the System ROM (BIOS), ncn-m001 will need to be rebooted. Follow instructions [Reboot NCNs](../node_management/Reboot_NCNs.md) for rebooting ncn-m001.
