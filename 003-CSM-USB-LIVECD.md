# CSM USB LiveCD - Creation and Configuration

This page will guide an administrator through creating a USB stick from either their Shasta v1.3 ncn-m001 node or their own laptop/desktop.

There are 5 overall steps that provide a bootable USB with SSH enabled, capable of installing Shasta v1.4 (or higher).

* [Download and Expand the CSM Release](#download-and-expand-the-csm-release)
* [Create the Bootable Media](#create-the-bootable-media)
* [Configuration Payload](#configuration-payload)
   * [SHASTA-CFG](#SHASTA-CFG)
   * [Generate Installation Files](#generate-installation-files)
   * [CSI Workarounds](#csi-workarounds)
* [Pre-Populate LiveCD Daemons Configuration and NCN Artifacts](#pre-populate-livecd-daemons-configuration-and-ncn-artifacts)
* [Boot the LiveCD](#boot-the-livecd)
   * [First Login](#first-login)


<a name="download-and-expand-the-csm-release"></a>
## Download and Expand the CSM Release

Fetch the base installation CSM tarball and extract it, installing the contained CSI tool.

1. Start a typescript to capture the commands and output from this installation.
   ```bash
   linux# script -af csm-usb-lived.$(date +%Y-%m-%d).txt
   linux# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

> **`INTERNAL USE`** The `ENDPOINT` URL below are for internal use, customer/external should
> use the URL for the server hosting their tarball.

2. Download the CSM software release to the Linux host which will be preparing the LiveCD.
   ```bash
   linux# cd ~
   linux# export ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm/
   linux# export CSM_RELEASE=csm-x.y.z
   linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
   ```

3. Expand the CSM software release:
   ```bash
   linux# tar -zxvf ${CSM_RELEASE}.tar.gz
   linux# ls -l ${CSM_RELEASE}
   ```
   The ISO and other files are now available in the extracted CSM tar.

4. Install/upgrade the CSI RPM.
   ```bash
   linux# rpm -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
   ```

5. Install/upgrade the workaround documentation RPM.
   ```bash
   linux# rpm -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/noarch/csm-install-workarounds-*.noarch.rpm
   ```

6. Show the version of CSI installed.
   ```bash
   linux# csi version
   CRAY-Site-Init build signature...
   Build Commit   : b3ed3046a460d804eb545d21a362b3a5c7d517a3-release-shasta-1.4
   Build Time     : 2021-02-04T21:05:32Z
   Go Version     : go1.14.9
   Git Version    : b3ed3046a460d804eb545d21a362b3a5c7d517a3
   Platform       : linux/amd64
   App. Version   : 1.5.18
    ```

6. Install podman or docker to support container tools required by SHASTA-CFG.

   Podman RPMs are included in the "embedded" repository in the CSM release and
   can be installed as follows:
   ```bash
   linux# zypper ar --gpgcheck-allow-unsigned -f "./${CSM_RELEASE}/rpm/embedded" "${CSM_RELEASE}-embedded"
   linux# zypper in -y podman podman-cni-config
   ```
   or the RPMs (and their dependencies) can be manually installed using `rpm`.

<a name="create-the-bootable-media"></a>
## Create the Bootable Media

Cray Site Init will create the bootable LiveCD. Before creating the media, we need to identify
which device that is.

1. Identify the USB device.

    This example shows the USB device is /dev/sdd on the host.

    ```bash
    linux# lsscsi
    [6:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sda
    [7:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdb
    [8:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdc
    [14:0:0:0]   disk    SanDisk  Extreme SSD      1012  /dev/sdd
    [14:0:0:1]   enclosu SanDisk  SES Device       1012  -      
    ```
    In the above example, we can see our internal disks as the `ATA` devices and our USB as the `disk` or `enclsou` device. Since the `SanDisk` fits the profile we're looking for, we are going to use `/dev/sdd` as our disk.

    Set a variable with your disk to avoid mistakes:

    ```bash
    linux# export USB=/dev/sd<disk_letter>
    ```

2. Format the USB device

    On Linux using the CSI application:
    ```bash
    linux# csi pit format $USB ~/${CSM_RELEASE}/cray-pre-install-toolkit-*.iso 50000
    ```
    On MacOS using the bash script:
    ```bash
    macos# ./cray-site-init/write-livecd.sh $USB ~/${CSM_RELEASE}/cray-pre-install-toolkit-*.iso 50000
    ```

    > NOTE: At this point the USB stick is usable in any server with an x86_64 architecture based CPU. The remaining steps help add the installation data and enable SSH on boot.

3. Mount the configuration and persistent data partition:

    ```bash
    linux# mkdir -pv /mnt/{cow,pitdata}
    linux# mount -L cow /mnt/cow && mount -L PITDATA /mnt/pitdata
    ```

4.  Copy and extract the tarball (compressed) into the USB:
    ```bash
    linux# cp -r ~/${CSM_RELEASE}.tar.gz /mnt/pitdata/
    linux# tar -zxvf ~/${CSM_RELEASE}.tar.gz -C /mnt/pitdata/
    ```

The USB stick is now bootable and contains our artifacts. This may be useful for internal or quick usage. Administrators seeking a Shasta installation must continue onto the [configuration payload](#configuration-payload).

<a name="configuration-payload"></a>
## Configuration Payload

The SHASTA-CFG structure and other configuration files will be prepared, then csi will generate system-unique configuration payload used for the rest of the CSM installation on the USB stick.

* [Generate Installation Files](#generate-installation-files)
* [CSI Workarounds](#csi-workarounds)
* [SHASTA-CFG](#SHASTA-CFG)

<a name="generate-installation-files"></a>
### Generate Installation Files

Some files are needed for generating the configuration payload. New systems will need to create these files before continuing.  Systems upgrading from Shasta v1.3 should prepare by [gathering data from the existing system](068-HARVEST-13-CONFIG.md).

> Note: The USB stick is usable at this time, but without SSH enabled as well as core services. This means the stick could be used to boot the system now, and a user can return to this step at another time.

Pull these files into the current working directory:
- `application-node-config.yaml` (optional - see below)
- `cabinets.yaml` (optional - see below)
- `hmn_connections.json`
- `ncn_metadata.csv`
- `switch_metadata.csv`
- `system_config.yaml` (see below)

> The optional `application-node-config.yaml` file may be provided for further defining of settings relating to how application nodes will appear in HSM (e.g. naming). See the CSI usage for more information.  This will also be useful 

> The optional `cabinets.yaml` file allows cabinet naming and numbering as well as some networking overrides (e.g. VLAN) which will allow systems on Shasta v1.3 to minimize changes to the existing system while migrating to Shasta v1.4.  More information on this file can be found [here](310-CABINETS.md).

After gathering the files into the working directory, generate your configs:

1. Change into the preparation directory:
   ```bash
   linux# mkdir -pv /mnt/pitdata/prep
   linux# cd /mnt/pitdata/prep
   ```

2. Generate the system configuration reusing a parameter file (see [avoiding parameters](./063-CSI-FILES.md#save-file--avoiding-parameters)) **or skip this step**.

   If moving from a Shasta v1.3 system, the system_config.yaml file will not be available, so skip this step and continue with step 3.

   The needed files should be in the current directory.
   ```bash
   linux# ls -1
   application_node_config.yaml
   cabinets.yaml
   hmn_connections.json
   ncn_metadata.csv
   shasta_system_configs
   switch_metadata.csv
   system_config.yaml
   ```

   Generate the system configuration.
   ```bash
   linux# csi config init
   ```

   A new directory matching your `--system-name` argument will now exist in your working directory.

   Set an environment variable so this system name can be used in later commands.
   ```bash
   linux# export SYSTEM_NAME=eniac
   ```

   Skip step 3 and continue with the CSI Workarounds

3. Generate the system configuration when a pre-existing parameter file is unavailable:

   If moving from a Shasta v1.3 system, this step is required.  If you did step 2 above, skip this step.

   The needed files should be in the current directory.  The application_node_config.yaml file is optional.
   ```bash
   linux# ls -1
   application_node_config.yaml
   hmn_connections.json
   ncn_metadata.csv
   shasta_system_configs
   switch_metadata.csv
   ```

   Set an environment variable so this system name can be used in later commands.
   ```bash
   linux# export SYSTEM_NAME=eniac
   ```

   Generate the system configuration.  See below for an explanation of the command line parameters and some common settings.
   ```
   linux# csi config init \
       --bootstrap-ncn-bmc-user root \
       --bootstrap-ncn-bmc-pass changeme \
       --system-name ${SYSTEM_NAME}  \
       --mountain-cabinets 4 \
       --starting-mountain-cabinet 1000 \
       --hill-cabinets 0 \
       --river-cabinets 1 \
       --can-cidr 10.103.11.0/24 \
       --can-external-dns 10.103.11.113 \
       --can-gateway 10.103.11.1 \
       --can-static-pool 10.103.11.112/28 \
       --can-dynamic-pool 10.103.11.128/25 \
       --nmn-cidr 10.252.0.0/17 \
       --hmn-cidr 10.254.0.0/17 \
       --ntp-pool time.nist.gov \
       --site-domain dev.cray.com \
       --site-ip 172.30.53.79/20 \
       --site-gw 172.30.48.1 \
       --site-nic p1p2 \
       --site-dns 172.30.84.40 \
       --install-ncn-bond-members p1p1,p10p1 \
       --application-node-config-yaml application_node_config.yaml \
       --cabinets-yaml cabinets.yaml \
       --hmn-mtn-cidr 10.104.0.0/17 \
       --nmn-mtn-cidr 10.100.0.0/17
   ```

   A new directory matching your `--system-name` argument will now exist in your working directory.

   > After generating a configuration, particularly when upgrading from Shasta v1.3 a visual audit of the generated files for network data should be performed.  Specifically, the <systemname>/networks/HMN_MTN.yaml and <systemname>/networks/NMN_MTN.yaml files should be viewed to ensure that cabinet names, subnets and VLANs have been preserved for an upgrade to Shasta v1.4.  Failure of these parameters to match will likely mean a re-installation or reprogramming of CDU switches and CMM VLANs.

   Run the command "csi config init --help" to get more information about the parameters mentioned in the example command above and others which are available.

   Notes about parameters to "csi config init":
   * The application_node_config.yaml file is optional, but if you have one describing the mapping between prefixes in hmn_connections.csv that should be maped to HSM subroles, you need to include a command line option to have it used.
   * The bootstrap-ncn-bmc-user and bootstrap-ncn-bmc-pass must match what is used for the BMC account and its password for the management NCNs.
   * Set site parameters (site-domain, site-ip, site-gw, site-nic, site-dns) for the information which connects the ncn-m001 (PIT) node to the site.  The site-nic is the interface on this node connected to the site.  If coming from Shasta v1.3, the information for all of these site parameters was collected.
   * There are other interfaces possible, but the install-ncn-bond-members are typically: p1p1,p10p1 for HPE nodes; p1p1,p1p2 for Gigabyte nodes; and p801p1,p801p2 for Intel nodes.  If coming from Shasta v1.3, this information was collected for ncn-m001.
   * Set the three cabinet parameters (mountain-cabinets, hill-cabinets, and river-cabinets) to the number of each cabinet which are part of this system.
   * The starting cabinet number for each type of cabinet (for example, starting-mountain-cabinet) has a default that can be overriden.  See the "csi config init --help" 
   * For systems that use non-sequential cabinet id numbers, use cabinets-yaml to include the cabinets.yaml file.  This file can include information about the starting ID for each cabinet type and number of cabinets which have separate command line options, but is a way to explicitly specify the id of every cabinet in the system.  This process is described [here](310-CABINETS.md).
   * An override to default cabinet IPv4 subnets can be made with the hmn-mtn-cidr and nmn-mtn-cidr parameters.  These are also used to maintain existing configuration in a Shasta v1.3 system.
   * Several parameters (can-gateway, can-cidr, can-static-pool, can-dynamic-pool) describe the CAN (Customer Access network).  The can-gateway is the common gateway IP used for both spine switches and commonly referred to as the Virtual IP for the CAN.  The can-cidr is the IP subnet for the CAN assigned to this system. The can-static-pool and can-dynamic-pool are the MetalLB address static and dynamic pools for the CAN. The can-external-dns is the static IP assigned to the DNS instance running in the cluster to which requests the cluster subdomain will be forwarded.   The can-external-dns IP must be within the can-static-pool range.
   * Set ntp-pool to a reachable NTP server

   These warnings from "csi config init" for issues in hmn_connections.json can be ignored.
   * The node with the external connection (ncn-m001) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other management NCNs.  It can be ignored.
      ```
      "Couldn't find switch port for NCN: x3000c0s1b0"
      ```
   * An unexpected component may have this message.  If this component is an application node with an unusual prefix, it should be added to the application_node_config.yaml file and then rerun "csi config init".   See the procedure to [create the application_node_config.yaml](308-APPLICATION-NODE-CONFIG.md)
      ```json
      {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
      {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
      ```
   * If a cooling door is found in hmn_connections.json, there may be a message like the following. It can be safely ignored.
      ```json
      {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
      {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
      ```
   Continue with the CSI Workarounds

<a name="csi-workarounds"></a>
### CSI Workarounds

Check for workarounds in the `/opt/cray/csm/workarounds/csi-config` directory.  If there are any workarounds in that directory, run those now. Instructions are in the README files.

  ```bash
  # Example
  linux# ls /opt/cray/csm/workarounds/csi-config
  casminst-999
  ```

<a name="SHASTA-CFG"></a>
### SHASTA-CFG

SHASTA-CFG is a distinct repository of relatively static, installation-centric artifacts, including:

* Cluster-wide network configuration settings required by Helm Charts deployed by product stream Loftsman Manifests
* [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
* Sealed Secret Generate Blocks -- an form of plain-text input that renders to a Sealed Secret
* Helm Chart value overrides that are merged into Loftsman Manifests by product stream installers

Follow [the instructions here](./067-SHASTA-CFG.md) to prepare a SHASTA-CFG repository for your system.

<a name="pre-populate-livecd-daemons-configuration-and-ncn-arti"></a>
## Pre-Populate LiveCD Daemons Configuration and NCN Artifacts

Now that the configuration is generated, we can populate the LiveCD with the generated files.

This will enable SSH, and other services when the LiveCD starts.
1. Set system name and enter prep directory
    ```bash
    linux# export SYSTEM_NAME=eniac
    ```

2. Use CSI to populate the LiveCD, provide both the mountpoint and the CSI generated config dir.
    ```bash
    linux# cd /mnt/pitdata/prep
    linux# csi pit populate cow /mnt/cow/ ${SYSTEM_NAME}/
    config------------------------> /mnt/cow/rw/etc/sysconfig/network/config...OK
    ifcfg-bond0-------------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-bond0...OK
    ifcfg-lan0--------------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-lan0...OK
    ifcfg-vlan002-----------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-vlan002...OK
    ifcfg-vlan004-----------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-vlan004...OK
    ifcfg-vlan007-----------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-vlan007...OK
    ifroute-lan0------------------> /mnt/cow/rw/etc/sysconfig/network/ifroute-lan0...OK
    ifroute-vlan002---------------> /mnt/cow/rw/etc/sysconfig/network/ifroute-vlan002...OK
    CAN.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/CAN.conf...OK
    HMN.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/HMN.conf...OK
    NMN.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/NMN.conf...OK
    mtl.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/mtl.conf...OK
    statics.conf------------------> /mnt/cow/rw/etc/dnsmasq.d/statics.conf...OK
    conman.conf-------------------> /mnt/cow/rw/etc/conman.conf...OK
    ```

3. Optionally set the hostname, print it into the hostname file.
   > Do not confuse other admins and name the LiveCD "ncn-m001", please append the "-pit" suffix
   > which will indicate that the node is booted from the LiveCD.
   ```bash
   linux# echo "${SYSTEM_NAME}-ncn-m001-pit" >/mnt/cow/rw/etc/hostname
   ```

4. Unmount the Overlay, we're done with it
    ```bash
    linux# umount /mnt/cow    
    ```

5. Make directories needed for basecamp (cloud-init) and the squashFS images

    ```bash
    linux# mkdir -p /mnt/pitdata/configs/
    linux# mkdir -p /mnt/pitdata/data/{k8s,ceph}/
    ```

6. Copy basecamp data
    ```bash
    linux# csi pit populate pitdata ${SYSTEM_NAME} /mnt/pitdata/configs -b
    data.json---------------------> /mnt/pitdata/configs/data.json...OK
    ```

7. Update CA Cert on the copied `data.json` file. Provide the path to the `data.json`, the path to
   our `customizations.yaml`, and finally the `sealed_secrets.key`
    ```bash
    linux# csi patch ca \
    --cloud-init-seed-file /mnt/pitdata/configs/data.json \
    --customizations-file /mnt/pitdata/prep/site-init/customizations.yaml \
    --sealed-secret-key-file /mnt/pitdata/prep/site-init/certs/sealed_secrets.key
   ```

8. Copy k8s artifacts:
    ```bash
    linux# csi pit populate pitdata ~/${CSM_RELEASE}/images/kubernetes/ /mnt/pitdata/data/k8s/ -kiK
    5.3.18-24.37-default-0.0.6.kernel-----------------> /mnt/pitdata/data/k8s/...OK
    initrd.img-0.0.6.xz-------------------------------> /mnt/pitdata/data/k8s/...OK
    kubernetes-0.0.6.squashfs-------------------------> /mnt/pitdata/data/k8s/...OK
    ```

9. Copy ceph/storage artifacts:
    ```bash
    linux# csi pit populate pitdata ~/${CSM_RELEASE}/images/storage-ceph/ /mnt/pitdata/data/ceph/ -kiC
    5.3.18-24.37-default-0.0.5.kernel-----------------> /mnt/pitdata/data/ceph/...OK
    initrd.img-0.0.5.xz-------------------------------> /mnt/pitdata/data/ceph/...OK
    storage-ceph-0.0.5.squashfs-----------------------> /mnt/pitdata/data/ceph/...OK
    ```

10. Unmount the data partition:
    ```bash
    linux# cd; umount /mnt/pitdata
    ```

11. Quit the typescript session with the `exit` command and copy the file (csm-usb-lived.<date>.txt) to a location on another server for reference later.

Now the USB stick may be reattached to the CRAY, or if it was made on the CRAY then its server can now
reboot into the LiveCD.

<a name="boot-the-livecd"></a>
## Boot the LiveCD

Some systems will boot the USB stick automatically if no other OS exists (bare-metal). Otherwise the
administrator may need to use the BIOS Boot Selection menu to choose the USB stick.

If an administrator is rebooting a node into the LiveCD, vs booting a bare-metal or wiped node, then `efibootmgr` will deterministically set the boot order. See the [EFI Boot Manager](064-EFIBOOTMGR.md) page for more information on this topic..

> UEFI booting must be enabled to find the USB sticks EFI bootloader.

1. Start a typescript on an external system, such as a laptop or Linux system, to record this section of activities done on the console of ncn-m001 via IPMI.

   ```bash
   external# script -a boot.livecd.$(date +%Y-%m-%d).txt
   external# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

Confirm that the IPMI credentials work for the BMC by checking the power status.

   ```bash
   external# username=root
   external# password=changme
   external# ipmitool -I lanplus -U $username -P $password -H ${SYSTEM_NAME}-ncn-m001-mgmt chassis power status
   ```

Connect to the IPMI console.  Press return and login on the console as root.

   ```bash
   external# ipmitool -I lanplus -U $username -P $password -H ${SYSTEM_NAME}-ncn-m001-mgmt sol activate
   eniac-ncn-m001 login: root
   ncn-m001#
   ```

2. Reboot

    ```bash
    ncn-m001# reboot
    ```

Watch the shutdown and boot from the ipmitool session to the console terminal.

> **An integrity check** runs before Linux starts by default, it can be skipped by selecting "OK" in its prompt.

<a name="first-login"></a>
### First Login

On first login (over SSH or at local console) the LiveCD will prompt the administrator to change the password.

1. **The initial password is empty**; set the username of `root` and press `return` twice:

   ```bash
   pit login: root
   Password:           <-------just press Enter here for a blank password
   You are required to change your password immediately (administrator enforced)
   Changing password for root.
   Current password:   <------- press Enter here, again, for a blank password
   New password:       <------- type new password
   Retype new password:<------- retype new password
   Welcome to the CRAY Prenstall Toolkit (LiveOS)

   Offline CSM documentation can be found at /usr/share/doc/metal (version: rpm -q docs-csm-install)
   ```

   > **`NOTE`** If this password is forgotten, it can be reset by mounting the USB stick on another computer. See [LiveCD Troubleshooting](058-LIVECD-TROUBLESHOOTING.md#root-password) for information on clearing the password.


2. Disconnect from IPMI console.

   Once the network is up so that ssh to the node works, disconnect from the IPMI console.

   You can disconnect from the IPMI console by using the "~.", that is, the tilde character followed by a period character.

   Login via ssh to the node.

   ```bash
   external# ssh ${SYSTEM_NAME}-ncn-m001
   ncn-m001 login: root
   pit#

   Note: The hostname should be something like eniac-ncn-m001-pit when booted from the LiveCD, but it will be shown as "pit#" in the command prompts from this point onward.


3. Start a typescript to record this section of activities done on ncn-m001 while booted from the LiveCD.

   ```bash
   pit# script -af booted-csm-lived.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

4. Check the pit-release version.

   ```bash
   pit# cat /etc/pit-release
   VERSION=1.2.2
   TIMESTAMP=20210121044136
   HASH=75e6c4a
   ```

5. Mount the data partition
    > The data partition is set to `fsopt=noauto` to facilitate LiveCDs over virtual-ISO mount. USB installations need to mount this manually.
    ```bash
    pit# mount -L PITDATA
    ```

6. Start services

   ```bash
   pit# systemctl start nexus
   pit# systemctl start basecamp
   pit# systemctl start conman
   ```

7. Verify the system:

   ```bash
   pit# csi pit validate --network
   pit# csi pit validate --services
   ```

   > - If dnsmasq is dead, restart it with `systemctl restart dnsmasq`.

   > In addition, the final output from validating the services should have information about the nexus and basecamp containers/images similar this example.

   ```
   CONTAINER ID  IMAGE                                               COMMAND               CREATED        STATUS            PORTS   NAMES
   ff7c22c6c6cb  dtr.dev.cray.com/sonatype/nexus3:3.25.0             sh -c ${SONATYPE_...  3 minutes ago  Up 3 minutes ago          nexus
   c7638b573b93  dtr.dev.cray.com/cray/metal-basecamp:1.1.0-1de4aa6                        5 minutes ago  Up 5 minutes ago          basecamp
   ```

8. Follow the output's directions for failed validations before moving on.

After successfully validating the LiveCD USB environment, the administrator may start the [CSM Metal Install](005-CSM-METAL-INSTALL.md).
