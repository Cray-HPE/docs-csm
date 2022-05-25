# Prepare Management Nodes

The procedures described on this page must be completed before any node is booted with the Cray Pre-Install Toolkit (PIT), which is performed in a later document. When the PIT
node is referenced during these procedures, it means the node that will be booted as the PIT node.

1. [Quiesce compute and application nodes](#quiesce_compute_and_application_nodes)
1. [Disable DHCP service](#disable_dhcp_service)
1. [Wipe disks on booted nodes](#wipe_disks_on_booted_nodes)
1. [Set IPMI credentials](#set_ipmi_credentials)
1. [Power off booted nodes](#power_off_booted_nodes)
1. [Set node BMCs to DHCP](#set_node_bmcs_to_dhcp)
1. [Wipe USB device on PIT node](#wipe_usb_device_on_pit_node)
1. [Power off PIT node](#power_off_pit_node)

<a name="quiesce_compute_and_application_nodes"></a>

## Quiesce compute nodes and application nodes

> **Skip this section if compute nodes and application nodes are not booted.**

The compute nodes and application nodes depend on the management nodes to provide services for their runtime environment. For example:

* Content Projection Service (CPS) to project the operating system image, the CPE image, or the Analytics image
* `cray-dns-unbound` (internal system DNS)
* `cray-kea` (DHCP leases)
* Access to the API gateway for node heartbeats

While the reinstall process happens, these nodes would not be able to function normally. As part of the reinstall, they will be rebooted with new boot images and configuration.

See [Shut Down and Power Off Compute and User Access Nodes](../operations/power_management/Shut_Down_and_Power_Off_Compute_and_User_Access_Nodes.md).

<a name="disable_dhcp_service"></a>

## Disable DHCP service

> **Skip this section if none of the management nodes are booted.**

If doing a reinstall and any of the management nodes are booted, then the DHCP service will need to be disabled before powering off management nodes.

Runtime DHCP services interfere with the LiveCD's bootstrap nature to provide DHCP leases to BMCs. To remove edge cases, disable the run-time `cray-dhcp-kea` pod.

Scale the deployment from either the LiveCD or any Kubernetes node:

```bash
ncn# kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
```

<a name="wipe_disks_on_booted_nodes"></a>

## Wipe disks on booted nodes

> **Skip this section if none of the management nodes are booted.**

If any of the management nodes are booted with Linux, then they have data from previous installations on them which must be wiped.

**REQUIRED** If the above is true, then for each management node (**excluding** `ncn-m001`), log in and do a "full wipe" of the node's disks.

See [full wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#full-wipe).

<a name="set_ipmi_credentials"></a>

## Set IPMI credentials

The upcoming procedures use `ipmitool`. Set IPMI credentials for the BMCs of the NCNs.

> `read -s` is used in order to prevent the credentials from being displayed on the screen or recorded in the shell history.

```bash
linux# USERNAME=root
linux# read -s IPMI_PASSWORD
linux# export IPMI_PASSWORD
```

<a name="power_off_booted_nodes"></a>

## Power off booted nodes

> **Skip this section if none of the management nodes are booted.**

Power each NCN off using `ipmitool` from `ncn-m001` (or the booted LiveCD, if reinstalling an incomplete install).

### Shut down from **LiveCD** (`pit`)

1. Power off NCNs.

    ```bash
    pit# conman -q | grep mgmt | grep -v m001 | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

1. Check the power status to confirm that the nodes have powered off.

    ```bash
    pit# conman -q | grep mgmt | grep -v m001 | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power status
    ```

### Shut down from `ncn-m001`

1. Power off NCNs.

    ```bash
    ncn-m001# grep ncn /etc/hosts | grep mgmt | grep -v m001 | sort -u | awk '{print $2}' | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

1. Check the power status to confirm that the nodes have powered off.

    ```bash
    ncn-m001# grep ncn /etc/hosts | grep mgmt | grep -v m001 | sort -u | awk '{print $2}' | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power status
    ```

<a name="set_node_bmcs_to_dhcp"></a>

## Set node BMCs to DHCP

Set the BMCs on the management nodes to DHCP. During the install of the management nodes their BMCs get set to static IP addresses. The installation expects these
BMCs to be set back to DHCP before proceeding.

> These steps require that the [Set IPMI credentials](#set_ipmi_credentials) steps have been performed.

1. Set the `LAN` variable based on NCN hardware type.

    * If NCNs are Intel, set it to 3.

        ```bash
        linux# LAN=3
        ```

    * For non-Intel nodes, set it to 1.

        ```bash
        linux# LAN=1
        ```

1. Collect BMC hostnames or IP addresses.

    * From the **LiveCD** (`pit`):

        > This collects BMC IP addresses using the old `statics.conf` on the system, in case CSI changes IP addresses:

        ```bash
        pit# BMCS=$(grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' |
                       grep -Eo "([0-9]{1,3}[.]){3}[0-9]{1,3}" | sort -u  | tr '\n' ' ') ; echo $BMCS
        ```

    * From **`ncn-m001`**:

        Collect BMC hostnames from `/etc/hosts`:

        ```bash
        ncn-m001# BMCS=$(grep -wEo "ncn-[msw][0-9]{3}-mgmt" /etc/hosts | grep -v "m001" | sort -u | tr '\n' ' ') ; echo $BMCS
        ```

1. Set the BMCs to DHCP.

    ```bash
    linux# for h in $BMCS ; do
               echo "Setting $h to DHCP"
               ipmitool -U $USERNAME -I lanplus -H $h -E lan set $LAN ipsrc dhcp
           done
    ```

1. Verify that the BMCs have been set to DHCP:

    ```bash
    linux# for h in $BMCS ; do
               printf "$h: "
               ipmitool -U $USERNAME -I lanplus -H $h -E lan print $LAN | grep Source
           done
    ```

1. Perform a cold reset of any BMCs which are still reachable.

    ```bash
    linux# for h in $BMCS ; do
               printf "$h: "
               if ping -c 3 $h >/dev/null 2>&1; then
                   printf "Still reachable. Issuing cold reset... "
                   ipmitool -U $USERNAME -I lanplus -H $h -E mc reset cold
               else
                   echo "Not reachable (DHCP setting appears to be successful)"
               fi
           done
    ```

    As long as every BMC is either not reachable or receives a cold reset, this step is successful.

<a name="wipe_usb_device_on_pit_node"></a>

## Wipe USB device on PIT node

> **Skip this section if intending to boot the PIT node from a USB device for the install.**

If the PIT node has previously been booted (either from a USB device or a remote ISO), then it should be wiped
in order to avoid problems stemming from leftover LiveCD disk labels.

Wipe LiveCD disk labels with the following command:

```bash
ncn-m001# wipefs --all --force /dev/disk/by-label/cow /dev/disk/by-label/PITDATA /dev/disk/by-label/BOOT /dev/disk/by-label/CRAYLIVE
```

<a name="power_off_pit_node"></a>

## Power off PIT node

> **Skip this step if planning to use this node as a staging area to create the USB LiveCD.**

Shut down the LiveCD or `ncn-m001` node.

```bash
linux# poweroff
```

<a name="next-topic"></a>

## Next topic

The next step is to bootstrap the PIT node.

See [Bootstrap PIT Node](index.md#bootstrap_pit_node).
