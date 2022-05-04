# Pre-Installation

The page will walk a user through setting up the Cray LiveCD with the intention of installing Cray System Management (CSM).

## Topics

1. [Boot Installation Environment](#1-boot-installation-environment)
   * [Prepare Installation Environment Server](#prepare-installation-environment-server)
   * [Boot the LiveCD](#boot-the-livecd)
   * [First Login](#first-login)
   * [Prepare the Data Partition](#prepare-the-data-partition)
   * [Set Reusable Environment Variables](#set-reusable-environment-variables)
   * [Exit the Console and Login with SSH](#exit-the-console-and-login-with-ssh)
1. [Import CSM Tarball](#2-import-csm-tarball)
   * [Download CSM Tarball](#download-csm-tarball)
   * [Import Tarball Assets](#import-tarball-assets)
1. [Create System Configuration](#3-create-system-configuration)
   * [Validate SHCD](#validate-shcd)
   * [Generate Topology Files](#generate-topology-files)
   * [Customize `system_config.yaml`](#customize-system_configyaml)
   * [Run CSI](#run-csi)
   * [Shasta CFG](#shasta-cfg)
   * [Initialize the LiveCD](#initialize-the-livecd)
1. [Next Topic](#next-topic)

# 1. Boot Installation Environment

This section will walk the user through booting and connecting to the LiveCD.

Before proceeding the user must obtain the CSM tarball containing the LiveCD.

> **`NOTE`** Each step denotes where its command(s) must run; `external#` refers to a server that is _not_ the CRAY, whereas `pit#` refers to the LiveCD itself. 

Any steps that require the use of an `external` server require that server to have the following tools:

- `ipmitool`
- `ssh`
- `tar`

> **`NOTE`** The CSM tarball will be fetched from the external server in the [import tarball assets](#import-tarball-assets) step using `curl` or `scp`. If a web server is not installed then `scp` is the backup option.

## Prepare Installation Environment Server

**`TODO: Manually validate the m001 firmware, UEFI settings, and cabling`**

1. (`external#`) Download the CSM software release from the public artifactory instance.

   ```bash
   # e.g. an alpha : CSM_RELEASE=1.3.0-alpha.99
   # e.g. an RC    : CSM_RELEASE=1.3.0-rc.1
   # e.g. a stable : CSM_RELEASE=1.3.0  
   CSM_RELEASE=1.3.0-alpha.4
   curl -C - -O "https://artifactory.algol60.net/artifactory/releases/csm/$(awk -F. '{print $1"."$2}' <<< ${CSM_RELEASE})/csm-${CSM_RELEASE}.tar.gz"
   ```

   > **`NOTE`** For users that are in an **air gap or behind a strict firewall**, the tarball will have to be obtained from the medium delivered by Cray-HPE. For these cases, please copy/download the tarball to the working directory and then proceed to the next step. The tarball will need to be fetched with `scp` during the [download CSM tarball](#download-csm-tarball) step.

1. (`external#`) Extract the LiveCD from the tarball.

   ```bash
   tar --wildcards --no-anchored -xzvf "csm-${CSM_RELEASE}.tar.gz" 'cray-pre-install-toolkit-*.iso'
   ```

1. The LiveCD is now extracted and the user may proceed to [boot the LiveCD](#boot-the-livecd).

### Boot the LiveCD

1. (`external#`) Start a typescript and set the PS1 to record timestamps.

   > **`NOTE`** Typescripts help triage if/when a user becomes stuck and requires assistance.

   ```bash
   script -a "boot.livecd.$(date +%Y-%m-%d).txt"
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. (`external#`) Follow one of the respective procedures below based on the vendor for the ncn-m001 node:

   - **HPE iLO BMCs**

      Prepare a server on the network to host the `cray-pre-install-toolkit` ISO file if the current server is insufficient.
      Then follow the [HPE iLO BMCs](livecd/Boot_LiveCD_RemoteISO.md#hpe-ilo-bmcs) to boot the RemoteISO before returning here.

   - **Gigabyte BMCs** and **Intel BMCs** must create a USB stick

      1. (`external#`) Get Cray-Site-Init from the Tarball and install it:

         ```bash
         tar --wildcards --no-anchored -xzvf "csm-${CSM_RELEASE}.tar.gz" 'cray-site-init-*.rpm'
         ```

      1. (`external#`) Install the `write-livecd.sh` script:

         - RPM Based Distros:

            ```bash
            rpm -Uvh cray-site-init*.rpm
            ```

         - Non-RPM Based Distros (requires `bsdtar`):         

            ```bash                                                                    
            bsdtar xvf cray-site-init-*.rpm --include *write-livecd.sh -C ./           
            mv ./usr/local/bin/write-livecd.sh ./                                      
            rmdir -p ./usr/local/bin/                                                  
            ```      

         - Non-RPM Based Distros (requires `rpm2cpio`):

            ```bash
            rpm2cpio cray-site-init-*.rpm | cpio -idmv
            mv ./usr/local/bin/write-livecd.sh ./                                      
            rm -rf ./usr
            ```

      1. Follow [Bootstrap a LiveCD USB](livecd/Boot_LiveCD_USB.md) and then return here.

1. The user may proceed to [first login](#first-login).

## First Login

On first login the LiveCD will prompt the administrator to change the password.

1. (`pit#`) At the login prompt type in `root` as the username and press return twice. The LiveCD will force the user to set a new password. 

   > **`NOTE`** **The initial password is empty**, pressing return the second time inputs an empty password.

   ```text
   pit login: root
   Password:
   ```

   > Expected output looks similar to the following:
   > 
   > ```text
   > Password:           <-------just press Enter here for a blank password
   > You are required to change your password immediately (administrator enforced)
   > Changing password for root.
   > Current password:   <------- press Enter here, again, for a blank password
   > New password:       <------- type new password
   > Retype new password:<------- retype new password
   > Welcome to the CRAY Pre-Install Toolkit (LiveOS)
   > ```

1. (`pit#`) Configure the site-link (`lan0`) static IP, DNS, and gateway.

   1. Set `site_ip`, `site_gw`, and `site_dns`:

      > **`NOTE`** The `site_ip`, `site_gw`, and `site_dns` values must come from the local network administration or authority.

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

   1. Set `site_nics`

      > **`NOTE`** The `site_nics` value(s) are found while the user is in the LiveCD (for example, `site_nics='p2p1 p2p2 p2p3'` or `site_nics=em1`).

      ```bash
      # Device Name: pXpY or emX (e.g. common values are p2p1, p801p1, or em1)
      site_nics=
      ```

   1. (`pit#`) Run the `csi-setup-lan0.sh` script to set up the site link and set the hostname.

      > **`NOTE`** All of the `/root/bin/csi-*` scripts are harmless to run without parameters; doing so will print usage statements.
      > **`NOTE`** The hostname is auto-resolved based on reverse DNS, if it is unresolvable then the user can set the hostname with:
      > ```bash
      > hostname=eniac-ncn-m001
      > hostamectl set-hostname "${hostname}-pit" 
      > ```

      ```bash
      /root/bin/csi-setup-lan0.sh "$site_ip" "$site_gw" "$site_dns" "$site_nics"
      ```

1. (`pit#`) Verify that the assigned IP successfully applied on `lan0` 

   ```bash
   wicked ifstatus --verbose lan0
   ```

   > **`NOTE`** The output from the above command must say "`leases:   ipv4 static granted`", 
   > if the IPv4 address was not granted then go back and recheck the variable values. The 
   > output will indicate the IP failed to assign, which can happen if the given IP is already 
   > taken on the connected network.

1. Proceed to [prepare the data partition](#prepare-the-data-partition).

## Prepare the Data Partition

1. (`pit#`) Mount the `PITDATA` partition using the **RemoteISO** directions or the **USB** option below depending how the LiveCD was connected in the [boot the LiveCD](#boot-the-livecd) section.

   - **RemoteISO** directions for using a local disk for PITDATA:

      ```bash
      disk="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print $2}' | head -n 1 | tr -d '\n')"
      echo $disk
      parted --wipesignatures -m --align=opt --ignore-busy -s /dev/$disk -- mklabel gpt mkpart primary ext4 2048s 100%
      mkfs.ext4 -L PITDATA "/dev/${disk}1"
      mount -vL PITDATA
      ```

   - **USB** directions for mounting the USB data partition:

      ```bash
      mount -vL PITDATA
      ```

## Set Reusable Environment Variables

These variables will need to be set for various pages used within docs-csm installation.

> **`NOTE`** This portion sets some variables that were already set, these should be set again anyway
> to ensure that they're set properly when a user resumes or picks up a pre-installation.

1. (`pit#`) Set the variables in the following order

   1. `PITDATA`

      ```bash
      export PITDATA="$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)"
      ```

   1. `CSM_RELEASE`

      ```bash
      # e.g. an alpha : CSM_RELEASE=1.3.0-alpha.99
      # e.g. an RC    : CSM_RELEASE=1.3.0-rc.1
      # e.g. a stable : CSM_RELEASE=1.3.0  
      export CSM_RELEASE=<value>
      ```

   1. `CSM_PATH`

      ```bash
      export CSM_PATH="${PITDATA}/csm-${CSM_RELEASE}"
      ```

   1. `SYSTEM_NAME`

      ```bash
      # SYSTEM_NAME is equal to the user friendly name for the system, e.g. the system name for "eniac-ncn-m001" is "eniac"
      export SYSTEM_NAME=<eniac>
      ```

1. (`pit#`) Set `/etc/environment` (preserve `GOSS_SERVERS` and clear out all other variables):

   ```bash
   cat << EOF >/etc/environment
   CSM_RELEASE=${CSM_RELEASE}
   CSM_PATH=${PITDATA}/csm-${CSM_RELEASE} 
   GOSS_BASE=${GOSS_BASE}
   PITDATA=${PITDATA}
   SYSTEM_NAME=${SYSTEM_NAME}
   EOF
   ```

## Exit the Console and Login with SSH

1. (`pit#`) Create the admin directory and logout.

   ```bash
   mkdir -pv "$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)/admin"
   logout
   ```

1. (`pit#`) Exit the typescript

   ```bash
   exit
   ```

1. (`pit#`) Exit the console by typing the key-sequence: tilde, period (e.g. "`~.`").

   > **`NOTE`** If the console is running via a jump-box (e.g. the user used SSH to log into another server, and then used `ipmitool` from that server to connect to ncn-m001), then press tilde _twice_ followed by a period to prevent from exiting the parent SSH session (e.g. "`~~.`")

1. (`external#`) Copy the typescript to the running LiveCD.

   ```bash
   scp boot.livecd.*.txt root@eniac-ncn-m001:/tmp/
   ```

1. (`pit#`) SSH into the LiveCD. 

   ```bash  
   livecd=eniac-ncn-m001.example.company.com
   ssh root@$livecd
   ```

1. (`pit#`) Change to the `admin` directory, copy any typescripts from `/tmp`, and start a new typescript with a timestamped PS1.

   ```bash
   cd "${PITDATA}/admin"
   cp -pv /tmp/boot.livecd.*.txt ./
   script -af ~/csm-install.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. (`pit#`) Print information about the booted PIT image for logging purposes.

   ```bash
   /root/bin/metalid.sh
   ```

   > Expected output looks similar to the following (the versions in the example below may differ). There should be **no** errors. This output facilitates requests for triage if/when they are issued.
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

## 2. Import CSM Tarball

### Download CSM Tarball

1. (`pit#`) Download the CSM Tarball

   - From Cray using `curl`:

      ```bash
      # Use -C to handle partial downloads; if the download is interrupted then re-running this command will resume.
      curl -C - -o /var/www/ephemeral/csm-${CSM_RELEASE}.tar.gz "https://artifactory.algol60.net/artifactory/releases/csm/$(awk -F. '{print $1"."$2}' <<< ${CSM_RELEASE})/csm-${CSM_RELEASE}.tar.gz"
      ``` 

   - From the `external` server used in [prepare the installation environment server](#prepare-installation-environment-server):

      ```bash
      scp "<external-server>:/<path>/csm-${CSM_RELEASE}.tar.gz" /var/www/ephemeral/
      ```

### Import Tarball Assets

If the user is resuming at this stage, the `CSM_RELEASE` and `PITDATA` variables are already set
via `/etc/environment` from the [download CSM tarball](#download-csm-tarball) step.

1. (`pit#`) Extract the tarball.

   ```text
   tar -C "${PITDATA}" -zxvf "csm-${CSM_RELEASE}.tar.gz"
   ```

1. (`pit#`) Copy the NCN images into the web server.

   ```bash
   rsync -a -P --delete "${CSM_PATH}/images/kubernetes/" "${PITDATA}/data/k8s/"
   rsync -a -P --delete "${CSM_PATH}/images/storage-ceph/" "${PITDATA}/data/ceph/"
   ```

1. (`pit#`) Install/update cray-site-init, csm-testing, and goss-servers.

   > **`NOTE`** `--no-gpg-checks` is used because the repository contained within the tarball does not provide a GPG key.

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
      update -y csm-testing goss-servers
   ```

1. (`pit#`) Log the currently installed PIT packages

   ```bash
   /root/bin/metalid.sh
   ```

   > Expected output looks similar to the following (the versions in the example below may differ). There should be **no** errors. This output facilitates requests for triage if/when they are issued.
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

## 3. Create System Configuration

This stage will walk the user through creating the configuration payload for the system.

Run the following steps before starting any of the system configuration procedures.

1. (`pit#`) Make the prep directory

   ```bash
   mkdir -pv "${PITDATA}/prep"
   ```

1. (`pit#`) Change into the prep directory.

   ```bash
   cd "${PITDATA}/prep"
   ```

### Validate SHCD

1. (`pit#`) Download the SHCD to the `prep/` directory. This will need to be retrieved from the administrators CRAY deliverable.

1. See [validate SHCD](../operations/network/management_network/validate_shcd.md) and then return to this page.

### Generate Topology Files

1. (`pit#`) Generate `hmn_connections.json`.

   ```bash
   csi config shcd "$SYSTEM_NAME-hmn-paddle.json" -H
   ```

1. (`pit#`) Create `application_node_config.yaml`, `ncn_metadata.csv`, and `switch_metadata.csv`.

    ```bash
    csi config shcd "${SYSTEM_NAME}-full-paddle.json" -ANS
    ```

1. Create the `cabinents.yaml` file, see [Create `cabinets.yaml`](./create_cabinets_yaml.md).

   > **`NOTE`** This file will be automated through `csi`, at this time it is manually created.
   > If the system requires this file, update `system_config.yaml#cabinets-yaml` with 
   > `'cabinets.yaml'` as its value in 
   > [Customize `system_config.yaml`](#customize-system_configyaml).

1. Fill in the `ncn_metadata.csv` placeholder values with the actual values.

   > **`NOTE`** If a previous `ncn_metadata.csv` file is available, simply copy it into place by overriding the generated one.

   See [Collect MAC Addresses for NCNs](./collect_mac_addresses_for_ncns.md).

### Customize `system_config.yaml`

1. (`pit#`) Create an empty `system_config.yaml`, or if a `system_config.yaml` exists from a prior installation then copy it into the working directory and move onto [run CSI](#run-csi).

   ```bash
   csi config init empty
   ```

1. (`pit#`) Edit the `system_config.yaml` file with the appropriate values.

   > **`NOTE`**
   > - For a short description of each key in the file, run `csi config init --help`.
   > - For more description of these settings and the default values, see 
   > [Default IP Address Ranges](../introduction/csm_overview.md#2-default-ip-address-ranges) and the other topics in
   > [CSM Overview](../introduction/csm_overview.md).

   ```bash
   vim system_config.yaml
   ```

### Run CSI

1. (`pit#`) Generate the initial configuration for CSI, this will validate whether the inputs for CSI are correct.

   ```bash
   csi config init
   ```

### Shasta CFG

See [prepare site init](prepare_site_init.md) for creating a `site-init` directory, 
once `site-init` is created the user can resume at [initialize the LiveCD](#initialize-the-livecd).

### Initialize the LiveCD

> **`NOTE`** If the user is starting an installation at this point, the user must sync their old `prep` directory back onto the system.

1. (`pit#`) Initialize the PIT:

   The `pit-init.sh` script will prepare the PIT server for deploying NCNs.

   ```bash
   /root/bin/pit-init.sh
   ```

1. (`pit#`) Set `IPMI_PASSWORD`:

   ```bash
   read -s IPMI_PASSWORD
   ```

1. (`pit#`) Export `IPMI_PASSWORD` and run the validation:

   ```bash
   export IPMI_PASSWORD
   ```

1. (`pit#`) Setup boot links to the artifacts extracted from the CSM tarball.

   > **`NOTE`**
   > - This will also set all the BMCs to DHCP.
   > - Change into the `$HOME` directory to ensure `set-sqfs-links.sh` doesn't affect any `ncn` prefixed directories.

   ```bash
   cd $HOME
   /root/bin/set-sqfs-links.sh
   ```

1. (`pit#`) Verify the LiveCD is ready by running the preflight tests. If any tests fail they need
   to be investigated. After actions have been taken to rectify the tests
   (e.g. editing configuration or CSI inputs) restart
   [initialize the LiveCD](#initialize-the-livecd) at step 1.

   ```bash
   csi pit validate --livecd-preflight
   ```

1. Save the `prep` directory for re-use. This needs to be copied off the system and either stored in 
   a secure location or in a secured git repository. There are secrets in this directory that
   shouldn't be accidentally exposed.

1. (`pit#`) Exit the typescript.

   ```bash
   exit
   ```

## Next Topic

After completing this procedure, proceed to configure the management network switches.

See [Configure Management Network Switches](README.md#4-configure-management-network-switches).
