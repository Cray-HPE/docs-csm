# Firmware Upgrade using SPP on HPE ProLiant Servers
#### Link to download SPP Image : 
https://techlibrary.hpe.com/us/en/enterprise/servers/products/service_pack/spp/index.aspx

* Naming convention for example : 2023.04.00.00 that's the ISO image released in 4th Month of 2023

* Download the latest version or the version you needed.

* We can either deploy individual firmware component or deploy SPP ISO image as a whole

### How to deploy individual firmware component?

####  Get the individual firmware component from SPP ISO image:

* If we mount the SPP ISO image or extract the iso image, we can see there is “contents.html” file present.
* For example, if we want to flash the BIOS/ROM for DL360 Gen11 server then find for DL360 in “Description” column, and you see the relevant component to flash through ILO. Note the extension should be fwpkg if we are flashing through ILO.
* Get the location of the file/package where it is located in the extracted/mounted ISO image. Usually, it will be present in the folder “Packages”

#### Steps to deploy individual components:

* Login to the ILO page in web browser 
* Go to the Firmware&OS Software at the left section
* Select upload to iLO Repository
* Select the file where it is located and click on upload.
* Go to iLO Repository, you should be able to see the uploaded component. Click on Install Component and then Click on TPM Override then click on add to the Installation queue
* You can check for the status message in Installation Queue. If you see any failed instance in Queue, then delete that instance else installation of next component would not get start if expiration is set to never for the failed instance.

#### How to deploy SPP ISO image as a whole

**Pre-requisites:**

+ SPP ISO image should be available
+ ILO accessibility should be present from the system where you are flashing firmware using SPP ISO image
+ The system from where the SPP is flashing should have default web browser running.

**Two methods to deploy:**

1. Local method
2. Remote method

**Local method:**

* Login to the ILO in web browser
* Select Remote console & media on to the left side
* Launch the remote console either HTML5 or .NET console or through HPLOCONS. Best option would be .NET and HPLOCONS
* Mount the ISO image either local location of the image or URL path. If URL path is given make sure that is in same network as ILO network
* Press F9 and go to One time Boot menu and select the mounted image, if URL is given then you see the URL path.
* Select Interactive option
* Accept and proceed
* Click on Firmware Update and then Click OK
* Inventory takes some time, wait until it completes and then click Next
* Select the components that needs firmware flashing, you can also check for the version by clicking view details for each component. If its already up to date then by default it will not be selected, you can force update the component. Click on TPM override and then deploy
* After deployment, check for the status and reboot the node

**Remote method**

* Mount the ISO image or copy and extract the ISO image.
* If its Windows Server then click on “launch_sum.bat” file, if its Linux then “launch_sum.sh” file
* Then Browser is opened
* If “localhost Guided Update” is selected, then it updates the components on the server from where launch_sum execution file is launched.
* You can deploy on one or more than one target nodes by selecting the option Nodes
* Click on Nodes, then Add Node. Give the ILO IP in IPV4 section(You can also give range of nodes), select Node type as iLO and give ILO credentials by scrolling down
* Once the Discovery is done click on Add inventory, once inventory is completed click on Next and steps are same as 9, 10, 11 from local method. Repeat this for all the nodes added.

### Notes:

For any new server to boot up it should have the right set of Firmware Components

1. ILO Firmware
2. ROM(BIOS version)
3. CPLD Firmware
4. SPS Firmware(Only in Intel Proc servers)
5. Minimum hardware requirements(like Proc, Mem, Fan, Power etc) based on quick speck

**On a high level:**

* SPP has Firmware's, Drivers, ILO, ROM, SPS and other hardware components for all the server supported(Only DL, ML and Apollo Servers. For Synergy and Blade that’s a different Bundle) for that particular release
* Procedure to flash from SPP can be found at SPP user guide, there are various deployment methods.

#### In Customer world:

* For any production server, by default it will have the minimum versions installed during factory integration.
* The release schedule of SPP is twice a year i.e every March and September there will be SPP released to customers.
* There will also be hot fixes that are released as patch bundle all over the year and it depends on the issues/fixes.
* It’s always best practice to check at the release notes of SPP image that is going to be used

#### Use Case:

* Now say for example the firmware versions that the server ABC is from SPP released during September 2022
* And now there is another new SPP that got released in March 2023 and there will be another SPP that gets released in September 2023.
* The hot fixes that are released between November 2022 and Feb 2023 will be available in March 2023. Similarly, the hot fixes between April 2023 and August 2023 will be carry forwarded in September 2023

#### If the customer tries to do the Firmware Upgrade from Sep SPP 2022 to Sep SPP 2023 following are the possibilities

* Upgrade can go smooth without any errors
* Some components can fail to upgrade, because that particular component may require a bunny hop i.e the minimum version would have got changed for it to upgrade to the latest version and that minimum version might be present in March SPP 2023 or in the Hot fixes
* One good thing while updating SPP by GUI interactive method is that before deployment and while selecting the components it will show the error message if it has dependency issue, at that time we can uncheck that particular component and proceed with other components. Later we can deploy alone for that particular component
* That component could be either ILO, ROM, CPLD, SPS, NIC card, Storage card etc
* There are options through command line as well to ignore errors/dependencies if we opt to install SPP via CLI.

#### Question: What combination of the components work?

* Whatever version present in SPP bundle, for sure that combination works. The challenge the customers can face is explained in point 2 above
* If the customers have the facility to download individual components then they get the versions to download from contents.html which is present in SPP ISO image and also can find those individual components in extracted ISO image
* And then they can flash by uploading it to the ILO Repository which is present in ILO GUI interface and then install the sets and this becomes challenging if they have 100s of nodes and we can use remote methods