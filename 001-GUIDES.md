# CSM Documentation Guide

The installation of CSM software has three scenarios which are described in this documentation with many supporting procedures.  Here is an overview of the workflow through the documentation to support these scenarios.

[CSM Install] (002-CSM-INSTALL.md)

Installation prerequisites

Satisfy the prerequisites for one of these three installation scenarios 

* Migration from a Shasta v1.3.x system.  How to collect information from a v1.3.x system to be used during the v1.4 installation, quiescing v1.3.x, checking and updating firmware to required versions, recabling site connection to shift from ncn-w001 to ncn-m001, adjust management NCNs to boot over PCIe instead of onboard NICs, shutting down Kubernetes, and powering off NCNs.  Then you move to Starting an Installation.
* First time installation of Shasta software (a bare-metal install).  This describes now to setup the LiveCD to be able to collect the configuration payload, configure network switches, update firmware for switches and nodes to required versions.  Then you move to Starting an Installation.
* Reinstalling Shasta v1.4 software on a system which previously had Shasta v1.4 installed.  These steps here are scaling down DHCP, wiping disks on the NCNs (except ncn-m001), power off NCNs, change management node BMCs to be DHCP not Static, and powering off the LiveCD or ncn-m001 (unless it will be used to prepare the LiveCD).  Then you move to Starting an Installation.

Once the installation prerequisites have been addressed, the installation is very similar for all of them.  There are a few places where a comment will be made for how one of the scenarios needs to do something different.

Starting an installation

The three separate scenarios (above) continue the same way at this point, with preparation and then booting from the LiveCD.  

* This version of the documentation supports booting from a [CSM USB LiveCD] (003-CSM-USB-LIVECD.md).
* A future version of this documentation will support booting from a virtual ISO method [CSM Remote LiveCD] (004-CSM-REMOTE-LIVECD.md). 

##### [CSM USB LiveCD - Creation and Configuration](003-CSM-USB-LIVECD.md#csm-usb-livecd---creation-and-configuration)

Preparation of the LiveCD on a USB stick can be done from a Linux system such as a booted ncn-m001 node with either Shasta v1.3 or v1.4 or a laptop or desktop.

