# Firmware Upgrade using SPP on HPE ProLiant Servers

## Download SPP Image

[Link to download site](https://techlibrary.hpe.com/us/en/enterprise/servers/products/service_pack/spp/index.aspx).

* Naming convention example: `2023.04.00.00` is the ISO image released in 4th Month of 2023
* Download the latest version or the version you require.
* Firmware can be deployed either individually by component or the SPP ISO image as a whole.

## Deploying Individual Firmware Components

### Get the individual firmware component from SPP ISO image

* Mount or extract the SPP ISO image and locate the `contents.html` file.
* Get the location of the file/package in the extracted/mounted ISO image from the 'contents.html' file.  Usually it will be in the folder `Packages`.
* For example, to flash the BIOS/ROM for `DL360 Gen11` server, find DL360 in `Description` column, and then find relevant component to flash. Note the extension should be `.fwpkg` if we are flashing through ILO.

### Steps to deploy individual components

1. Log in to the ILO page in web browser.
1. Go to the `Firmware & OS` Software at the left section.
1. Select `upload to iLO Repository`.
1. Select the file where it is located and click on upload.
1. Go to iLO Repository, you should be able to see the uploaded component. Click on `Install Component`, and then Click on `TPM Override` then click on `Add to the Installation queue`
1. Check for the status message in Installation Queue. If you see any failed instance in Queue, then delete that instance or else the installation of the next component will not get to start if the expiration is set to never for the failed instance.

## Deploy SPP ISO image as a Whole

### Pre-requisites

* Downloaded SPP ISO image
* ILO accessible on system where you are flashing firmware using SPP ISO image
* Web Browser

The SPP ISO Image can be deployed locally or remotely.

## Deploying the ISO Image using the local method

1. Log in to ILO in web browser.
1. Select `Remote console & Media` on to the left side.
1. Launch the remote console either `HTML5` or `.NET` console or through `HPLOCONS`. Best option would be .NET and HPLOCONS.
1. Mount the ISO image either local location of the image or URL path. If URL path is given make sure that is in same network as ILO network.
1. Do a cold reboot or reset the node from the iLO remote console.
1. Press `F9` and go to `One time Boot` menu and select the mounted image. If the URL is given, then you will see the URL path.
1. Select the `Interactive` option.
1. Accept and proceed.
1. Click on `Firmware Update` and then Click `OK`.
1. Inventory takes some time, wait until it completes and then click `Next`.
1. Select the components that needs firmware flashing, you can also check for the version by clicking view details for each component.
If it is already up to date then by default it will not be selected. You can force update the component. Click on `TPM override`, and then deploy.
1. After deployment, check for the status and reboot the node.

## Deploying the ISO Image using the remote method

1. Mount the ISO image or copy and extract the ISO image.
1. If on a Windows Server then click on `launch_sum.bat` file, if on a Linux then `launch_sum.sh` file.
1. Continue in the browser window that was opened.
1. If `localhost Guided Update` is selected, then it updates the components on the server from where `launch_sum` execution file is launched.
1. You can deploy on one or more than one target nodes by selecting the option Nodes.
1. Click on `Nodes`, then `Add Node`. Give the ILO IP in IPV4 section (You can also give range of nodes), select Node type as iLO and give ILO credentials by scrolling down.
1. Once the Discovery is done, click on `Add Inventory`. Once inventory is completed, click on `Next`.
1. Inventory takes some time, wait until it completes and then click `Next`.
1. Select the components that needs firmware flashing, you can also check for the version by clicking view details for each component. If it is already up to date then by default it will not be selected, you can force
  update the component. Click on `TPM Override`, and then `deploy`.
1. After deployment, check for the status and reboot the node
1. Repeat this for all the nodes added.

## Notes

For any new server to boot up it should have the right set of Firmware Components

1. ILO Firmware
2. System ROM (BIOS)
3. CPLD Firmware
4. SPS Firmware (Only on `Intel Proc servers`)
5. Minimum hardware requirements (like `Proc`, `Mem`, `Fan`, `Powe`r etc) based on `QuickSpecs`

### On a high level

* SPP has Firmware's, Drivers, ILO, ROM, SPS and other hardware components for all the server supported (Only DL, ML and Apollo Servers. For Synergy and Blade that’s a different Bundle) for that particular release
* Procedure to flash from SPP can be found at SPP user guide, there are various deployment methods.

### In Customer world

* Production server will have the minimum versions of firmware installed during factory integration.
* SPP Images are released twice a year i.e every March and September.
* There will be hot fixes that are released as patch bundles throughout the year.
* It is always a best practice to check the release notes of the SPP image that is going to be used.
