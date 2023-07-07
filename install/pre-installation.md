# Pre-Installation

The page walks a user through setting up the Cray LiveCD with the intention of installing Cray System Management (CSM).

1. [Boot installation environment](#1-boot-installation-environment)
    1. [Prepare installation environment server](#11-prepare-installation-environment-server)
    1. [Boot the LiveCD](#12-boot-the-livecd)
    1. [First log in](#13-first-log-in)
    1. [Prepare the data partition](#14-prepare-the-data-partition)
    1. [Set reusable environment variables](#15-set-reusable-environment-variables)
    1. [Exit the console and log in with SSH](#16-exit-the-console-and-log-in-with-ssh)
1. [Download and extract the CSM tarball](#2-download-and-extract-the-csm-tarball)
1. [Create system configuration](#3-create-system-configuration)
    1. [Validate SHCD](#31-validate-shcd)
    1. [Generate topology files](#32-generate-topology-files)
    1. [Customize `system_config.yaml`](#33-customize-system_configyaml)
    1. [Run CSI](#34-run-csi)
    1. [Prepare Site Init](#35-prepare-site-init)
    1. [Initialize the LiveCD](#36-initialize-the-livecd)
1. [Import the CSM Tarball](#4-import-the-csm-tarball)
1. [Validate the LiveCD](#5-validate-the-livecd)
1. [Next topic](#next-topic)

## 1. Boot installation environment

This section walks the user through booting and connecting to the LiveCD.

Before proceeding, the user must obtain the CSM tarball containing the LiveCD.

> **NOTE:** Each step denotes where its commands must run; `external#` refers to a server that is **not** the Cray, whereas `pit#` refers to the LiveCD itself.

Any steps run on an `external` server require that server to have the following tools:

- `ipmitool`
- `ssh`
- `tar`

> **NOTE:** The CSM tarball will be fetched from the external server in the [download and extract the CSM tarball](#2-download-and-extract-the-csm-tarball) step using `curl` or `scp`. If a web server is not installed, then `scp` is the backup option.

### 1.1 Prepare installation environment server

1. (`external#`) Download the CSM software release from the public Artifactory instance.

   > **NOTES:**
   >
   > - `-C -` is used to allow partial downloads. These tarballs are large; in the event of a connection disruption, the same `curl` command can be used to continue the disrupted download.
   > - **If air-gapped or behind a strict firewall**, then the tarball must be obtained from the medium delivered by Cray-HPE. For these cases, copy or download the tarball to the working
   >   directory and then proceed to the next step. The tarball will need to be fetched with `scp` during the [download and extract the CSM tarball](#2-download-and-extract-the-csm-tarball) step.

   1. (`external#`) Set the CSM RELEASE version

      > Example release versions:
      >
      > - An alpha build: `CSM_RELEASE=1.5.0-alpha.99`
      > - A release candidate: `CSM_RELEASE=1.5.0-rc.1`
      > - A stable release: `CSM_RELEASE=1.5.0`

      ```bash
      CSM_RELEASE=<value>
      ```

   1. (`external#`) Download the CSM tarball

      > ***NOTE:*** CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
      Using `http_proxy` or `https_proxy` in any way other than the following examples will cause many failures in subsequent steps.

      - Without proxy:

        ```bash
        curl -C - -f -O "https://release.algol60.net/$(awk -F. '{print "csm-"$1"."$2}' <<< ${CSM_RELEASE})/csm/csm-${CSM_RELEASE}.tar.gz"
        ```

      - With https proxy:

        ```bash
        https_proxy=https://example.proxy.net:443 curl -C - -f -O "https://release.algol60.net/$(awk -F. '{print "csm-"$1"."$2}' <<< ${CSM_RELEASE})/csm/csm-${CSM_RELEASE}.tar.gz"
        ```

1. (`external#`) Extract the LiveCD from the tarball.

   ```bash
   OUT_DIR="$(pwd)/csm-temp"
   mkdir -pv "${OUT_DIR}"
   tar -C "${OUT_DIR}" --wildcards --no-anchored --transform='s/.*\///' -xzvf "csm-${CSM_RELEASE}.tar.gz" 'pre-install-toolkit-*.iso'
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

      Prepare a server on the network to host the `pre-install-toolkit` ISO file, if the current server is insufficient.
      Then follow the [HPE iLO BMCs](livecd/Boot_LiveCD_RemoteISO.md#hpe-ilo-bmcs) to boot the RemoteISO before returning here.

   - **Gigabyte BMCs** and **Intel BMCs**

      Create a USB stick using the following procedure.

      1. (`external#`) Get `cray-site-init` from the tarball.

         ```bash
         OUT_DIR="$(pwd)/csm-temp"
         mkdir -pv "${OUT_DIR}"
         tar -C "${OUT_DIR}" --wildcards --no-anchored --transform='s/.*\///' -xzvf "csm-${CSM_RELEASE}.tar.gz" 'cray-site-init-*.rpm'
         ```

      1. (`external#`) Install the `write-livecd.sh` script:

         - RPM-based systems:

            ```bash
            rpm -Uvh --force ${OUT_DIR}/cray-site-init*.rpm
            ```

         - Non-RPM-based systems (requires `bsdtar`):

            ```bash
            bsdtar xvf "${OUT_DIR}"/cray-site-init-*.rpm --include *write-livecd.sh -C "${OUT_DIR}"
            mv -v "${OUT_DIR}"/usr/local/bin/write-livecd.sh "./${OUT_DIR}"
            rmdir -pv "${OUT_DIR}/usr/local/bin/"
            ```

         - Non-RPM-based distros (requires `rpm2cpio`):

            ```bash
            rpm2cpio cray-site-init-*.rpm | cpio -idmv
            mv -v ./usr/local/bin/write-livecd.sh "./${OUT_DIR}"
            rm -vrf ./usr
            ```

      1. Follow [Bootstrap a LiveCD USB](livecd/Boot_LiveCD_USB.md) and then return here.

### 1.3 First log in

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

   > **NOTE:** The `site_ip`, `site_gw`, and `site_dns` values must come from the local network administration or authority.

   1. Set `site_ip` variable.

      Set the `site_ip` value in CIDR format (`A.B.C.D/N`):

      ```bash
      site_ip=<IP CIDR>
      ```

   1. Set the `site_gw` and `site_dns` variables.

      Set the `site_gw` and `site_dns` values in IPv4 dotted decimal format (`A.B.C.D`):

      ```bash
      site_gw=<Gateway IP address>
      site_dns=<DNS IP address>
      ```

   1. Set the `site_nics` variable.

      The `site_nics` value or values are found while the user is in the LiveCD (for example, `site_nics='p2p1 p2p2 p2p3'` or `site_nics=em1`).

      ```bash
      site_nics='<site NIC or NICs>'
      ```

   1. Set the `SYSTEM_NAME` variable.

      `SYSTEM_NAME` is the name of the system. This will only be used for the PIT hostname.
      This variable is capitalized because it will be used in a subsequent section.

      ```bash
      SYSTEM_NAME=<system name>
      ```

   1. Run the `csi-setup-lan0.sh` script to set up the site link and set the hostname.

      > **NOTES:**
      >
      > - All of the `/root/bin/csi-*` scripts can be run without parameters to display usage statements.
      > - The hostname is auto-resolved based on reverse DNS.

      ```bash
      /root/bin/csi-setup-lan0.sh "${SYSTEM_NAME}" "${site_ip}" "${site_gw}" "${site_dns}" "${site_nics}"
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
      disk="$(lsblk -l -o SIZE,NAME,TYPE,TRAN -e7 -e11 -d -n | grep -v usb | sort -h | awk '{print $2}' | xargs -I {} bash -c "if ! grep -Fq {} /proc/mdstat; then echo {}; fi" | head -n 1)"
      echo "Using ${disk}"
      parted --wipesignatures -m --align=opt --ignore-busy -s "/dev/${disk}" -- mklabel gpt mkpart primary ext4 2048s 100%
      partprobe "/dev/${disk}"
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

      > Example release versions:
      >
      > - An alpha build: `CSM_RELEASE=1.5.0-alpha.99`
      > - A release candidate: `CSM_RELEASE=1.5.0-rc.1`
      > - A stable release: `CSM_RELEASE=1.5.0`

      ```bash
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
      export SYSTEM_NAME=<value>
      ```

1. (`pit#`) Update `/etc/environment`.

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

1. (`pit#`) Create the `admin` directory for the typescripts and administrative scratch work.

   ```bash
   mkdir -pv "$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)/prep/admin"
   ls -l "$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/PITDATA)/prep/admin"
   ```

1. (`pit#`) Exit the typescript and log out.

   ```bash
   exit
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
   ssh root@"${livecd}"
   ```

1. (`pit#`) Copy the previous typescript and start a new one.

   ```bash
   cp -pv /tmp/boot.livecd.*.txt "${PITDATA}/prep/admin"
   script -af "${PITDATA}/prep/admin/csm-install.$(date +%Y-%m-%d).txt"
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. (`pit#`) Print information about the booted PIT image for logging purposes.

   Having this information in the typescript can be helpful if problems are encountered during the install.

   ```bash
   /root/bin/metalid.sh
   ```

   Expected output looks similar to the following (the versions in the example below may differ). There should be **no** errors.

   ```text
   = PIT Identification = COPY/CUT START =======================================
   VERSION=1.6.0
   TIMESTAMP=20220504161044
   HASH=g10e2532
   2022/05/04 17:08:19 Using config file: /var/www/ephemeral/prep/system_config.yaml
   CRAY-Site-Init build signature...
   Build Commit   : 0915d59f8292cfebe6b95dcba81b412a08e52ddf-main
   Build Time     : 2022-05-02T20:21:46Z
   Go Version     : go1.16.10
   Git Version    : v1.9.13-29-g0915d59f
   Platform       : linux/amd64
   App. Version   : 1.17.1
   metal-ipxe-2.2.6-1.noarch
   metal-net-scripts-0.0.2-20210722171131_880ba18.noarch
   metal-basecamp-1.1.12-1.x86_64
   pit-init-1.2.20-1.noarch
   pit-nexus-1.1.4-1.x86_64
   = PIT Identification = COPY/CUT END =========================================
   ```

## 2. Download and extract the CSM Tarball

1. Download and install the latest documentation and scripts RPMs, see [Check for latest documentation](../update_product_stream/README.md#check-for-latest-documentation).

1. (`pit#`) Download the CSM tarball.

   - From Cray using `curl`:

      > - `-C -` is used to allow partial downloads. These tarballs are large; in the event of a connection disruption, the same `curl` command can be used to continue the disrupted download.
      > - CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints. Using `http_proxy` or `https_proxy` in any way other than the following examples will cause many failures in subsequent steps.

      Without proxy:

      ```bash
      curl -C - -f -o "/var/www/ephemeral/csm-${CSM_RELEASE}.tar.gz" \
        "https://release.algol60.net/$(awk -F. '{print "csm-"$1"."$2}' <<< ${CSM_RELEASE})/csm/csm-${CSM_RELEASE}.tar.gz"
      ```

      With HTTPS proxy:

      ```bash
      https_proxy=https://example.proxy.net:443 curl -C - -f -o "/var/www/ephemeral/csm-${CSM_RELEASE}.tar.gz" \
        "https://release.algol60.net/$(awk -F. '{print "csm-"$1"."$2}' <<< ${CSM_RELEASE})/csm/csm-${CSM_RELEASE}.tar.gz"
      ```

   - `scp` from the external server used in [Prepare installation environment server](#11-prepare-installation-environment-server):

      ```bash
      scp "<external-server>:/<path>/csm-${CSM_RELEASE}.tar.gz" /var/www/ephemeral/
      ```

1. (`pit#`) Extract the tarball.

   ```bash
   tar -zxvf  "${PITDATA}/csm-${CSM_RELEASE}.tar.gz" -C ${PITDATA}
   ```

1. (`pit#`) Install/update the RPMs necessary for the CSM installation.

   > ***NOTE*** `--no-gpg-checks` is used because the repository contained within the tarball does not provide a GPG key.

   1. Update `cray-site-init` and `pit-init`.

       > ***NOTES***
       >
       > - `cray-site-init` provides `csi`, a tool for creating and managing configurations, as well as
       >   orchestrating the [handoff and deploy of the final non-compute node](deploy_final_non-compute_node.md).
       > - `pit-init` provides several scripts in `/root/bin` used for fresh installations.

       ```bash
       zypper --plus-repo "${CSM_PATH}/rpm/cray/csm/noos" --no-gpg-checks update -y cray-site-init pit-init
       ```

1. (`pit#`) Get the artifact versions.

   ```bash
   KUBERNETES_VERSION="$(find ${CSM_PATH}/images/kubernetes -name '*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')"
   echo "${KUBERNETES_VERSION}"
   CEPH_VERSION="$(find ${CSM_PATH}/images/storage-ceph -name '*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')"
   echo "${CEPH_VERSION}"
   ```

1. (`pit#`) Copy the NCN images from the expanded tarball.

   > ***NOTE*** This hard-links the files to do this copy as fast as possible, as well as to mitigate space waste on the USB stick.

   ```bash
   mkdir -pv "${PITDATA}/data/k8s/" "${PITDATA}/data/ceph/"
   rsync -rltDP --delete "${CSM_PATH}/images/kubernetes/" --link-dest="${CSM_PATH}/images/kubernetes/" "${PITDATA}/data/k8s/${KUBERNETES_VERSION}"
   rsync -rltDP --delete "${CSM_PATH}/images/storage-ceph/" --link-dest="${CSM_PATH}/images/storage-ceph/" "${PITDATA}/data/ceph/${CEPH_VERSION}"
   ```

1. (`pit#`) Modify the NCN images with SSH keys and `root` passwords.

   The following substeps provide the most commonly used defaults for this process. For more advanced options, see
   [Set NCN Image Root Password, SSH Keys, and Timezone on PIT Node](../operations/security_and_authentication/Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md).

   1. Generate SSH keys.

       > ***NOTE*** The code block below assumes there is an RSA key without a passphrase. This step can be customized to use a passphrase if desired.

       ```bash
       ssh-keygen -N "" -t rsa
       ```

   1. Export the password hash for `root` that is needed for the `ncn-image-modification.sh` script.

       This will set the NCN `root` user password to be the same as the `root` user password on the PIT.

       ```bash
       export SQUASHFS_ROOT_PW_HASH="$(awk -F':' /^root:/'{print $2}' < /etc/shadow)"
       ```

   1. Inject these into the NCN images by running `ncn-image-modification.sh` from the CSM documentation RPM.

       ```bash
       NCN_MOD_SCRIPT=$(rpm -ql docs-csm | grep ncn-image-modification.sh)
       echo "${NCN_MOD_SCRIPT}"
       "${NCN_MOD_SCRIPT}" -p \
          -d /root/.ssh \
          -k "/var/www/ephemeral/data/k8s/${KUBERNETES_VERSION}/kubernetes-${KUBERNETES_VERSION}-$(uname -i).squashfs" \
          -s "/var/www/ephemeral/data/ceph/${CEPH_VERSION}/storage-ceph-${CEPH_VERSION}-$(uname -i).squashfs"
       ```

1. (`pit#`) Log the currently installed PIT packages.

   Having this information in the typescript can be helpful if problems are encountered during the install.
   This command was run once in a previous step -- running it again now is intentional.

   ```bash
   /root/bin/metalid.sh
   ```

   Expected output looks similar to the following (the versions in the example below may differ). There should be **no** errors.

   ```text
   = PIT Identification = COPY/CUT START =======================================
   VERSION=1.6.0
   TIMESTAMP=20220504161044
   HASH=g10e2532
   2022/05/04 17:08:19 Using config file: /var/www/ephemeral/prep/system_config.yaml
   CRAY-Site-Init build signature...
   Build Commit   : 0915d59f8292cfebe6b95dcba81b412a08e52ddf-main
   Build Time     : 2022-05-02T20:21:46Z
   Go Version     : go1.16.10
   Git Version    : v1.9.13-29-g0915d59f
   Platform       : linux/amd64
   App. Version   : 1.17.1
   metal-ipxe-2.2.6-1.noarch
   metal-net-scripts-0.0.2-20210722171131_880ba18.noarch
   metal-basecamp-1.1.12-1.x86_64
   pit-init-1.2.20-1.noarch
   pit-nexus-1.1.4-1.x86_64
   = PIT Identification = COPY/CUT END =========================================
   ```

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

    This will need to be retrieved from the administrator's Cray deliverable.

1. Validate the SHCD.

    See [Validate SHCD](../operations/network/management_network/validate_shcd.md) and then return to this page.

### 3.2 Generate topology files

The following steps use the new, automated method for generating files. The previous step for
[validate SHCD](#31-validate-shcd) generated "paddle" files; these are necessary for generating
the rest of the seed files.

> ***NOTE*** The paddle files are temporarily not used due to bugs in the seed file generation software.
> Until these bugs are resolved, the seed files must be manually generated.

If seed files from a prior installation of the same major-minor version of CSM exist, then these can be used and
this step may be skipped.

1. (`pit#`) Create each seed file, unless they already exist from a previous installation.

   - For new installations of CSM that have no prior seed files, each one must be created:

      - [Create `application_node_config.yaml`](create_application_node_config_yaml.md)
      - [Create `cabinets.yaml`](create_cabinets_yaml.md)
      - [Create `hmn_connections.json`](create_hmn_connections_json.md)
      - [Create `ncn_metadata.csv`](create_ncn_metadata_csv.md)
      - [Create `switch_metadata.csv`](create_switch_metadata_csv.md)

   - For re-installations of CSM 1.3, the previous seed files may be used and this step can be skipped.
   - For new installations of CSM 1.3 that have prior seed files from CSM 1.2 or older, the previous seed files
     may be used **except that the following files must be recreated** because of content or formatting changes:

      - [Create `cabinets.yaml`](create_cabinets_yaml.md)
      - [Create `hmn_connections.json`](create_hmn_connections_json.md)

1. (`pit#`) Confirm that the following files exist.

   ```bash
   ls -l "${PITDATA}"/prep/{application_node_config.yaml,cabinets.yaml,hmn_connections.json,ncn_metadata.csv,switch_metadata.csv}
   ```

   Expected output may look like:

   ```text
   -rw-r--r-- 1 root root  146 Jun  6 00:12 /var/www/ephemeral/prep/application_node_config.yaml
   -rw-r--r-- 1 root root  392 Jun  6 00:12 /var/www/ephemeral/prep/cabinets.yaml
   -rwxr-xr-x 1 root root 3768 Jun  6 00:12 /var/www/ephemeral/prep/hmn_connections.json
   -rw-r--r-- 1 root root 1216 Jun  6 00:12 /var/www/ephemeral/prep/ncn_metadata.csv
   -rw-r--r-- 1 root root  150 Jun  6 00:12 /var/www/ephemeral/prep/switch_metadata.csv
   ```

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
   > - To enable or disable audit logging, refer to [Audit Logs](../operations/security_and_authentication/Audit_Logs.md)
   >   for more information.
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
   read -r -s -p "NCN BMC root password: " IPMI_PASSWORD
   ```

1. (`pit#`) Export the `IPMI_PASSWORD` variable.

   ```bash
   export IPMI_PASSWORD
   ```

1. (`pit#`) Setup links to the boot artifacts extracted from the CSM tarball.

   > ***NOTES***
   >
   > - This will also set all the BMCs to DHCP.
   > - Changing into the `$HOME` directory ensures the proper operation of the script.

   ```bash
   cd $HOME && /root/bin/set-sqfs-links.sh
   ```

## 4 Import the CSM Tarball

The following steps require [create system configuration](#3-create-system-configuration) to have completed
successfully.

1. (`pit#`) Upload the CSM tarball's RPMs and container images to the local Nexus instance.

   ```bash
   /srv/cray/metal-provision/scripts/nexus/setup-nexus.sh -s
   ```

1. Add the local Zypper repositories for `noos` and the current SLES distribution.

   > ***NOTE*** The `${releasever_major}` and `${releasever_minor}` variables are interpolated by Zypper, the URI
   > is intentionally wrapped with single-quotes to prevent the shell from interpolating them. Zypper will replace
   > these variables with the currently running distributions major and minor version numbers.

   ```bash
   zypper addrepo --no-gpgcheck --refresh http://packages/repository/csm-noos csm-noos
   zypper addrepo --no-gpgcheck --refresh 'http://packages/repository/csm-sle-${releasever_major}sp${releasever_minor}' 'csm-sle'
   ```

1. (`pit#`) Ensure any new, updated packages pertinent to the CSM install are installed.

   > ***NOTES***
   >
   > - `csm-testing` package provides the necessary tests and their dependencies for validating the pre-installation, installation, and more.
   > - This provides `iuf`, a command line interface to the [Install and Upgrade Framework](../operations/iuf/IUF.md).

   ```bash
   zypper --no-gpg-checks install -y canu craycli csm-testing iuf-cli
   ```

## 5 Validate the LiveCD

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

## Next topic

After completing this procedure, proceed to configure the management network switches.

See [Configure management network switches](csm-install/README.md#5-configure-management-network-switches).
