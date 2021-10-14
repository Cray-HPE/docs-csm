# Bootstrap PIT Node from LiveCD USB

The Pre-Install Toolkit (PIT) node needs to be bootstrapped from the LiveCD. There are two media available
to bootstrap the PIT node--the RemoteISO or a bootable USB device. This procedure describes using the USB
device. If not using the USB device, see [Bootstrap Pit Node from LiveCD Remote ISO](bootstrap_livecd_remote_iso.md).

There are 5 overall steps that provide a bootable USB with SSH enabled, capable of installing Shasta v1.5 (or higher).

### Topics
   1. [Download and Expand the CSM Release](#download-and-expand-the-csm-release)
   1. [Create the Bootable Media](#create-the-bootable-media)
   1. [Configuration Payload](#configuration-payload)
      1. [Before Configuration Payload Workarounds](#before-configuration-payload-workarounds)
      1. [Generate Installation Files](#generate-installation-files)
      1. [CSI Workarounds](#csi-workarounds)
      1. [Prepare Site Init](#prepare_site_init)
   1. [Prepopulate LiveCD Daemons Configuration and NCN Artifacts](#prepopulate-livecd-daemons-configuration-and-ncn-artifacts)
   1. [Boot the LiveCD](#boot-the-livecd)
      1. [First Login](#first-login)
   1. [Next Topic](#next-topic)

## Details

<a name="download-and-expand-the-csm-release"></a>
### 1. Download and Expand the CSM Release

Fetch the base installation CSM tarball and extract it, installing the contained CSI tool.

1. Set up the Typescript directory as well as the initial typescript. This directory will be returned to for every typescript in the entire CSM installation.

   ```bash
   linux# cd ~
   linux# script -af csm-install-usb.$(date +%Y-%m-%d).txt
   linux# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. The CSM software release should be downloaded and expanded for use.

   **Important:** To ensure that the CSM release plus any patches, workarounds, or hotfixes are included
   follow the instructions in [Update CSM Product Stream](../update_product_stream/index.md)

   **Important:** Download to a location that has sufficient space for both the tarball and the expanded tarball.

   The rest of this procedure will use the CSM_RELEASE variable and expect to have the
   contents of the CSM software release tarball plus any patches, workarounds, or hotfixes.

   ```bash
   linux# CSM_RELEASE=csm-x.y.z
   linux# echo $CSM_RELEASE
   linux# tar -zxvf ${CSM_RELEASE}.tar.gz
   linux# ls -l ${CSM_RELEASE}
   linux# CSM_PATH=$(pwd)/${CSM_RELEASE}
   ```

   The ISO and other files are now available in the directory from the extracted CSM tar.

1. Install/upgrade the CSI RPM

   ```bash
   linux# rpm -Uvh --force $(find ${CSM_PATH}/rpm/cray/csm/ -name "cray-site-init-*.x86_64.rpm" | sort -V | tail -1)
   ```

1. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have direct internet
   access these RPMs will need to be externally downloaded and then copied to this machine.

   **Important:** To ensure that the latest workarounds and documentation updates are available,
   see [Check for Latest Workarounds and Documentation Updates](../update_product_stream/index.md#workarounds)

1. Show the version of CSI installed.

   ```bash
   linux# csi version
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

1. Configure zypper with the `embedded` repository from the CSM release.

   ```bash
   linux# zypper ar -fG "${CSM_PATH}/rpm/embedded" "${CSM_RELEASE}-embedded"
   ```

1. Install podman or docker to support container tools required to generated
   sealed secrets.

   Podman RPMs are included in the `embedded` repository in the CSM release and
   may be installed in your pre-LiveCD environment using `zypper` as follows:

   * Install `podman` and `podman-cni-config` packages:

     ```bash
     linux# zypper in --repo ${CSM_RELEASE}-embedded -y podman podman-cni-config
     ```

   Or you may use `rpm -Uvh` to install RPMs (and their dependencies) manually
   from the `${CSM_PATH}/rpm/embedded` directory.
   ```bash
   linux# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Containers/15-SP2/x86_64/update/x86_64/podman-*.x86_64.rpm
   linux# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Containers/15-SP2/x86_64/update/noarch/podman-cni-config-*.noarch.rpm
   ```

1. Install lsscsi to view attached storage devices.

   lsscsi RPMs are included in the `embedded` repository in the CSM release and
   may be installed in your pre-LiveCD environment using `zypper` as follows:

   * Install `lsscsi` package:

     ```bash
     linux# zypper in --repo ${CSM_RELEASE}-embedded -y lsscsi
     ```

   Or you may use `rpm -Uvh` to install RPMs (and their dependencies) manually
   from the `${CSM_PATH}/rpm/embedded` directory.
   ```bash
   linux# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Basesystem/15-SP2/x86_64/product/x86_64/lsscsi-*.x86_64.rpm
   ```


1. Although not strictly required, the procedures for setting up the
   `site-init` directory recommend persisting `site-init` files in a Git
   repository.

   Git RPMs are included in the `embedded` repository in the CSM release and
   may be installed in your pre-LiveCD environment using `zypper` as follows:

   * Install `git` package:

     ```bash
     linux# zypper in --repo ${CSM_RELEASE}-embedded -y git
     ```

   Or you may use `rpm -Uvh` to install RPMs (and their dependencies) manually
   from the `${CSM_PATH}/rpm/embedded` directory.
   ```bash
   linux# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Basesystem/15-SP2/x86_64/update/x86_64/git-core-*.x86_64.rpm
   linux# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Development-Tools/15-SP2/x86_64/update/x86_64/git-*.x86_64.rpm
   ```

<a name="create-the-bootable-media"></a>
### 2. Create the Bootable Media

Cray Site Init will create the bootable LiveCD. Before creating the media, we need to identify
which device that is.

1. Identify the USB device.

    This example shows the USB device is /dev/sdd on the host.

    ```bash
    linux# lsscsi
    ```

    Expected output looks similar to the following:
    ```
    [6:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sda
    [7:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdb
    [8:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdc
    [14:0:0:0]   disk    SanDisk  Extreme SSD      1012  /dev/sdd
    [14:0:0:1]   enclosu SanDisk  SES Device       1012  -
    ```

    In the above example, we can see our internal disks as the `ATA` devices and our USB as the `disk` or `enclosu` device. Because the `SanDisk` fits the profile we are looking for, we are going to use `/dev/sdd` as our disk.

    Set a variable with your disk to avoid mistakes:

    ```bash
    linux# export USB=/dev/sd<disk_letter>
    ```

1. Format the USB device

    On Linux using the CSI application:

    ```bash
    linux# csi pit format $USB ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
    ```

    > Note: If the previous command fails with this error message, this indicates that this Linux computer does not have the checkmedia RPM installed. In that case, the RPM can be installed and `csi pit format` can be run again
    > ```
    > ERROR: Unable to validate ISO. Please install checkmedia
    > ```
    >
    >   1.  Install the missing rpms
    >
    >   ```bash
    >   linux# zypper in --repo ${CSM_RELEASE}-embedded -y libmediacheck5 checkmedia
    >   linux# csi pit format $USB ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
    >   ```

    On MacOS using the bash script:

    ```bash
    macos# ./cray-site-init/write-livecd.sh $USB ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
    ```

    > NOTE: At this point the USB device is usable in any server with an x86_64 architecture based CPU. The remaining steps help add the installation data and enable SSH on boot.

1. Mount the configuration and persistent data partition:

    ```bash
    linux# mkdir -pv /mnt/{cow,pitdata}
    linux# mount -vL cow /mnt/cow && mount -vL PITDATA /mnt/pitdata
    ```

1.  Copy and extract the tarball (compressed) into the USB:
    ```bash
    linux# cp -v ${CSM_PATH}.tar.gz /mnt/pitdata/
    linux# tar -zxvf ${CSM_PATH}.tar.gz -C /mnt/pitdata/
    ```

The USB device is now bootable and contains our artifacts. This may be useful for internal or quick usage. Administrators seeking a Shasta installation must continue onto the [configuration payload](#configuration-payload).
<a name="configuration-payload"></a>
### 3. Configuration Payload

The SHASTA-CFG structure and other configuration files will be prepared, then `csi` will generate system-unique configuration payload used for the rest of the CSM installation on the USB device.

* [Before Configuration Payload Workarounds](#before-configuration-payload-workarounds)
* [Generate Installation Files](#generate-installation-files)
* [CSI Workarounds](#csi-workarounds)
* [Prepare Site Init](#prepare_site_init)

<a name="before-configuration-payload-workarounds"></a>
#### 3.1 Before Configuration Payload Workarounds

Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `before-configuration-payload` breakpoint.

<a name="generate-installation-files"></a>
#### 3.2 Generate Installation Files

Some files are needed for generating the configuration payload. See these topics in [Prepare Configuration Payload](prepare_configuration_payload.md) if you have not already prepared the information for this system.

   * [Command Line Configuration Payload](prepare_configuration_payload.md#command_line_configuration_payload)
   * [Configuration Payload Files](prepare_configuration_payload.md#configuration_payload_files)

> Note: The USB device is usable at this time, but without SSH enabled as well as core services. This means the USB device could be used to boot the system now, and a user can return to this step at another time.

1. At this time see [Create HMN Connections JSON](create_hmn_connections_json.md) for instructions about creating the `hmn_connections.json`.

1. Change into the preparation directory:

   ```bash
   linux# mkdir -pv /mnt/pitdata/prep
   linux# cd /mnt/pitdata/prep
   ```

1. Pull these files into the current working directory:

   - `application_node_config.yaml` (optional - see below)
   - `cabinets.yaml` (optional - see below)
   - `hmn_connections.json`
   - `ncn_metadata.csv`
   - `switch_metadata.csv`
   - `system_config.yaml` (see below)

   > The optional `application_node_config.yaml` file may be provided for further defining of settings relating to how application nodes will appear in HSM for roles and subroles. See [Create Application Node YAML](create_application_node_config_yaml.md)

   > The optional `cabinets.yaml` file allows cabinet naming and numbering as well as some VLAN overrides. See [Create Cabinets YAML](create_cabinets_yaml.md).

   > The `system_config.yaml` is required for a reinstall, because it was created during a previous install. For a first time install, the information in it can be provided as command line arguments to `csi config init`.

   After gathering the files into this working directory, generate your configurations:

1. If doing a reinstall and the `system_config.yaml` parameter file is available, then generate the system configuration reusing this parameter file (see [avoiding parameters](../background/cray_site_init_files.md#save-file--avoiding-parameters)).

   If not doing a reinstall of Shasta software, then the `system_config.yaml` file will not be available, so skip the rest of this step.

   1. Check for the configuration files. The needed files should be in the current directory.

      ```bash
      linux# ls -1
      ```

      Expected output looks similar to the following:

      ```
      application_node_config.yaml
      cabinets.yaml
      hmn_connections.json
      ncn_metadata.csv
      switch_metadata.csv
      system_config.yaml
      ```

   1. Set an environment variable so this system name can be used in later commands.

      ```bash
      linux# export SYSTEM_NAME=eniac
      ```

   1. Generate the system configuration.

      ```bash
      linux# csi config init
      ```

      A new directory matching your `--system-name` argument will now exist in your working directory.

      These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
      * The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other management NCNs. It can be ignored.

         ```
         "Couldn't find switch port for NCN: x3000c0s1b0"
         ```

      * An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml` file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md)

         ```json
         {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
         {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
         ```

      * If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.

         ```json
         {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
         {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}

   1. Skip the next step and continue with the [CSI Workarounds](#csi-workarounds).

1. If doing a first time install or the `system_config.yaml` parameter file for a reinstall is not available, generate the system configuration.

   If doing a first time install, this step is required. If you did the previous step as part of a reinstall, skip this.

   1. Check for the configuration files. The needed files should be in the current directory.

      ```bash
      linux# ls -1
      ```

      Expected output looks similar to the following:

      ```
      application_node_config.yaml
      cabinets.yaml
      hmn_connections.json
      ncn_metadata.csv
      switch_metadata.csv
      ```

   1. Set an environment variable so this system name can be used in later commands.

      ```bash
      linux# export SYSTEM_NAME=eniac
      ```

   1. Generate the system configuration. See below for an explanation of the command line parameters and some common settings.

      ```bash
      linux# csi config init \
          --bootstrap-ncn-bmc-user root \
          --bootstrap-ncn-bmc-pass changeme \
          --system-name ${SYSTEM_NAME} \
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
          --nmn-mtn-cidr 10.100.0.0/17 \
          --bgp-peers aggregation
      ```

      A new directory matching your `--system-name` argument will now exist in your working directory.

      > After generating a configuration, a visual audit of the generated files for network data should be performed.

      Run the command `csi config init --help` to get more information about the parameters mentioned in the example command above and others which are available.

      Notes about parameters to `csi config init`:
      * The `application_node_config.yaml` file is optional, but if you have one describing the mapping between prefixes in `hmn_connections.csv` that should be mapped to HSM subroles, you need to include a command line option to have it used. See [Create Application Node YAML](create_application_node_config_yaml.md).
      * The `bootstrap-ncn-bmc-user` and `bootstrap-ncn-bmc-pass` must match what is used for the BMC account and its password for the management NCNs.
      * Set site parameters (`site-domain`, `site-ip`, `site-gw`, `site-nic`, `site-dns`) for the information which connects `ncn-m001` (the PIT node) to the site. The `site-nic` is the interface on this node connected to the site.
      * There are other interfaces possible, but the `install-ncn-bond-members` are typically:
         * `p1p1,p10p1` for HPE nodes
         * `p1p1,p1p2` for Gigabyte nodes
         * `p801p1,p801p2` for Intel nodes
      * If you are not using a `cabinets-yaml` file, set the three cabinet parameters (`mountain-cabinets`, `hill-cabinets`, and `river-cabinets`) to the number of each cabinet which are part of this system.
      * The starting cabinet number for each type of cabinet (for example, `starting-mountain-cabinet`) has a default that can be overridden. See the `csi config init --help`
      * For systems that use non-sequential cabinet ID numbers, use `cabinets-yaml` to include the `cabinets.yaml` file. This file can include information about the starting ID for each cabinet type and number of cabinets which have separate command line options, but is a way to specify explicitly the id of every cabinet in the system. If you are using a `cabinets-yaml` file, flags specified on the `csi` command-line related to cabinets will be ignored. See [Create Cabinets YAML](create_cabinets_yaml.md).
      * An override to default cabinet IPv4 subnets can be made with the `hmn-mtn-cidr` and `nmn-mtn-cidr` parameters.
      * By default, spine switches are used as MetalLB peers. Use `--bgp-peers aggregation` to use aggregation switches instead.
      * Several parameters (`can-gateway`, `can-cidr`, `can-static-pool`, `can-dynamic-pool`) describe the CAN (Customer Access network). The `can-gateway` is the common gateway IP address used for both spine switches and commonly referred to as the Virtual IP address for the CAN. The `can-cidr` is the IP subnet for the CAN assigned to this system. The `can-static-pool` and `can-dynamic-pool` are the MetalLB address static and dynamic pools for the CAN. The `can-external-dns` is the static IP address assigned to the DNS instance running in the cluster to which requests the cluster subdomain will be forwarded. The `can-external-dns` IP address must be within the `can-static-pool` range.
      * Set `ntp-pool` to a reachable NTP server

      These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
      * The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other management NCNs. It can be ignored.

         ```
         "Couldn't find switch port for NCN: x3000c0s1b0"
         ```

      * An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml` file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md)

         ```json
         {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
         {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
         ```

      * If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.

         ```json
         {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
         {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
         ```

   1. Continue with the next step to apply the csi-config workarounds.

<a name="csi-workarounds"></a>
#### 3.3 CSI Workarounds

Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `csi-config` breakpoint.

<a name="prepare_site_init"></a>
#### 3.4 Prepare Site Init

Follow the procedures to [Prepare Site Init](prepare_site_init.md) directory for your system.

<a name="prepopulate-livecd-daemons-configuration-and-ncn-artifacts"></a>
### 4. Prepopulate LiveCD Daemons Configuration and NCN Artifacts

Now that the configuration is generated, we can populate the LiveCD with the generated files.

This will enable SSH, and other services when the LiveCD starts.

1. Set system name and enter prep directory

    ```bash
    linux# export SYSTEM_NAME=eniac
    linux# cd /mnt/pitdata/prep
    ```

1. Use CSI to populate the LiveCD, provide both the mount point and the CSI generated config dir.

    ```bash
    linux# csi pit populate cow /mnt/cow/ ${SYSTEM_NAME}/
    ```

    Expected output looks similar to the following:

    ```
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

1. Set the hostname and print it into the hostname file.
   > Do not confuse other administrators and name the LiveCD "ncn-m001", please append the "-pit" suffix
   > which will indicate that the node is booted from the LiveCD.

   ```bash
   linux# echo "${SYSTEM_NAME}-ncn-m001-pit" >/mnt/cow/rw/etc/hostname
   ```

1. Unmount the Overlay, we are done with it

    ```bash
    linux# umount -v /mnt/cow
    ```

1. Make directories needed for basecamp (cloud-init) and the squashFS images

    ```bash
    linux# mkdir -pv /mnt/pitdata/configs/ /mnt/pitdata/data/{k8s,ceph}/
    ```

1. Copy basecamp data

    ```bash
    linux# csi pit populate pitdata ${SYSTEM_NAME} /mnt/pitdata/configs -b
    ```

    Expected output looks similar to the following:

    ```
    data.json---------------------> /mnt/pitdata/configs/data.json...OK
    ```

1. Update CA Cert on the copied `data.json` file. Provide the path to the `data.json`, the path to
   our `customizations.yaml`, and finally the `sealed_secrets.key`

    ```bash
    linux# csi patch ca \
    --cloud-init-seed-file /mnt/pitdata/configs/data.json \
    --customizations-file /mnt/pitdata/prep/site-init/customizations.yaml \
    --sealed-secret-key-file /mnt/pitdata/prep/site-init/certs/sealed_secrets.key
   ```

1. Copy k8s artifacts:

    ```bash
    linux# csi pit populate pitdata "${CSM_PATH}/images/kubernetes/" /mnt/pitdata/data/k8s/ -kiK
    ```

    Expected output looks similar to the following:

    ```
    5.3.18-24.37-default-0.0.6.kernel-----------------> /mnt/pitdata/data/k8s/...OK
    initrd.img-0.0.6.xz-------------------------------> /mnt/pitdata/data/k8s/...OK
    kubernetes-0.0.6.squashfs-------------------------> /mnt/pitdata/data/k8s/...OK
    ```

1. Copy Ceph/storage artifacts:

    ```bash
    linux# csi pit populate pitdata "${CSM_PATH}/images/storage-ceph/" /mnt/pitdata/data/ceph/ -kiC
    ```

    Expected output looks similar to the following:

    ```
    5.3.18-24.37-default-0.0.5.kernel-----------------> /mnt/pitdata/data/ceph/...OK
    initrd.img-0.0.5.xz-------------------------------> /mnt/pitdata/data/ceph/...OK
    storage-ceph-0.0.5.squashfs-----------------------> /mnt/pitdata/data/ceph/...OK
    ```

1. Quit the typescript session with the `exit` command and copy the file (csm-install-usb.<date>.txt) to the data partition on the USB drive.

    ```bash
    linux# mkdir -pv /mnt/pitdata/prep/logs
    linux# exit
    linux# cp ~/csm-install-usb.*.txt /mnt/pitdata/prep/logs
    ```

1. Unmount the data partition:

    ```bash
    linux# cd; umount -v /mnt/pitdata
    ```

Now the USB device may be reattached to the management node, or if it was made on the management node then it can now
reboot into the LiveCD.

<a name="boot-the-livecd"></a>
### 5. Boot the LiveCD

Some systems will boot the USB device automatically if no other OS exists (bare-metal). Otherwise the
administrator may need to use the BIOS Boot Selection menu to choose the USB device.

If an administrator is rebooting a node into the LiveCD, versus booting a bare-metal or wiped node, then `efibootmgr` will deterministically set the boot order.

See the [set boot order](../background/ncn_boot_workflow.md#set-boot-order) page for more information on this topic..

> UEFI booting must be enabled to find the USB device's EFI bootloader.

1. Start a typescript on an external system, such as a laptop or Linux system, to record this section of activities done on the console of ncn-m001 via IPMI.

   ```bash
   external# script -a boot.livecd.$(date +%Y-%m-%d).txt
   external# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

   Confirm that the IPMI credentials work for the BMC by checking the power status.

   ```bash
   external# export SYSTEM_NAME=eniac
   external# export USERNAME=root
   external# export IPMI_PASSWORD=changeme
   external# ipmitool -I lanplus -U $USERNAME -E -H ${SYSTEM_NAME}-ncn-m001-mgmt chassis power status
   ```

   Connect to the IPMI console.

   ```bash
   external# ipmitool -I lanplus -U $USERNAME -E -H ${SYSTEM_NAME}-ncn-m001-mgmt sol activate
   ncn-m001#
   ```

1. Reboot

    ```bash
    ncn-m001# reboot
    ```

Watch the shutdown and boot from the ipmitool session to the console terminal.
The typescript can be discarded, otherwise if issues arise then it should be submitted with the bug report.

> **An integrity check** runs before Linux starts by default, it can be skipped by selecting "OK" in its prompt.

<a name="first-login"></a>
#### 5.1 First Login

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
   Welcome to the CRAY Pre-Install Toolkit (LiveOS)
   ```

   > **`NOTE`** If this password is forgotten, it can be reset by mounting the USB device on another computer. See [Reset root Password on LiveCD](reset_root_password_on_LiveCD.md) for information on clearing the password.


1. Disconnect from IPMI console.

   Once the network is up so that SSH to the node works, disconnect from the IPMI console.

   You can disconnect from the IPMI console by using the "~.", that is, the tilde character followed by a period character.

   Log in via `ssh` to the node as root.

   ```bash
   external# ssh root@${SYSTEM_NAME}-ncn-m001
   pit#
   ```

   Note: The hostname should be similar to eniac-ncn-m001-pit when booted from the LiveCD, but it will be shown as "pit#" in the command prompts from this point onward.

<a name="configure-the-running-livecd"></a>
### 6. Configure the Running LiveCD

1. Mount the data partition
    > The data partition is set to `fsopt=noauto` to facilitate LiveCDs over virtual-ISO mount. USB installations need to mount this manually.

    ```bash
    pit# mount -vL PITDATA
    ```

1. Start a typescript to record this section of activities done on ncn-m001 while booted from the LiveCD.

   ```bash
   pit# mkdir -pv /var/www/ephemeral/prep/logs
   pit# script -af /var/www/ephemeral/prep/logs/booted-csm-livecd.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and install/upgrade the workaround and documentation RPMs.

   If this machine does not have direct Internet access these RPMs will need to be externally downloaded and then copied to the system.

   **Important:** In an earlier step, the CSM release plus any patches, workarounds, or hotfixes
   were downloaded to a system using the instructions in [Check for Latest Workarounds and Documentation Updates](../update_product_stream/index.md#workarounds). Use that set of RPMs rather than downloading again.

   ```bash
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   linux# scp -p docs-csm-*rpm csm-install-workarounds-*rpm ncn-m001:/root
   linux# ssh ncn-m001
   pit# rpm -Uvh --force docs-csm-latest.noarch.rpm
   pit# rpm -Uvh --force csm-install-workarounds-latest.noarch.rpm
   ```

1. Check the pit-release version.

   ```bash
   pit# cat /etc/pit-release
   ```

   Expected output looks similar to the following:

   ```
   VERSION=1.4.9
   TIMESTAMP=20210309034439
   HASH=g1e67449
   ```

1. First login workarounds

   Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `first-livecd-login` breakpoint.

1. Start services

   ```bash
   pit# systemctl start nexus
   pit# systemctl start basecamp
   pit# systemctl start conman
   ```

1. Set shell environment variables.

   The CSM_RELEASE and CSM_PATH variables will be used later.

   ```bash
   pit# cd /var/www/ephemeral
   pit# export CSM_RELEASE=csm-x.y.z
   pit# echo $CSM_RELEASE
   pit# export CSM_PATH=$(pwd)/${CSM_RELEASE}
   pit# echo $CSM_PATH
   ```

1. Install Goss Tests and Server

   The following assumes the CSM_PATH environment variable is set to the absolute path of the unpacked CSM release.

   ```bash
   pit# rpm -Uvh --force $(find ${CSM_PATH}/rpm/cray/csm/ -name "goss-servers*.rpm" | sort -V | tail -1)
   pit# rpm -Uvh --force $(find ${CSM_PATH}/rpm/cray/csm/ -name "csm-testing*.rpm" | sort -V | tail -1)
   ```

1. Verify the system:

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

1. Follow directions in the output from the 'csi pit validate' commands for failed validations before continuing.

<a name="next-topic"></a>
# Next Topic

   After completing this procedure the next step is to configure the management network switches.

   * See [Configure Management Network Switches](index.md#configure_management_network)

