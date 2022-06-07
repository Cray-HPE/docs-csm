# Bootstrap PIT Node from LiveCD USB

The Pre-Install Toolkit (PIT) node needs to be bootstrapped from the LiveCD. There are two media available
to bootstrap the PIT node: the RemoteISO or a bootable USB device. This procedure describes using the USB
device. If not using the USB device, see [Bootstrap PIT Node from LiveCD Remote ISO](bootstrap_livecd_remote_iso.md).

These steps provide a bootable USB with SSH enabled, capable of installing this CSM release.

## Topics

1. [Download and expand the CSM release](#download-and-expand-the-csm-release)
1. [Create the bootable media](#create-the-bootable-media)
1. [Configuration payload](#configuration-payload)
   1. [Generate installation files](#generate-installation-files)
      * [Subsequent installs (reinstalls)](#subsequent-fresh-installs-re-installs)
      * [Initial installs (bare-metal)](#first-timeinitial-installs-bare-metal)
   1. [Verify and backup `system_config.yaml`](#verify-csi-versions-match)
   1. [Prepare `Site Init`](#prepare-site-init)
1. [Prepopulate LiveCD daemons configuration and NCN artifacts](#prepopulate-livecd-daemons-configuration-and-ncn-artifacts)
1. [Boot the LiveCD](#boot-the-livecd)
   1. [First login](#first-login)
1. [Configure the running LiveCD](#configure-the-running-livecd)
1. [Next topic](#next-topic)

<a name="download-and-expand-the-csm-release"></a>

## 1. Download and expand the CSM release

Fetch the base installation CSM tarball, extract it, and install the contained CSI tool.

1. Create a working area for this procedure:

   ```bash
   linux# mkdir usb
   linux# cd usb
   ```

1. Set up the initial typescript.

   ```bash
   linux# SCRIPT_FILE=$(pwd)/csm-install-usb.$(date +%Y-%m-%d).txt
   linux# script -af ${SCRIPT_FILE}
   linux# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Set and export helper variables.

   > **Important:** All CSM install procedures for preparing the PIT node assume that these variables are set
   > and exported.

   ```bash
   pit# export CSM_RELEASE=csm-x.y.z
   pit# export SYSTEM_NAME=eniac
   pit# export PITDATA=/mnt/pitdata
   ```

1. Download and expand the CSM software release.

   **Important:** Ensure that you have the CSM release plus any patches or hotfixes by
   following the instructions in [Update CSM Product Stream](../update_product_stream/index.md)

   **Important:** Download to a location that has sufficient space for both the tarball and the expanded tarball.

   > **Important:** All CSM install procedures for preparing the PIT node assume that the `CSM_PATH` variable
   > has been set and exported.
   >
   > **Note:** Expansion of the tarball may take more than 45 minutes.

   ```bash
   linux# tar -zxvf ${CSM_RELEASE}.tar.gz
   linux# ls -l ${CSM_RELEASE}
   linux# export CSM_PATH=$(pwd)/${CSM_RELEASE}
   ```

   The ISO and other files are now available in the directory from the extracted CSM tarball.

1. <a name="install-csi-rpm"></a>Install the latest version of CSI tool.

   ```bash
   linux# rpm -Uvh --force $(find ${CSM_PATH}/rpm/cray/csm/ -name "cray-site-init-*.x86_64.rpm" | sort -V | tail -1)
   ```

1. Install the latest documentation RPM.

   See [Check for Latest Documentation](../update_product_stream/index.md#documentation)

1. Show the version of CSI installed.

   ```bash
   linux# csi version
   ```

   Expected output looks similar to the following:

   ```text
   CRAY-Site-Init build signature...
   Build Commit   : b3ed3046a460d804eb545d21a362b3a5c7d517a3-release-shasta-1.4
   Build Time     : 2021-02-04T21:05:32Z
   Go Version     : go1.14.9
   Git Version    : b3ed3046a460d804eb545d21a362b3a5c7d517a3
   Platform       : linux/amd64
   App. Version   : 1.5.18
   ```

1. Configure `zypper` with the `embedded` repository from the CSM release.

   ```bash
   linux# zypper ar -fG "${CSM_PATH}/rpm/embedded" "${CSM_RELEASE}-embedded"
   ```

1. Install Podman or Docker to support container tools required to generate
   sealed secrets.

   Podman RPMs are included in the `embedded` repository in the CSM release and
   may be installed in your pre-LiveCD environment using `zypper` as follows:

   * Install `podman` and `podman-cni-config` packages:

      ```bash
      linux# zypper in --repo ${CSM_RELEASE}-embedded -y podman podman-cni-config
      ```

   * Alternatively, one may use `rpm -Uvh` to install RPMs (and their dependencies) manually
     from the `${CSM_PATH}/rpm/embedded` directory.

      ```bash
      linux# rpm -Uvh $(find ${CSM_PATH}/rpm/embedded -name "podman-*.x86_64.rpm" | sort -V | tail -1) \
                      $(find ${CSM_PATH}/rpm/embedded -name "podman-cni-config-*.noarch.rpm" | sort -V | tail -1)
      ```

1. Install `lsscsi` to view attached storage devices.

   `lsscsi` RPMs are included in the `embedded` repository in the CSM release and
   may be installed in your pre-LiveCD environment using `zypper` as follows:

   * Install `lsscsi` package:

      ```bash
      linux# zypper in --repo ${CSM_RELEASE}-embedded -y lsscsi
      ```

   * Alternatively, one may use `rpm -Uvh` to install RPMs (and their dependencies) manually
     from the `${CSM_PATH}/rpm/embedded` directory.

      ```bash
      linux# rpm -Uvh $(find ${CSM_PATH}/rpm/embedded -name "lsscsi-*.x86_64.rpm" | sort -V | tail -1)
      ```

1. Remove CNI configuration from prior install

    If reinstalling the system and **using `ncn-m001` to prepare the USB image**, then remove the prior CNI configuration.

    ```bash
    ncn-m001# rm -rf /etc/cni/net.d/00-multus.conf /etc/cni/net.d/10-*.conflist /etc/cni/net.d/multus.d
    ```

    This should leave the following two files in `/etc/cni/net.d`.

    ```bash
    ncn-m001# ls /etc/cni/net.d
    87-podman-bridge.conflist  99-loopback.conf.sample
    ```

<a name="create-the-bootable-media"></a>

## 2. Create the bootable media

Before creating the the bootable LiveCD, identify which device will be used for it.

1. Identify the USB device.

    This example shows the USB device is `/dev/sdd` on the host.

    ```bash
    linux# lsscsi
    ```

    Expected output looks similar to the following:

    ```text
    [6:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sda
    [7:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdb
    [8:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdc
    [14:0:0:0]   disk    SanDisk  Extreme SSD      1012  /dev/sdd
    [14:0:0:1]   enclosu SanDisk  SES Device       1012  -
    ```

    In the above example, internal disks are the `ATA` devices and USB drives are final two devices.

    Set a variable with your disk to avoid mistakes:

    ```bash
    linux# USB=/dev/sd<disk_letter>
    ```

2. Format the USB device.

    * On Linux, use the CSI application to do this:

        ```bash
        linux# csi pit format ${USB} ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
        ```

        > **Note:** If the previous command fails with the following error message, it indicates that this Linux computer does not have the `checkmedia` RPM installed.
        > In that case, install the RPM and run `csi pit format` again.
        >
        > ```text
        > ERROR: Unable to validate ISO. Please install checkmedia
        > ```
        >
        > 1. Install the missing RPMs
        >
        > ```bash
        > linux# zypper in --repo ${CSM_RELEASE}-embedded -y libmediacheck5 checkmedia
        > linux# csi pit format ${USB} ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
        > ```

    * On MacOS, use the `write-livecd.sh` script to do this.

        This script is contained in the CSI tool RPM. See [install latest version of the CSI tool](#install-csi-rpm) step.

        ```bash
        macos# write-livecd.sh ${USB} ${CSM_PATH}/cray-pre-install-toolkit-*.iso 50000
        ```

    > **Note:** At this point, the USB device is usable in any server with a CPU with x86_64 architecture. The remaining steps help add the installation data and enable SSH on boot.

3. Mount the configuration and persistent data partitions.

    ```bash
    linux# mkdir -pv /mnt/cow ${PITDATA} &&
           mount -vL cow /mnt/cow &&
           mount -vL PITDATA ${PITDATA} &&
           mkdir -pv ${PITDATA}/configs ${PITDATA}/prep/{admin,logs} ${PITDATA}/data/{ceph,k8s}
    ```

4. Copy and extract the tarball into the USB.

    ```bash
    linux# cp -v ${CSM_PATH}.tar.gz ${PITDATA} &&
           tar -zxvf ${CSM_PATH}.tar.gz -C ${PITDATA}/
    ```

The USB device is now bootable and contains the CSM artifacts. This may be useful for internal or quick usage. Administrators seeking a Shasta installation must continue
on to the [configuration payload](#configuration-payload).

<a name="configuration-payload"></a>

## 3. Configuration payload

The `SHASTA-CFG` structure and other configuration files will be prepared, then `csi` will generate a system-unique configuration payload.
This payload will be used for the rest of the CSM installation on the USB device.

1. [Generate Installation Files](#generate-installation-files)
1. [Verify and Backup `system_config.yaml`](#verify-csi-versions-match)
1. [Prepare `Site Init`](#prepare-site-init)

<a name="generate-installation-files"></a>

### 3.1 Generate installation files

Some files are needed for generating the configuration payload. See these topics in [Prepare Configuration Payload](prepare_configuration_payload.md) if the
information for this system has not yet been prepared.

* [Command line configuration payload](prepare_configuration_payload.md#command_line_configuration_payload)
* [Configuration payload files](prepare_configuration_payload.md#configuration_payload_files)

> **Note:**: The USB device is usable at this time, but without SSH enabled as well as core services. This means the USB device could be used to boot the system now, and
> this step can be returned to at another time.

1. At this time see [Create HMN Connections JSON](create_hmn_connections_json.md) for instructions about creating the `hmn_connections.json`.

1. Create the configuration input files if needed and copy them into the preparation directory.

   The preparation directory is `${PITDATA}/prep`.

   Copy these files into the preparation directory, or create them if this is an initial install of the system:

   * `application_node_config.yaml` (optional - see below)
   * `cabinets.yaml` (optional - see below)
   * `hmn_connections.json`
   * `ncn_metadata.csv`
   * `switch_metadata.csv`
   * `system_config.yaml` (only available after [first-install generation of system files](#first-timeinitial-installs-bare-metal))

   > The optional `application_node_config.yaml` file may be provided for further definition of settings relating to how application nodes will appear in HSM for roles and subroles.
   > See [Create Application Node YAML](create_application_node_config_yaml.md)
   >
   > The optional `cabinets.yaml` file allows cabinet naming and numbering as well as some VLAN overrides. See [Create Cabinets YAML](create_cabinets_yaml.md).
   >
   > The `system_config.yaml` file is generated by the `csi` tool during the first install of a system, and can later be used for reinstalls of the system. For the initial install,
   > the information in it must be provided as command line arguments to `csi config init`.

1. Proceed to the appropriate next step.

   * If this is the initial install of the system, then proceed to [Initial Installs (bare-metal)](#first-timeinitial-installs-bare-metal).
   * If this is a reinstall of the system, then proceed to [Subsequent Installs (Re-Installs)](#subsequent-fresh-installs-re-installs).

<a name="subsequent-fresh-installs-re-installs"></a>

#### 3.1.a Subsequent installs (reinstalls)

1. **For subsequent fresh-installs (re-installs) where the `system_config.yaml` parameter file is available**, generate the updated system configuration
   (see [Cray `Site Init` Files](../background/index.md#cray_site_init_files)).

   > **Warning:** If the `system_config.yaml` file is unavailable, then skip this step and proceed to [Initial Installs (bare-metal)](#first-timeinitial-installs-bare-metal).

   1. Check for the configuration files. The needed files should be in the preparation directory.

      ```bash
      linux# ls -1 ${PITDATA}/prep
      ```

      Expected output looks similar to the following:

      ```text
      application_node_config.yaml
      cabinets.yaml
      hmn_connections.json
      ncn_metadata.csv
      switch_metadata.csv
      system_config.yaml
      ```

   1. Generate the system configuration.

      > **Note:** Ensure that you specify a reachable NTP pool or server using the `ntp-pools` or `ntp-servers` fields, respectively. Adding an unreachable server can
      > cause clock skew as `chrony` tries to continually reach out to a server it can never reach.

      ```bash
      linux# cd ${PITDATA}/prep && csi config init
      ```

      A new directory matching the `system-name` field in `system_config.yaml` will now exist in the working directory.

      > **Note:** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
      >
      > * The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other
      >   management NCNs. It can be ignored.
      >
      >    ```text
      >    "Couldn't find switch port for NCN: x3000c0s1b0"
      >    ```
      >
      > * An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml`
      >   file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md).
      >
      >    ```json
      >    {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
      >    {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
      >    ```
      >
      > * If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.
      >
      >    ```json
      >    {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
      >    {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
      >    ```

   1. Skip the next step and continue to [verify and backup `system_config.yaml`](#verify-csi-versions-match).

<a name="first-timeinitial-installs-bare-metal"></a>

#### 3.1.b Initial installs (bare-metal)

1. **For first-time/initial installs (without a `system_config.yaml`file)**, generate the system configuration. See below for an explanation of the command line parameters and
   some common settings.

   1. Check for the configuration files. The needed files should be in the preparation directory.

      ```bash
      linux# ls -1 ${PITDATA}/prep
      ```

      Expected output looks similar to the following:

      ```text
      application_node_config.yaml
      cabinets.yaml
      hmn_connections.json
      ncn_metadata.csv
      switch_metadata.csv
      ```

   1. Generate the system configuration.

      > **Notes:**
      >
      > * Run `csi config init --help` to print a full list of parameters that must be set. These will vary
      >   significantly depending on the system and site configuration.
      > * Ensure that you specify a reachable NTP pool or server using the `--ntp-pools` or `--ntp-servers` flags, respectively. Adding an unreachable server can
      >   cause clock skew as `chrony` tries to continually reach out to a server it can never reach.

      ```bash
      linux# cd ${PITDATA}/prep && csi config init <options>
      ```

      A new directory matching the `--system-name` argument will now exist in the working directory.

      > **Important:** After generating a configuration, a visual audit of the generated files for network data should be performed.
      >
      > **Special Notes:** Certain parameters to `csi config init` may be hard to grasp on first-time configuration generations:
      >
      > * The optional `application_node_config.yaml` file is used to map prefixes in `hmn_connections.csv` to HSM subroles. A
      >   command line option is required in order for `csi` to use the file. See [Create Application Node YAML](create_application_node_config_yaml.md).
      > * The `bootstrap-ncn-bmc-user` and `bootstrap-ncn-bmc-pass` must match what is used for the BMC account and its password for the management NCNs.
      > * Set site parameters (`site-domain`, `site-ip`, `site-gw`, `site-nic`, `site-dns`) for the network information which connects `ncn-m001` (the PIT node) to the site.
      >   The `site-nic` is the interface on `ncn-m001` that is connected to the site network.
      > * There are other interfaces possible, but the `install-ncn-bond-members` are typically:
      >   * `p1p1,p10p1` for HPE nodes
      >   * `p1p1,p1p2` for Gigabyte nodes
      >   * `p801p1,p801p2` for Intel nodes
      > * If not using a `cabinets-yaml` file, then set the three cabinet parameters (`mountain-cabinets`, `hill-cabinets`, and `river-cabinets`) to the quantity of each cabinet
      >   type included in this system.
      > * The starting cabinet number for each type of cabinet (for example, `starting-mountain-cabinet`) has a default that can be overridden. See the `csi config init --help`.
      > * For systems that use non-sequential cabinet ID numbers, use the `cabinets-yaml` argument to include the `cabinets.yaml` file. This file gives the ability to
      >   explicitly specify the ID of every cabinet in the system. When specifying a `cabinets.yaml` file with the `cabinets-yaml` argument, other command line arguments related to
      >   cabinets will be ignored by `csi`. See [Create Cabinets YAML](create_cabinets_yaml.md).
      > * An override to default cabinet IPv4 subnets can be made with the `hmn-mtn-cidr` and `nmn-mtn-cidr` parameters.
      >
      > **Note:** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
      >
      > * The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other
      >   management NCNs. It can be ignored.
      >
      >    ```text
      >    "Couldn't find switch port for NCN: x3000c0s1b0"
      >    ```
      >
      > * An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml`
      >   file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md).
      >
      >    ```json
      >    {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
      >    {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
      >    ```
      >
      > * If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.
      >
      >    ```json
      >    {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
      >    {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
      >    ```

   1. Continue to the next step to [verify and backup `system_config.yaml`](#verify-csi-versions-match).

<a name="verify-csi-versions-match"></a>

### 3.2 Verify and backup `system_config.yaml`

1. Verify that the newly generated `system_config.yaml` matches the current version of CSI.

   1. View the new `system_config.yaml` file and note the CSI version reported near the end of the file.

      ```bash
      linux# cat ${PITDATA}/prep/${SYSTEM_NAME}/system_config.yaml
      ```

   1. Note the version reported by the `csi` tool.

      ```bash
      linux# csi version
      ```

   1. The two versions should match. If they do not, determine the cause and regenerate the file.

1. Copy the new `system_config.yaml` file somewhere safe to facilitate re-installs.

1. Continue to the next step to [Prepare `Site Init`](#prepare-site-init).

<a name="prepare-site-init"></a>

### 3.3 Prepare `Site Init`

> **Note:**: It is assumed at this point that `$PITDATA` (that is, `/mnt/pitdata`) is still mounted on the Linux system. This is important because the following procedure
> depends on that mount existing.

1. Install Git if not already installed (recommended).

   Although not strictly required, the procedures for setting up the
   `site-init` directory recommend persisting `site-init` files in a Git
   repository.

1. Prepare the `site-init` directory.

   Perform the [Prepare `Site Init`](prepare_site_init.md) procedures.

<a name="prepopulate-livecd-daemons-configuration-and-ncn-artifacts"></a>

## 4. Prepopulate LiveCD daemons configuration and NCN artifacts

Now that the configuration is generated, the LiveCD must be populated with the generated files.

1. Use CSI to populate the LiveCD with networking files so SSH will work on the first boot.

   ```bash
   linux# cd ${PITDATA}/prep && csi pit populate cow /mnt/cow/ ${SYSTEM_NAME}/
   ```

   Expected output looks similar to the following:

   ```text
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

1. Set the hostname and print it into the `hostname` file.

   > **Note:** Do not confuse other administrators by naming the LiveCD `ncn-m001`. Append the `-pit` suffix,
   > indicating that the node is booted from the LiveCD.

   ```bash
   linux# echo "${SYSTEM_NAME}-ncn-m001-pit" | tee /mnt/cow/rw/etc/hostname
   ```

1. Add some helpful variables to the PIT environment.

   By adding these to the `/etc/environment` file of the PIT image, these variables will be
   automatically set and exported in shell sessions on the booted PIT node.

   > **Important:** All CSM install procedures on the booted PIT node assume that these variables
   > are set and exported.
   >
   > The `echo` prepends a newline to ensure that the variable assignment occurs on a unique line,
   > and not at the end of another line.

   ```bash
   linux# echo "
   CSM_RELEASE=${CSM_RELEASE}
   SYSTEM_NAME=${SYSTEM_NAME}" | tee -a /mnt/cow/rw/etc/environment
   ```

1. Unmount the overlay.

    ```bash
    linux# umount -v /mnt/cow
    ```

1. Copy the NCN artifacts.

   1. Copy Kubernetes node artifacts:

       ```bash
       linux# csi pit populate pitdata "${CSM_PATH}/images/kubernetes/" ${PITDATA}/data/k8s/ -kiK
       ```

       Expected output looks similar to the following:

       ```text
       5.3.18-24.37-default-0.0.6.kernel-----------------> /mnt/pitdata/data/k8s/...OK
       initrd.img-0.0.6.xz-------------------------------> /mnt/pitdata/data/k8s/...OK
       kubernetes-0.0.6.squashfs-------------------------> /mnt/pitdata/data/k8s/...OK
       ```

   1. Copy Ceph/storage node artifacts:

       ```bash
       linux# csi pit populate pitdata "${CSM_PATH}/images/storage-ceph/" ${PITDATA}/data/ceph/ -kiC
       ```

       Expected output looks similar to the following:

       ```text
       5.3.18-24.37-default-0.0.5.kernel-----------------> /mnt/pitdata/data/ceph/...OK
       initrd.img-0.0.5.xz-------------------------------> /mnt/pitdata/data/ceph/...OK
       storage-ceph-0.0.5.squashfs-----------------------> /mnt/pitdata/data/ceph/...OK
       ```

1. Quit the typescript session with the `exit` command and copy the typescript file to the data partition on the USB drive.

    ```bash
    linux# exit
    linux# cp -v ${SCRIPT_FILE} /mnt/pitdata/prep/admin
    ```

1. Unmount the data partition:

    ```bash
    linux# cd ~ && umount -v /mnt/pitdata
    ```

1. Move the USB device to the system to be installed, if needed.

   If the USB device was created somewhere other than `ncn-m001` of the system to be installed,
   move it there from its current location.

1. Proceed to the next step to boot into the LiveCD image.

<a name="boot-the-livecd"></a>

## 5. Boot the LiveCD

Some systems will boot the USB device automatically if no other OS exists (bare-metal). Otherwise the
administrator may need to use the BIOS Boot Selection menu to choose the USB device.

If an administrator has the node booted with an operating system which will next be rebooting into the LiveCD,
then use `efibootmgr` to set the boot order to be the USB device. See the
[set boot order](../background/ncn_boot_workflow.md#set-boot-order) page for more information about how to set the
boot order to have the USB device first.

> **Note:** UEFI booting must be enabled in order for the system to find the USB device's EFI bootloader.

1. Start a typescript on an external system.

   This will record this section of activities done on the console of `ncn-m001` using IPMI.

   ```bash
   external# script -a boot.livecd.$(date +%Y-%m-%d).txt
   external# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Confirm that the IPMI credentials work for the BMC by checking the power status.

   Set the `BMC` variable to the hostname or IP address of the BMC of the PIT node.

   > `read -s` is used in order to prevent the credentials from being displayed on the screen or recorded in the shell history.

   ```bash
   external# BMC=eniac-ncn-m001-mgmt
   external# read -s IPMI_PASSWORD
   external# export IPMI_PASSWORD ; ipmitool -I lanplus -U root -E -H ${BMC} chassis power status
   ```

1. Connect to the IPMI console.

   ```bash
   external# ipmitool -I lanplus -U root -E -H ${BMC} sol activate
   ```

1. Reboot `ncn-m001`.

   ```bash
   ncn-m001# reboot
   ```

1. Watch the shutdown and boot from the `ipmitool` console session.

   > **An integrity check** runs before Linux starts by default; it can be skipped by selecting `OK` in its prompt.

<a name="first-login"></a>

### 5.1 First login

On first log in (over SSH or at local console), the LiveCD will prompt the administrator to change the password.

1. **The initial password is empty**; enter the username of `root` and press `return` twice.

   ```text
   pit login: root
   ```

   Expected output looks similar to the following:

   ```text
   Password:           <-------just press Enter here for a blank password
   You are required to change your password immediately (administrator enforced)
   Changing password for root.
   Current password:   <------- press Enter here, again, for a blank password
   New password:       <------- type new password
   Retype new password:<------- retype new password
   Welcome to the CRAY Pre-Install Toolkit (LiveOS)
   ```

   > **Note:** If this password ever becomes lost or forgotten, one may reset it by mounting the USB device on another computer. See
   > [Reset root Password on LiveCD](reset_root_password_on_LiveCD.md) for information on clearing the password.

1. Disconnect from IPMI console.

   Once the network is up so that SSH to the node works, disconnect from the IPMI console.

   You can disconnect from the IPMI console by entering `~.`; That is, the tilde character followed by a period character.

1. Exit the typescript started on the external system and use `scp` to transfer it to the PIT node.

   > Set `PIT_NODE` variable to the site IP address or hostname of the PIT node.

   ```bash
   external# exit
   external# PIT_NODE=eniac-ncn-m001
   external# scp boot.livecd.*.txt root@${PIT_NODE}:/root
   ```

1. Log in to the PIT node as `root` using `ssh`.

   ```bash
   external# ssh root@${PIT_NODE}
   ```

1. Mount the data partition.

   The data partition is set to `fsopt=noauto` to facilitate LiveCDs over virtual-ISO mount. Therefore, USB installations
   need to mount this manually by running the following command.

   > **Note:** When creating the USB PIT image, this was mounted over `/mnt/pitdata`. Now that the USB PIT is booted,
   > it will mount over `/var/www/ephemeral`. The `FSLabel` `PITDATA` is already in `/etc/fstab`, so the path is omitted
   > in the following `mount` command.

   ```bash
   pit# mount -vL PITDATA
   ```

1. Set and export new environment variables.

   The commands below save them to `/etc/environment` as well, which makes them available in all new shell sessions on the PIT node.

   ```bash
   pit# export PITDATA=$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)
   pit# export CSM_PATH=${PITDATA}/${CSM_RELEASE}
   pit# echo "
   PITDATA=${PITDATA}
   CSM_PATH=${CSM_PATH}" | tee -a /etc/environment
   ```

1. Start a typescript to record this section of activities done on `ncn-m001` while booted from the LiveCD.

   ```bash
   pit# script -af /var/www/ephemeral/prep/admin/booted-csm-livecd.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Verify that expected environment variables are set in the new login shell.

   These were written into `/etc/environment` on the USB PIT image earlier in this procedure, before it was booted.

   ```bash
   pit# echo -e "CSM_PATH=${CSM_PATH}\nCSM_RELEASE=${CSM_RELEASE}\nPITDATA=${PITDATA}\nSYSTEM_NAME=${SYSTEM_NAME}"
   ```

1. Copy the typescript made on the external system into the `PITDATA` mount.

   ```bash
   pit# cp -v /root/boot.livecd.*.txt ${PITDATA}/prep/admin
   ```

1. Check the hostname.

   ```bash
   pit# hostnamectl
   ```

   > **Note:**
   >
   > * The hostname should be similar to `eniac-ncn-m001-pit` when booted from the LiveCD, but it will be shown as `pit#`
   >   in the documentation command prompts from this point onward.
   > * If the hostname returned by the `hostnamectl` command is `pit`, then set the hostname manually with `hostnamectl`. In that case, do not confuse other administrators
   >   by using the hostname `ncn-m001`. Append the `-pit` suffix, indicating that the node is booted from the LiveCD.

1. Install the latest documentation RPM.

   See [Check for Latest Documentation](../update_product_stream/index.md#documentation)

1. Print information about the booted PIT image.

   There is nothing in the output that needs to be verified. This is run in order to ensure the information is
   recorded in the typescript file, in case it is needed later. For example, this information is useful to include in
   any bug reports or service queries for issues encountered on the PIT node.

   ```bash
   pit# /root/bin/metalid.sh
   ```

   Expected output looks similar to the following:

   ```text
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

<a name="configure-the-running-livecd"></a>

## 6. Configure the running LiveCD

1. Set and export BMC credential variables.

   > `read -s` is used in order to prevent the credentials from being displayed on the screen or recorded in the shell history.

   ```bash
   pit# read -s IPMI_PASSWORD
   pit# USERNAME=root
   pit# export IPMI_PASSWORD USERNAME
   ```

1. Initialize the PIT.

   The `pit-init.sh` script will prepare the PIT server for deploying NCNs.

   ```bash
   pit# /root/bin/pit-init.sh
   ```

1. Start and configure NTP on the LiveCD for a fallback/recovery server.

   ```bash
   pit# /root/bin/configure-ntp.sh
   ```

1. Install Goss Tests and Server

   The following assumes the `CSM_PATH` environment variable is set to the absolute path of the unpacked CSM release.

   ```bash
   pit# rpm -Uvh --force $(find ${CSM_PATH}/rpm/ -name "goss-servers*.rpm" | sort -V | tail -1) \
                         $(find ${CSM_PATH}/rpm/ -name "csm-testing*.rpm" | sort -V | tail -1)
   ```

<a name="next-topic"></a>

## Next topic

After completing this procedure, proceed to configure the management network switches.

See [Configure Management Network Switches](index.md#configure_management_network).
