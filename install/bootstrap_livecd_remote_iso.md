# Bootstrap PIT Node from LiveCD Remote ISO

The Pre-Install Toolkit (PIT) node needs to be bootstrapped from the LiveCD. There are two media available
to bootstrap the PIT node--the RemoteISO or a bootable USB device. This procedure describes using the
RemoteISO. If not using the RemoteISO, see [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

The installation process is similar to the USB based installation with adjustments to account for the
lack of removable storage.

**Important:** Before starting this procedure be sure to complete the procedure to
[Prepare Configuration Payload](prepare_configuration_payload.md) for the relevant installation scenario.

## Topics

1. [Known compatibility issues](#known-compatibility-issues)
1. [Attaching and booting the LiveCD with the BMC](#attaching-and-booting-the-livecd-with-the-bmc)
1. [First login](#first-login)
1. [Configure the running LiveCD](#configure-the-running-livecd)
1. [Next topic](#next-topic)

<a name="known-compatibility-issues"></a>

## 1. Known compatibility issues

The LiveCD Remote ISO has known compatibility issues for nodes from certain vendors.

* Intel nodes should not attempt to bootstrap using the LiveCD Remote ISO method. Instead use [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)
* Gigabyte nodes should not attempt to bootstrap using the LiveCD Remote ISO method. Instead use [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

<a name="attaching-and-booting-the-livecd-with-the-bmc"></a>

## 2. Attaching and booting the LiveCD with the BMC

> **Warning:** If this is a re-installation on a system that still has a USB device from a prior
> installation, then that USB device must be wiped before continuing. Failing to wipe the USB, if present, may result in confusion.
> If the USB is still booted, then it can wipe itself using the [basic wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe).
> If it is not booted, please do so and wipe it **or** disable the USB ports in the BIOS (not available for all vendors).

Obtain and attach the LiveCD `cray-pre-install-toolkit` ISO file to the BMC. Depending on the vendor of the node,
the instructions for attaching to the BMC will differ.

1. The CSM software release should be downloaded and expanded for use.

   **Important:** To ensure that the CSM release plus any patches, workarounds, or hot fixes are included
   follow the instructions in [Update CSM Product Stream](../update_product_stream/index.md)

   The `cray-pre-install-toolkit` ISO and other files are now available in the directory from the extracted CSM `tar`.
   The ISO will have a name similar to
   `cray-pre-install-toolkit-sle15sp2.x86_64-1.4.10-20210514183447-gc054094.iso`

   This ISO file can be extracted from the CSM release `tar` file using the following command:

   ```bash
   linux# tar --wildcards --no-anchored -xzvf <csm-release>.tar.gz 'cray-pre-install-toolkit-*.iso'
   ```

   This release of CSM software, the `cray-pre-install-toolkit` ISO should be placed on a server which the PIT node
   will be able to contact using HTTP or HTTPS.

   **Note:** A shorter path name is better than a long path name on the webserver.

      * The Cray Pre-Install Toolkit ISO is included in the CSM release `tar` file. It will have a long filename similar to
        `cray-pre-install-toolkit-sle15sp2.x86_64-1.4.10-20210514183447-gc054094.iso`, so pick a shorter name on the webserver.

1. See the respective procedure below to attach an ISO.

   * [HPE iLO BMCs](boot_livecd_virtual_iso.md#hpe-ilo-bmcs)
   * **Gigabyte BMCs** Do not use the RemoteISO method. See [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)
   * **Intel BMCs** Do not use the RemoteISO method. See [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md)

1. The chosen procedure should have rebooted the server. Observe the server boot into the LiveCD.

<a name="first-login"></a>

## 3. First login

On first login (over SSH or at local console) the LiveCD will prompt the administrator to change the password.

1. **The initial password is empty**; set the username of `root` and press `return` twice.

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

<a name="configure-the-running-livecd"></a>

## 4. Configure the running LiveCD

1. Set up the initial typescript.

   ```bash
   pit# cd ~
   pit# script -af csm-install-remoteiso.$(date +%Y-%m-%d).txt
   pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. <a name="set-up-site-link"></a>Set up the site-link, enabling SSH to work. You can reconnect with SSH after this step.
   > **`NOTICE REGARDING DHCP`** If your site's network authority or network administrator has already provisioned an IPv4 address for your master node(s) external NIC(s), **then skip this step**.

   1. Setup variables.

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

   1. Print `lan0`, and if it has an IP address, then exit console and log in again using SSH.

      ```bash
      pit# ip a show lan0
      pit# exit
      external# ssh root@${SYSTEM_NAME}-ncn-m001
      ```

   1. (Recommended) After reconnecting, resume the typescript (the `-a` appends to an existing script).

      ```bash
      pit# cd ~
      pit# script -af $(ls -tr csm-install-remoteiso* | head -n 1)
      pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
      ```

   1. Check hostname.

      ```bash
      pit# hostnamectl
      ```

      > **Note:**
      >
      > * The hostname should be similar to `eniac-ncn-m001-pit` when booted from the LiveCD, but it will be shown as `pit#`
      >   in the documentation command prompts from this point onward.
      > * If the hostname returned by the `hostnamectl` command is `pit`, then re-run the `csi-set-hostname.sh` script with the same parameters.
      >   Otherwise, an administrator should set the hostname manually with `hostnamectl`. In the latter case, do not confuse other administrators
      >   by using the hostname `ncn-m001`. Append the `-pit` suffix, indicating that the node is booted from the LiveCD.

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
    because it/they are in use. As a result, the old partition(s) will remain in use. You should reboot now before making
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

    ```bash
    pit# mount -v -L PITDATA
    pit# pushd /var/www/ephemeral
    pit# mkdir -v admin prep prep/admin configs data
    ```

1. Quit the typescript session with the `exit` command, copy the file (`csm-install-remoteis.<date>.txt`) from its initial location to the newly created directory, and restart the typescript.

    ```bash
    pit# exit # The typescript
    pit# cp -v ~/csm-install-remoteiso.*.txt /var/www/ephemeral/prep/admin
    pit# cd /var/www/ephemeral/prep/admin
    pit# script -af $(ls -tr csm-install-remoteiso* | head -n 1)
    pit# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    pit# pushd /var/www/ephemeral
    ```

1. Download the CSM software release to the PIT node.

   **Important:** In an earlier step, the CSM release plus any patches, workarounds, or hot fixes
   were downloaded to a system using the instructions in [Update CSM Product Stream](../update_product_stream/index.md)
   Either copy from that system to the PIT node or set the ENDPOINT variable to URL and use `wget`.

   1. Set helper variables.

      ```bash
      pit# ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm
      pit# export CSM_RELEASE=csm-x.y.z
      pit# export SYSTEM_NAME=eniac
      ```

   1. Save the `CSM_RELEASE` and `SYSTEM_NAME` variables for usage later; all subsequent shell sessions will have this variable set.

      > The `echo` prepends a newline to ensure that the variable assignment occurs on a unique line,
      > and not at the end of another.

      ```bash
      pit# echo -e "\nCSM_RELEASE=${CSM_RELEASE}\nSYSTEM_NAME=${SYSTEM_NAME}" >>/etc/environment
      ```

   1. Fetch the release `tar` file.

      ```bash
      pit# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz -O /var/www/ephemeral/${CSM_RELEASE}.tar.gz
      ```

   1. Expand the `tar` file on the PIT node.

      > Note: Expansion of the `tar` file may take more than 45 minutes.

      ```bash
      pit# tar -zxvf ${CSM_RELEASE}.tar.gz
      pit# ls -l ${CSM_RELEASE}
      ```

   1. Copy the artifacts into place.

      ```bash
      pit# mkdir -pv data/{k8s,ceph}
      pit# rsync -a -P --delete ./${CSM_RELEASE}/images/kubernetes/ ./data/k8s/
      pit# rsync -a -P --delete ./${CSM_RELEASE}/images/storage-ceph/ ./data/ceph/
      ```

   > The PIT ISO, Helm charts/images, and bootstrap RPMs are now available in the extracted CSM `tar`.

1. Install/upgrade the CSI and testing RPMs.

   ```bash
   pit# rpm -Uvh --force $(find ./${CSM_RELEASE}/rpm/ -name "cray-site-init-*.x86_64.rpm" | sort -V | tail -1)
   pit# rpm -Uvh --force $(find ./${CSM_RELEASE}/rpm/ -name "goss-servers*.rpm" | sort -V | tail -1)
   pit# rpm -Uvh --force $(find ./${CSM_RELEASE}/rpm/ -name "csm-testing*.rpm" | sort -V | tail -1)
   ```

1. Show the version of CSI installed.

   ```bash
   pit# csi version
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

1. Download and install/upgrade the workaround and documentation RPMs.

   If this machine does not have direct Internet access these RPMs will need to be externally downloaded and then copied to the system.

   **Important:** In an earlier step, the CSM release plus any patches, workarounds, or hot fixes
   were downloaded to a system using the instructions in [Check for Latest Workarounds and Documentation Updates](../update_product_stream/index.md#workarounds). Use that set of RPMs rather than downloading again.

   ```bash
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm
   linux# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   linux# scp -p docs-csm-*rpm csm-install-workarounds-*rpm ncn-m001:/root
   linux# ssh ncn-m001
   pit# rpm -Uvh --force docs-csm-latest.noarch.rpm
   pit# rpm -Uvh --force csm-install-workarounds-latest.noarch.rpm
   ```

<a name="generate-installation-files"></a>

### 4.1 Generate installation files

Some files are needed for generating the configuration payload. See the [Command Line Configuration Payload](prepare_configuration_payload.md#command_line_configuration_payload)
and [Configuration Payload Files](prepare_configuration_payload.md#configuration_payload_files) topics if one has not already prepared the information for this system.

* [Command Line Configuration Payload](prepare_configuration_payload.md#command_line_configuration_payload)
* [Configuration Payload Files](prepare_configuration_payload.md#configuration_payload_files)

1. Create the `hmn_connections.json` file by following the [Create HMN Connections JSON](create_hmn_connections_json.md)  procedure. Return to this section when completed.

1. Create the configuration input files if needed and copy them into the preparation directory.

   The preparation directory is `${PITDATA}/prep`.

   Copy these files into the preparation directory, or create them if this is an initial install of the system:

   * `application_node_config.yaml` (optional - see below)
   * `cabinets.yaml` (optional - see below)
   * `hmn_connections.json`
   * `ncn_metadata.csv`
   * `switch_metadata.csv`
   * `system_config.yaml` (only available after [first-install generation of system files](#first-timeinitial-installs-bare-metal))

   > The optional `application_node_config.yaml` file may be provided for further definition of settings relating to how application nodes will appear in HSM for roles and
   > subroles. See [Create Application Node YAML](create_application_node_config_yaml.md).
   >
   > The optional `cabinets.yaml` file allows cabinet naming and numbering as well as some VLAN overrides. See [Create Cabinets YAML](create_cabinets_yaml.md).
   >
   > The `system_config.yaml` file is generated by the `csi` tool during the first install of a system, and can later be used for reinstalls of the system. For the initial
   > install, the information in it must be provided as command line arguments to `csi config init`.

   1. Change into the preparation directory.

      ```bash
      linux# mkdir -pv /var/www/ephemeral/prep
      linux# cd /var/www/ephemeral/prep
      ```

      After gathering the files into this working directory, generate your configurations.

   1. If doing a reinstall and have the `system_config.yaml` parameter file available, then generate the system configuration reusing this parameter file (see [avoiding parameters](../background/cray_site_init_files.md#save-file--avoiding-parameters)).

      If not doing a reinstall of Shasta software, then the `system_config.yaml` file will not be available, so skip the rest of this step.

      1. Check for the configuration files. The needed files should be in the current directory.

         ```bash
         linux# ls -1
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
         linux# csi config init
         ```

         A new directory matching the `system-name` field in `system_config.yaml` will now exist in the working directory.

         > **Note:** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
         >
         > * The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other
         >    management NCNs. It can be ignored.
         >
         >    ```text
         >    "Couldn't find switch port for NCN: x3000c0s1b0"
         >    ```
         >
         > * An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml`
         >    file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md)
         >
         >   ```json
         >   {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
         >   {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
         >   ```
         >
         > * If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.
         >
         >   ```json
         >   {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
         >   {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
         >   ```

      1. Skip the next step and continue to the [CSI Workarounds](#csi-workarounds).

   1. If doing a first time install or the `system_config.yaml` parameter file for a reinstall is not available, generate the system configuration.

      If doing a first time install, this step is required. If you did the previous step as part of a reinstall, skip this.

      1. Check for the configuration files. The needed files should be in the current directory.

         ```bash
         linux# ls -1
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
         linux# csi config init <options>
         ```

         A new directory matching the `system-name` field in `system_config.yaml` will now exist in the working directory.

         > **Important:** After generating a configuration, a visual audit of the generated files for network data should be performed.
         >
         > **Special Notes:** Certain parameters to `csi config init` may be hard to grasp on first-time configuration generations:
         >
         > Notes about parameters to `csi config init`:
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
         > * By default, spine switches are used as MetalLB peers. Use `--bgp-peers aggregation` to use aggregation switches instead.
         > * Several parameters (`can-gateway`, `can-cidr`, `can-static-pool`, `can-dynamic-pool`) describe the CAN (Customer Access network). The `can-gateway` is the common gateway
         > IP address used for both spine switches and commonly referred to as the Virtual IP address for the CAN. The `can-cidr` is the IP subnet for the CAN assigned to this system.
         > The `can-static-pool` and `can-dynamic-pool` are the MetalLB address static and dynamic pools for the CAN. The `can-external-dns` is the static IP address assigned to the DNS
         > instance running in the cluster to which requests the cluster subdomain will be forwarded. The `can-external-dns` IP address must be within the `can-static-pool` range.
         > * Set `ntp-pools` to reachable NTP pools
         >
         > **Note:** These warnings from `csi config init` for issues in `hmn_connections.json` can be ignored.
         >
         > * The node with the external connection (`ncn-m001`) will have a warning similar to this because its BMC is connected to the site and not the HMN like the other
         >    management NCNs. It can be ignored.
         >
         >    ```text
         >    "Couldn't find switch port for NCN: x3000c0s1b0"
         >    ```
         >
         > * An unexpected component may have this message. If this component is an application node with an unusual prefix, it should be added to the `application_node_config.yaml`
         >    file. Then rerun `csi config init`. See the procedure to [Create Application Node Config YAML](create_application_node_config_yaml.md)
         >
         >   ```json
         >   {"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":
         >   {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
         >   ```
         >
         > * If a cooling door is found in `hmn_connections.json`, there may be a message like the following. It can be safely ignored.
         >
         >   ```json
         >   {"level":"warn","ts":1612552159.2962296,"msg":"Cooling door found, but xname does not yet exist for cooling doors!","row":
         >   {"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}}
         >   ```

      1. Link the generated `system_config.yaml` file into the `prep/` directory. This is needed for `pit-init` to find and resolve the file.

         > **`NOTE`** This step is needed only for fresh installs where `system_config.yaml` is missing from the `prep/` directory.

         ```bash
         pit# cd ${PITDATA}/prep && ln ${SYSTEM_NAME}/system_config.yaml
         ```

      1. Continue with the next step to apply the csi-config workarounds.

1. <a name="csi-workarounds"></a>CSI Workarounds

   Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `csi-config` breakpoint.

1. Copy the interface configuration files generated earlier by `csi config init`
   into `/etc/sysconfig/network/` with the first option **or** use the provided scripts in the second option below.

   * Option 1: Copy PIT files.

      ```bash
      pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/pit-files/* /etc/sysconfig/network/
      pit# wicked ifreload all
      pit# systemctl restart wickedd-nanny && sleep 5
      ```

   * Option 2: Set up `dnsmasq` by hand.

      ```bash
      pit# /root/bin/csi-setup-vlan002.sh $nmn_cidr
      pit# /root/bin/csi-setup-vlan004.sh $hmn_cidr
      pit# /root/bin/csi-setup-vlan007.sh $can_cidr
      ```

1. Check that IP addresses are set for each interface and investigate any failures.

    1. Check IP addresses. Do not run tests if these are missing and instead triage the issue.

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

    2. Run tests, inspect failures.

       ```bash
       pit# csi pit validate --network
       ```

1. Copy the service configuration files generated earlier by `csi config init` for `dnsmasq`, Metal
   Basecamp (`cloud-init`), and ConMan.

    1. Copy files (files only, `-r` is expressly not used).

        ```bash
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/dnsmasq.d/* /etc/dnsmasq.d/
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/conman.conf /etc/conman.conf
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/basecamp/* /var/www/ephemeral/configs/
        ```

    2. Enable, and fully restart all PIT services.

        ```bash
        pit# systemctl enable basecamp nexus dnsmasq conman
        pit# systemctl stop basecamp nexus dnsmasq conman
        pit# systemctl start basecamp nexus dnsmasq conman
        ```

1. Start and configure NTP on the LiveCD for a fallback/recovery server.

   ```bash
   pit# /root/bin/configure-ntp.sh
   ```

1. Check that our services are ready and investigate any test failures.

   ```bash
   pit# csi pit validate --services
   ```

1. Mount a shim to match the `SHASTA-CFG` steps' directory structure.

    ```bash
    pit# mkdir -vp /mnt/pitdata
    pit# mount -v -L PITDATA /mnt/pitdata
    ```

1. The following procedure will set up customized CA certificates for deployment using `SHASTA-CFG`.

   * [Prepare `site-init`](prepare_site_init.md) to create and prepare the `site-init` directory for your system.

<a name="next-topic"></a>

## Next topic

After completing this procedure, the next step is to configure the management network switches.

See [Configure Management Network Switches](index.md#configure_management_network)