* [Download and Expand the CSM Release](003-CSM-USB-LIVECD.md#download-and-expand-the-csm-release)
* [Create the Bootable Media](003-CSM-USB-LIVECD.md#create-the-bootable-media)
* [Configuration Payload](003-CSM-USB-LIVECD.md#configuration-payload)
  * [Generate Installation Files](003-CSM-USB-LIVECD.md#generate-installation-files)
  * [CSI Workarounds](003-CSM-USB-LIVECD.md#csi-workarounds)
  * [SHASTA-CFG](003-CSM-USB-LIVECD.md#shasta-cfg)
* [Pre-Populate LiveCD Daemons Configuration and NCN Artifacts](003-CSM-USB-LIVECD.md#pre-populate-livecd-daemons-configuration-and-ncn-artifacts)
* [Boot the LiveCD](003-CSM-USB-LIVECD.md#boot-the-livecd)
  * [First Login](003-CSM-USB-LIVECD.md#first-login)

##### [CSM Metal Install](005-CSM-METAL-INSTALL.md#csm-metal-install)

Now that ncn-m001 has been booted from the LiveCD, the other management NCNs will be deployed to create the management Kubernetes cluster.

  * [Overview](005-CSM-METAL-INSTALL.md#overview)
  * [Configure Bootstrap Registry to Proxy an Upstream Registry](005-CSM-METAL-INSTALL.md#configure-bootstrap-registry-to-proxy-an-upstream-registry)
  * [Tokens and IPMI Password](005-CSM-METAL-INSTALL.md#tokens-and-ipmi-password)
  * [Timing of Deployments](005-CSM-METAL-INSTALL.md#timing-of-deployments)
  * [NCN Deployment](005-CSM-METAL-INSTALL.md#ncn-deployment)
    * [Apply NCN Pre-Boot Workarounds](005-CSM-METAL-INSTALL.md#apply-ncn-pre-boot-workarounds)
    * [Ensure Time Is Accurate Before Deploying NCNs](005-CSM-METAL-INSTALL.md#ensure-time-is-accurate-before-deploying-ncns)
    * [Start Deployment](005-CSM-METAL-INSTALL.md#start-deployment)
      * [Workflow](005-CSM-METAL-INSTALL.md#workflow)
      * [Deploy](005-CSM-METAL-INSTALL.md#deploy)
    * [Apply NCN Post-Boot Workarounds](005-CSM-METAL-INSTALL.md#apply-ncn-post-boot-workarounds)
    * [LiveCD Cluster Authentication](005-CSM-METAL-INSTALL.md#livecd-cluster-authentication)
    * [BGP Routing](005-CSM-METAL-INSTALL.md#bgp-routing)
    * [Validation](005-CSM-METAL-INSTALL.md#validation)
* [Additional Validation Tasks for Failed Installs](005-CSM-METAL-INSTALL.md#additional-validation-tasks-for-failed-installs)
  * [Configure and Trim UEFI Entries](005-CSM-METAL-INSTALL.md#configure-and-trim-uefi-entries)


##### [CSM Platform Install](006-CSM-PLATFORM-INSTALL.md#csm-platform-install)

Install all of the CSM applications and services into the management Kubernetes cluster.

* [Initialize Bootstrap Registry](006-CSM-PLATFORM-INSTALL.md#initialize-bootstrap-registry)
* [Create Site-Init Secret](006-CSM-PLATFORM-INSTALL.md#create-site-init-secret)
* [Deploy Sealed Secret Decryption Key](006-CSM-PLATFORM-INSTALL.md#deploy-sealed-secret-decryption-key)
* [Start the Deployment](006-CSM-PLATFORM-INSTALL.md#start-the-deployment)
  * [Run `install.sh`](006-CSM-PLATFORM-INSTALL.md#run-installsh)
* [Add Compute Cabinet Routing to NCNs](006-CSM-PLATFORM-INSTALL.md#add-compute-cabinet-routing-to-ncns)
* [Known Issues](006-CSM-PLATFORM-INSTALL.md#known-issues)
  * [error: timed out waiting for the condition on jobs/cray-sls-init-load](006-CSM-PLATFORM-INSTALL.md#error-timed-out-waiting-for-the-condition-on-jobscray-sls-init-load)
  * [Error: not ready: https://packages.local](006-CSM-PLATFORM-INSTALL.md#error-not-ready-httpspackageslocal)
  * [Error initiating layer upload ... in registry.local: received unexpected HTTP status: 200 OK](006-CSM-PLATFORM-INSTALL.md#error-initiating-layer-upload--in-registrylocal-received-unexpected-http-status-200-ok)
  * [Error lookup registry.local: no such host](006-CSM-PLATFORM-INSTALL.md#error-lookup-registry.local:-no-such-host)

<a name="csm-install-validation-and-health-checks"></a> 
###### [CSM Install Validation and Health Checks](008-CSM-VALIDATION.md)

The CSM installation validation and health checks can be run after install.sh finishes in this installation process, but can also be run at other times later.

* [Platform Health Checks](008-CSM-VALIDATION.md#platform-health-checks)
  * [ncnHealthChecks](008-CSM-VALIDATION.md#ncnhealthchecks)
  * [ncnPostgresHealthChecks](008-CSM-VALIDATION.md#ncnpostgreshealthchecks)
  * [BGP Peering Status and Reset](008-CSM-VALIDATION.md#bgp-peering-status-and-reset)
    * [Mellanox Switch](008-CSM-VALIDATION.md#mellanox-switch)
    * [Aruba Switch](008-CSM-VALIDATION.md#aruba-switch)


* [Network Health Checks](008-CSM-VALIDATION.md#network-health-checks)
  * [Verify that KEA has active DHCP leases](008-CSM-VALIDATION.md#verify-that-kea-has-active-dhcp-leases)
  * [Verify ability to resolve external DNS](008-CSM-VALIDATION.md#verify-ability-to-resolve-external-dns)
  * [Verify Spire Agent is Running on Kuberetes NCNs](008-CSM-VALIDATION.md#verify-spire-agent-is-running-on-kuberetes-ncns)
  * [Verify the Vault Cluster is Healthy](008-CSM-VALIDATION.md#verify-the-vault-cluster-is-healthy)


* [Automated Goss Testing](008-CSM-VALIDATION.md#automated-goss-testing)
  * [Known Goss Test Issues](008-CSM-VALIDATION.md#known-goss-test-issues)


* [Hardware Management Services Tests](008-CSM-VALIDATION.md#hardware-management-services-tests)
  * [Test Execution](008-CSM-VALIDATION.md#test-execution)
  * [Cray Management Services Validation Utility](008-CSM-VALIDATION.md#cray-management-services-validation-utility)
  * [Usage](008-CSM-VALIDATION.md#usage)
    * [Interpreting Results](008-CSM-VALIDATION.md#interpreting-results)
  * [Checks To Run](008-CSM-VALIDATION.md#checks-to-run)
    * [Booting CSM Barebones Image](008-CSM-VALIDATION.md#booting-csm-barebones-image)
      * [Locate the CSM Barebones Image in IMS](008-CSM-VALIDATION.md#locate-the-csm-barebones-image-in-ims)
      * [Create a BOS Session Template for the CSM Barebones Image](008-CSM-VALIDATION.md#create-a-bos-session-template-for-the-csm-barebones-image)
    * [Find an available compute node and boot the session template](008-CSM-VALIDATION.md#find-an-available-compute-node-and-boot-the-session-template)
    * [Verify console connections](008-CSM-VALIDATION.md#verify-console-connections)
    * [Connect to the node's console and watch the boot](008-CSM-VALIDATION.md#connect-to-the-node's-console-and-watch-the-boot)


* [UAS / UAI Tests](008-CSM-VALIDATION.md#uas--uai-tests)
  * [Initialize and Authorize the CLI](008-CSM-VALIDATION.md#initialize-and-authorize-the-cli)
    * [Stop Using the CRAY_CREDENTIALS Service Account Token](008-CSM-VALIDATION.md#stop-using-the-cray_credentials-service-account-token)
  * [Initialize the CLI Configuration](008-CSM-VALIDATION.md#initialize-the-cli-configuration)
  * [Authorize the CLI for Your User](008-CSM-VALIDATION.md#authorize-the-cli-for-your-user)
  * [Validate UAS and UAI Functionality](008-CSM-VALIDATION.md#validate-uas-and-uai-functionality)
  * [Validate the Basic UAS Installation](008-CSM-VALIDATION.md#validate-the-basic-uas-installation)
  * [Validate UAI Creation](008-CSM-VALIDATION.md#validate-uai-creation)
  * [Authorization Issues](008-CSM-VALIDATION.md#authorization-issues)
    * [UAS Cannot Access Keycloak](008-CSM-VALIDATION.md#uas-cannot-access-keycloak)
    * [UAI Images not in Registry](008-CSM-VALIDATION.md#uai-images-not-in-registry)
    * [Missing Volumes and other Container Startup Issues](008-CSM-VALIDATION.md#missing-volumes-and-other-container-startup-issues)

##### [CSM Install Reboot - Final NCN Install](007-CSM-INSTALL-REBOOT.md#csm-install-reboot---final-ncn-install)

The ncn-m001 node needs to reboot from the LiveCD to normal operation as a Kubernetes master node.

* [Required Services](007-CSM-INSTALL-REBOOT.md#required-services)
* [Notice of Danger](007-CSM-INSTALL-REBOOT.md#notice-of-danger)
* [LiveCD Pre-Reboot Workarounds](007-CSM-INSTALL-REBOOT.md#livecd-pre-reboot-workarounds)
* [Example](007-CSM-INSTALL-REBOOT.md#example)
* [Hand-Off](007-CSM-INSTALL-REBOOT.md#hand-off)
  * [Start Hand-Off](007-CSM-INSTALL-REBOOT.md#start-hand-off)
* [Accessing USB Partitions After Reboot](007-CSM-INSTALL-REBOOT.md#accessing-usb-partitions-after-reboot)
  * [Accessing CSI from a USB or RemoteISO](007-CSM-INSTALL-REBOOT.md#accessing-csi-from-a-usb-or-remoteiso)
* [Enable NCN Disk Wiping Safeguard](007-CSM-INSTALL-REBOOT.md#enable-ncn-disk-wiping-safeguard)

##### [CSM Validation process](008-CSM-VALIDATION.md)

[*Double-back...*](#csm-install-validation-and-health-checks008-csm-validationmd)

The CSM installation validation and health checks can be run again now that ncn-m001 has been rebooted to join the Kubernetes cluster. 

##### [NCN/Management Node Locking](009-NCN-LOCKING.md) 

The NCNs should be locked to prevent accidental firmware upgrades with FAS or power down operations and reset operations with CAPMC.

* [Why?](009-NCN-LOCKING.md#a-namewhyawhy)
* [When To Lock Management NCNs](009-NCN-LOCKING.md#a-namewhen-to-lock-management-ncnsawhen-to-lock-management-ncns)
* [When To Unlock Management NCNs](009-NCN-LOCKING.md#a-namewhen-to-unlock-management-ncnsawhen-to-unlock-management-ncns)
* [Locked Behavior](009-NCN-LOCKING.md#a-namelocked-behavioralocked-behavior)
* [How To Lock Management NCNs](009-NCN-LOCKING.md#a-namehow-to-lock-management-ncnsastart--how-to-lock-management-ncns)
* [How To Unlock Management NCNs](009-NCN-LOCKING.md#a-namehow-to-unlock-management-ncnsahow-to-unlock-management-ncns)


##### [Firmware Update the system with FAS](010-FIRMWARE-UPDATE-WITH-FAS.md#firmware-update-the-system-with-fas) 

The firmware versions of many components may need to be updated at this point in the installation process.

* [Prerequisites](010-FIRMWARE-UPDATE-WITH-FAS.md#prerequisites)
* [Current Capabilities as of Shasta Release v1.4](010-FIRMWARE-UPDATE-WITH-FAS.md#current-capabilities-as-of-shasta-release-v1.4)
* [Order Of Operations](010-FIRMWARE-UPDATE-WITH-FAS.md#order-of-operations)
* [Hardware Precedence Order](010-FIRMWARE-UPDATE-WITH-FAS.md#hardware-precedence-order)
* [Next Steps](010-FIRMWARE-UPDATE-WITH-FAS.md#next-steps)


The details of the process are outlined in [255-FIRMWARE-ACTION-SERVICE-FAS.md](255-FIRMWARE-ACTION-SERVICE-FAS.md) using recipes listed in [256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md](256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md)


Using the process outlined in [`255-FIRMWARE-ACTION-SERVICE-FAS.md`](../255-FIRMWARE-ACTION-SERVICE-FAS.md) follow the process to update the system.  We recommend that you use the 'recipes' listed in [`256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md`](256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md) to update each supported type.

Then the administrator should install additional products following the procedures in the HPE Cray EX System Installation and Configuration Guide S-8000.

# Naming convention for files in CSM documentation

These documentation files are grouped to keep similar pages together.

- 000 - 001 INTRO : Information describing this book.
- 002 - 008 CSM INSTALL : Install Pages for CSM
- 009 - 049: Other install pages
- 050 - 099 PROCS : Procedures referenced by install; help guides, tricks/tips, etc.
- 100 - 150 NCN-META : Technical information for Non-Compute Nodes
- 250 - 300 Common  : Technical information common to all nodes.
- 300 - 350 MFG/SVC : Procedures referenced by service teams.
- 400 - 499 NETWORK : Procedures for management network installation.
