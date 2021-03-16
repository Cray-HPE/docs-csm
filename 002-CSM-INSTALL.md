# CSM Install

This page will prepare you for a CSM install using the LiveCD in different scenarios.

* [Install Prerequisites](#install-prerequisites)
* [Starting an Installation](#starting-an-installation)

  * [Boot the LiveCD](#boot-the-livecd)

<a name="install-prerequisites"></a>
# Install Prerequisites

The prerequisites for each install scenario are defined here. **All prerequisites must be met
before commencing an installation**.

After finishing any of these prerequisite guides, an administrator may move
to [Starting an Installation](#starting-an-installation).

#### Available Installation Paths

  * [Prerequisites for Shasta v1.4 Installations on Shasta v1.3 Systems](#prerequisites-for-shasta-v14-installations-on-shasta-v13-systems)
  * [Prerequisites for Shasta v1.4 Installations on Bare-metal Systems](#prerequisites-for-shasta-v14-installations-on-bare-metal-systems)
  * [Prerequisites for Reinstalling Shasta v1.4](#prerequisites-for-reinstalling-shasta-v14)

---

<a name="pre-requisites-for-shasta-v14-installations-on-shasta-v13-systems"></a>
## Prerequisites for Shasta v1.4 Installations on Shasta v1.3 Systems


Each item below defines a prerequisite that must be completed on systems with existing Shasta
v1.3 installations. Optional steps are noted as such.

* [Collect Shasta v1.4 Config Payload](#collect-shasta-v14-config-payload)
* [Quiesce Shasta v1.3 System](#quiesce-shasta-v13-system)
* [Upgrading BIOS and Firmware](#upgrading-bios-and-firmware-from-13)
* [Re-cabling](#re-cabling)
  * [Site Connections](#site-connections)
  * [PCIe Connections](#pcie-connections)
* [Shut Down Management Kubernetes Cluster](#shut-down-management-kubernetes-cluster)
* [Powering off NCNs](#powering-off-ncns)

<a name="collect-shasta-v14-config-payload"></a>
### Collect Shasta v1.4 Config Payload

Although some configuration data can be saved from a Shasta v1.3 system, there are new configuration files
needed for Shasta v1.4.  Some of this data is easier to collect from a running Shasta v1.3 system.

There may be some operational data to be saved such as any nodes which are disabled or marked down in a
workload manager.  These nodes might need hardware or firmware actions to repair them.  If not addressed,
and the newer firmware in v1.4 does not improve their performance or operation, then these may need to be
disabled with v1.4 as well.

There may be site modifications to the system from v1.3 which are desired in v1.4.  They cannot be directly
copied to v1.4, however, recommendation will be made about what to save.  Some saved information from v1.3
may be referenced when making a similar site modification to v1.3.

See the [Harvest Shasta v1.3 Information](068-HARVEST-13-CONFIG.md) page for the data harvesting procedure.

See the [service guides](300-SERVICE-GUIDES.md) for information regarding the v1.4 configuration files.

<a name="quiesce-shasta-v13-system"></a>
### Quiesce Shasta v1.3 System

1. Follow site processes to quiesce the system, such as draining workload manager queues, saving user data somewhere
off the system, and limiting new logins to application nodes.

    Check for running slurm jobs

    ```bash
    ncn-w001# ssh nid001000 squeue -l
    ```

    Check for running PBS jobs

    ```bash
    ncn-w001# ssh nid001000 qstat -Q
    ncn-w001# ssh nid001000 qstat -a
    ```

2. Obtain the authorization key for SAT.

    See System Security and Authentication, Authenticate an Account with the Command Line, SAT
    Authentication in the Cray Shasta Administration Guide 1.3 S-8001 for more information.

    v1.3.0: Use Rev C of the guide
    v1.3.2: Use Rev E or later

3. Check for running sessions from BOS, CFS, CRUS, FAS, and NMD.

    ```bash
    ncn-w001# sat bootsys shutdown --stage session-checks
    ```
    
    Expected output will look something like this:
    
    ```
    Checking for active BOS sessions.
    Found no active BOS sessions.
    Checking for active CFS sessions.
    Found no active CFS sessions.
    Checking for active CRUS upgrades.
    Found no active CRUS upgrades.
    Checking for active FAS actions.
    Found no active FAS actions.
    Checking for active NMD dumps.
    Found no active NMD dumps.
    No active sessions exist. It is safe to proceed with the shutdown procedure.
    ```

    Coordinate amongst system administration staff to prevent new sessions from starting in the services listed.

    In CLE release 1.3, there is no method to prevent new sessions from being created as long as the service APIs are accessible on the API gateway

4. Shut down and power off all compute nodes and application nodes.

    * v1.3.2 use the "sat bootsys shutdown" command to do compute nodes and application nodes at the same time.
    See the Cray Shasta Administration Guide 1.3 S-8001 RevF (or later) in the section "Shut Down and Power Off Compute and User Access Nodes"

    * v1.3.0 use the "cray bos" command to create a shutdown session for the compute nodes and then for the application nodes
    See the Cray Shasta Administration Guide 1.3 S-8001 RevC (or later) in the section "Shut Down and Power Off Compute and User Access Nodes"


<a name="upgrading-bios-and-firmware-from-1.3"></a>
### Upgrading BIOS and Firmware from 1.3

The management NCNs are expected to have certain minimum firmware installed for BMC, node BIOS, and PCIe card
firmware.

Known issues for Shasta v1.3 systems include:
* Gigabyte nodes should use the Gigabyte Node Firmware Update Guide (1.3.2) S-8010 while booted with Shasta v1.3.2.  However, since v1.3 will never be booted again on this system, there is no need to ensure that the etcd clusters are healthy and that BGP Peering has been ESTABLISHED as recommended in that guide.
* Nodes with Mellanox ConnectX-4 and ConnectX-5 PCIe NICs need to update their firmware.  This should be done while Shasta v1.3.2 is booted.  The Mellanox ConnectX-4 cards will be enabled for PXE booting later.

1. For minimum BIOS spec (required settings), see [Node BIOS Preferences](200-NCN-BIOS-PREF.md).

2. For minimum NCN firmware versions see [Node Firmware](252-FIRMWARE-NCN.md).

3. For minimum Network switch firmware versions see [Network Firmware](251-FIRMWARE-NETWORK.md).

4. For minimum Network switch configurations see [Management Network Install](401-MANAGEMENT-NETWORK-INSTALL.md).

> **`WARNING`** Skipping this on a system that is new to Shasta v1.4 (bare-metal or previously installed with Shasta v1.3 or earlier) can result in undesirable difficulties:
>
> - Misnamed interfaces (missing `hsn0`)
> - Malfunctioning bonds (`bond0`)
> - Link failures (i.e. QLogic cards set to 10Gbps fixed)
> - Malfunctioning or disabled Multi-Chassis LAGG
> - Back-firing work-around scripts

<a name="recabling"></a>
### Re-cabling

The Shasta v1.3 system needs to change a few connections.

- [Site Connections](#site-connections)
- [PCIe Connections](#pcie-connections)

<a name="site-connections"></a>
#### Site Connections

Installs in Shasta v1.4 are based on ncn-m001, which functions as the PIT (Pre-Install-Toolkit) node booted
from the LiveCD with Shasta v1.4, instead of ncn-w001, which was the BIS node used for installation with
Shasta v1.3 software. Systems are required to change their cabling to match.

See [moving site connections](309-MOVE-SITE-CONNECTIONS.md) to complete this step.

<a name="pcie-connections"></a>
#### PCIe Connections

This **is strongly encouraged** to prevent overhead when adding new NCNs that the
existing NCNs are re-cabled to facilitate PCIe PXE booting and "keeping NCNs the same."

Installs for NCNs support PCIe PXE booting for deployment. Previous installations of Shasta v1.3 and
earlier used their onboard interfaces to start PXE, before pivoting to their faster PCIe ports for
Linux install. Now, everything is over the PCIe network interface card.

See [PCIe Net-boot and Recable](304-NCN-PCIE-NET-BOOT-AND-RE-CABLE.md) for information on enabling
PCIe card PXE boot.

<a name="shut-down-management-kubernetes-cluster"></a>
### Shut Down Management Kubernetes Cluster

Shut down Ceph and the Kubernetes management cluster.  This performs several actions to quiesce the
management services and leaves each management NCN running Linux, but no other services.

Shutdown platform services.
  ```bash
  ncn-w001# sat bootsys shutdown --stage platform-services
  ```

<a name="powering-off-ncns"></a>
### Powering off NCNs

The management NCNs need to be powered off to facilitate a 1.4 install. Wiping the node
will avoid boot mistakes, making the only viable option the PXE option. Below, use Ansible
for wiping and shutting down the NCNs. 

1. Since 1.3 installs used ncn-w001 as a place to run Ansible and host Ansible inventory, 
we'll start by jumping from the manager node to ncn-w001.
    ```bash
    # jumpbox
    ncn-m001# ssh ncn-w001
    ncn-w001#
    ```
1. Wipe disks on all nodes:
    ```bash
    ncn-w001# ansible ncn -m shell -a 'wipefs --all --force /dev/sd*'
    ```

    For disks which have no labels, no output will be shown by the wipefs commands being run. 
    If one or more disks have labels, output similar to the following is expected:
    ```
    /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdb: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdb: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdb: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdc: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
    /dev/sdc: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
    ```
  
    The thing to verify is that there are no error messages in the output.
1. Power off all other nodes except ncn-m001
    ```bash
    ncn-w001# ansible ncn -m shell --limit='!ncn-w001:!ncn-m001' -a 'ipmitool power off'
    ```
1. Power off ncn-w001:
    ```bash
    ncn-w001# ipmitool power off
    ```

At this time all that is left powered on is ncn-m001. The final `ipmitool power off` command should disconnect the administrator from ncn-w001, leaving them on ncn-m001.

If the connection fails to disconnect, an administrator can escape and disconnect IPMI without exiting their SSH session by pressing `~~.` until `ipmitool` disconnects.

> Next: Starting an Installation

The system is now ready for [Starting an Installation](#starting-an-installation).

---

<a name="prerequisites-for-shasta-v14-installations-on-bare-metal-systems"></a>
## Prerequisites for Shasta v1.4 Installations on Bare-metal Systems

Each item below defines a prerequisite necessary for a bare-metal installation to succeed.

> **`NOTE`** On bare-metal, the LiveCD tool will assist with these steps.

* [LiveCD Setup](#livecd-setup)
* [Collect Config Payload](#collect-config-payload)
* [Network Configuration and Firmware](#network-configuration-and-firmware)
* [Upgrading BIOS and Firmware](#upgrading-bios-and-firmware)

<a name="livecd-setup"></a>
### LiveCD Setup

A 1TB USB3.0 USB stick will be required in order to create a bootable LiveCD.

The LiveCD itself can be used out-of-the-box, and with only a little configuration it can serve for
the various bare-metal prerequisite tasks.

Experimental - See **[LiveCD Quick Setup](062-LIVECD-VIRTUAL-ISO-BOOT.md)** for either remote ISO path, this is useful for exploring a new system quickly. Other lab users may prefer a bootable USB stick to enable persistence, and for bringing artifacts for firmware updates.

Once you are booted into a LiveCD, proceed onto the next prerequisite steps for bare-metal.

<a name="collect-config-payload"></a>
### Collect Config Payload

New configuration files are needed for the installation of Shasta v1.4.

See the [Service Guides](300-SERVICE-GUIDES.md) for information regarding the four files.

<a name="network-configuration-and-firmware"></a>
### Network Configuration and Firmware

To complete this step, the network configuration needs to be applied. For information on bare
configurations, firmware, and more, see [Management network install](401-MANAGEMENT-NETWORK-INSTALL.md).

<a name="upgrading-bios-and-firmware"></a>
### Upgrading BIOS and Firmware

The management NCNs are expected to have certain minimum firmware installed for BMC, node BIOS, and PCIe card
firmware.  Where possible, the firmware should be updated prior to install.  Some firmware can be updated
during or after the Shasta v1.4 installation, but it is better to meet the minimum NCN firmware requirement
before starting.

1. For minimum BIOS spec (required settings), see [Node BIOS Preferences](200-NCN-BIOS-PREF.md).

2. For minimum NCN firmware versions see [Node Firmware](252-FIRMWARE-NCN.md).

3. For minimum Network switch firmware versions see [Network Firmware](251-FIRMWARE-NETWORK.md).

4. For minimum Network switch configurations see [Management Network Install](401-MANAGEMENT-NETWORK-INSTALL.md).

> **`WARNING`** Skipping this on a system that is new to Shasta v1.4 (bare-metal or previously installed with Shasta v1.3 or earlier) can result in undesirable difficulties:
>
> - Misnamed interfaces (missing `hsn0`)
> - Malfunctioning bonds (`bond0`)
> - Link failures (i.e. QLogic cards set to 10Gbps fixed)
> - Malfunctioning or disabled Multi-Chassis LAGG
> - Back-firing work-around scripts


> Next: Starting an Installation

The system is now ready for [Starting an Installation](#starting-an-installation).

---

<a name="prerequisites-for-reinstalling-shasta-v14"></a>
## Prerequisites for Reinstallting Shasta v1.4

The following prerequisites must be completed in order to successfully reinstall Shasta v1.4.

* [Standing Kubernetes Down](#standing-kubernetes-down)
* [Prepare the Non-Compute Nodes](#prepare-the-non-compute-nodes)

<a name="Standing Kubernetes Down"></a>
### Standing Kubernetes Down

Runtime DHCP services interfere with the LiveCD's bootstrap nature to provide DHCP leases to BMCs. To remove
edge-cases, disable the run-time cray-dhcp-kea pod.

Scale the deployment from either the LiveCD or any Kubernetes node

```bash
ncn# kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
```

<a name="prepare-the-non-compute-nodes"></a>
### Prepare the Non-Compute Nodes

> UANs and CNs do not need to be powered off.

The steps below detail how to prepare the NCNs.

<a name="degraded-system-notice"></a>
> #### Degraded System Notice
>
> If the system is degraded; CRAY services are down, or the NCNs are in inconsistent states then a cleanslate should be performed.  [basic wipe from Disk Cleanslate](051-DISK-CLEANSLATE.md#basic-wipe)

1. **REQUIRED** For each NCN, **excluding** ncn-m001, login and wipe it (this step uses the [basic wipe from Disk Cleanslate](051-DISK-CLEANSLATE.md#basic-wipe)):
    > **`NOTE`** Pending completion of CASMINST-1659, the auto-wipe is insufficient for masters and workers. All administrators must wipe their NCNs with this step.
    - Wipe NCN disks from **LiveCD** (`pit`)
        ```bash
        pit# ncns=$(grep Bond0 /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F',' '{print $6}')
        pit# for h in $ncns; do
            read -r -p "Are you sure you want to wipe the disks on $h? [y/N] " response
            response=${response,,}
            if [[ "$response" =~ ^(yes|y)$ ]]; then
                 ssh $h 'wipefs --all --force /dev/sd* /dev/disk/by-label/*'
            fi
        done
        ```

    - Wipe NCN disks from **ncn-m001**
        ```bash
        ncn-m001# ncns=$(grep ncn /etc/hosts | grep nmn | grep -v m001 | awk '{print $3}')
        ncn-m001# for h in $ncns; do
            read -r -p "Are you sure you want to wipe the disks on $h? [y/N] " response
            response=${response,,}
            if [[ "$response" =~ ^(yes|y)$ ]]; then
                 ssh $h 'wipefs --all --force /dev/sd* /dev/disk/by-label/*'
            fi
        done
        ```

    In either case, for disks which have no labels, no output will be shown. If one or more disks have labels, output similar
    to the following is expected:
    ```
    ...
    Are you sure you want to wipe the disks on ncn-m003? [y/N] y
    /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdb: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdb: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdb: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdc: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
    /dev/sdc: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
    ...
    ```

    The thing to verify is that there are no error messages in the output.

2. Power each NCN off using `ipmitool` from ncn-m001 (or the booted LiveCD if reinstalling an incomplete
install).

    - Shutdown from **LiveCD** (`pit`)
        ```bash
        pit# export username=root
        pit# export IPMI_PASSWORD=changeme
        pit# conman -q | grep mgmt | xargs -t -i  ipmitool -I lanplus -U $username -E -H {} power off
        ```

    - Shutdown from **ncn-m001**
        ```bash
        ncn-m001# export username=root
        ncn-m001# export IPMI_PASSWORD=changeme
        ncn-m001# grep ncn /etc/hosts | grep mgmt | grep -v m001 | sort -u | awk '{print $2}' | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
        ```

<a name="set-the-bmcs-on-the-systems-back-to-dhcp"></a>
3. Set the BMCs on the systems back to DHCP.
   > **`NOTE`** During the install of the NCNs their BMCs get set to static IP addresses. The installation expects the that the NCN BMCs are set back to DHCP before proceeding.

   * from the **LiveCD** (`pit`):
        > **`NOTE`** This step uses the old statics.conf on the system in case CSI changes IPs:

        ```bash
        pit# export username=root
        pit# export IPMI_PASSWORD=changeme

        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E lan set 1 ipsrc dhcp
        done
        ```

        The timing of this change can vary based on the hardware, so if the IP can no longer be reached after running the above command, run these commands.

        ```
        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E lan print 1 | grep Source
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
        ipmitool -U $username -I lanplus -H $h -E lan set 1 ipsrc dhcp
        done
        ```

        The timing of this change can vary based on the hardware, so if the IP can no longer be reached after running the above command, run these commands.

        ```
        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E lan print 1 | grep Source
        done

        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E mc reset cold
        done
        ```

4. Powering Off LiveCD or ncn-m001 node
    > **`Skip this step if`** you are planning to use this node as a staging area to create the LiveCD. Lastly, shutdown the LiveCD or ncn-m001 node.
    ```bash
    ncn-m001# poweroff
    ```

With the nodes off, the system is now ready for [Starting an Installation](#starting-an-installation).

---

<a name="starting-an-installation"></a>
# Starting an Installation

**After finishing the prerequisites** an installation can be started one of two ways.

<a name="boot-the-livecd"></a>
## Boot the LiveCD

All installs may be done in full from a LiveCD of any supported medium.

- For preloading on a laptop or Linux node and inserting into a CRAY, click here for starting an installation
  with the (persistent bootable) [CSM USB LiveCD](003-CSM-USB-LIVECD.md).

*Experimental*
- For installing through a remote console, click here for starting an installation with the (
  non-persistent bootable) [CSM Remote LiveCD](004-CSM-REMOTE-LIVECD.md).

> **`NOTICE`** the remote ISO runs entirely in the systems volatile memory.

> For installs using the remote mounted LiveCD (no USB stick), pay attention to memory usage as
artifacts are downloaded and subsequently extracted. When RAM is limited to less than 128GB, memory
pressure may occur from increasing file-system usage.
> For instances where memory is scarce, an NFS/CIF or HTTP/S share can be mounted in-place of the USB's data partition at `/var/www/ephemeral`. Using the same mount point as the USB data partition will help ward off mistakes when following along.
