## HPE PDU Admin Procedures
* [Connecting to HPE PDU Web Interface](#connecting-to-hpe-pdu-web-interface)
* [HPE PDU Initial Set-up](#hpe-pdu-initial-set-up)
* [Updating HPE PDU Firmware](#updating-hpe-pdu-firmware)
* [Changing HPE PDU User Passwords](#changing-hpe-pdu-user-passwords)
* [Discovery of HPE PDU after upgrading CSM](#discovery-of-hpe-pdu-after-upgrading-csm)

**Because of the pulling method used to process sensor data from the HPD PDU, telemetry data may take up to 6 minutes to refresh, this includes outlet status, voltage and other data from the PDU.**


### Connecting to HPE PDU Web Interface
You will need to know the:
* IP address or Domain Name of m001
* Xname of the HPE PDU
* Root password for m001
* Admin password for HPE PDU _(default: 12345678)_

1. Use the SSH command from your local machine:\
`> ssh -L 8443:{PDU_xname}:443 -N root@{m001_ip}`\
Where `{PDU_xname}` is the xname of the PDU and `{m001_ip}` is the ip address of m001\
You will need to enter the root password for m001
2. Using a web browser, connect to: [`https://localhost:8443`](https://localhost:8443)
3. Log in using the username: _admin_ and _admin password_
4. If you have not changed the admin password, you will be prompted to change the password.

### HPE PDU Initial Set-up
This procedure will:
* Make sure redfish is enabled
* Add the default user
* Enable Outlet Control

1. Connect to the HPE PDU Web Interface (See [Connecting to HPE PDU Web Interface](#connecting-to-hpe-pdu-web-interface)) and login as admin

#### Make sure redfish is enabled
1. Using the **"Settings" Icon** (gear in computer monitor in top right corner) go to **"Network Settings"**
2. Make sure there is a check next to “RESTapi Access”, if not, click the “Edit” Icon (pencil) and enable.

#### Add default user
1. Using the **"admin"** menu (top right corner) go to **"User Accounts"**
2. Click on the **"Add User"** button
3. Using the form, add the _username_ and _password_ for the default river user.  Assign the role _"Administrator"_ to that user.

#### Enable Outlet Control
1. Using the **"Home"** icon (House in top right corner) go to **"Control & Manage"**
2. Make sure **"Outlet Control Enable"** switch on the top of the page is selected (green)

#### Updating HPE PDU Firmware
##### Check Firmware Version
1. Connect to the HPE PDU Web Interface (See [Connecting to HPE PDU Web Interface](#connecting-to-hpe-pdu-web-interface)) and login as admin
2. Check which version of firmware is installed by selecting the **"Home"** icon (House in the top right corner) go to **"Identification"**
3. The _"Version"_ will be displayed.  If the version is less than _"2.0.0.L"_ update firmware.

##### Update Firmware
1. Download the latest firmware from: [https://support.hpe.com/connect/s/search?language=en_US#q=P9S23A&t=All&sort=%40hpescuniversaldate%20descending&numberOfResults=25&f:@contenttype=[Drivers%20and%20Software]](https://support.hpe.com/connect/s/search?language=en_US#q=P9S23A&t=All&sort=%40hpescuniversaldate%20descending&numberOfResults=25&f:@contenttype=[Drivers%20and%20Software])
2. This will download an ".exe" file which is a self extracting zip file.  If using a windows system, run the .exe file to extract the files, or use an unzip program on the file.  One of the files extracted will be named **"HPE.FW"**, that is the firmware file you will need for uploading.
3. Connect to the HPE PDU Web Interface (See [Connecting to HPE PDU Web Interface](#connecting-to-hpe-pdu-web-interface)) and login as admin
4. Using the **"Settings"** Icon (gear in computer monitor in top right corner) go to **"System Management"**
5. Click the **"Update FIrmware"** button
6. Click **"Choose File"** and select the **"HPE.FW"** file downloaded
7. Click **"Upload"** button
8. Firmware will be updated and the PDU management processor will restart.

#### Changing HPE PDU User Passwords
1. Connect to the HPE PDU Web Interface (See [Connecting to HPE PDU Web Interface](#connecting-to-hpe-pdu-web-interface)) and login as admin
2. Using the **"admin"** menu (top right corner) go to **"User Accounts"**
3. Click on the edit icon (pencil) next to the user
4. Enter new password and make any other changes for that user account and click the "Save" button

#### Discovery of HPE PDU after upgrading CSM
**This procedure is only needed when upgrading CSM, not performing a fresh install.  This procedure should be run after CSM has been fully upgraded including the discovery job.**
1. Find the list of PDU MAC address:\
`# cray hsm inventory ethernetInterfaces list --type CabinetPDUController`\
This will return a list of PDU ethernet interfaces.  Each interface must be deleted.

2. Using the `"ID"` from the `hsm inventory` command delete from HSM:
3. `# cray hsm inventory ethernetInterfaces delete {ID}`\
Where `{ID}` is the ID from `hsm inventory`
4. On the next discovery job run, it should locate the PDU and discover it correctly as a HPE PDU.
