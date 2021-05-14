# Bootstrap PIT Node from LiveCD Remote ISO 

The Pre-Install Toolkit (PIT) node needs to be bootstraped from the LiveCD.  There are two media available
to bootstrap the PIT node--the RemoteISO or a bootable USB device.  This procedure describes using the 
RemoveISO.  If not using the RemoteISO, see [Bootstrap PIT Node from LiveCD USB](#bootstrap_livecd_usb.md)

The installation process is similar to the USB based installation with adjustments to account for the
lack of removable storage.

**Important:** Before starting this page be sure to complete the
[CSM Install Prerequisites](prepare_configuration_payload.md#csm-install-prerequisites) for
the relevant installation scenario.

### Topics:
   * [Known Compatibility Issues](*known-compatibility-issues)
   * [Attaching and Booting the LiveCD with the BMC](#attaching-and-booting-the-livecd-with-the-bmc)
   * [First Login](#first-login)
   * [Configure the Running LiveCD](#configure-the-running-livecd)
   * [Next Topic](#next-topic)

## Details
<a name="known-compatibility-issues"></a>
### Known Compatibility Issues

The LiveCD Remote ISO has known compatibility issues for nodes from certain vendors.

- [`INTEL`] S2600WF and any *26** series may experience the described issues below.
- [`INTEL`] Samba is untested and undocumented by Intel at this time. It may be used on Intels as a workaround at the user's own leisure.
- [`INTEL`] Mounting the LiveCD on an Intel server does not provide a recognizable boot device without the BIOS running in LEGACY mode (not UEFI).
   - Boot the node with `ipmitool chassis bootdev reset/on options=legacy`

<a name="attaching-and-booting-the-livecd-with-the-bmc"></a>
### Attaching and Booting the LiveCD with the BMC

> **`INTERNAL WARNING`** If this is a re-installation on a system that still has a USB stick from a prior
> installation then that USB stick must be wiped before continuing. Failing to wipe the USB, if present, may result in confusion.
> If the USB is booted still then it can wipe itself using the [basic wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe). If it is not booted, please do so and wipe it _or_ disable the USB ports in the BIOS (not available for all vendors).

Obtain and attach the LiveCD `.iso` file to the BMC. Depending on the server vendor, the instructions for attaching to the BMC will differ.

1. Obtain the ISO

   TODO Replace the EXTERNAL information with a link to [Update Product Stream](../update_product_stream/index.md) for how to get the latest CSM software release and apply any patches.  Still needs to explain how to get the ISO from that CSM tarball.

   - **`EXTERNAL`** Obtain the CSM TAR ball from CrayPort
   - **`INTERNAL`** latest nightly ISO: http://car.dev.cray.com/artifactory/csm/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/cray-pre-install-toolkit-latest.iso
   - **`INTERNAL ADVISORY`** The latest ISO in Artifactory can change, it is advised to use the FQDN of the ISO name. Every `latest` ISO has a matching ISO with the real buildID in the name, this ISO will have the same File-Time meta as the latest ISO.

1. See the respective guide below to attach an ISO:

   TODO Is it better to include this content here or link to an outside topic?

   - [HPE iLO BMCs](./062-LIVECD-VIRTUAL-ISO-BOOT.md#hpe-ilo-bmcs)
   - [Gigabyte BMCs](./062-LIVECD-VIRTUAL-ISO-BOOT.md#gigabyte-bmcs)
   - [Intel BMCs](./062-LIVECD-VIRTUAL-ISO-BOOT.md#intel-bmcs)

1. Each guide should have rebooted the server.  Observe the server boot into the LiveCD.

<a name"first-login"></a>
### First Login

On first login (over SSH or at local console) the LiveCD will prompt the administrator to change the password.

1. **The initial password is empty**; set the username of `root` and press `return` twice:

   ```
   pit login: root
   ```

   Expected output looks similar to the following:

   ```
   Password:           <-------just press Enter here for a blank password
   You are required to change your password immediately (administrator enforced)
   Changing password for root.
   Current password:   <------- press Enter here, again, for a blank password
   New password:       <------- type new password
   Retype new password:<------- retype new password
   Welcome to the CRAY Prenstall Toolkit (LiveOS)

   Offline CSM documentation can be found at /usr/share/doc/metal (version: rpm -q docs-csm-install)

   ```

<a name="configure-the-running-livecd"></a>
### Configure the Running LiveCD

1. Set up the Typescript directory as well as the initial typescript. This directory will be returned to for every typescript in the entire CSM installation.


   ```bash
   pit# mkdir -p /var/www/ephemeral/prep/admin
   pit# pushd !$
   pit# script -af csm-install-remoteiso.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Set up the site-link, enabling SSH to work. The administrator or CI/CD agent can reconnect with SSH after this step.
   > **`NOTICE REGARDING DHCP`** If your site's network authority or network administrator has already provisioned an IPv4 address for your master node(s) external NIC(s), **then skip this step**.

   1. Setup Variables:

      ```bash
      # The IPv4 Address for the nodes external interface(s); this will be provided if not already by the site's network administrator or network authority.
      pit# site_ip=172.30.XXX.YYY/20
      pit# site_gw=172.30.48.1
      pit# site_dns=172.30.84.40
      # The actual NIC names for the external site interface; the first onboard or the first 1GBe PCIe (RJ-45).
      pit# site_nics='p2p1 p2p2 p2p3'
      # another example:
      pit# site_nics=em1
      ```

   1. Run the link setup script:
      > **`NOTE : USAGE`** All of the `/root/bin/csi-*` scripts are harmless to run without parameters, doing so will dump usage statements.

      ```bash
      pit# /root/bin/csi-setup-lan0.sh $site_ip $site_gw $site_dns $site_nics
      ```

   1. (recommended) print `lan0`, and if it has an IP then exit console and login again. The SSH connection will
      provide larger window sizes and better bufferhandling (screen wrapping).

      ```bash
      pit# ip a show lan0
      pit# exit
      external# ssh root@${SYSTEM_NAME}-ncn-m001
      ```

   1. (recommended) After reconnecting, resume the typescript (the `-a` appends to an existing script):

       ```bash
      pit# pushd /var/www/ephemeral/prep/admin
      pit# script -af $(ls -tr csm-install-remoteiso* | head -n 1)
      pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
      ```

   1. Check hostname:

      ```bash
      pit# hostnamectl
      ```
      > **`NOTE`** If the hostname returned by the `hostnamectl` command is still `pit`, then re-run the above script with the same parameters. Otherwise feel free to set the hostname by hand with `hostnamectl`, please continue to use the `-pit` suffix to prevent masquerading a pit node as a real NCN to administrators and automation.

1. Find a local disk for storing product installers:

    ```bash
    pit# disk="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print $2}' | head -n 1 | tr -d '\n')"
    pit# parted --wipesignatures -m --align=opt --ignore-busy -s /dev/$disk -- mklabel gpt mkpart primary ext4 2048s 100%
    pit# mkfs.ext4 -L PITDATA "/dev/${disk}1"
    ```

1. Mount local disk, check the output of each command as it goes.

    ```bash
    pit# mount -v -L PITDATA
    pit# pushd /var/www/ephemeral
    pit/var/www/ephemeral# mkdir -v prep configs data 
    ```

1. If necessary, download the CSM software release to the Linux host which will be preparing the
   LiveCD.

   TODO Does this information in substeps 1 to 3 need to be replaced with a link to [Update Product Stream](../update_product_stream/index.md) for how to get the latest CSM software release and apply any patches?

   > **`INTERNAL NOTE: $ENDPOINT`** The `$ENDPOINT` URL (`arti.dev.cray.com`) below are for internal use. Customers do not need to download any additional
   > artifacts, the CSM tarball is included along with the Shasta release.

   1. Set helper variables

      ```bash
      pit:/var/www/ephemeral# export ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm
      pit:/var/www/ephemeral# export CSM_RELEASE=csm-x.y.z
      ```

   1. Save the `CSM_RELEASE` for usage later; all subsequent shell sessions will have this var set.

      ```bash
      # Prepend a new line to assure we add on a unique line and not at the end of another.
      pit:/var/www/ephemeral# echo -e "\nCSM_RELEASE=$CSM_RELEASE" >>/etc/environment
      ```

   1. Fetch the release ball:

      ```bash
      pit:/var/www/ephemeral# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz -O /var/www/ephemeral/${CSM_RELEASE}.tar.gz
      ```

   1. Expand the ball:

      ```bash
      pit:/var/www/ephemeral# tar -zxvf ${CSM_RELEASE}.tar.gz
      pit:/var/www/ephemeral# ls -l ${CSM_RELEASE}
      ```

   1. Copy the artifacts into place:

      ```bash
      pit/var/www/ephemeral# mkdir -p data/{k8s,ceph}
      pit/var/www/ephemeral# rsync -a -P --delete ./${CSM_RELEASE}/images/kubernetes/ ./data/k8s/
      pit/var/www/ephemeral# rsync -a -P --delete ./${CSM_RELEASE}/images/storage-ceph/ ./data/ceph/
      ```

   > The PIT ISO, Helm charts/images, and bootstrap RPMs are now available in the extracted CSM tar.

1. Install/upgrade the CSI RPM.


   > **`IMPORTANT`** Before proceeding, refer to the "CSM Patch Assembly" section of the Shasta Install Guide
   > to apply any needed patch content for CSM. It is critical to perform these steps to ensure that the correct
   > CSM release artifacts are deployed.
   >
   > TODO Does this information in this IMPORTANT section need to be replaced with a link to [Update Product Stream](../update_product_stream/index.md) for how to get the latest CSM software release and apply any patches?
   >
   > **`WARNING`** Ensure that the `CSM_RELEASE` environment variable is set to the version of the patched CSM release tarball.
   > Applying the "CSM Patch Assembly" procedure will result in a different CSM version when compared to
   > the pre-patched CSM release tarball.

   ```bash
   pit:/var/www/ephemeral# rpm -Uvh $(ls -r ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm | head -n 1)
   ```

1. Show the version of CSI installed.

   ```bash
   pit# csi version
   ```

   Expected output looks similar to the following:
   ```
   CRAY-Site-Init build signature...
   Build Commit   : b3ed3046a460d804eb545d21a362b3a5c7d517a3-release-shasta-1.4
   Build Time     : 2021-02-04T21:05:32Z
   Go Version     : go1.14.9
   Git Version    : b3ed3046a460d804eb545d21a362b3a5c7d517a3
   Platform       : linux/amd64
   App. Version   : 1.5.18
   ```

1. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have
   direct internet access these RPMs will need to be externally downloaded and then copied to be
   installed.

   TODO Getting workaround rpms is in [Update Product Stream](../update_product_stream/index.md).
   TODO Are the 1.5 workaround rpms really in a URL that has "shasta-1.4" in it?

   ```bash
   pit# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm-install/docs-csm-install-latest.noarch.rpm
   pit# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

1. Generate configuration files:
   > For help, see [generate installation files](bootstrap_livecd_usb.md#generate-installation-files) from the USB stick; the description there works here.

   TODO don't reference the USB method of generating installation files here.  Both bootstrap_livecd_usb.md and bootstrap_livecd_remote_iso.md should reference the same information in prepare_configuration_payload.md.  Anything else should be replicated from USB to RemoteISO because we don't want to jump between too many different files, especially between USB and RemoteISO.

   ```bash
   pit:/var/www/ephemeral# csi config init
   ```

1. Check for workarounds in the `/opt/cray/csm/workarounds/csi-config` directory. If there are any workarounds in that directory, run those now. Each has its own instructions in their respective `README.md` files.

      ```bash
      # Example
      linux# ls /opt/cray/csm/workarounds/csi-config
      ```

   If there is a workaround here, the output looks similar to the following:

      ```
      CASMINST-999
      ```

1. Copy the interface config files generated earlier by `csi config init`
   into `/etc/sysconfig/network/` **or** use the provided scripts under "lab usage" below:

   1. Copy PIT files:

      ```bash
      pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/pit-files/* /etc/sysconfig/network/
      pit# wicked ifreload all
      pit# systemctl restart wickedd-nanny && sleep 5
      ```
   1. Lab usage; setup dnsmasq by hand:

      ```bash
      pit# /root/bin/csi-setup-vlan002.sh $nmn_cidr
      pit# /root/bin/csi-setup-vlan004.sh $hmn_cidr
      pit# /root/bin/csi-setup-vlan007.sh $can_cidr
      ```

1. Check that IPs are set for each interface and investigate any failures:

    1. Check IPs, do not run tests if these are missing and instead start triage:

       ```bash
       pit# wicked show bond0 vlan002 vlan004 vlan007
       bond0           up
       link:     #7, state up, mtu 1500
       type:     bond, mode ieee802-3ad, hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-bond0
       leases:   ipv4 static granted
       addr:     ipv4 10.1.1.2/16 [static]

       vlan002         up
       link:     #8, state up, mtu 1500
       type:     vlan bond0[2], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan002
       leases:   ipv4 static granted
       addr:     ipv4 10.252.1.4/17 [static]
       route:    ipv4 10.92.100.0/24 via 10.252.0.1 proto boot

       vlan007         up
       link:     #9, state up, mtu 1500
       type:     vlan bond0[7], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan007
       leases:   ipv4 static granted
       addr:     ipv4 10.102.9.5/24 [static]
 
       vlan004         up
       link:     #10, state up, mtu 1500
       type:     vlan bond0[4], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan004
       leases:   ipv4 static granted
       addr:     ipv4 10.254.1.4/17 [static]
       ```

    1. Run tests, inspect failures:

       ```bash
       pit# csi pit validate --network
       ```

1. Copy the service config files generated earlier by `csi config init` for DNSMasq, Metal
   Basecamp (cloud-init), and Conman:

    1. Copy files (files only, `-r` is exclusively not used):

       ```bash
       pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/dnsmasq.d/* /etc/dnsmasq.d/
       pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/conman.conf /etc/conman.conf
       pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/basecamp/* /var/www/ephemeral/configs/
       ```

    1. Enable, and fully restart all PIT services:

      ```bash
       pit# systemctl enable basecamp nexus dnsmasq conman
       pit# systemctl stop basecamp nexus dnsmasq conman
       pit# systemctl start basecamp nexus dnsmasq conman
       ```

1. Start and configure NTP on the LiveCD for a fallback/recovery server:

   ```bash
   pit# /root/bin/configure-ntp.sh
   ```

1. Check that our services are ready and investigate any test failures.

   ```bash
   pit# csi pit validate --services
   ```

1. Mount a shim to match the Shasta-CFG steps' directory structure:

    ```bash
    pit# mkdir -vp /mnt/pitdata
    pit# mount -v -L PITDATA /mnt/pitdata
    ```

1. The following procedure will set up customized CA certificates for deployment using Shasta-CFG.

   * [Prepare Site-Init](prepare_site_init.md) to create and prepare the `site-init` directory for your system.


<a name="next-topic"></a>
# Next Topic

   After completing this procedure the next step is to configure the management network switches.

   * See [Configure Management Network Switches](index.md#configure_management_network)

