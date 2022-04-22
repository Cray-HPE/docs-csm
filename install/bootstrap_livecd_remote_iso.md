# Bootstrap PIT Node from LiveCD Remote ISO

The Pre-Install Toolkit (PIT) node needs to be bootstrapped from the LiveCD. There are two media available
to bootstrap the PIT node: the RemoteISO or a bootable USB device. This procedure describes using the USB
device. If not using the RemoteISO, see [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

The installation process is similar to the USB-based installation, with adjustments to account for the
lack of removable storage.

**Important:** Before starting this procedure be sure to complete the procedure to
[Prepare Configuration Payload](prepare_configuration_payload.md) for the relevant installation scenario.

## Topics

1. [Known Compatibility Issues](#known-compatibility-issues)
1. [Attaching and Booting the LiveCD with the BMC](#attaching-and-booting-the-livecd-with-the-bmc)
1. [First Login](#first-login)
1. [Configure the Running LiveCD](#configure-the-running-livecd)
   1. [Generate Installation Files](#generate-installation-files)
      * [Subsequent Installs (Reinstalls)](#subsequent-fresh-installs-re-installs)
      * [Initial Installs (bare-metal)](#first-timeinitial-installs-bare-metal)
   1. [Verify and Backup `system_config.yaml`](#verify-csi-versions-match)
   1. [Prepare Site Init](#prepare-site-init)
1. [Bring-up the PIT Services and Validate PIT Health](#bring---up-the-pit-services-and-validate-pit-health)
1. [Next Topic](#next-topic)

<a name="known-compatibility-issues"></a>
## 1. Known Compatibility Issues

The LiveCD Remote ISO has known compatibility issues for nodes from certain vendors.

   * Intel nodes should not attempt to bootstrap using the LiveCD Remote ISO method. Instead use [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)
   * Gigabyte nodes should not attempt to bootstrap using the LiveCD Remote ISO method. Instead use [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

<a name="attaching-and-booting-the-livecd-with-the-bmc"></a>
## 2. Attaching and Booting the LiveCD with the BMC

> **Warning:** If this is a re-installation on a system that still has a USB device from a prior
> installation, then that USB device must be wiped before continuing. Failing to wipe the USB, if present, may result in confusion.
> If the USB is still booted, then it can wipe itself using the [basic wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe). If it is not booted, please do so and wipe it _or_ disable the USB ports in the BIOS (not available for all vendors).

Obtain and attach the LiveCD `cray-pre-install-toolkit` ISO file to the BMC. Depending on the vendor of the node,
the instructions for attaching to the BMC will differ.

1. Download the CSM software release and extract the LiveCD remote ISO image.

   **Important:** Ensure that you have the CSM release plus any patches or hotfixes by
   following the instructions in [Update CSM Product Stream](../update_product_stream/index.md)

   The `cray-pre-install-toolkit` ISO and other files are now available in the directory from the extracted CSM tar file.
   The ISO will have a name similar to
   `cray-pre-install-toolkit-sle15sp3.x86_64-1.5.8-20211203183315-geddda8a.iso`
   
   This ISO file can be extracted from the CSM release tar file using the following command:
   ```bash
   linux# tar --wildcards --no-anchored -xzvf <csm-release>.tar.gz 'cray-pre-install-toolkit-*.iso'
   ```

1. Prepare a server on the network to host the `cray-pre-install-toolkit` ISO file.

   Place the `cray-pre-install-toolkit` ISO file on a server which the BMC of the PIT node
   will be able to contact using HTTP or HTTPS.

   **Note:** A short URL is better than a long URL for the PIT file on the webserver.

1. See the respective procedure below to attach an ISO.

   - [HPE iLO BMCs](boot_livecd_virtual_iso.md#hpe-ilo-bmcs)
   - **Gigabyte BMCs** Do not use the RemoteISO method. See [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)
   - **Intel BMCs** Do not use the RemoteISO method. See [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

1. The chosen procedure should have rebooted the server. Observe the server boot into the LiveCD.

<a name="first-login"></a>
## 3. First Login

On first login (over SSH or at local console) the LiveCD will prompt the administrator to change the password.

1. **The initial password is empty**; enter the username of `root` and press `return` twice.

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
## 4. Configure the Running LiveCD

1. Start a typescript to record this section of activities done on `ncn-m001` while booted from the LiveCD.

   ```bash
   pit# script -af ~/csm-install-remoteiso.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```
   
1. Print information about the booted PIT image.

   There is nothing in the output that needs to be verified. This is run in order to ensure the information is
   recorded in the typescript file, in case it is needed later. For example, this information is useful to include in
   any bug reports or service queries for issues encountered on the PIT node.

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

1. Find a local disk for storing product installers.

   ```bash
   pit# disk="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print $2}' | head -n 1 | tr -d '\n')"
   pit# echo $disk
   pit# parted --wipesignatures -m --align=opt --ignore-busy -s /dev/$disk -- mklabel gpt mkpart primary ext4 2048s 100%
   pit# mkfs.ext4 -L PITDATA "/dev/${disk}1"
   pit# mount -vL PITDATA
   ```

   The `parted` command may give an error similar to the following:
   ```text
   Error: Partition(s) 4 on /dev/sda have been written, but we have been unable to inform the kernel of the change, probably
   because it/they are in use. As a result, the old partition(s) will remain in use. You should reboot now before making
   further changes.
   ```

   In that case, the following steps may resolve the problem without needing to reboot. These commands remove
   volume groups and raid arrays that may be using the disk. **These commands only need to be run if the earlier
   `parted` command failed.**

   ```bash
   pit# RAIDS=$(grep "${disk}[0-9]" /proc/mdstat | awk '{ print "/dev/"$1 }') ; echo ${RAIDS}
   pit# VGS=$(echo ${RAIDS} | xargs -r pvs --noheadings -o vg_name 2>/dev/null) ; echo ${VGS}
   pit# echo ${VGS} | xargs -r -t -n 1 vgremove -f -v
   pit# echo ${RAIDS} | xargs -r -t -n 1 mdadm -S -f -v
   ```

   After running the above procedure, retry the `parted` command which failed. If it succeeds, resume the install from that point.

1. <a name="set-up-site-link"></a>Set up the site-link, enabling SSH to work. You can reconnect with SSH after this step.
   > **Note:** If your site's network authority or network administrator has already provisioned a DHCP IPv4 address for your master node's external NIC(s), **then skip this step**.

   1. Set networking variables.

      > If you have previously created the `system_config.yaml` file for this system, the values for these variables are in it. The
      > following table lists the variables being set, their corresponding `system_config.yaml` fields, and a description of what
      > they are.

      | Variable    | `system_config.yaml`   | Description                                                                        |
      |-------------|------------------------|------------------------------------------------------------------------------------|
      | `site_ip`   | `site-ip`              | The IPv4 address **and CIDR netmask** for the node's external interface(s)         |
      | `site_gw`   | `site-gw`              | The IPv4 gateway address for the node's external interface(s)                      |
      | `site_dns`  | `site-dns`             | The IPv4 domain name server address for the site                                   |
      | `site_nics` | `site-nic`             | The actual NIC name(s) for the external site interface(s)                          |
      
      > If the `system_config.yaml` file has not yet been generated for this system, the values for `site_ip`, `site_gw`, and
      > `site_dns` should be provided by the site's network administrator or network authority. The `site_nics` interface(s)
      > are typically the first onboard adapter or the first copper 1 GbE PCIe adapter on the PIT node. If multiple interfaces are
      > specified, they must be separated by spaces (for example, `site_nics='p2p1 p2p2 p2p3'`).

      ```bash
      pit# site_ip=172.30.XXX.YYY/20
      pit# site_gw=172.30.48.1
      pit# site_dns=172.30.84.40
      pit# site_nics=em1
      ```

   1. Run the `csi-setup-lan0.sh` script to set up the site link.

      > **Note:** All of the `/root/bin/csi-*` scripts are harmless to run without parameters; doing so will print usage statements.

      ```bash
      pit# /root/bin/csi-setup-lan0.sh $site_ip $site_gw $site_dns $site_nics
      ```

   1. Verify that `lan0` has an IP address and attempt to auto-set the hostname based on DNS.
   
      The script appends `-pit` to the end of the hostname as a means to reduce the chances of confusing the PIT node with an actual, deployed NCN. 
      
      ```bash
      pit# ip a show lan0
      pit# /root/bin/csi-set-hostname.sh # this will attempt to set the hostname based on the site's own DNS records.
      ```

   1. Add helper variables to PIT node environment.

      > **Important:** All CSM install procedures on the PIT node assume that these variables are set
      > and exported.

      1. Set helper variables.

         ```bash
         pit# CSM_RELEASE=csm-x.y.z
         pit# SYSTEM_NAME=eniac
         pit# PITDATA=$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)
         ```

      1. Add variables to the PIT environment.

         By adding these to the `/etc/environment` file of the PIT node, these variables will be
         automatically set and exported in shell sessions on the PIT node. 

         > The `echo` prepends a newline to ensure that the variable assignment occurs on a unique line,
         > and not at the end of another line.

         ```bash
         pit# echo "
         CSM_RELEASE=${CSM_RELEASE}
         PITDATA=${PITDATA}
         CSM_PATH=${PITDATA}/${CSM_RELEASE}
         SYSTEM_NAME=${SYSTEM_NAME}" | tee -a /etc/environment
         ```

   1. Exit the typescript, exit the console session, and log in again using SSH.

      ```bash
      pit# exit # exit the typescript started earlier
      pit# exit # log out of the pit node
      # Close the console session by entering &. or ~.
      # Then ssh back into the PIT node
      external# ssh root@${SYSTEM_NAME}-ncn-m001
      ```

   1. After reconnecting, resume the typescript (the `-a` appends to an existing script).

       ```bash
      pit# script -af $(ls -tr ~/csm-install-remoteiso*.txt | head -n 1)
      pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
      ```

   1. Verify that expected environment variables are set in the new login shell.

      ```bash
      pit# echo -e "CSM_PATH=${CSM_PATH}\nCSM_RELEASE=${CSM_RELEASE}\nPITDATA=${PITDATA}\nSYSTEM_NAME=${SYSTEM_NAME}"
      ```

   1. Check hostname.

      ```bash
      pit# hostnamectl
      ```

      > **Note:** The hostname should be similar to `eniac-ncn-m001-pit` when booted from the LiveCD, but it will be shown as `pit#` 
      > in the documentation command prompts from this point onward.

      > **Note:** If the hostname returned by the `hostnamectl` command is `pit`, then re-run the `csi-set-hostname.sh` script with the same parameters. Otherwise, an administrator should set the hostname manually with `hostnamectl`. In the latter case, be sure to append the `-pit` suffix to prevent masquerading a PIT node as a real NCN to administrators and automation.

1. Mount local disk.

   > **Note:** The FSLabel `PITDATA` is already in `/etc/fstab`, so the path is omitted in the following call to `mount`.

   ```bash
   pit# mount -vL PITDATA &&
        mkdir -pv ${PITDATA}/{admin,configs} ${PITDATA}/prep/{admin,logs} ${PITDATA}/data/{k8s,ceph}
   ```

1. Relocate the typescript to the newly mounted `PITDATA` directory.

   1. Quit the typescript session with the `exit` command.

   1. Copy the typescript file to its new location.

      ```bash
      pit# cp -v ~/csm-install-remoteiso.*.txt ${PITDATA}/prep/admin
      ```

   1. Restart the typescript, appending to the previous file.

      ```bash
      pit# script -af $(ls -tr ${PITDATA}/prep/admin/csm-install-remoteiso*.txt | head -n 1)
      pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
      ```

1. Download the CSM software release to the PIT node.

   1. Set variable to URL of CSM tarball.

      ```bash
      pit# URL=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm/${CSM_RELEASE}.tar.gz
      ```

   1. Fetch the release tarball.

      ```bash
      pit# wget ${URL} -O ${CSM_PATH}.tar.gz
      ```

   1. Expand the tarball on the PIT node.

      > **Note:** Expansion of the tarball may take more than 45 minutes.

      ```bash
      pit# tar -C ${PITDATA} -zxvf ${CSM_PATH}.tar.gz && ls -l ${CSM_PATH}
      ```

   1. Copy the artifacts into place.

      ```bash
      pit# rsync -a -P --delete ${CSM_PATH}/images/kubernetes/   ${PITDATA}/data/k8s/ &&
           rsync -a -P --delete ${CSM_PATH}/images/storage-ceph/ ${PITDATA}/data/ceph/
      ```

   > **Note:** The PIT ISO, Helm charts/images, and bootstrap RPMs are now available in the extracted CSM tar file.

1. Install/upgrade CSI; check if a newer version was included in the tarball.

   ```bash
   pit# rpm -Uvh $(find ${CSM_PATH}/rpm/ -name "cray-site-init-*.x86_64.rpm" | sort -V | tail -1)
   ```

1. Install the latest documentation RPM.

   See [Check for Latest Documentation](../update_product_stream/index.md#documentation)

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

<a name="generate-installation-files"></a>
### 4.1 Generate Installation Files

Some files are needed for generating the configuration payload. See the [Command Line Configuration Payload](prepare_configuration_payload.md#command_line_configuration_payload) and [Configuration Payload Files](prepare_configuration_payload.md#configuration_payload_files) topics if one has not already prepared the information for this system.

* [Command Line Configuration Payload](prepare_configuration_payload.md#command_line_configuration_payload)
* [Configuration Payload Files](prepare_configuration_payload.md#configuration_payload_files)

1. Create the `hmn_connections.json` file by following the [Create HMN Connections JSON](create_hmn_connections_json.md)  procedure. Return to this section when completed.

1. Copy these files into the current working directory, or create them if this is an initial install of the system:

   - `application_node_config.yaml` (optional - see below)
   - `cabinets.yaml` (optional - see below)
   - `hmn_connections.json`
   - `ncn_metadata.csv`
   - `switch_metadata.csv`
   - `system_config.yaml` (only available after [first-install generation of system files](#first-timeinitial-installs-bare-metal)

   > The optional `application_node_config.yaml` file may be provided for further definition of settings relating to how application nodes will appear in HSM for roles and subroles. See [Create Application Node YAML](create_application_node_config_yaml.md).

   > The optional `cabinets.yaml` file allows cabinet naming and numbering as well as some VLAN overrides. See [Create Cabinets YAML](create_cabinets_yaml.md).

   > The `system_config.yaml` file is generated by the `csi` tool during the first install of a system, and can later be used for reinstalls of the system. For the initial install, the information in it must be provided as command line arguments to `csi config init`.

   After gathering the files into this working directory, move on to [Subsequent Fresh-Installs (Re-Installs)](#subsequent-fresh-installs-re-installs).

1. Proceed to the appropriate next step.

   * If this is the initial install of the system, then proceed to [Initial Installs (bare-metal)](#first-timeinitial-installs-bare-metal).
   * If this is a reinstall of the system, then proceed to [Subsequent Installs (Reinstalls)](#subsequent-fresh-installs-re-installs).

<a name="subsequent-fresh-installs-re-installs"></a>
#### 4.1.a Subsequent Installs (Reinstalls)

1. **For subsequent fresh-installs (re-installs) where the `system_config.yaml` parameter file is available**, generate the updated system configuration (see [Cray Site Init Files](../background/index.md#cray_site_init_files)).

   > **Warning:** If the `system_config.yaml` file is unavailable, please skip this step and move onto the next one in step 4.1.b to generate the first configuration payload.

   1. Check for the configuration files. The needed files should be in the preparation directory.

      ```bash
      pit# ls -1 ${PITDATA}/prep
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

   1. Generate the system configuration

      > **Note:** Make sure to select a reachable NTP pool/server (passed in via the `--ntp-pools`/`--ntp-servers` flags, respectively). Adding an unreachable server can cause clock skew as `chrony` tries to continually reach out to a server it can never reach.

      ```bash
      pit# cd ${PITDATA}/prep && csi config init
      ```

      A new directory matching the `system-name` field in `system_config.yaml` will now exist in the working directory.

      > **Note:** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
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

   1. Skip the next step and continue to [verify and backup `system_config.yaml`](#verify-csi-versions-match).

<a name="first-timeinitial-installs-bare-metal"></a>
#### 4.1.b Initial Installs (bare-metal)

1. **For first-time/initial installs (without a `system_config.yaml`file)**, generate the system configuration. See below for an explanation of the command line parameters and some common settings.

   1. Check for the configuration files. The needed files should be in the preperation directory.

      ```bash
      pit# ls -1 ${PITDATA}/prep
      ```

       1. Expected output looks similar to the following:

          ```
          application_node_config.yaml
          cabinets.yaml
          hmn_connections.json
          ncn_metadata.csv
          switch_metadata.csv
          ```

   1. Generate the system config:
      > **Note:** The following command is an **example only**, run `csi config init --help` to print a full list of parameters that must be set. These will vary significantly depending on the system and site configuration in use.

      ```bash
      pit# cd ${PITDATA}/prep && csi config init \
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
      ```

      A new directory matching the `--system-name` argument will now exist in the working directory.

      > **Important:** After generating a configuration, a visual audit of the generated files for network data should be performed.

      > **Special Notes:** Certain parameters to `csi config init` may be hard to grasp on first-time configuration generations:
      >
      > * The `application_node_config.yaml` file is optional, but if one has one describing the mapping between prefixes in `hmn_connections.csv` that should be mapped to HSM subroles, one needs to include a command line option to have it used. See [Create Application Node YAML](create_application_node_config_yaml.md).
      > * The `bootstrap-ncn-bmc-user` and `bootstrap-ncn-bmc-pass` must match what is used for the BMC account and its password for the management NCNs.
      > * Set site parameters (`site-domain`, `site-ip`, `site-gw`, `site-nic`, `site-dns`) for the information which connects `ncn-m001` (the PIT node) to the site. The `site-nic` is the interface on this node connected to the site.
      > * There are other interfaces possible, but the `install-ncn-bond-members` are typically:
      >    * `p1p1,p10p1` for HPE nodes
      >    * `p1p1,p1p2` for Gigabyte nodes
      >    * `p801p1,p801p2` for Intel nodes
      > * If one are not using a `cabinets-yaml` file, set the three cabinet parameters (`mountain-cabinets`, `hill-cabinets`, and `river-cabinets`) to the number of each cabinet which are part of this system.
      > * The starting cabinet number for each type of cabinet (for example, `starting-mountain-cabinet`) has a default that can be overridden. See the `csi config init --help`
      > * For systems that use non-sequential cabinet ID numbers, use `cabinets-yaml` to include the `cabinets.yaml` file. This file can include information about the starting ID for each cabinet type and number of cabinets which have separate command line options, but is a way to specify explicitly the id of every cabinet in the system. If one are using a `cabinets-yaml` file, flags specified on the `csi` command-line related to cabinets will be ignored. See [Create Cabinets YAML](create_cabinets_yaml.md).
      > * An override to default cabinet IPv4 subnets can be made with the `hmn-mtn-cidr` and `nmn-mtn-cidr` parameters.

      > **Ignorable Warnings:** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored:
      >
      > * The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other management NCNs. It can be ignored.
      >
      >    ```
      >    "Couldn't find switch port for NCN: x3000c0s1b0"
      >    ```
      >
      > * An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml` file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md).
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
### 4.2 Verify and Backup `system_config.yaml`

1. Verify that the newly generated `system_config.yaml` matches the current version of CSI.

   1. View the new `system_config.yaml` file and note the CSI version reported near the end of the file.

      ```bash
      pit# cat ${PITDATA}/prep/${SYSTEM_NAME}/system_config.yaml
      ```

   1. Note the version reported by the `csi` tool.

      ```bash
      pit# csi version
      ```

   1. The two versions should match. If they do not, determine the cause and regenerate the file.

1. Copy the new `system_config.yaml` file somewhere safe to facilitate re-installs.

1. Continue to the next step to [prepare site init](#prepare-site-init).

<a name="prepare-site-init"></a>
### 4.3 Prepare Site Init

> **Important:** Although the command prompts in this procedure are `linux#`, the procedure should be
> performed on the PIT node.

Prepare the `site-init` directory by performing the [Prepare Site Init](prepare_site_init.md) procedures.

<a name="bring---up-the-pit-services-and-validate-pit-health"></a>
## 5. Bring-up the PIT Services and Validate PIT Health

1. Initialize the PIT.

   The `pit-init.sh` script will prepare the PIT server for deploying NCNs.

   > Set the `USERNAME` and `IPMI_PASSWORD` variables to the credentials for the BMC of the PIT node.
   >
   > `read -s` is used in order to prevent the credentials from being displayed on the screen or recorded in the shell history.

   ```bash
   pit# USERNAME=root
   pit# read -s IPMI_PASSWORD
   pit# export USERNAME IPMI_PASSWORD ; /root/bin/pit-init.sh
   ```

1. Start and configure NTP on the LiveCD for a fallback/recovery server.

   ```bash
   pit# /root/bin/configure-ntp.sh
   ```

1. Install Goss Tests and Server

   ```bash
   pit# rpm -Uvh --force $(find ${CSM_PATH}/rpm/ -name "goss-servers*.rpm" | sort -V | tail -1) \
                         $(find ${CSM_PATH}/rpm/ -name "csm-testing*.rpm" | sort -V | tail -1)
   ```

<a name="next-topic"></a>
## Next Topic

After completing this procedure, proceed to configure the management network switches.

See [Configure Management Network Switches](index.md#configure_management_network)
