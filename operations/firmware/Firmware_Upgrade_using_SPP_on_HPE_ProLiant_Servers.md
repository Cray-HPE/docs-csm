# Firmware Upgrade using SPP on HPE ProLiant Servers

* [Download SPP image](#download-spp-image)
* [Deploying individual firmware components](#deploying-individual-firmware-components)
  * [Get the individual firmware component from SPP ISO image](#get-the-individual-firmware-component-from-spp-iso-image)
  * [Steps to deploy individual components](#steps-to-deploy-individual-components)
* [Deploy SPP ISO image as a whole](#deploy-spp-iso-image-as-a-whole)
  * [Prerequisites](#prerequisites)
  * [Deploying the ISO image using the local method](#deploying-the-iso-image-using-the-local-method)
  * [Deploying the ISO image using the remote method](#deploying-the-iso-image-using-the-remote-method)
* [Notes](#notes)
  * [High level](#high-level)
  * [Production systems](#production-systems)

## Download SPP image

[Link to download site](https://techlibrary.hpe.com/us/en/enterprise/servers/products/service_pack/spp/index.aspx).

* Naming convention example: `2023.04.00.00` is the ISO image released in 4th Month of 2023
* Download the latest version or the specific required version.
* Firmware can be deployed either individually by component or the SPP ISO image as a whole.

## Deploying individual firmware components

### Get the individual firmware component from SPP ISO image

* Mount or extract the SPP ISO image and locate the `contents.html` file.
* Get the location of the file/package in the extracted/mounted ISO image from the 'contents.html' file. Usually it will be in the folder `Packages`.
* For example, to flash the BIOS/ROM for `DL360 Gen11` server, find DL360 in `Description` column, and then find relevant component to flash.
  Note that the extension should be `.fwpkg` if flashing through ILO.

### Steps to deploy individual components

1. Log in to the ILO page in web browser.
1. Go to the `Firmware & OS` Software at the left section.
1. Select `upload to iLO Repository`.
1. Select the file where it is located and click on upload.
1. Go to iLO Repository; the uploaded component should be shown. Click on `Install Component`, and then Click on `TPM Override` then click on `Add to the Installation queue`
1. Check for the status message in Installation Queue. If any failed instance in Queue are shown, then delete that instance, or else the installation of the next component will not get to start if the expiration is set to never for the failed instance.

## Deploy SPP ISO image as a whole

### Prerequisites

* Downloaded SPP ISO image
* ILO accessible on system where the firmware is being flashed using SPP ISO image
* Web browser

The SPP ISO image can be deployed locally or remotely.

### Deploying the ISO image using the local method

1. Log in to ILO in web browser.
1. Select `Remote console & Media` on to the left side.
1. Launch the remote console (either `HTML5` or `.NET` console) or through `HPLOCONS`. The best option would be `.NET` or `HPLOCONS`.
1. Mount the ISO image using either the local location of the image or its URL path. If URL path is given, make sure that it is in the same network as ILO network.
1. Do a cold reboot or reset the node from the iLO remote console.
1. Press `F9` and go to `One time Boot` menu and select the mounted image. If the URL is given, then it will show the URL path.
1. Select the `Interactive` option.
1. Accept and proceed.
1. Click on `Firmware Update` and then click `OK`.
1. Inventory takes some time, wait until it completes and then click `Next`.
1. Select the components that need firmware flashing; it is also possible to check for the version by clicking `View details` for each component.
   If it is already up to date, then by default it will not be selected. The update can be forced on the component by clicking on `TPM override`, and then deploy.
1. After deployment, check for the status and reboot the node.

### Deploying the ISO image using the remote method

1. Mount the ISO image or copy and extract the ISO image.
1. If on a Windows Server, then click on `launch_sum.bat` file; if on Linux, then `launch_sum.sh` file.
1. Continue in the browser window that was opened.
1. If `localhost Guided Update` is selected, then it updates the components on the server from where `launch_sum` execution file is launched.
1. One or more target nodes may be deployed by selecting the option `Nodes`.
1. Click on `Nodes`, then `Add Node`. Give the ILO IP address in the IPV4 section (Or give range of nodes). Select `Node type` as iLO and give ILO credentials by scrolling down.
1. Once the Discovery is done, click on `Add Inventory`. Once inventory is completed, click on `Next`.
1. Inventory takes some time; wait until it completes and then click `Next`.
1. Select the components that need firmware flashing; it is also possible to check for the version by clicking `View details` for each component.
   If it is already up to date, then by default it will not be selected. The update can be forced on the component by clicking on `TPM override`, and then deploy.
1. After deployment, check for the status and reboot the node
1. Repeat this for all the nodes added.

## Notes

For any new server to boot up it should have the right set of firmware components

* ILO firmware
* System ROM (BIOS)
* CPLD firmware
* SPS firmware (Only on Intel processor servers)
* Minimum hardware requirements (like processor, memory, fan, power) based on `QuickSpecs`

### High level

* SPP has firmware, drivers, ILO, ROM, SPS, and other hardware components for all the supported servers for that particular release (Only DL, ML, and Apollo Servers. Synergy and Blade use a different bundle)
* Procedure to flash from SPP can be found at SPP user guide; there are various deployment methods.

### Production systems

* Production server will have the minimum versions of firmware installed during factory integration.
* SPP images are released twice a year.
* Hot fixes are released as patch bundles throughout the year.
* It is always a best practice to check the release notes of the SPP image that is going to be used.
