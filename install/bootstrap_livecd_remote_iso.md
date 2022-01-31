# Bootstrap PIT Node from LiveCD Remote ISO

The Pre-Install Toolkit (PIT) node needs to be bootstrapped from the LiveCD. There are two media available
to bootstrap the PIT node--the RemoteISO or a bootable USB device. This procedure describes using the
RemoteISO. If not using the RemoteISO, see [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

The installation process is similar to the USB based installation with adjustments to account for the
lack of removable storage.

**Important:** Before starting this procedure be sure to complete the procedure to
[Prepare Configuration Payload](prepare_configuration_payload.md) for the relevant installation scenario.

### Topics:
   1. [Known Compatibility Issues](#known-compatibility-issues)
   1. [Attaching and Booting the LiveCD with the BMC](#attaching-and-booting-the-livecd-with-the-bmc)
   1. [First Login](#first-login)
   1. [Configure the Running LiveCD](#configure-the-running-livecd)
      1. [Before Configuration Payload Workarounds](#before-configuration-payload-workarounds)
      1. [Generate Installation Files](#generate-installation-files)
         1. [Subsequent Fresh-Installs (Re-Installs)](#subsequent-fresh-installs-re-installs)
         1. [First-Time/Initial Installs (bare-metal)](#first-timeinitial-installs-bare-metal)
      1. [CSI Workarounds](#csi-workarounds)
      1. [Prepare Site Init](#prepare-site-init)
   1. [Bring-up the PIT Services and Validate PIT Health](#bring---up-the-pit-services-and-validate-pit-health)
   1. [Next Topic](#next-topic)

<a name="known-compatibility-issues"></a>
### 1. Known Compatibility Issues

The LiveCD Remote ISO has known compatibility issues for nodes from certain vendors.

   * Intel nodes should not attempt to bootstrap using the LiveCD Remote ISO method. Instead use [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)
   * Gigabyte nodes should not attempt to bootstrap using the LiveCD Remote ISO method. Instead use [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

<a name="attaching-and-booting-the-livecd-with-the-bmc"></a>
### 2. Attaching and Booting the LiveCD with the BMC

> **Warning:** If this is a re-installation on a system that still has a USB device from a prior
> installation, then that USB device must be wiped before continuing. Failing to wipe the USB, if present, may result in confusion.
> If the USB is still booted, then it can wipe itself using the [basic wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe). If it is not booted, please do so and wipe it _or_ disable the USB ports in the BIOS (not available for all vendors).

Obtain and attach the LiveCD cray-pre-install-toolkit ISO file to the BMC. Depending on the vendor of the node,
the instructions for attaching to the BMC will differ.

1. The CSM software release should be downloaded and expanded for use.

   **Important:** To ensure that the CSM release plus any patches, workarounds, or hotfixes are included
   follow the instructions in [Update CSM Product Stream](../update_product_stream/index.md)

   The cray-pre-install-toolkit ISO and other files are now available in the directory from the extracted CSM tar.
   The ISO will have a name similar to
   `cray-pre-install-toolkit-sle15sp3.x86_64-1.5.8-20211203183315-geddda8a.iso`

1. Prepare a server on the network to host the cray-pre-install-toolkit ISO.

   This release of CSM software, the cray-pre-install-toolkit ISO should be placed on a server which the PIT node
   will be able to contact via http or https.

      * HPE nodes can use http or https.

   **Note:** A shorter path name is better than a long path name on the webserver.

      - The Cray Pre-Install Toolkit ISO is included in the CSM release tarball. It will have a long filename similar to
        `cray-pre-install-toolkit-sle15sp3.x86_64-1.5.8-20211203183315-geddda8a.iso`, so pick a shorter name on the webserver.

1. See the respective procedure below to attach an ISO.

   - [HPE iLO BMCs](boot_livecd_virtual_iso.md#hpe-ilo-bmcs)
   - **Gigabyte BMCs** Should not use the RemoteISO method. See [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)
   - **Intel BMCs** Should not use the RemoteISO method. See [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

1. The chosen procedure should have rebooted the server. Observe the server boot into the LiveCD.

<a name="first-login"></a>
### 3. First Login

On first login (over SSH or at local console) the LiveCD will prompt the administrator to change the password.

1. **The initial password is empty**; set the username of `root` and press `return` twice.

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

<a name="configure-the-running-livecd"></a>
### 4. Configure the Running LiveCD

1. Set up the Typescript directory as well as the initial typescript. This directory will be returned to for every typescript in the entire CSM installation.


   ```bash
   pit# cd ~
   pit# script -af csm-install-remoteiso.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
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

1. <a name="set-up-site-link"></a>Set up the site-link, enabling SSH to work. You can reconnect with SSH after this step.
   > **`NOTICE REGARDING DHCP`** If your site's network authority or network administrator has already provisioned an IPv4 address for your master node(s) external NIC(s), **then skip this step**.

   1. Setup Variables.

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

   1. Run the link setup script.
      > **`NOTE : USAGE`** All of the `/root/bin/csi-*` scripts are harmless to run without parameters, doing so will dump usage statements.

      ```bash
      pit# /root/bin/csi-setup-lan0.sh $site_ip $site_gw $site_dns $site_nics
      ```

   1. Check if `lan0` has an IP address and attempt to auto-set the hostname based on DNS (this script appends `-pit` to the end of the hostname as a means to mitigate confusing the PIT node with an actual, deployed NCN). Then exit the typescript, exit the console session, and log in again using SSH.

      ```bash
      pit# ip a show lan0
      pit# /root/bin/csi-set-hostname.sh # this will attempt to set the hostname based on the site's own DNS records.
      pit# exit # exit the typescript started earlier
      pit# exit # log out of the pit node
      # Close the console session by entering &. or ~.
      # Then ssh back into the PIT node     
      external# ssh root@${SYSTEM_NAME}-ncn-m001
      ```

   1. After reconnecting, resume the typescript (the `-a` appends to an existing script).

       ```bash
      pit# cd ~
      pit# script -af $(ls -tr csm-install-remoteiso* | head -n 1)
      pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
      ```

   1. Check hostname.

      ```bash
      pit# hostnamectl
      ```
      > **`NOTE`** If the hostname returned by the `hostnamectl` command is still `pit`, then re-run the above script with the same parameters. Otherwise an administrator should feel free to set the hostname by hand with `hostnamectl`, please continue to use the `-pit` suffix to prevent masquerading a PIT node as a real NCN to administrators and automation.

1. Find a local disk for storing product installers.

    ```bash
    pit# disk="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print $2}' | head -n 1 | tr -d '\n')"
    pit# echo $disk
    pit# parted --wipesignatures -m --align=opt --ignore-busy -s /dev/$disk -- mklabel gpt mkpart primary ext4 2048s 100%
    pit# mkfs.ext4 -L PITDATA "/dev/${disk}1"
    ```

    In some cases the `parted` command may give an error similar to the following:
    ```text
    Error: Partition(s) 4 on /dev/sda have been written, but we have been unable to inform the kernel of the change, probably 
    because it/they are in use.  As a result, the old partition(s) will remain in use.  You should reboot now before making 
    further changes.
    ```

    In that case, the following steps may resolve the problem without needing to reboot. These commands will remove 
    volume groups and raid arrays that may be using the disk. **These commands only need to be run if the earlier 
    `parted` command failed.**
    
    ```bash
    pit# RAIDS=$(grep "${disk}[0-9]" /proc/mdstat | awk '{ print "/dev/"$1 }')
    pit# echo $RAIDS
    pit# VGS=$(echo $RAIDS | xargs -r pvs --noheadings -o vg_name 2>/dev/null)
    pit# echo $VGS
    pit# echo $VGS | xargs -r -t -n 1 vgremove -f -v
    pit# echo $RAIDS | xargs -r -t -n 1 mdadm -S -f -v 
    ```

    After running the above procedure, retry the `parted` command which failed. If it succeeds, resume the install from that point.

1. Mount local disk, check the output of each command as it goes.
   
   > **`NOTE`** The FSLabel `PITDATA` is already in `/etc/fstab`, so the path is omitted in the following calls to `mount`.

    ```bash
    pit# mount -v -L PITDATA
    pit# pushd /var/www/ephemeral
    pit# mkdir -v admin prep prep/admin configs data
    ```

1. Quit the typescript session with the `exit` command, copy the file (csm-install-remoteis.<date>.txt) from its initial location to the newly created directory, and restart the typescript.

    ```bash
    pit# exit # The typescript
    pit# cp -v ~/csm-install-remoteiso.*.txt /var/www/ephemeral/prep/admin
    pit# cd /var/www/ephemeral/prep/admin
    pit# script -af $(ls -tr csm-install-remoteiso* | head -n 1)
    pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

1. Download the CSM software release to the PIT node.

   **Important:** In an earlier step, the CSM release plus any patches, workarounds, or hotfixes
   were downloaded to a system using the instructions in [Update CSM Product Stream](../update_product_stream/index.md)
   Either copy from that system to the PIT node or set the ENDPOINT variable to URL and use `wget`.

   1. Set helper variables

      ```bash
      pit# export ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm
      pit# export CSM_RELEASE=csm-x.y.z
      pit# export SYSTEM_NAME=eniac
      ```

   1. Save the `CSM_RELEASE` and `SYSTEM_NAME` variable for usage later; all subsequent shell sessions will have this var set.

      ```bash
      # Prepend a new line to assure we add on a unique line and not at the end of another.
      pit# echo -e "\nCSM_RELEASE=$CSM_RELEASE\nSYSTEM_NAME=$SYSTEM_NAME" >>/etc/environment
      ```

   1. Fetch the release tarball.

      ```bash
      pit# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz -O /var/www/ephemeral/${CSM_RELEASE}.tar.gz
      ```

   1. Expand the tarball on the PIT node.

      > Note: Expansion of the tarball may take more than 45 minutes.


      ```bash
      pit# tar -C /var/www/ephemeral -zxvf /var/www/ephemeral/${CSM_RELEASE}.tar.gz
      pit# CSM_PATH=/var/www/ephemeral/${CSM_RELEASE}
      pit# echo $CSM_PATH
      pit# echo -e "\CSM_PATH=$CSM_PATH" >>/etc/environment
      pit# ls -l ${CSM_PATH}
      ```

   1. Copy the artifacts into place.

      ```bash
      pit# mkdir -pv /var/www/ephemeral/data/{k8s,ceph} &&
            rsync -a -P --delete ${CSM_PATH}/images/kubernetes/ /var/www/ephemeral/data/k8s/ &&
            rsync -a -P --delete ${CSM_PATH}/images/storage-ceph/ /var/www/ephemeral/data/ceph/
      ```

   > The PIT ISO, Helm charts/images, and bootstrap RPMs are now available in the extracted CSM tar.

1. Install/upgrade CSI; check if a newer version was included in the tar-ball.

   ```bash
   pit# rpm -Uvh $(find ${CSM_PATH}/rpm/ -name "cray-site-init-*.x86_64.rpm" | sort -V | tail -1)
   ```

1. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have direct internet
   access these RPMs will need to be externally downloaded and then copied to this machine.

   **Important:** To ensure that the latest workarounds and documentation updates are available,
   see [Check for Latest Workarounds and Documentation Updates](../update_product_stream/index.md#workarounds)

1. Show the version of CSI installed.

   ```bash
   pit# /root/bin/metalid.sh
   ```

   Expected output looks similar to the following:
   ```
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

<a name="before-configuration-payload-workarounds"></a>
#### 4.1 Before Configuration Payload Workarounds

Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `before-configuration-payload` breakpoint.

<a name="generate-installation-files"></a>
#### 4.2 Generate Installation Files

Some files are needed for generating the configuration payload. See these topics in [Prepare Configuration Payload](prepare_configuration_payload.md) if one has not already prepared the information for this system.

* [Command Line Configuration Payload](prepare_configuration_payload.md#command_line_configuration_payload)
* [Configuration Payload Files](prepare_configuration_payload.md#configuration_payload_files)

1. At this time see [Create HMN Connections JSON](create_hmn_connections_json.md) for instructions about creating the `hmn_connections.json`.

1. Change into the preparation directory plus necessary PIT directories (for later):

   ```bash
   pit# cd /var/www/ephemeral/prep
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
##### 4.2.a Subsequent Fresh-Installs (Re-Installs)

1. **For subsequent fresh-installs (re-installs) where the `system_config.yaml` parameter file is available**, generate the updated system configuration (see [avoiding parameters](../background/cray_site_init_files.md#save-file--avoiding-parameters)).

   > **`SKIP STEP IF`** if the `system_config.yaml` file is unavailable please skip this step and move onto the next one in order to generate the first configuration payload..

   1. Check for the configuration files. The needed files should be in the current directory.

      ```bash
      pit:/var/www/ephemeral/prep/# ls -1
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

   1. Verify that the `SYSTEM_NAME` variable is set.

      ```bash
      pit:/var/www/ephemeral/prep/# echo $SYSTEM_NAME
      ```

   1. Generate the system configuration

      > **`NOTE`** for those more familiar with a CSM Install, this step may be skipped entirely by simple invoking pit-intas detailed in the [#first time](#bring---up-the-pit-services-and-validate-pit-health) section.

      ```bash
      pit:/var/www/ephemeral/prep/# csi config init

      # Verify the newly generated configuration payload's `system_config.yaml` matches the current version of CSI.
      # NOTE: Keep this new system_config.yaml somewhere safe to facilitate re-installs.
      pit:/var/www/ephemeral/prep/# cat ${SYSTEM_NAME}/system_config.yaml
      pit:/var/www/ephemeral/prep/# csi version
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
##### 4.2.b First-Time/Initial Installs (bare-metal)

1. **For first-time/initial installs (without a `system_config.yaml`file)**, generate the system configuration. See below for an explanation of the command line parameters and some common settings.

   1. Check for the configuration files. The needed files should be in the current directory.

      > **`NOTE`** for those more familiar with a CSM Install, this step may be skipped entirely by simple invoking pit-intas detailed in the [#first time](#bring---up-the-pit-services-and-validate-pit-health) section.

      ```bash
      pit:/var/www/ephemeral/prep/# ls -1
      ```

   Expected output looks similar to the following:

      ```
      application_node_config.yaml
      cabinets.yaml
      hmn_connections.json
      ncn_metadata.csv
      switch_metadata.csv
      ```

   1. Verify that the `SYSTEM_NAME` variable is set.

      ```bash
      pit:/var/www/ephemeral/prep/# echo $SYSTEM_NAME
      ```

   1. Generate the system config:
      > **`NOTE`** the provided command below is an **example only**, run `csi config init --help` to print a full list of parameters that must be set. These will vary sifnificatnly depending on ones system and site configuration.

      ```bash
      pit:/var/www/ephemeral/prep/# csi config init \
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
      pit:/var/www/ephemeral/prep/# cat ${SYSTEM_NAME}/system_config.yaml
      pit:/var/www/ephemeral/prep/# csi version
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
#### 4.3 CSI Workarounds

Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `csi-config` breakpoint.

<a name="prepare_site_init"></a>
#### 4.4 Prepare Site Init

First, prepare a shim to faciliate going through the site-init guide:

 ```bash
 pit# mkdir -vp /mnt/pitdata
 pit# mount -v --bind /var/www/ephemeral/ /mnt/pitdata/
 ```

Follow the procedures to [Prepare Site Init](prepare_site_init.md) directory for your system.

Finally, cleanup the shim:
 ```bash
 pit# cd ~
 # this uses rmdir to safely remove the directory, preventing accidental removal if one does not notice a umount command failure.
 pit# umount -v /mnt/pitdata/
 pit# rmdir -v /mnt/pitdata
 ```

<a name="bring---up-the-pit-services-and-validate-pit-health"></a>
### 5. Bring-up the PIT Services and Validate PIT Health

1. Set the same variables from the `csi config init` step from earlier, and then invoke "PIT init" to setup the PIT server for deploying NCNs.
   > **`NOTE`** `pit-init` will re-run `csi config init`, copy all generated files into place, apply the CA patch, and finally restart daemons. This will also re-print the `metalid.sh` content incase it was skipped in the previous step. **Re-installs** can skip running `csi config init` entirely and simply run `pit-init.sh` after gathering CSI input files into `/var/www/ephemeral/prep`.

    ```bash
    pit# export USERNAME=root
    pit# export IPMI_PASSWORD=changeme
    pit# /root/bin/pit-init.sh
    ```

1. Start and configure NTP on the LiveCD for a fallback/recovery server.

   ```bash
   pit# /root/bin/configure-ntp.sh
   ```

1. Install Goss Tests and Server

   The following assumes the CSM_PATH environment variable is set to the absolute path of the unpacked CSM release.

   ```bash
   pit# rpm -Uvh --force $(find ${CSM_PATH}/rpm/ -name "goss-servers*.rpm" | sort -V | tail -1)
   pit# rpm -Uvh --force $(find ${CSM_PATH}/rpm/ -name "csm-testing*.rpm" | sort -V | tail -1)   
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


