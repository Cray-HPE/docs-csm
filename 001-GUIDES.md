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

* This version of the documention supports booting from a [CSM USB LiveCD] (003-CSM-USB-LIVECD.md).
* A future version of this documentation will support booting from a virtual ISO method [CSM Remote LiveCD] (004-CSM-REMOTE-LIVECD.md). 

[CSM USB LiveCD] (003-CSM-LIVECD.md)

Preparation of the LiveCD on a USB stick can be done from a Linux system such as a booted ncn-m001 node with either Shasta v1.3 or v1.4 or a laptop or desktop.

* Download and Expand the CSM Release
  * Install the Cray Site Init (CSI) rpm
  * Install the CSM workaround documentation rpms
  * Install podman or docker to support tools required by SHASTA-CFG
* Create the Bootable Media 
* Create the Configuration Payload
   * Generate Installation Files and Run CSI
   * Apply CSI Workarounds
   * Prepare SHASTA-CFG with Kubernetes cluster network configuration settings needed by helm charts and loftsman manifests, generate sealed secrets, and adjust helm chart value overrides.  See [SHASTA-CFG](067-SHASTA-CFG.md)
* Pre-Populate LiveCD Daemons Configuration and NCN Artifacts
* Boot ncn-m001 from the LiveCD
   * First Login to ncn-m001 booted from LiveCD 

[CSM Metal Install](005-CSM-METAL-INSTALL.md)

Now that ncn-m001 has been booted from the LiveCD, the other management NCNs will be deployed to create the management Kubernetes cluster.

* Apply NCN Pre-Boot Workarounds
* Start Deployment of the NCNs
* Apply NCN Post-Boot Workarounds
* Prepare the LiveCD node with Cluster Authentication
* Check BGP Peering 
* CSI Validation for Ceph and Kubernetes
* Optional Manual Validation
* Change Root Password on all NCNs

[CSM Platform Install](006-CSM-PLATFORM-INSTALL.md)

Install all of the CSM applications and services into the management Kubernetes cluster.

* Initialize Bootstrap Nexus Registry
* Create Site-Init Secret for Loftsman
* Deploy Sealed Secret Decryption Key
* Start the Deployment of CSM services by running install.sh
* Add Compute Cabinet Routing to NCNs

[CSM Validation process](008-CSM-VALIDATION.md)

The CSM installation validation and health checks can be run after install.sh finishes in this installation process, but can also be run at other times later.

* Platform Health Checks
* Network Health Checks
* Automated Goss Testing
* Hardware Management Services Tests
* Cray Management Services Validation Utility
* Booting CSM Barebones Image
* UAS/UAI Tests

[Reboot from the LiveCD to NCN](007-CSM-INSTALL-REBOOT.md)

The ncn-m001 node needs to reboot from the LiveCD to normal operation as a Kubernetes master node.

* Apply LiveCD Pre-reboot Workarounds
* Hand-off from LiveCD for SLS and BSS 
* Reboot ncn-m001
* Apply post-boot steps to complete configuration
* Apply LiveCD Post-reboot Workarounds


[CSM Validation process](008-CSM-VALIDATION.md)

The CSM installation validation and health checks can be run again now that ncn-m001 has been rebooted to join the Kubernetes cluster. 

[NCN/Management Node Locking](009-NCN-LOCKING.md) 

The NCNs should be locked to prevent accidental firmware upgrades with FAS or power down operations and reset operations with CAPMC.

* Why?
* When To Lock Management/NCN Nodes
* When To Unlock Management/NCN Nodes
* Locked Behavior
* How To Lock Management NCNs
* How To Unlock Management NCNs

[Firmware updates with FAS](010-FIRMWARE-UPDATE-WITH-FAS.md)

The firmware versions of many components may need to be updated at this point in the installation process.

* Prerequisites
* Current Capabilities as of Shasta Release v1.4
* Order Of Operations
* Hardware Precedence Order

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
