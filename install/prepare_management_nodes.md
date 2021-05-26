# Prepare Management Nodes

Some preparation of the management nodes might be needed before starting an install or reinstall.  

For either scenario, the BMC and BIOS firmware should be checked and may need to be updated on the node which will become the PIT node.

For an install, if the system ever had any previous software installed, then storage might need to be wiped on management nodes.  And if switching a system from USB LiveCD to RemoteISO LiveCD, the old USB device might need to be wiped.

For a reinstall, the preparation includes quiescing the compute nodes and application nodes, scaling back DHCP on the management nodes,
wiping the storage on the management nodes, and powering off the management nodes.

### Topics:

For install:
   1. [Firmware Check on PIT Node](#firmware_check_on_pit_node)
   1. [Wipe Disks on Booted Nodes](#wipe_disks_on_booted_nodes)
   1. [Power Off Booted Nodes](#power_off_booted_nodes)
   1. [Wipe USB Device on PIT Node](#wipe_usb_device_on_pit_node) (**Only if** switching from USB LiveCD method to RemoteISO LiveCD method)
   1. [Power Off PIT Node](#power_off_pit_node)

For reinstall:
   1. [Firmware Check on PIT Node](#firmware_check_on_pit_node)
   1. [Quiesce Compute and Application Nodes](#quiesce_compute_and_application_nodes)
   1. [Disable DHCP Service](#disable_dhcp_service) (if any management nodes are booted)
   1. [Wipe Disks on Booted Nodes](#wipe_disks_on_booted_nodes)
   1. [Power Off Booted Nodes](#power_off_booted_nodes)
   1. [Wipe USB Device on PIT Node](#wipe_usb_device_on_pit_node) (**Only if** switching from USB LiveCD method to RemoteISO LiveCD method)
   1. [Power Off PIT Node](#power_off_pit_node)

## Details

<a name="firmware_check_on_pit_node"></a>
### Firmware Check on PIT Node

Check the BMC and BIOS firmware for the PIT node and update if necessary.

If the PIT node does not have the minimum level, it is possible to update it using a method described in the HPC Firmware Pack (HFP).
The HPC Firmware Pack is available in the same location as other product streams which are part of the software stack for HPE Cray Ex systems.

See the HPC Firmware Pack product stream for required minimum levels and procedures to check and update.

**`INTERNAL USE`**  The HPC Firmware Pack is available at https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/firmware/

Later in the installation process the HPC Firmware Pack will be installed on the PIT node and added to the Nexus repository so that it can be used in conjunction with the Firmware Action Services (FAS) to update firmware on other components.

<a name="quiesce_compute_and_application_nodes"></a>
### Quiesce compute nodes and application nodes.

   > **Skip this section if compute nodes and application nodes are not booted**

   The compute nodes and application nodes depend on the management nodes to provide services for their runtime environment.

   * CPS to project the operating system image or the CPE image or the Analytics image
   * cray-dns-unbound (internal system DNS)
   * cray-kea (DHCP leases)
   * Access to the API gateway for node heartbeats

   While the reinstall process happens, these nodes would not be able to function normally.  As part of the
   reinstall, they will be rebooted with new boot images and configuration.

   Refer to "Shut Down and Power Off Compute and User Access Nodes" in the _HPE Cray EX Hardware Management Administration Guide 1.5 S-8015_.

<a name="disable_dhcp_service"></a>
### Disable DHCP Service

   > **Skip this section if none of the management nodes are booted**

   If doing a reinstall and any of the management nodes are booted, then DHCP service will need to be disabled before powering off management nodes.

   1. Scale back DHCP.

      Runtime DHCP services interfere with the LiveCD's bootstrap nature to provide DHCP leases to BMCs. To remove
      edge-cases, disable the run-time cray-dhcp-kea pod.
   
      Scale the deployment from either the LiveCD or any Kubernetes node
   
      ```bash
      ncn# kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
      ```

<a name="wipe_disks_on_booted_nodes"></a>
### Wipe Disks on Booted Nodes

   > **Skip this section if none of the management nodes are booted**

   If any of the management nodes are booted with Linux, they have previous disk data on them which should be wiped.

   1. **REQUIRED** For each management node, **excluding** ncn-m001, login and do a full wipe of the storage on the node. 

   See  [full wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#full-wipe)

<a name="power_off_booted_nodes"></a>
### Power Off Booted Nodes

> **Skip this section if none of the management nodes are booted**

1. Power each NCN off using `ipmitool` from ncn-m001 (or the booted LiveCD if reinstalling an incomplete
install).

   * Shutdown from **LiveCD** (`pit`)

      ```bash
      pit# export username=root
      pit# export IPMI_PASSWORD=changeme
      pit# conman -q | grep mgmt | grep -v m001 | xargs -t -i  ipmitool -I lanplus -U $username -E -H {} power off
         ```

   * Shutdown from **ncn-m001**

      ```bash
      ncn-m001# export username=root
      ncn-m001# export IPMI_PASSWORD=changeme
      ncn-m001# grep ncn /etc/hosts | grep mgmt | grep -v m001 | sort -u | awk '{print $2}' | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
      ```
1. Set the BMCs on the management nodes to DHCP.
   > **`NOTE`** During the install of the management nodes their BMCs get set to static IP addresses. The installation expects the that these BMCs are set back to DHCP before proceeding.
   
   * Set the lan variable.
      If you have Intel nodes set it to 3.
      ```bash
      ncn# export lan=3
      ```
    
      Otherwise set it to 1.
      ```bash
      ncn# export lan=1
      ```

   * from the **LiveCD** (`pit`):
      > **`NOTE`** This step uses the old statics.conf on the system in case CSI changes IPs:

      ```bash
      pit# export username=root
      pit# export IPMI_PASSWORD=changeme
      pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
      do
         ipmitool -U $username -I lanplus -H $h -E lan set $lan ipsrc dhcp
      done
      ```

      The timing of this change can vary based on the hardware, so if the IP can no longer be reached after running the above command, run these commands.

      ```bash
      pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
      do
         ipmitool -U $username -I lanplus -H $h -E lan print $lan | grep Source
      done
      pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
      do
         ipmitool -U $username -I lanplus -H $h -E mc reset cold
      done
      ```

   * from **ncn-m001**:
      > **`NOTE`** This step uses to the `/etc/hosts` file on ncn-m001 to determine the IP addresses of the BMCs:

      ```bash
      ncn-m001# export username=root
      ncn-m001# export IPMI_PASSWORD=changeme
      ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
      do
         ipmitool -U $username -I lanplus -H $h -E lan set $lan ipsrc dhcp
      done
      ```

      The timing of this change can vary based on the hardware, so if the IP can no longer be reached after running the above command, run these commands.

      ```
      ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
      do
         ipmitool -U $username -I lanplus -H $h -E lan print $lan | grep Source
      done
      ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
      do
         ipmitool -U $username -I lanplus -H $h -E mc reset cold
      done
      ```


<a name="wipe_usb_device_on_pit_node"></a>
### Wipe USB Device on PIT Node

   If intending to boot the PIT node from the Remote ISO and there is a USB device which was previously used with LiveCD data, it should be wiped to avoid having two devices with disk labels claiming to be the LiveCD. 

   Or the USB device could be removed from the PIT node.

   1.  Wipe USB storage on **ncn-m001**
        ```bash
        ncn-m001# wipefs --all --force /dev/disk/by-label/cow /dev/disk/by-label/PITDATA /dev/disk/by-label/BOOT /dev/disk/by-label/CRAYLIVE
        ```

<a name="power_off_pit_node"></a>
### Power Off PIT Node 
    > **`Skip this step if`** you are planning to use this node as a staging area to create the USB LiveCD.

    Lastly, shutdown the LiveCD or ncn-m001 node.
    ```bash
    ncn-m001# poweroff
    ```

<a name="next-topic"></a>
# Next Topic

   After completing this procedure the next step is to bootstrap the PIT node.

   * See [Bootstrap PIT Node](index.md#bootstrap_pit_node)

