# Prepare Management Nodes

The procedures described on this page are being done before any node is booted with the Cray Pre-Install Toolkit. When the PIT node is referenced during these procedures, it means the node that will be be booted as the PIT node.

## Topics:

1. [Quiesce Compute and Application Nodes](#quiesce_compute_and_application_nodes)
1. [Disable DHCP Service](#disable_dhcp_service) (if any management nodes are booted)
1. [Wipe Disks on Booted Nodes](#wipe_disks_on_booted_nodes)
1. [Power Off Booted Nodes](#power_off_booted_nodes)
1. [Set Node BMCs to DHCP](#set_node_bmcs_to_dhcp)
1. [Wipe USB Device on PIT Node](#wipe_usb_device_on_pit_node) (**Only if** switching from USB LiveCD method to RemoteISO LiveCD method)
1. [Power Off PIT Node](#power_off_pit_node)

<a name="quiesce_compute_and_application_nodes"></a>
## Quiesce compute nodes and application nodes.

> **Skip this section if compute nodes and application nodes are not booted**

The compute nodes and application nodes depend on the management nodes to provide services for their runtime environment.

* CPS to project the operating system image or the CPE image or the Analytics image
* cray-dns-unbound (internal system DNS)
* cray-kea (DHCP leases)
* Access to the API gateway for node heartbeats

While the reinstall process happens, these nodes would not be able to function normally. As part of the reinstall, they will be rebooted with new boot images and configuration.

See [Shut Down and Power Off Compute and User Access Nodes](../operations/power_management/Shut_Down_and_Power_Off_Compute_and_User_Access_Nodes.md).

<a name="disable_dhcp_service"></a>
## Disable DHCP Service

> **Skip this section if none of the management nodes are booted**

If doing a reinstall and any of the management nodes are booted, then the DHCP service will need to be disabled before powering off management nodes.

Runtime DHCP services interfere with the LiveCD's bootstrap nature to provide DHCP leases to BMCs. To remove edge cases, disable the run-time `cray-dhcp-kea` pod.

Scale the deployment from either the LiveCD or any Kubernetes node

```bash
ncn# kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
```

<a name="wipe_disks_on_booted_nodes"></a>
## Wipe Disks on Booted Nodes

> **Skip this section if none of the management nodes are booted**

If any of the management nodes are booted with Linux, then they have previous installations data on them which should be wiped.

>**REQUIRED** If the above is true, then for each management node, **excluding** `ncn-m001`, log in and do a full wipe of the of the node.
>
> See [full wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#full-wipe)

<a name="power_off_booted_nodes"></a>
## Power Off Booted Nodes

> **Skip this section if none of the management nodes are booted**

Power each NCN off using `ipmitool` from ncn-m001 (or the booted LiveCD if reinstalling an incomplete install).

* Shut down from **LiveCD** (`pit`)

    ```bash
    pit# export USERNAME=root
    pit# export IPMI_PASSWORD=changeme
    pit# conman -q | grep mgmt | grep -v m001 | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

    Check the power status to confirm the nodes have powered off.
    ```bash
    pit# conman -q | grep mgmt | grep -v m001 | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power status
    ```

* Shut down from **ncn-m001**

    ```bash
    ncn-m001# export USERNAME=root
    ncn-m001# export IPMI_PASSWORD=changeme
    ncn-m001# grep ncn /etc/hosts | grep mgmt | grep -v m001 | sort -u | awk '{print $2}' | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

    Check the power status to confirm the nodes have powered off.
    ```bash
    ncn-m001# grep ncn /etc/hosts | grep mgmt | grep -v m001 | sort -u | awk '{print $2}' | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power status
    ```

<a name="set_node_bmcs_to_dhcp"></a>
## Set Node BMCs to DHCP

Set the BMCs on the management nodes to DHCP.
> **`NOTE`** During the install of the management nodes their BMCs get set to static IP addresses. The installation expects the that these BMCs are set back to DHCP before proceeding.

1. Set the `LAN` variable.
    * If you have Intel nodes, set it to 3.
        ```bash
        linux# export LAN=3
        ```

    * For non-Intel nodes, set it to 1.
        ```bash
        linux# export LAN=1
        ```

1. Set the BMCs to DHCP.

    * from the **LiveCD** (`pit`):
        > **`NOTE`** This step uses the old statics.conf on the system in case CSI changes IP addresses:

        ```bash
        pit# export USERNAME=root
        pit# export IPMI_PASSWORD=changeme
        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
            echo "Setting $h to DHCP"
            ipmitool -U $USERNAME -I lanplus -H $h -E lan set $LAN ipsrc dhcp
        done
        ```

        Verify the BMCs have been set to DHCP:
        ```bash
        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
            printf "$h: "
            ipmitool -U $USERNAME -I lanplus -H $h -E lan print $LAN | grep Source
        done
        ```

        > If an error similar to the following occurs, it means that the BMC is no longer reachable by its IP.
        > ```
        > 10.254.1.5: Error: Unable to establish IPMI v2 / RMCP+ session
        > ```

        The timing of this change can vary based on the hardware, so if the IP address of any BMC can still be reached after running the above commands then run the following. A BMC is considered reachable if it can still be pinged by its IP address or hostname (such as `ncn-w001-mgmt`).

        ```bash
        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
            printf "$h: "
            ipmitool -U $USERNAME -I lanplus -H $h -E mc reset cold
        done
        ```

    * from **ncn-m001**:
        > **`NOTE`** This step uses to the `/etc/hosts` file on ncn-m001 to determine the IP addresses of the BMCs:

        ```bash
        ncn-m001# export USERNAME=root
        ncn-m001# export IPMI_PASSWORD=changeme
        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
            echo "Setting $h to DHCP"
            ipmitool -U $USERNAME -I lanplus -H $h -E lan set $LAN ipsrc dhcp
        done
        ```

        Verify the BMCs have been set to DHCP:
        ```bash
        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
            printf "$h: "
            ipmitool -U $USERNAME -I lanplus -H $h -E lan print $LAN | grep Source
        done
        ```
        > If an error similar to the following occurs, it means that the BMC is no longer reachable by its IP.
        > ```
        > ncn-w001-mgmt: Error: Unable to establish IPMI v2 / RMCP+ session
        > ```

        The timing of this change can vary based on the hardware, so if the IP address of any BMC can still be reached after running the above commands then run the following. A BMC is considered reachable if it can still be pinged by its IP address or hostname (such as `ncn-w001-mgmt`).

        ```bash
        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
            printf "$h: "
            ipmitool -U $USERNAME -I lanplus -H $h -E mc reset cold
        done
        ```

<a name="wipe_usb_device_on_pit_node"></a>
## Wipe USB Device on PIT Node

If intending to boot the PIT node from the Remote ISO and there is a USB device which was previously used with LiveCD data, it should be wiped to avoid having two devices with disk labels claiming to be the LiveCD. Alternatively, the USB device could be removed from the PIT node.

1. If not removing the USB device from `ncn-m001`, then wipe its USB storage with the following command:

    ```bash
    ncn-m001# wipefs --all --force /dev/disk/by-label/cow /dev/disk/by-label/PITDATA /dev/disk/by-label/BOOT /dev/disk/by-label/CRAYLIVE
    ```

<a name="power_off_pit_node"></a>
## Power Off PIT Node

> **`Skip this step if`** you are planning to use this node as a staging area to create the USB LiveCD.

Shut down the LiveCD or `ncn-m001` node.
```bash
ncn-m001# poweroff
```

<a name="next-topic"></a>
## Next Topic

   After completing this procedure the next step is to bootstrap the PIT node.

   * See [Bootstrap PIT Node](index.md#bootstrap_pit_node)
