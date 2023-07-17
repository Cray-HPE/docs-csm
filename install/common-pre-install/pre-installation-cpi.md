# Pre-Installation

The page walks a user through setting up the Cray LiveCD with the intention of installing Cray System Management (CSM).

1. [Boot installation environment](#1-boot-installation-environment)
    1. [Setup site network](#11-setup-site-network)
    1. [Prepare the data partition](#12-prepare-the-data-partition)
    1. [Set reusable environment variables](#13-set-reusable-environment-variables)
    1. [Configure Pre-install environment](#14-configure-pre-install-environment)
1. [Create system configuration](#2-create-system-configuration)
    1. [Generate topology files](#21-generate-topology-files)
    1. [Customize `system_config.yaml`](#22-customize-system_configyaml)
    1. [Run CSI](#23-run-csi)
    1. [Prepare `site init`](#24-prepare-site-init)
    1. [Configure Management Network](#25-configure-management-network)
    1. [Initialize the LiveCD](#26-initialize-the-livecd)
1. [Initialize Nexus](#3-initialize-nexus)
1. [Next topic](#next-topic)

## 1. Boot installation environment

Before proceeding, ensure that other NCNs are powered off and their BMC's IP source is set to DHCP and external connectivity is working.

DHCP and external connectivity is required to download CSM tar ball.

> **NOTE:** Each step denotes where its commands must run; `external#` refers to a server that is **not** the Cray, whereas `pit#` refers to the LiveCD itself.

### 1.1 Setup site network

On the first login, configure and verify the site-link, DNS and gateway IP addresses.

1. (`pit#`) Configure the site-link (`lan0`), DNS, and gateway IP addresses. (Optional) Also, at this stage, you can change the admin node password.

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

   1. Set network device files.

        1. Download and extract the contents of network file template tarball from [here](files/network_template.tar.gz), extract the contents.

            ```bash
            tar -xzvf network_template.tar.gz
            ```

        1. Delete existing network settings and copy the extracted files to `/etc/sysconfig/network/`.

            ```bash
            rm -rf /etc/sysconfig/network/*
            cp -r $PWD/network/* /etc/sysconfig/network/
            ```

   1. (`pit#`) Run the `csi-setup-lan0.sh` script to set up the site link and set the hostname.

      > **NOTE:**
      >
      > - Use `ipmi sol` session or `conman` session while performing this step as SSH session may disconnect.
      > - All of the `/root/bin/csi-*` scripts can be run without parameters to display usage statements.
      > - The hostname is auto-resolved based on reverse DNS.

      ```bash
      /root/bin/csi-setup-lan0.sh "${SYSTEM_NAME}" "${site_ip}" "${site_gw}" "${site_dns}" "${site_nics}"
      ```

1. (`pit#`) Verify that the assigned IP address was successfully applied to `lan0`.

   ```bash
   wicked ifstatus --verbose lan0
   ```

   > **NOTE:**
   >
   > - The output from the above command must say `leases: ipv4 static granted`.
   >
   > - If the IPv4 address was not granted, then go back and recheck the variable values. The output will indicate the IP address failed to assign, which can happen if the given IP address is already taken on the connected network.

### 1.2 Prepare the data partition

1. Populate the `/etc/fstab` as follows:

   ```bash
    LABEL=PITDATA  /var/www/ephemeral               ext4      noauto,noatime                0 2
    tmpfs          /var/lib/containers/storage      tmpfs     auto,nodev,nosuid,size=64g     0 0
   ```

   Ensure that `tmpfs` is large enough as almost 31 GB of data will be placed in `/var/lib/containers/storage` during the install CSM services step. If `tmpfs` is small, to increase the `tmpfs` capacity use the following command:

   ```bash
    LABEL=PITDATA  /var/www/ephemeral               ext4      noauto,noatime                0 2
    /dev/sda1          /var/lib/containers/storage      ext4     defaults     0 0
   ```

1. Create the required directories using the following command:

   ```bash
     mkdir -p /var/www/ephemeral
     mkdir -p /var/lib/containers/storage
     mount -a
   ```

1. (`pit#`) Mount the `PITDATA` partition. Use a local disk for `PITDATA`:

      ```bash
      disk="$(lsblk -l -o SIZE,NAME,TYPE,TRAN -e7 -e11 -d -n | grep -v usb | sort -h | awk '{print $2}' | xargs -I {} bash -c "if ! grep -Fq {} /proc/mdstat; then echo {}; fi" | head -n 1)"
      echo "Using ${disk}"
      parted --wipesignatures -m --align=opt --ignore-busy -s "/dev/${disk}" -- mklabel gpt mkpart primary ext4 2048s 100%
      partprobe "/dev/${disk}"
      mkfs.ext4 -L PITDATA "/dev/${disk}1"
      mount -vL PITDATA
      ```

### 1.3 Set reusable environment variables

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
      > - An alpha build: `CSM_RELEASE=1.4.0-alpha.99`
      > - A release candidate: `CSM_RELEASE=1.4.0-rc.1`
      > - A stable release: `CSM_RELEASE=1.4.0`

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
   export GOSS_BASE=/opt/cray/tests/install/livecd
   cat << EOF >/etc/environment
   CSM_RELEASE=${CSM_RELEASE}
   CSM_PATH=${PITDATA}/csm-${CSM_RELEASE}
   GOSS_BASE=${GOSS_BASE}
   PITDATA=${PITDATA}
   SYSTEM_NAME=${SYSTEM_NAME}
   EOF
   ```

### 1.4 Configure Pre-install environment

1. Update `dnsmasq` and `apache2` configuration files.

   Download the tarball from [here](files/dhcp_http.tar.gz) and extract it in the current working directory.

   ```bash
   tar -xf dhcp_http.tar.gz
   ```

1. Update the `apache2` and `dnsmasq` configurations as follows:

   ```bash
   cp -rv dnsmasq/dnsmasq.conf  /etc/dnsmasq.conf
   cp -rv apache2/* /etc/apache2/
   cp -rv  conman/conman.conf /etc/conman.conf
   cp -rv logrotate/conman /etc/logrotate.d/conman
   cp -rv kubectl/kubectl /usr/bin/
   ```

   (Optional) Uncomment the `tftp_secure` entry in the `dnsmasq.conf` file.

1. Stop the following services: `dhcpd` and `named`.

   ```bash
   systemctl stop dhcpd
   systemctl stop named
   systemctl restart apache2
   ```

1. If `ping dcldap3.us.cray.com` does not work, then add the following entry in `/etc/hosts`.

   ```text
   172.30.12.37    dcldap3.us.cray.com
   ```

1. (`pit#`) Get the artifact versions.

   ```bash
   KUBERNETES_VERSION="$(find ${CSM_PATH}/images/kubernetes -name '*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')"
   echo "${KUBERNETES_VERSION}"
   CEPH_VERSION="$(find ${CSM_PATH}/images/storage-ceph -name '*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')"
   echo "${CEPH_VERSION}"
   ```

1. (`pit#`) Copy the NCN images from the expanded tarball.

   > **NOTE:** This hard-links the files to do this copy as fast as possible, as well as to mitigate space waste on the USB stick.

   ```bash
   mkdir -pv "${PITDATA}/data/k8s/" "${PITDATA}/data/ceph/"
   rsync -rltDP --delete "${CSM_PATH}/images/kubernetes/" --link-dest="${CSM_PATH}/images/kubernetes/" "${PITDATA}/data/k8s/${KUBERNETES_VERSION}"
   rsync -rltDP --delete "${CSM_PATH}/images/storage-ceph/" --link-dest="${CSM_PATH}/images/storage-ceph/" "${PITDATA}/data/ceph/${CEPH_VERSION}"
   ```

1. (`pit#`) Modify the NCN images with SSH keys and `root` passwords.

   The following substeps provide the most commonly used defaults for this process. For more advanced options, see
   [Set NCN Image Root Password, SSH Keys, and Timezone on PIT Node](../../operations/security_and_authentication/Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md).

   1. Generate SSH keys.

       > **NOTE:** The code block below assumes there is an RSA key without a passphrase. This step can be customized to use a passphrase if desired.

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
          -k "/var/www/ephemeral/data/k8s/${KUBERNETES_VERSION}/kubernetes-${KUBERNETES_VERSION}.squashfs" \
          -s "/var/www/ephemeral/data/ceph/${CEPH_VERSION}/storage-ceph-${CEPH_VERSION}.squashfs"
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

## 2. Create system configuration

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

### 2.1 Generate topology files

> **NOTE:** The following seed files are auto-generated with the common pre-installer `application_node_config.yaml` ,`hmn_connections.json` ,`ncn_metadata.csv` ,`switch_metadata.csv`. See [Seed file generation](hpcm_installation-cpi.md#seed-file-generation).

1. Verify if `cabinets.yaml` config file has not been created (manually).

   If `cabinets.yaml` config file has not been created, create the `cabinets.yaml` using the following step, else skip the following step.

      (`pit#`)
      1. Create remaining seed files,  unless they already exist from a previous installation.
         - [Create `cabinets.yaml`](../create_cabinets_yaml.md)

1. (`pit#`) Assuming all seed files are under `$HOME/seedfiles` directory, copy the generated files under `${PITDATA}/prep` directory.

   ```bash
   cp $HOME/seedfiles/* "${PITDATA}/prep"
   ```

1. (`pit#`) Confirm that the following files exist.

   ```bash
   ls -l "${PITDATA}"/prep/{application_node_config.yaml,cabinets.yaml,hmn_connections.json,ncn_metadata.csv,switch_metadata.csv}
   ```

   Expected output look similar to the following example:

   ```text
   -rw-r--r-- 1 root root  146 Jun  6 00:12 /var/www/ephemeral/prep/application_node_config.yaml
   -rw-r--r-- 1 root root  392 Jun  6 00:12 /var/www/ephemeral/prep/cabinets.yaml
   -rwxr-xr-x 1 root root 3768 Jun  6 00:12 /var/www/ephemeral/prep/hmn_connections.json
   -rw-r--r-- 1 root root 1216 Jun  6 00:12 /var/www/ephemeral/prep/ncn_metadata.csv
   -rw-r--r-- 1 root root  150 Jun  6 00:12 /var/www/ephemeral/prep/switch_metadata.csv
   ```

### 2.2 Customize `system_config.yaml`

1. (`pit#`) Create or copy `system_config.yaml`.

   - If one does not exist from a prior installation, then create an empty one:

      ```bash
      csi config init empty
      ```

   - Otherwise, copy the existing `system_config.yaml` file into the working directory and proceed to the [Run CSI](#23-run-csi) step.

1. (`pit#`) Edit the `system_config.yaml` file with the appropriate values.

   > **NOTE:**
   >
   > - For a short description of each key in the file, run `csi config init --help`.
   > - For more description of these settings and the default values, see [Default IP Address Ranges](../../introduction/csm_overview.md#2-default-ip-address-ranges) and the other topics in [CSM Overview](../../introduction/csm_overview.md).
   > - To enable or disable audit logging, refer to [Audit Logs](../../operations/security_and_authentication/Audit_Logs.md) for more information.
   > - If the system is using a `cabinets.yaml` file, be sure to update the `cabinets-yaml` field with `'cabinets.yaml'` as its value.

   ```bash
   vim system_config.yaml
   ```

### 2.3 Run CSI

1. (`pit#`) Generate the initial configuration for CSI.

   This will validate whether the inputs for CSI are correct.

   ```bash
   csi config init
   ```

   Expected Output:

   ```text
        2022/09/29 06:40:15 Using config file: /var/www/ephemeral/prep/system_config.yaml
        2022/09/29 06:40:15 Using application node config: /var/www/ephemeral/prep/application_node_config.yaml
        2022/09/29 06:40:15 SLS Cabinet Map
        2022/09/29 06:40:15      Class River
        2022/09/29 06:40:15             x3000
        {"level":"info","ts":1664433615.2577472,"msg":"Beginning SLS configuration generation."}
        2022/09/29 06:40:15 WARNING (Not Fatal): Couldn't find switch port for NCN: x3000c0s1b0
        2022/09/29 06:40:15 wrote 24725 bytes to /var/www/ephemeral/prep/system_name/sls_input_file.json
        2022/09/29 06:40:15 wrote 2342 bytes to /var/www/ephemeral/prep/system_name/customizations.yaml
        2022/09/29 06:40:15 Generating Installer Node (PIT) interface configurations for: ncn-m001
        2022/09/29 06:40:15 wrote 509 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifcfg-bond0
        2022/09/29 06:40:15 wrote 376 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifcfg-lan0
        2022/09/29 06:40:15 wrote 1030 bytes to /var/www/ephemeral/prep/system_name/pit-files/config
        2022/09/29 06:40:15 wrote 24 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifroute-lan0
        2022/09/29 06:40:15 wrote 335 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifcfg-bond0.hmn0
        2022/09/29 06:40:15 wrote 335 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifcfg-bond0.nmn0
        2022/09/29 06:40:15 wrote 39 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifroute-bond0.nmn0
        2022/09/29 06:40:15 wrote 336 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifcfg-bond0.can0
        2022/09/29 06:40:15 wrote 335 bytes to /var/www/ephemeral/prep/system_name/pit-files/ifcfg-bond0.cmn0
        2022/09/29 06:40:15 wrote 320 bytes to /var/www/ephemeral/prep/system_name/dnsmasq.d/CMN.conf
        2022/09/29 06:40:15 wrote 572 bytes to /var/www/ephemeral/prep/system_name/dnsmasq.d/HMN.conf
        2022/09/29 06:40:15 wrote 572 bytes to /var/www/ephemeral/prep/system_name/dnsmasq.d/NMN.conf
        2022/09/29 06:40:15 wrote 540 bytes to /var/www/ephemeral/prep/system_name/dnsmasq.d/MTL.conf
        2022/09/29 06:40:15 wrote 324 bytes to /var/www/ephemeral/prep/system_name/dnsmasq.d/CAN.conf
        2022/09/29 06:40:15 wrote 8917 bytes to /var/www/ephemeral/prep/system_name/dnsmasq.d/statics.conf
        2022/09/29 06:40:15 wrote 1226 bytes to /var/www/ephemeral/prep/system_name/conman.conf
        2022/09/29 06:40:15 wrote 894 bytes to /var/www/ephemeral/prep/system_name/metallb.yaml
        2022/09/29 06:40:15 wrote 60609 bytes to /var/www/ephemeral/prep/system_name/basecamp/data.json

        ===== [system_name] Installation Summary =====

        Installation Node: ncn-m001
        Customer Management: 10.102.5.0/25 GW: 10.102.5.1
        Customer Access: 10.102.5.128/25 GW: 10.102.5.129
                Upstream DNS: 8.8.8.8, 9.9.9.9
                MetalLB Peers: [spine]
        Networking
                BICAN user network toggle set to CAN
                Supernet enabled!  Using the supernet gateway for some management subnets
                * Hardware Management Network 10.254.0.0/17 with 2 subnets
                * High Speed Network 10.253.0.0/16 with 1 subnets
                * Provisioning Network (untagged) 10.1.1.0/16 with 2 subnets
                * Node Management Network 10.252.0.0/17 with 3 subnets
                * Customer Access Network 10.102.5.128/25 with 2 subnets
                * River Compute Hardware Management Network 10.107.0.0/17 with 1 subnets
                * River Compute Node Management Network 10.106.0.0/17 with 1 subnets
                * SystemDefaultRoute points the network name of the default route 0.0.0.0/0 with 0 subnets
                * Customer Management Network 10.102.5.0/25 with 4 subnets
                * Node Management Network LoadBalancers 10.92.100.0/24 with 1 subnets
                * Hardware Management Network LoadBalancers 10.94.100.0/24 with 1 subnets
        System Information
                NCNs: 9
                Mountain Compute Cabinets: 0
                Hill Compute Cabinets: 0
                River Compute Cabinets: 1
        CSI Version Information
                e7684168d062ed7276c6a349930f3582c0a7600f-heads-v1.26.1
                v1.26.1
        ]
   ```

### 2.4 Prepare `site init`

Follow the [Prepare `site init`](../prepare_site_init.md) procedure.

### 2.5 Configure Management Network

Follow  [Configure management network switches](README.md#6-configure-management-network-switches).

> **NOTE:** The generated paddle file can be used as input to the CANU command to configure the switches.

### 2.6 Initialize the LiveCD

> **NOTE:** If starting an installation at this point, ensure to copy the previous `prep` directory back onto the system.

1. (`pit#`) Initialize the PIT.

   >  **NOTE:** This step restarts the network interface, so this step can be performed from `ipmi sol` or `conman` session.

   The `pit-init.sh` script will prepare the PIT server for deploying NCNs.

   ```bash
   /root/bin/pit-init.sh
   ```

1. Setup `tftp` boot  directory and  restart `dnsmasq`.

    ```bash
     mkdir -p /srv/tftpboot/boot/
     cp -r /var/www/boot/* /srv/tftpboot/boot/
     systemctl restart dnsmasq
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

   > **NOTE:**
   >
   > - This will also set all the BMCs to DHCP.
   > - Changing into the `$HOME` directory ensures the proper operation of the script.

   ```bash
   cd $HOME && /root/bin/set-sqfs-links.sh
   ```

   Expected Output:

   ```text
        Resolving images to boot ...
        Images resolved
        Kubernetes Boot Selection:
                kernel: /var/www/ephemeral/data/k8s/0.3.51/5.3.18-150300.59.87-default-0.3.51.kernel
                initrd: /var/www/ephemeral/data/k8s/0.3.51/initrd.img-0.3.51.xz
                squash: /var/www/ephemeral/data/k8s/0.3.51/secure-kubernetes-0.3.51.squashfs
        Storage Boot Selection:
                kernel: /var/www/ephemeral/data/ceph/0.3.51/5.3.18-150300.59.87-default-0.3.51.kernel
                initrd: /var/www/ephemeral/data/ceph/0.3.51/initrd.img-0.3.51.xz
                squash: /var/www/ephemeral/data/ceph/0.3.51/secure-storage-ceph-0.3.51.squashfs
        Attempting to set all known BMCs (from /etc/conman.conf) to DHCP mode
        current BMC count: 8
        Waiting on 8 to request DHCP ...
        All [8] expected BMCs have requested DHCP.
        /root/bin/set-sqfs-links.sh is creating boot directories for each NCN with a BMC that has a lease in /var/lib/misc/dnsmasq.leases
                NOTE: Nodes without boot directories will still boot the non-destructive iPXE binary for bare-metal discovery usage.
                Images will be stored on the NCN at /run/initramfs/live/1.3.0-rc.3/
        /var/www is ready.
   ```

   Go to `/var/www` and create additional symlinks as follows:

   ```bash
   cp -r /var/www/ncn-* /srv/tftpboot/
   mkdir /srv/tftpboot/ephemeral
   cp -r /var/www/ephemeral/data/ /srv/tftpboot/ephemeral/
   ```

   Start `conman` service.

   ```bash
   systemctl start conman.service
   ```

1. (`pit#`) Verify that the LiveCD is ready by running the preflight tests.

   Run the following command to make the `kubectl` binary executable:

   ```bash
   chmod +x /usr/bin/kubectl
   ```

   Run preflight tests.

   ```bash
   csi pit validate --livecd-preflight
   ```

   Expected Output:

   ```text
        Running LiveCD preflight checks (may take a few minutes to complete)...
        Writing full output to /opt/cray/tests/install/logs/print_goss_json_results/20220929_101501.528062-22314-Z7D4bWt9/out

        Reading test results for node system_name-ncn-m001-pit (suites/livecd-preflight-tests.yaml)

        Checking test results
        Only errors will be printed to the screen

        GRAND TOTAL: 162 passed, 0 failed

        PASSED
   ```

   If any tests fail, they need to be investigated.
   After actions have been taken to rectify the tests (for example, editing configuration or CSI inputs), then restart from the beginning of the [Initialize the LiveCD](#26-initialize-the-livecd) procedure.

1. Save the `prep` directory for re-use.

   This needs to be copied off the system and either stored in a secure location or in a secured Git repository.
   There are secrets in this directory that should not be accidentally exposed.

## 3. Initialize Nexus

1. Grant necessary privileges by running the following command:

   ```bash
   sed -i 's/podman run/podman run --privileged/g' /usr/share/doc/csm/install/scripts/csm_services/steps/1.initialize_bootstrap_registry.yaml
   ```

1. Check if there are any processes attached to port 5000 by running the following command:

   ```bash
   netstat -tlnp | grep 5000
   ```

   If there is a process attached to port 5000, kill it using the `kill` command.

   ```bash
   kill -9 <pid>
   ```

   Restart Nexus.

   ```bash
   systemctl restart nexus.service
   ```

## Next topic

After completing the Pre-install step, the next step is to Deploy Management Nodes.

See [Deploy Management Nodes](README.md#1-deploy-management-nodes).
