# Pre-Installation

The page walks a user through setting up the Cray LiveCD with the intention of installing Cray System Management (CSM).

1. [Boot installation environment](#1-boot-installation-environment)
    1. [Prepare installation environment server](#11-prepare-installation-environment-server)
    1. [Boot the LiveCD](#12-boot-the-livecd)
    1. [First log in](#13-first-log-in)
    1. [Prepare the data partition](#14-prepare-the-data-partition)
    1. [Set reusable environment variables](#15-set-reusable-environment-variables)
    1. [Exit the console and log in with SSH](#16-exit-the-console-and-log-in-with-ssh)
1. [Import CSM tarball](#2-import-csm-tarball)
    1. [Download CSM tarball](#21-download-csm-tarball)
    1. [Import tarball assets](#22-import-tarball-assets)
1. [Create system configuration](#3-create-system-configuration)
    1. [Validate SHCD](#31-validate-shcd)
    1. [Generate topology files](#32-generate-topology-files)
    1. [Customize `system_config.yaml`](#33-customize-system_configyaml)
    1. [Run CSI](#34-run-csi)
    1. [Prepare Site Init](#35-prepare-site-init)
    1. [Initialize the LiveCD](#36-initialize-the-livecd)
1. [Next topic](#next-topic)

## 1. Boot installation environment

This section walks the user through booting and connecting to the LiveCD.

Before proceeding, the user must obtain the CSM tarball containing the LiveCD.

> **NOTE:** Each step denotes where its commands must run; `external#` refers to a server that is **not** the CRAY, whereas `pit#` refers to the LiveCD itself.

Any steps run on an `external` server require that server to have the following tools:

- `ipmitool`
- `ssh`
- `tar`

> **NOTE:** The CSM tarball will be fetched from the external server in the [Import tarball assets](#22-import-tarball-assets) step using `curl` or `scp`. If a web server is not installed, then `scp` is the backup option.

### 1.1 Prepare installation environment server

**`TODO: Manually validate the m001 firmware, UEFI settings, and cabling`**

1. (`external#`) Download the CSM software release from the public Artifactory instance.

   > **NOTES:**
   >
   > - `-C -` is used to allow partial downloads. These tarballs are large; in the event of a connection disruption, the same `curl` command can be used to continue the disrupted download.
   > - **If air-gapped or behind a strict firewall**, then the tarball must be obtained from the medium delivered by Cray-HPE. For these cases, copy or download the tarball to the working
   >   directory and then proceed to the next step. The tarball will need to be fetched with `scp` during the [Download CSM tarball](#21-download-csm-tarball) step.

   ```bash
   # e.g. an alpha : CSM_RELEASE=1.3.0-alpha.99
   # e.g. an RC    : CSM_RELEASE=1.3.0-rc.1
   # e.g. a stable : CSM_RELEASE=1.3.0  
   CSM_RELEASE=1.3.0-alpha.9
   ```

   ```bash
   curl -C - -O "https://artifactory.algol60.net/artifactory/csm-releases/csm/$(awk -F. '{print $1"."$2}' <<< ${CSM_RELEASE})/csm-${CSM_RELEASE}.tar.gz"
   ```

1. (`external#`) Extract the LiveCD from the tarball.

   ```bash
   tar --wildcards --no-anchored -xzvf "csm-${CSM_RELEASE}.tar.gz" 'cray-pre-install-toolkit-*.iso'
   ```

### 1.2 Boot the LiveCD

1. (`external#`) Start a typescript and set the `PS1` variable to record timestamps.

   > **NOTE:** Typescripts help triage if problems are encountered.

   ```bash
   script -a "boot.livecd.$(date +%Y-%m-%d).txt"
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. (`external#`) Follow one of the procedures below based on the vendor for the `ncn-m001` node:

   - **HPE iLO BMCs**

      Prepare a server on the network to host the `cray-pre-install-toolkit` ISO file, if the current server is insufficient.
      Then follow the [HPE iLO BMCs](livecd/Boot_LiveCD_RemoteISO.md#hpe-ilo-bmcs) to boot the RemoteISO before returning here.

   - **Gigabyte BMCs** and **Intel BMCs**

      Create a USB stick using the following procedure.

      1. (`external#`) Get `cray-site-init` from the tarball.

         ```bash
         tar --wildcards --no-anchored -xzvf "csm-${CSM_RELEASE}.tar.gz" 'cray-site-init-*.rpm'
         ```

      1. (`external#`) Install the `write-livecd.sh` script:

         - RPM-based systems:

            ```bash
            rpm -Uvh --force cray-site-init*.rpm
            ```

         - Non-RPM-based systems (requires `bsdtar`):

            ```bash
            bsdtar xvf cray-site-init-*.rpm --include *write-livecd.sh -C ./
            mv -v ./usr/local/bin/write-livecd.sh ./
            rmdir -pv ./usr/local/bin/
            ```

         - Non-RPM Based Distros (requires `rpm2cpio`):

            ```bash
            rpm2cpio cray-site-init-*.rpm | cpio -idmv
            mv -v ./usr/local/bin/write-livecd.sh ./
            rm -vrf ./usr
            ```

      1. Follow [Bootstrap a LiveCD USB](livecd/Boot_LiveCD_USB.md) and then return here.

### 1.3 First login

On first login, the LiveCD will prompt the administrator to change the password.

1. (`pit#`) Log in.

   > **NOTE:** The initial password is empty.

   At the login prompt, enter `root` as the username. Because the initial password is blank,
   press return twice at the first two password prompts. The LiveCD will force a new password to be set.

   ```text
   Password:           <-------just press Enter here for a blank password
   You are required to change your password immediately (administrator enforced)
   Changing password for root.
   Current password:   <------- press Enter here, again, for a blank password
   New password:       <------- type new password
   Retype new password:<------- retype new password
   Welcome to the CRAY Pre-Install Toolkit (LiveOS)
   ```

1. (`pit#`) Configure the site-link (`lan0`), DNS, and gateway IP addresses.

   1. Set `site_ip`, `site_gw`, and `site_dns` variables.

      > **NOTE:** The `site_ip`, `site_gw`, and `site_dns` values must come from the local network administration or authority.

      ```bash
      # CIDR Format: A.B.C.D/N
      site_ip=
      ```

      ```bash
      # IPv4 Format: A.B.C.D
      site_gw=
      ```

      ```bash
      # IPv4 Format: A.B.C.D
      site_dns=
      ```

   1. Set `site_nics` variable.

      > **NOTE:** The `site_nics` value or values are found while the user is in the LiveCD (for example, `site_nics='p2p1 p2p2 p2p3'` or `site_nics=em1`).

      ```bash
      # Device Name: pXpY or emX (e.g. common values are p2p1, p801p1, or em1)
      site_nics=
      ```

   1. (`pit#`) Run the `csi-setup-lan0.sh` script to set up the site link and set the hostname.

      > **NOTES:**
      >
      > - All of the `/root/bin/csi-*` scripts can be run without parameters to display usage statements.
      > - The hostname is auto-resolved based on reverse DNS, if it is unresolvable then the user can set the hostname with:
      >
      >    ```bash
      >    hostname=eniac-ncn-m001
      >    hostamectl set-hostname "${hostname}-pit" 
      >    ```

      ```bash
      /root/bin/csi-setup-lan0.sh "$site_ip" "$site_gw" "$site_dns" "$site_nics"
      ```

1. (`pit#`) Verify that the assigned IP address was successfully applied to `lan0` .

   ```bash
   wicked ifstatus --verbose lan0
   ```

   > **NOTE:** The output from the above command must say `leases:   ipv4 static granted`.
   > If the IPv4 address was not granted, then go back and recheck the variable values. The
   > output will indicate the IP address failed to assign, which can happen if the given IP address
   > is already taken on the connected network.

### 1.4 Prepare the data partition

1. (`pit#`) Mount the `PITDATA` partition.

   Use either the **RemoteISO** or the **USB** option below, depending how the LiveCD was connected in the [Boot the LiveCD](#12-boot-the-livecd) step.

   - **RemoteISO**

      Use a local disk for `PITDATA`:

      ```bash
      disk="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print $2}' | head -n 1 | tr -d '\n')"
      echo $disk
      parted --wipesignatures -m --align=opt --ignore-busy -s /dev/$disk -- mklabel gpt mkpart primary ext4 2048s 100%
      mkfs.ext4 -L PITDATA "/dev/${disk}1"
      mount -vL PITDATA
      ```

   - **USB**

      Mount the USB data partition:

      ```bash
      mount -vL PITDATA
      ```

### 1.5 Set reusable environment variables

These variables will need to be set for many procedures within the CSM installation process.

> **NOTE:** This sets some variables that were already set. These should be set again anyway.

1. (`pit#`) Set the variables.

   1. Set the `PITDATA` variable.

      ```bash
      export PITDATA="$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)"
      ```

   1. Set the `CSM_RELEASE` variable.

      The value is based on the version of the CSM release being installed.

      ```bash
      # e.g. an alpha : CSM_RELEASE=1.3.0-alpha.99
      # e.g. an RC    : CSM_RELEASE=1.3.0-rc.1
      # e.g. a stable : CSM_RELEASE=1.3.0  
      export CSM_RELEASE=<value>
      ```

   1. Set the `CSM_PATH` variable.

      After the CSM release tarball has been expanded, this will be the path to its base directory.

      ```bash
      export CSM_PATH="${PITDATA}/csm-${CSM_RELEASE}"
      ```

   1. Set the `SYSTEM_NAME` variable.

      This is the user friendly name for the system. For example, for `eniac-ncn-m001`, `SYSTEM_NAME` should be set to `eniac`.

      ```bash
      export SYSTEM_NAME=<eniac>
      ```

1. (`pit#`) Set `/etc/environment`.

   This ensures that these variables will be set in all future shells on the PIT node.

   ```bash
   cat << EOF >/etc/environment
   CSM_RELEASE=${CSM_RELEASE}
   CSM_PATH=${PITDATA}/csm-${CSM_RELEASE} 
   GOSS_BASE=${GOSS_BASE}
   PITDATA=${PITDATA}
   SYSTEM_NAME=${SYSTEM_NAME}
   EOF
   ```

### 1.6 Exit the console and log in with SSH

1. (`pit#`) Create the `admin` directory and logout.

   ```bash
   mkdir -pv "$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)/admin"
   logout
   ```

1. (`pit#`) Exit the typescript

   ```bash
   exit
   ```

1. (`pit#`) Exit the console.

   This is done by typing the key-sequence: tilde, period. That is, `~.`

   If the console was accessed over an SSH session (that is, the user used SSH to log into another server, and from there used `ipmitool` to access the console),
   then press tilde **twice** followed by a period, in order to prevent exiting the parent SSH session. That is, `~~.`

1. (`external#`) Copy the typescript to the running LiveCD.

   ```bash
   scp boot.livecd.*.txt root@eniac-ncn-m001:/tmp/
   ```

1. (`pit#`) SSH into the LiveCD.

   ```bash
   livecd=eniac-ncn-m001.example.company.com
   ssh root@$livecd
   ```

1. (`pit#`) Copy the previous typescript and start a new one.

   ```bash
   cd "${PITDATA}/admin"
   cp -pv /tmp/boot.livecd.*.txt ./
   script -af ~/csm-install.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. (`pit#`) Print information about the booted PIT image for logging purposes.

   Having this information in the typescript can be helpful if problems are encountered during the install.

   ```bash
   /root/bin/metalid.sh
   ```

   > Expected output looks similar to the following (the versions in the example below may differ). There should be **no** errors.
   >
   > ```text
   > = PIT Identification = COPY/CUT START =======================================
   > VERSION=1.6.0
   > TIMESTAMP=20220504161044
   > HASH=g10e2532
   > 2022/05/04 17:08:19 Using config file: /var/www/ephemeral/prep/system_config.yaml
   > CRAY-Site-Init build signature...
   > Build Commit   : 0915d59f8292cfebe6b95dcba81b412a08e52ddf-main
   > Build Time     : 2022-05-02T20:21:46Z
   > Go Version     : go1.16.10
   > Git Version    : v1.9.13-29-g0915d59f
   > Platform       : linux/amd64
   > App. Version   : 1.17.1
   > metal-ipxe-2.2.6-1.noarch
   > metal-net-scripts-0.0.2-20210722171131_880ba18.noarch
   > metal-basecamp-1.1.12-1.x86_64
   > pit-init-1.2.20-1.noarch
   > pit-nexus-1.1.4-1.x86_64
   > = PIT Identification = COPY/CUT END =========================================
   > ```

## 2. Import CSM tarball

### 2.1 Download CSM tarball

1. (`pit#`) Download the CSM tarball

   - From Cray using `curl`:

      > - `-C -` is used to allow partial downloads. These tarballs are large; in the event of a connection disruption, the same `curl` command can be used to continue the disrupted download.

      ```bash
      curl -C - -o /var/www/ephemeral/csm-${CSM_RELEASE}.tar.gz "https://artifactory.algol60.net/artifactory/csm-releases/csm/$(awk -F. '{print $1"."$2}' <<< ${CSM_RELEASE})/csm-${CSM_RELEASE}.tar.gz"
      ```

   - `scp` from the external server used in [Prepare installation environment server](#11-prepare-installation-environment-server):

      ```bash
      scp "<external-server>:/<path>/csm-${CSM_RELEASE}.tar.gz" /var/www/ephemeral/
      ```

### 2.2 Import tarball assets

If resuming at this stage, the `CSM_RELEASE` and `PITDATA` variables are already set
in `/etc/environment` from the [Download CSM tarball](#21-download-csm-tarball) step.

1. (`pit#`) Extract the tarball.

   ```text
   tar -C "${PITDATA}" -zxvf "csm-${CSM_RELEASE}.tar.gz"
   ```

1. (`pit#`) Copy the NCN images from the expanded tarball.

   ```bash
   rsync -a -P --delete "${CSM_PATH}/images/kubernetes/" "${PITDATA}/data/k8s/"
   rsync -a -P --delete "${CSM_PATH}/images/storage-ceph/" "${PITDATA}/data/ceph/"
   ```

1. (`pit#`) Install or update `cray-site-init`, `csm-testing`, and `goss-servers` RPMs.

   > **NOTE:** `--no-gpg-checks` is used because the repository contained within the tarball does not provide a GPG key.

   ```bash
   zypper \
      --plus-repo "${CSM_PATH}/rpm/cray/csm/sle-15sp2/" \
      --plus-repo "${CSM_PATH}/rpm/cray/csm/sle-15sp3/" \
      --no-gpg-checks \
      update -y cray-site-init
   zypper \
      --plus-repo "${CSM_PATH}/rpm/cray/csm/sle-15sp2/" \
      --plus-repo "${CSM_PATH}/rpm/cray/csm/sle-15sp3/" \
      --no-gpg-checks \
      install -y csm-testing goss-servers
   ```

1. (`pit#`) Log the currently installed PIT packages.

   Having this information in the typescript can be helpful if problems are encountered during the install.
   This command was run once in a previous step -- running it again now is intentional.

   ```bash
   /root/bin/metalid.sh
   ```

   > Expected output looks similar to the following (the versions in the example below may differ). There should be **no** errors.
   >
   > ```text
   > = PIT Identification = COPY/CUT START =======================================
   > VERSION=1.6.0
   > TIMESTAMP=20220504161044
   > HASH=g10e2532
   > 2022/05/04 17:08:19 Using config file: /var/www/ephemeral/prep/system_config.yaml
   > CRAY-Site-Init build signature...
   > Build Commit   : 0915d59f8292cfebe6b95dcba81b412a08e52ddf-main
   > Build Time     : 2022-05-02T20:21:46Z
   > Go Version     : go1.16.10
   > Git Version    : v1.9.13-29-g0915d59f
   > Platform       : linux/amd64
   > App. Version   : 1.17.1
   > metal-ipxe-2.2.6-1.noarch
   > metal-net-scripts-0.0.2-20210722171131_880ba18.noarch
   > metal-basecamp-1.1.12-1.x86_64
   > pit-init-1.2.20-1.noarch
   > pit-nexus-1.1.4-1.x86_64
   > = PIT Identification = COPY/CUT END =========================================
   > ```

## 3. Create system configuration

This stage walks the user through creating the configuration payload for the system.

Run the following steps before starting any of the system configuration procedures.

1. (`pit#`) Make the `prep` directory.

   ```bash
   mkdir -pv "${PITDATA}/prep"
   ```

1. (`pit#`) Change into the `prep` directory.

   ```bash
   cd "${PITDATA}/prep"
   ```

### 3.1 Validate SHCD

1. (`pit#`) Download the SHCD to the `prep` directory.

   This will need to be retrieved from the administrators Cray deliverable.

1. Validate the SHCD.

   See [Validate SHCD](../operations/network/management_network/validate_shcd.md) and then return to this page.

### 3.2 Generate topology files

1. (`pit#`) Generate `hmn_connections.json`.

   ```bash
   csi config shcd "$SYSTEM_NAME-hmn-paddle.json" -H
   ```

1. (`pit#`) Create `application_node_config.yaml`, `ncn_metadata.csv`, and `switch_metadata.csv`.

    ```bash
    csi config shcd "${SYSTEM_NAME}-full-paddle.json" -ANS
    ```

1. Create the `cabinents.yaml` file.

   > If using this file, then do not forget to set the `cabinets-yaml` field in the
   > [Customize `system_config.yaml`](#33-customize-system_configyaml) step.

   See [Create `cabinets.yaml`](./create_cabinets_yaml.md).

1. Fill in the `ncn_metadata.csv` placeholder values with the actual values.

   > **NOTE:** If a previous `ncn_metadata.csv` file is available, simply copy it into place by overriding the generated one.

   See [Collect MAC Addresses for NCNs](./collect_mac_addresses_for_ncns.md).

### 3.3 Customize `system_config.yaml`

1. (`pit#`) Create or copy `system_config.yaml`.

   - If one does not exist from a prior installation, then create an empty one:

      ```bash
      csi config init empty
      ```

   - Otherwise, copy the existing `system_config.yaml` file into the working directory and proceed to the [Run CSI](#34-run-csi) step.

1. (`pit#`) Edit the `system_config.yaml` file with the appropriate values.

   > **NOTES:**
   >
   > - For a short description of each key in the file, run `csi config init --help`.
   > - For more description of these settings and the default values, see
   >   [Default IP Address Ranges](../introduction/csm_overview.md#2-default-ip-address-ranges) and the other topics in
   >   [CSM Overview](../introduction/csm_overview.md).
   > - If the system is using a `cabinets.yaml` file, be sure to update the `cabinets-yaml` field with `'cabinets.yaml'` as its value.

   ```bash
   vim system_config.yaml
   ```

### 3.4 Run CSI

1. (`pit#`) Generate the initial configuration for CSI.

   This will validate whether the inputs for CSI are correct.

   ```bash
   csi config init
   ```

### 3.5 Prepare Site Init

Follow the [Prepare Site Init](prepare_site_init.md) procedure.

### 3.6 Initialize the LiveCD

> **NOTE:** If starting an installation at this point, then be sure to copy the previous `prep` directory back onto the system.

1. (`pit#`) Initialize the PIT.

   The `pit-init.sh` script will prepare the PIT server for deploying NCNs.

   ```bash
   /root/bin/pit-init.sh
   ```

1. (`pit#`) Set the `IPMI_PASSWORD` variable.

   ```bash
   read -s IPMI_PASSWORD
   ```

1. (`pit#`) Export the `IPMI_PASSWORD` variable.

   ```bash
   export IPMI_PASSWORD
   ```

1. (`pit#`) Setup boot links to the artifacts extracted from the CSM tarball.

   > **NOTES:**
   >
   > - This will also set all the BMCs to DHCP.
   > - Changing into the `$HOME` directory ensures the proper operation of the script.

   ```bash
   cd $HOME && /root/bin/set-sqfs-links.sh
   ```

1. (`pit#`) Verify that the LiveCD is ready by running the preflight tests.

   ```bash
   csi pit validate --livecd-preflight
   ```

   If any tests fail, they need to be investigated. After actions have been taken to rectify the tests
   (for example, editing configuration or CSI inputs), then restart from the beginning of the
   [Initialize the LiveCD](#36-initialize-the-livecd) procedure.

1. Save the `prep` directory for re-use.

   This needs to be copied off the system and either stored in a secure location or in a secured Git repository.
   There are secrets in this directory that should not be accidentally exposed.

1. (`pit#`) Exit the typescript.

   ```bash
   exit
   ```

## Next topic

After completing this procedure, proceed to configure the management network switches.

See [Configure management network switches](README.md#5-configure-management-network-switches).
