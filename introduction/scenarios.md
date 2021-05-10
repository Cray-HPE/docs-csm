# Scenarios for Shasta v1.5

TODO Revise this section

There are multiple scenarios for installing CSM software.

* Installation
  There are two ways to install the CSM software
  * [First Time Install of v1.5](#first-time)
    TODO 
  * [Reinstall of v1.5](#reinstall)
    TODO 
* Upgrade
  An upgrade from the previous release Shasta v1.4.x is supported.
  [Upgrade from 1.4.x to v1.5](../upgrade/index.md)
* Migration
  There is no direct migration from Shasta v1.3.x releases to Shasta v1.5.  However there is a supported path.
  * Migration from v1.3.x to v1.4.0
    The migration from v1.3.x to v1.4.0 is described in the Shasta v1.4 documentation
    See HPE Cray EX System Installation and Configuration Guide 1.4 S-8000.
  * Upgrade v1.4.x to v1.5
    An upgrade from the previous release (Shasta v1.4.x) is supported with this release.
    [Upgrade from 1.4.x to v1.5](../upgrade/index.md)


TODO Revise this section

# CSM Documentation Guide

The installation of CSM software has three scenarios which are described in this documentation with many supporting procedures.  Here is an overview of the workflow through the documentation to support these scenarios.

[CSM Install] (002-CSM-INSTALL.md)

Installation prerequisites

Satisfy the prerequisites for one of these three installation scenarios 

* First time installation of Shasta software (a bare-metal install).  This describes now to setup the LiveCD to be able to collect the configuration payload, configure network switches, update firmware for switches and nodes to required versions.  Then you move to Starting an Installation.
* Reinstalling Shasta v1.4 software on a system which previously had Shasta v1.4 installed.  These steps here are scaling down DHCP, wiping disks on the NCNs (except ncn-m001), power off NCNs, change management node BMCs to be DHCP not Static, and powering off the LiveCD or ncn-m001 (unless it will be used to prepare the LiveCD).  Then you move to Starting an Installation.

Once the installation prerequisites have been addressed, the installation is very similar for all of them.  There are a few places where a comment will be made for how one of the scenarios needs to do something different.

Starting an installation

The three separate scenarios (above) continue the same way at this point, with preparation and then booting from the LiveCD.  

* This version of the documentation supports booting from a [CSM USB LiveCD] (../install/bootstrap_livecd_remote_iso.md).
* A future version of this documentation will support booting from a virtual ISO method [CSM Remote LiveCD] (004-CSM-REMOTE-LIVECD.md). 

##### [CSM USB LiveCD - Creation and Configuration](064-LIVECD-USB-BOOT.md)

Preparation of the LiveCD on a USB stick can be done from a Linux system such as a booted ncn-m001 node with either Shasta v1.3 or v1.4 or a laptop or desktop.

* [Download and Expand the CSM Release](064-LIVECD-USB-BOOT.md#download-and-expand-the-csm-release)
* [Create the Bootable Media](064-LIVECD-USB-BOOT.md#create-the-bootable-media)
* [Configuration Payload](064-LIVECD-USB-BOOT.md#configuration-payload)
  * [Generate Installation Files](064-LIVECD-USB-BOOT.md#generate-installation-files)
  * [CSI Workarounds](064-LIVECD-USB-BOOT.md#csi-workarounds)
  * [SHASTA-CFG](064-LIVECD-USB-BOOT.md#shasta-cfg)
* [Pre-Populate LiveCD Daemons Configuration and NCN Artifacts](064-LIVECD-USB-BOOT.md#pre-populate-livecd-daemons-configuration-and-ncn-artifacts)
* [Boot the LiveCD](064-LIVECD-USB-BOOT.md#boot-the-livecd)
  * [First Login](064-LIVECD-USB-BOOT.md#first-login)

##### [Deploy Management Nodes](../install/deploy_management_nodes.md)

Now that ncn-m001 has been booted from the LiveCD, the other management NCNs will be deployed to create the management Kubernetes cluster.

* [Configure Bootstrap Registry to Proxy an Upstream Registry](../install/deploy_management_nodes.md#configure-bootstrap-registry-to-proxy-an-upstream-registry)
* [Tokens and IPMI Password](../install/deploy_management_nodes.md#tokens-and-ipmi-password)
* [Timing of Deployments](../install/deploy_management_nodes.md#timing-of-deployments)
* [NCN Deployment](../install/deploy_management_nodes.md#ncn-deployment)
  * [Apply NCN Pre-Boot Workarounds](../install/deploy_management_nodes.md#apply-ncn-pre-boot-workarounds)
  * [Ensure Time Is Accurate Before Deploying NCNs](../install/deploy_management_nodes.md#ensure-time-is-accurate-before-deploying-ncns)
  * [Start Deployment](../install/deploy_management_nodes.md#start-deployment)
    * [Workflow](../install/deploy_management_nodes.md#workflow)
    * [Deploy](../install/deploy_management_nodes.md#deploy)
  * [Apply NCN Post-Boot Workarounds](../install/deploy_management_nodes.md#apply-ncn-post-boot-workarounds)
  * [LiveCD Cluster Authentication](../install/deploy_management_nodes.md#livecd-cluster-authentication)
  * [BGP Routing](../install/deploy_management_nodes.md#bgp-routing)
  * [Validation](../install/deploy_management_nodes.md#validation)
  * [Optional Validation](../install/deploy_management_nodes.md#optional-validation)
* [Configure and Trim UEFI Entries](../install/deploy_management_nodes.md#configure-and-trim-uefi-entries)


##### [Install CSM Services](../install/install_csm_services.md)

Install all of the CSM applications and services into the management Kubernetes cluster.

* [Initialize Bootstrap Registry](../install/install_csm_services.md#initialize-bootstrap-registry)
* [Create Site-Init Secret](../install/install_csm_services.md#create-site-init-secret)
* [Deploy Sealed Secret Decryption Key](../install/install_csm_services.md#deploy-sealed-secret-decryption-key)
* [Deploy CSM Applications and Services](../install/install_csm_services.md#deploy-csm-applications-and-services)
  * [Setup Nexus](../install/install_csm_services.md#setup-nexus)
  * [Set NCNs to use Unbound](../install/install_csm_services.md#set-ncns-to-use-unbound)
  * [Validate CSM Install](../install/install_csm_services.md#validate-csm-install)
  * [Reboot from the LiveCD to NCN](../install/install_csm_services.md#reboot-from-the-livecd-to-ncn)
* [Add Compute Cabinet Routing to NCNs](../install/install_csm_services.md#add-compute-cabinet-routing-to-ncns)
* [Known Issues](../install/install_csm_services.md#known-issues)
  * [error: timed out waiting for the condition on jobs/cray-sls-init-load](../install/install_csm_services.md#error-timed-out-sls-init-load-job)
  * [Error: not ready: https://packages.local](../install/install_csm_services.md#error-not-ready)
  * [Error initiating layer upload ... in registry.local: received unexpected HTTP status: 200 OK](../install/install_csm_services.md#error-initiating-layer-upload)
  * [Error lookup registry.local: no such host](../install/install_csm_services.md#error-registry-local-no-such-host)

<a name="csm-install-validation-and-health-checks"></a> 
###### [Validate CSM Health](../operations/validate_csm_health.md)

The CSM installation validation and health checks can be run after install.sh finishes in this installation process, but can also be run at other times later.

* [Platform Health Checks](../operations/validate_csm_health.md#platform-health-checks)
  * [ncnHealthChecks](../operations/validate_csm_health.md#pet-ncnhealthchecks)
  * [ncnPostgresHealthChecks](../operations/validate_csm_health.md#pet-ncnpostgreshealthchecks)
  * [BGP Peering Status and Reset](../operations/validate_csm_health.md#pet-bgp)
    * [Mellanox Switch](../operations/validate_csm_health.md#pet-bgp-mellanox)
    * [Aruba Switch](../operations/validate_csm_health.md#pet-bgp-aruba)
* [Network Health Checks](../operations/validate_csm_health.md#network-health-checks)
  * [Verify that KEA has active DHCP leases](../operations/validate_csm_health.md#net-kea)
  * [Verify ability to resolve external DNS](../operations/validate_csm_health.md#net-extdns)
  * [Verify Spire Agent is Running on Kubernetes NCNs](../operations/validate_csm_health.md#net-spire)
  * [Verify the Vault Cluster is Healthy](../operations/validate_csm_health.md#net-vault)
* [Automated Goss Testing](../operations/validate_csm_health.md#automated-goss-testing)
  * [Known Goss Test Issues](../operations/validate_csm_health.md#autogoss-issues)
* [Hardware Management Services Tests](../operations/validate_csm_health.md#hms-tests)
  * [Test Execution](../operations/validate_csm_health.md#hms-exec)
* [Cray Management Services Validation Utility](../operations/validate_csm_health.md#cms-validation-utility)
  * [Usage](../operations/validate_csm_health.md#cms-usage)
  * [Interpreting Results](../operations/validate_csm_health.md#cms-results)
  * [Checks To Run](../operations/validate_csm_health.md#cms-checks)
* [Booting CSM Barebones Image](../operations/validate_csm_health.md#booting-csm-barebones-image)
  * [Locate the CSM Barebones Image in IMS](../operations/validate_csm_health.md#csm-ims)
  * [Create a BOS Session Template for the CSM Barebones Image](../operations/validate_csm_health.md#csm-bst)
  * [Find an available compute node and boot the session template](../operations/validate_csm_health.md#csm-node)
  * [Reboot node](../operations/validate_csm_health.md#csm-reboot)
  * [Verify console connections](../operations/validate_csm_health.md#csm-consoles)
  * [Connect to the node's console and watch the boot](../operations/validate_csm_health.md#csm-watch)
* [UAS / UAI Tests](../operations/validate_csm_health.md#uas-uai-tests)
  * [Initialize and Authorize the CLI](../operations/validate_csm_health.md#uas-uai-init-cli)
    * [Stop Using the CRAY_CREDENTIALS Service Account Token](../operations/validate_csm_health.md#uas-uai-init-cli-stop)
    * [Initialize the CLI Configuration](../operations/validate_csm_health.md#uas-uai-init-cli-init)
    * [Authorize the CLI for Your User](../operations/validate_csm_health.md#uas-uai-init-cli-auth)
    * [Troubleshooting CLI issues](../operations/validate_csm_health.md#uas-uai-init-cli-debug)
  * [Validate UAS and UAI Functionality](../operations/validate_csm_health.md#uas-uai-validate)
    * [Validate the Basic UAS Installation](../operations/validate_csm_health.md#uas-uai-validate-install)
    * [Validate UAI Creation](../operations/validate_csm_health.md#uas-uai-validate-create)
    * [Troubleshooting](../operations/validate_csm_health.md#uas-uai-validate-debug)
      * [Authorization Issues](../operations/validate_csm_health.md#uas-uai-validate-debug-auth)
      * [UAS Cannot Access Keycloak](../operations/validate_csm_health.md#uas-uai-validate-debug-keycloak)
      * [UAI Images not in Registry](../operations/validate_csm_health.md#uas-uai-validate-debug-registry)
      * [Missing Volumes and other Container Startup Issues](../operations/validate_csm_health.md#uas-uai-validate-debug-container)

##### [Redeploy PIT Node](../install/redeploy_pit_node.md)

The ncn-m001 node needs to reboot from the LiveCD to normal operation as a Kubernetes master node.

* [Required Services](../install/redeploy_pit_node.md#required-services)
* [Notice of Danger](../install/redeploy_pit_node.md#danger)
* [Hand-Off](../install/redeploy_pit_node.md#hand-off)
  * [Start Hand-Off](../install/redeploy_pit_node.md#start-hand-off)
* [Reboot](../install/redeploy_pit_node.md#reboot)
* [Next Step](../install/redeploy_pit_node.md#next-step)

##### [Validate CSM Health](../operations/validate_csm_health.md)

[*Double-back...*](#csm-install-validation-and-health-checks)

The CSM installation validation and health checks can be run again now that ncn-m001 has been rebooted to join the Kubernetes cluster. 

##### [Lock And Unlock Nodes](../operations/lock_and_unlock_nodes.md) 

The NCNs should be locked to prevent accidental firmware upgrades with FAS or power down operations and reset operations with CAPMC.

* [Why?](../operations/lock_and_unlock_nodes.md#why)
* [When To Lock Management NCNs](../operations/lock_and_unlock_nodes.md#when-to-lock-management-ncns)
* [When To Unlock Management NCNs](../operations/lock_and_unlock_nodes.md#when-to-unlock-management-ncns)
* [Locked Behavior](../operations/lock_and_unlock_nodes.md#locked-behavior)
* [How To Lock Management NCNs](../operations/lock_and_unlock_nodes.md#how-to-lock-management-ncns)
* [How To Unlock Management NCNs](../operations/lock_and_unlock_nodes.md#how-to-unlock-management-ncns)


##### [Firmware Update the system with FAS](../operations/update_firmware_with_fas.md)

The firmware versions of many components may need to be updated at this point in the installation process.

* [Prerequisites](../operations/update_firmware_with_fas.md#prerequisites)
* [Current Capabilities as of Shasta Release v1.4](../operations/update_firmware_with_fas.md#current-capabilities)
* [Order Of Operations](../operations/update_firmware_with_fas.md#order-of-operations)
* [Hardware Precedence Order](../operations/update_firmware_with_fas.md#hardware-precedence-order)
* [Next Steps](../operations/update_firmware_with_fas.md#next-steps)


The details of the process are outlined in [255-FIRMWARE-ACTION-SERVICE-FAS.md](255-FIRMWARE-ACTION-SERVICE-FAS.md) using recipes listed in [256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md](256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md)

Then the administrator should install additional products following the procedures in the HPE Cray EX System Installation and Configuration Guide S-8000.
