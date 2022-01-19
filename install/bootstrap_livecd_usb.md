# Bootstrap PIT Node from LiveCD USB

The Pre-Install Toolkit (PIT) node needs to be bootstrapped from the LiveCD. There are two media available
to bootstrap the PIT node--the RemoteISO or a bootable USB device. This procedure describes using the USB
device. If not using the USB device, see [Bootstrap PIT Node from LiveCD Remote ISO](bootstrap_livecd_remote_iso.md).

There are 5 overall steps that provide a bootable USB with SSH enabled, capable of installing Shasta v1.5 (or higher).

### Topics
   1. [Download and Expand the CSM Release](#download-and-expand-the-csm-release)
   1. [Create the Bootable Media](#create-the-bootable-media)
   1. [Configuration Payload](#configuration-payload)
      1. [Before Configuration Payload Workarounds](#before-configuration-payload-workarounds)
      1. [Generate Installation Files](#generate-installation-files)
         1. [Subsequent Fresh-Installs (Re-Installs)](#subsequent-fresh-installs-re-installs)
         1. [First-Time/Initial Installs (bare-metal)](#first-timeinitial-installs-bare-metal)
      1. [CSI Workarounds](#csi-workarounds)
      1. [Prepare Site Init](#prepare_site_init)
   1. [Prepopulate LiveCD Daemons Configuration and NCN Artifacts](#prepopulate-livecd-daemons-configuration-and-ncn-artifacts)
   1. [Boot the LiveCD](#boot-the-livecd)
      1. [First Login](#first-login)
   1. [Next Topic](#next-topic)

<a name="download-and-expand-the-csm-release"></a>
### 1. Download and Expand the CSM Release

Fetch the base installation CSM tarball and extract it, installing the contained CSI tool.

1. Create a working area for this procedure:

   ```bash
   linux# mkdir usb
   linux# cd usb
   ```

1. Set up the Typescript directory as well as the initial typescript. This directory will be returned to for every typescript in the entire CSM installation.

   ```bash
   linux:usb# script -af csm-install-usb.$(date +%Y-%m-%d).txt
   linux:usb# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. The CSM software release should be downloaded and expanded for use.

   **Important:** To ensure that the CSM release plus any patches, workarounds, or hotfixes are included
   follow the instructions in [Update CSM Product Stream](../update_product_stream/index.md)

   **Important:** Download to a location that has sufficient space for both the tarball and the expanded tarball.

   > Note: Expansion of the tarball may take more than 45 minutes.

   The rest of this procedure will use the CSM_RELEASE variable and expect to have the
   contents of the CSM software release tarball plus any patches, workarounds, or hotfixes.

   ```bash
   linux:usb# CSM_RELEASE=csm-x.y.z
   linux:usb# echo $CSM_RELEASE
   linux:usb# tar -zxvf ${CSM_RELEASE}.tar.gz
   linux:usb# ls -l ${CSM_RELEASE}
   linux:usb# CSM_PATH=$(pwd)/${CSM_RELEASE}
   ```

   The ISO and other files are now available in the directory from the extracted CSM tar.

1. Install/upgrade CSI; check if a newer version was included in the tar-ball.

   ```bash
   linux:usb# rpm -Uvh $(find ./${CSM_RELEASE}/rpm/cray/csm/ -name "cray-site-init-*.x86_64.rpm" | sort -V | tail -1)
   ```

1. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have direct internet
   access these RPMs will need to be externally downloaded and then copied to this machine.

   **Important:** To ensure that the latest workarounds and documentation updates are available,
   see [Check for Latest Workarounds and Documentation Updates](../update_product_stream/index.md#workarounds)

1. Show the version of CSI installed.

   ```bash
   linux:usb# csi version
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
   linux:usb# zypper ar -fG "${CSM_PATH}/rpm/embedded" "${CSM_RELEASE}-embedded"
   ```

1. Install podman or docker to support container tools required to generated
   sealed secrets.

   Podman RPMs are included in the `embedded` repository in the CSM release and
   may be installed in your pre-LiveCD environment using `zypper` as follows:

   * Install `podman` and `podman-cni-config` packages:

     ```bash
     linux:usb# zypper in --repo ${CSM_RELEASE}-embedded -y podman podman-cni-config
     ```

   Or one may use `rpm -Uvh` to install RPMs (and their dependencies) manually
   from the `${CSM_PATH}/rpm/embedded` directory.
   ```bash
   linux:usb# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Containers/15-SP2/x86_64/update/x86_64/podman-*.x86_64.rpm
   linux:usb# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Containers/15-SP2/x86_64/update/noarch/podman-cni-config-*.noarch.rpm
   ```

1. Install lsscsi to view attached storage devices.

   lsscsi RPMs are included in the `embedded` repository in the CSM release and
   may be installed in your pre-LiveCD environment using `zypper` as follows:

   * Install `lsscsi` package:

     ```bash
     linux:usb# zypper in --repo ${CSM_RELEASE}-embedded -y lsscsi
     ```

   Or one may use `rpm -Uvh` to install RPMs (and their dependencies) manually
   from the `${CSM_PATH}/rpm/embedded` directory.
   ```bash
   linux:usb# rpm -Uvh ${CSM_PATH}/rpm/embedded/suse/SLE-Module-Basesystem/15-SP2/x86_64/product/x86_64/lsscsi-*.x86_64.rpm
   ```


1. Although not strictly required, the procedures for setting up the
   `site-init` directory recommend persisting `site-init` files in a Git
   repository.

   Follow the procedure in [Prepare Site Init](prepare_site_init.md) to set up the site-init directory for your system.


<a name="create-the-bootable-media"></a>
### 2. Create the Bootable Media

Cray Site Init will create the bootable LiveCD. Before creating the media, we need to identify
which device that is.

1. Identify the USB device.

    This example shows the USB device is /dev/sdd on the host.

    ```bash
    linux:usb# lsscsi
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
    linux:usb# export USB=/dev/sd<disk_letter>
    ```

1. Format the USB device

    On Linux using the CSI application:

    ```bash
    linux:usb# csi pit format $USB ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
    ```

    > Note: If the previous command fails with this error message, this indicates that this Linux computer does not have the checkmedia RPM installed. In that case, the RPM can be installed and `csi pit format` can be run again
    > ```
    > ERROR: Unable to validate ISO. Please install checkmedia
    > ```
    >
    >   1.  Install the missing rpms
    >
    >   ```bash
    >   linux:usb# zypper in --repo ${CSM_RELEASE}-embedded -y libmediacheck5 checkmedia
    >   linux:usb# csi pit format $USB ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
    >   ```

    On MacOS using the bash script:

    ```bash
    macos:usb# ./cray-site-init/write-livecd.sh $USB ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
    ```

    > NOTE: At this point the USB device is usable in any server with an x86_64 architecture based CPU. The remaining steps help add the installation data and enable SSH on boot.

1. Mount the configuration and persistent data partition:

    ```bash
    linux:usb# mkdir -pv /mnt/{cow,pitdata}
    linux:usb# mount -vL cow /mnt/cow && mount -vL PITDATA /mnt/pitdata
    ```

1.  Copy and extract the tarball (compressed) into the USB:
    ```bash
    linux:usb# cp -v ${CSM_PATH}.tar.gz /mnt/pitdata/
    linux:usb# tar -zxvf ${CSM_PATH}.tar.gz -C /mnt/pitdata/
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

Some files are needed for generating the configuration payload. See these topics in [Prepare Configuration Payload](prepare_configuration_payload.md) if one has not already prepared the information for this system.

   * [Command Line Configuration Payload](prepare_configuration_payload.md#command_line_configuration_payload)
   * [Configuration Payload Files](prepare_configuration_payload.md#configuration_payload_files)

> **`NOTE`**: The USB device is usable at this time, but without SSH enabled as well as core services. This means the USB device could be used to boot the system now, and a user can return to this step at another time.

1. At this time see [Create HMN Connections JSON](create_hmn_connections_json.md) for instructions about creating the `hmn_connections.json`.

1. Change into the preparation directory plus necessary PIT directories (for later):

   ```bash
   linux:usb# mkdir -pv /mnt/pitdata/admin /mnt/pitdata/prep /mnt/pitdata/configs /mnt/pitdata/data
   linux:usb# cd /mnt/pitdata/prep
   ```

1. Pull these files into the current working directory, or create them if this is a first-time/initial install:

   - `application_node_config.yaml` (optional - see below)
   - `cabinets.yaml` (optional - see below)
   - `hmn_connections.json`
   - `ncn_metadata.csv`
   - `switch_metadata.csv`
   - `system_config.yaml` (only available after [first-install generation of system files](#first-timeinitial-installs-bare-metal)

   > The optional `application_node_config.yaml` file may be provided for further defining of settings relating to how application nodes will appear in HSM for roles and subroles. See [Create Application Node YAML](create_application_node_config_yaml.md)

   > The optional `cabinets.yaml` file allows cabinet naming and numbering as well as some VLAN overrides. See [Create Cabinets YAML](create_cabinets_yaml.md).

   > The `system_config.yaml` is required for a re-install, because it was created during a previous session of configuration generation. For a first time install, the information in it must be provided as command line arguments to `csi config init`.

   After gathering the files into this working directory, move on to [Subsequent Fresh-Installs (Re-Installs)](#subsequent-fresh-installs-re-installs).

<a name="subsequent-fresh-installs-re-installs"></a>
##### 3.2.a Subsequent Fresh-Installs (Re-Installs)

1. **For subsequent fresh-installs (re-installs) where the `system_config.yaml` parameter file is available**, generate the updated system configuration (see [avoiding parameters](../background/cray_site_init_files.md#save-file--avoiding-parameters)).

   > **`SKIP STEP IF`** if the `system_config.yaml` file is unavailable please skip this step and move onto the next one in order to generate the first configuration payload..
   
   1. Check for the configuration files. The needed files should be in the current directory.

      ```bash
      linux:/mnt/pitdata/prep# ls -1
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
      linux:/mnt/pitdata/prep# export SYSTEM_NAME=eniac
      ```

   1. Generate the system configuration

   > **`NOTE`** if it is desirable to expedite booting into the USB, this step may be skipped. Instead, after logging into the PIT for [#first time](#51-first-login) and running `pit-init` the USB will gain connectivity and SSH. As long as the required files are present then one may continue to the first time boot.

      ```bash
      linux:/mnt/pitdata/prep# csi config init
      
      # Verify the newly generated configuration payload's `system_config.yaml` matches the current version of CSI.
      # NOTE: Keep this new system_config.yaml somewhere safe to facilitate re-installs.
      linux:/mnt/pitdata/prep# cat ${SYSTEM_NAME}/system_config.yaml
      linux:/mnt/pitdata/prep# csi version
      ```

      A new directory matching your `--system-name` argument will now exist in your working directory.

      > **`NOTE`** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
      > 
      > 1. The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other management NCNs. It can be ignored.
      >   ```bash
      >   "Couldn't find switch port for NCN: x3000c0s1b0"
      >   ```
      >
      > 1. An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml` file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md)
      >
      >   ```json
      >   {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
      >   {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
      >   ```
      >
      > 1. If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.
      >
      >   ```json
      >   {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
      >   {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
      >   ```

   1. Skip the next step and continue with the [CSI Workarounds](#csi-workarounds).

<a name="first-timeinitial-installs-bare-metal"></a>
##### 3.2.b First-Time/Initial Installs (bare-metal)

1. **For first-time/initial installs (without a `system_config.yaml`file)**, generate the system configuration. See below for an explanation of the command line parameters and some common settings.

   1. Check for the configuration files. The needed files should be in the current directory.
   
     > **`NOTE`** if it is desirable to expedite booting into the USB, this step may be skipped. Instead, after logging into the PIT for [#first time](#51-first-login) and running `pit-init` the USB will gain connectivity and SSH. As long as the required files are present then one may continue to the first time boot.

      ```bash
      linux:/mnt/pitdata/prep# ls -1
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
      linux:/mnt/pitdata/prep# export SYSTEM_NAME=eniac
      ```

   1. Generate the system config:
      > **`NOTE`** the provided command below is an **example only**, run `csi config init --help` to print a full list of parameters that must be set. These will vary sifnificatnly depending on ones system and site configuration.
      
      ```bash
      linux:/mnt/pitdata/prep# csi config init \
          --bootstrap-ncn-bmc-user root \
          --bootstrap-ncn-bmc-pass ${IPMI_PASSWORD} \
          --system-name ${SYSTEM_NAME} \
          --can-cidr 10.103.11.0/24 \
          --cmn-cidr 10.103.11.0/24 \
          --can-external-dns 10.103.11.113 \
          --can-gateway 10.103.11.1 \
          --cmn-gateway 10.103.11.1 \
          --can-static-pool 10.103.11.112/28 \
          --can-dynamic-pool 10.103.11.128/25 \
          --nmn-cidr 10.252.0.0/17 \
          --hmn-cidr 10.254.0.0/17 \
          --ntp-pools time.nist.gov \
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
            
      # Verify the newly generated configuration payload's `system_config.yaml` matches the current version of CSI.
      # NOTE: Keep this new system_config.yaml somewhere safe to facilitate re-installs.
      linux:/mnt/pitdata/prep# cat ${SYSTEM_NAME}/system_config.yaml
      linux:/mnt/pitdata/prep# csi version
      ```

      A new directory matching your `--system-name` argument will now exist in your working directory.

      > **`IMPORTANT`** After generating a configuration, a visual audit of the generated files for network data should be performed.
   
      > **`SPECIAL NOTES`** Certain parameters to `csi config init` may be hard to grasp on first-time configuration generations:
      > 
      > 1. The `application_node_config.yaml` file is optional, but if one has one describing the mapping between prefixes in `hmn_connections.csv` that should be mapped to HSM subroles, one needs to include a command line option to have it used. See [Create Application Node YAML](create_application_node_config_yaml.md).
      > 1. The `bootstrap-ncn-bmc-user` and `bootstrap-ncn-bmc-pass` must match what is used for the BMC account and its password for the management NCNs.
      > 1. Set site parameters (`site-domain`, `site-ip`, `site-gw`, `site-nic`, `site-dns`) for the information which connects `ncn-m001` (the PIT node) to the site. The `site-nic` is the interface on this node connected to the site.
      > 1. There are other interfaces possible, but the `install-ncn-bond-members` are typically:
      >    * `p1p1,p10p1` for HPE nodes
      >    * `p1p1,p1p2` for Gigabyte nodes
      >    * `p801p1,p801p2` for Intel nodes
      > 1. If one are not using a `cabinets-yaml` file, set the three cabinet parameters (`mountain-cabinets`, `hill-cabinets`, and `river-cabinets`) to the number of each cabinet which are part of this system.
      > 1. The starting cabinet number for each type of cabinet (for example, `starting-mountain-cabinet`) has a default that can be overridden. See the `csi config init --help`
      > 1. For systems that use non-sequential cabinet ID numbers, use `cabinets-yaml` to include the `cabinets.yaml` file. This file can include information about the starting ID for each cabinet type and number of cabinets which have separate command line options, but is a way to specify explicitly the id of every cabinet in the system. If one are using a `cabinets-yaml` file, flags specified on the `csi` command-line related to cabinets will be ignored. See [Create Cabinets YAML](create_cabinets_yaml.md).
      > 1. An override to default cabinet IPv4 subnets can be made with the `hmn-mtn-cidr` and `nmn-mtn-cidr` parameters.
      > 1. By default, spine switches are used as MetalLB peers. Use `--bgp-peers aggregation` to use aggregation switches instead.
      
      > **`SPECIAL/IGNORABLE WARNINGS`** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored:
      > 
      > 1. The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other management NCNs. It can be ignored.
      >
      >    ```
      >    "Couldn't find switch port for NCN: x3000c0s1b0"
      >    ```
      >
      > 1. An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml` file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md).
      >
      >    ```json
      >    {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
      >    {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
      >    ```
      >
      > 1. If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.
      >
      >    ```json
      >    {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
      >    {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
      >    ```

   1. Continue with the next step to apply the [csi-config workarounds](#33-csi-workarounds).
      
<a name="csi-workarounds"></a>
#### 3.3 CSI Workarounds

Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `csi-config` breakpoint.

<a name="prepare_site_init"></a>
#### 3.4 Prepare Site Init

> **`NOTE`**: It is assumed at this point that `/mnt/pitdata` is still mounted on the linux system, this is important as the following procedure depends on that mount existing.  

Follow the procedures to [Prepare Site Init](prepare_site_init.md) directory for your system.

<a name="prepopulate-livecd-daemons-configuration-and-ncn-artifacts"></a>
### 4. Prepopulate LiveCD Daemons Configuration and NCN Artifacts

Now that the configuration is generated, we can populate the LiveCD with the generated files.

This will enable SSH, and other services when the LiveCD starts.

1. Set system name and enter prep directory if one has not already (one should already be here from the previous section).

    ```bash
    linux# export SYSTEM_NAME=eniac
    linux# cd /mnt/pitdata/prep
    ```

1. Use CSI to populate the LiveCD with networking files so SSH will work on the first boot. 

   > **`NOTE`** ll other files will be copied in by "PIT init" in a later step, after booting into the USB stick).

    ```bash
    linux:/mnt/pitdata/prep# csi pit populate cow /mnt/cow/ ${SYSTEM_NAME}/
    ```

    Expected output looks similar to the following:

    ```
    config------------------------> /mnt/cow/rw/etc/sysconfig/network/config...OK
    ifcfg-bond0-------------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-bond0...OK
    ifcfg-lan0--------------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-lan0...OK
    ifcfg-bond0.nmn0--------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-bond0.nmn0...OK
    ifcfg-bond0.hmn0--------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-bond0.hmn0...OK
    ifcfg-bond0.can0--------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-bond0.can0...OK
    ifcfg-bond0.cmn0--------------> /mnt/cow/rw/etc/sysconfig/network/ifcfg-bond0.cmn0...OK
    ifroute-lan0------------------> /mnt/cow/rw/etc/sysconfig/network/ifroute-lan0...OK
    ifroute-bond0.nmn0------------> /mnt/cow/rw/etc/sysconfig/network/ifroute-bond0.nmn0...OK
    CAN.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/CAN.conf...OK
    CMN.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/CMN.conf...OK
    HMN.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/HMN.conf...OK
    NMN.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/NMN.conf...OK
    MTL.conf----------------------> /mnt/cow/rw/etc/dnsmasq.d/MTL.conf...OK
    statics.conf------------------> /mnt/cow/rw/etc/dnsmasq.d/statics.conf...OK
    conman.conf-------------------> /mnt/cow/rw/etc/conman.conf...OK
    ```

1. Set the hostname and print it into the hostname file.

   > **`NOTE`** Do not confuse other administrators and name the LiveCD "ncn-m001". Please append the "-pit" suffix,
   > that will indicate that the node is booted from the LiveCD.

   ```bash
   linux:/mnt/pitdata/prep# echo "${SYSTEM_NAME}-ncn-m001-pit" >/mnt/cow/rw/etc/hostname
   ```

1. Unmount the Overlay, we are done with it

    ```bash
    linux:/mnt/pitdata/prep# umount -v /mnt/cow
    ```

1. Copy the NCN artifacts:

   1. Copy k8s artifacts:

       ```bash
       linux:/mnt/pitdata/prep# csi pit populate pitdata "${CSM_PATH}/images/kubernetes/" /mnt/pitdata/data/k8s/ -kiK
       ```

       Expected output looks similar to the following:

       ```
       5.3.18-24.37-default-0.0.6.kernel-----------------> /mnt/pitdata/data/k8s/...OK
       initrd.img-0.0.6.xz-------------------------------> /mnt/pitdata/data/k8s/...OK
       kubernetes-0.0.6.squashfs-------------------------> /mnt/pitdata/data/k8s/...OK
       ```

   1. Copy Ceph/storage artifacts:

       ```bash
       linux:/mnt/pitdata/prep# csi pit populate pitdata "${CSM_PATH}/images/storage-ceph/" /mnt/pitdata/data/ceph/ -kiC
       ```

       Expected output looks similar to the following:

       ```
       5.3.18-24.37-default-0.0.5.kernel-----------------> /mnt/pitdata/data/ceph/...OK
       initrd.img-0.0.5.xz-------------------------------> /mnt/pitdata/data/ceph/...OK
       storage-ceph-0.0.5.squashfs-----------------------> /mnt/pitdata/data/ceph/...OK
       ```

1. Quit the typescript session with the `exit` command and copy the file (csm-install-usb.<date>.txt) to the data partition on the USB drive.

    ```bash
    linux:/mnt/pitdata/prep# exit
    linux:/mnt/pitdata/prep# cp ~/csm-install-usb.*.txt /mnt/pitdata/prep/admin
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

If an administrator has the node booted with an operating system which will next be rebooting into the LiveCD, then use `efibootmgr` to set the boot order to be the USB device. See the [set boot order](../background/ncn_boot_workflow.md#set-boot-order) page for more information about how to set the boot order to have the USB device first.

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

   > **`NOTE`** If this password ever becomes lost or forgotten, one may reset it by mounting the USB device on another computer. See [Reset root Password on LiveCD](reset_root_password_on_LiveCD.md) for information on clearing the password.


1. Disconnect from IPMI console.

   Once the network is up so that SSH to the node works, disconnect from the IPMI console.

   You can disconnect from the IPMI console by using the "~.", that is, the tilde character followed by a period character.

   Log in via `ssh` to the node as root and run `metalid.sh` to print the PIT's ID tag (this is used for referring to ones running PIT in any triage request).

   ```bash
   external# ssh root@${SYSTEM_NAME}-ncn-m001
   pit# /root/bin/metalid.sh
   = PIT Identification = COPY/CUT START =======================================
   VERSION=1.5.7
   TIMESTAMP=20211028194247
   HASH=ge4aceb1
   CRAY-Site-Init build signature...
   Build Commit   : a6c8dddf9df1a9fc7f8c4f17cb26568a8b41d433-main
   Build Time     : 2021-12-01T16:16:41Z
   Go Version     : go1.16.10
   Git Version    : a6c8dddf9df1a9fc7f8c4f17cb26568a8b41d433
   Platform       : linux/amd64
   App. Version   : 1.12.2
   metal-net-scripts-0.0.2-1.noarch
   metal-basecamp-1.1.9-1.x86_64
   metal-ipxe-2.0.10-1.noarch
   pit-init-1.2.12-1.noarch
   = PIT Identification = COPY/CUT END =========================================
   ```

   Note: The hostname should be similar to eniac-ncn-m001-pit when booted from the LiveCD, but it will be shown as "pit#" in the command prompts from this point onward until the PIT server is setup.

<a name="configure-the-running-livecd"></a>
### 6. Configure the Running LiveCD

1. Start a typescript to record this section of activities done on ncn-m001 while booted from the LiveCD.

   ```bash
   pit# mkdir -pv /var/www/ephemeral/prep/admin
   pit# script -af /var/www/ephemeral/prep/admin/booted-csm-livecd.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Set the same variables from the `csi config init` step from earlier, and then invoke "PIT init" to setup the PIT server for deploying NCNs.
    > The data partition is set to `fsopt=noauto` to facilitate LiveCDs over virtual-ISO mount. USB installations need to mount this manually.
   > **`NOTE`** `pit-init` will re-run `csi config init`, copy all generated files into place, apply the CA patch, and finally restart daemons. This will also re-print the `metalid.sh` content incase it was skipped in the previous step. **Re-installs** can skip running `csi config init` entirely and simply run `pit-init.sh` after gathering CSI input files into `/var/www/ephemeral/prep`.
   
    ```bash
    pit# export SYSTEM_NAME=eniac
    pit# export USERNAME=root
    pit# export IPMI_PASSWORD=changeme
    pit# /root/bin/pit-init.sh
    ```

1. Start and configure NTP on the LiveCD for a fallback/recovery server.

   ```bash
   pit# /root/bin/configure-ntp.sh
   ```

1. Set shell environment variables.

   The CSM_RELEASE and CSM_PATH variables will be used later.

   ```bash
   pit# cd /var/www/ephemeral
   pit:/var/www/ephemeral# export CSM_RELEASE=csm-x.y.z
   pit:/var/www/ephemeral# echo $CSM_RELEASE
   pit:/var/www/ephemeral# export CSM_PATH=$(pwd)/${CSM_RELEASE}
   pit:/var/www/ephemeral# echo $CSM_PATH
   ```

1. Install Goss Tests and Server

   The following assumes the CSM_PATH environment variable is set to the absolute path of the unpacked CSM release.

   ```bash
   pit:/var/www/ephemeral# rpm -Uvh --force $(find ${CSM_PATH}/rpm/cray/csm/ -name "goss-servers*.rpm" | sort -V | tail -1)
   pit:/var/www/ephemeral# rpm -Uvh --force $(find ${CSM_PATH}/rpm/cray/csm/ -name "csm-testing*.rpm" | sort -V | tail -1)   
   pit:/var/www/ephemeral# cd
   ```

1. Verify the system:

   ```bash
   pit# csi pit validate --network
   pit# csi pit validate --services
   ```

1. Follow directions in the output from the 'csi pit validate' commands for failed validations before continuing.

<a name="next-topic"></a>
# Next Topic

After completing this procedure the next step is to configure the management network switches.

* See [Configure Management Network Switches](index.md#configure_management_network)

