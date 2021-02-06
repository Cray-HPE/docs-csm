# CSM USB LiveCD - Creation and Configuration

This page will guide an administrator through creating a USB stick from either their Shasta v1.3 ncn-m001 node or their own laptop/desktop.

There are 5 overall steps that provide a bootable USB with SSH enabled, capable of installing Shasta v1.4 (or higher).

* [Download and Expand the CSM Release](#download-and-expand-the-csm-release)
* [Create the Bootable Media](#create-the-bootable-media)
* [Configuration Payload](#configuration-payload)
   * [SHASTA-CFG](#SHASTA-CFG)
   * [Generate Installation Files](#generate-installation-files)
   * [CSI Workarounds](#csi-workarounds)
* [Pre-Populate LiveCD Daemons Configuration and NCN Artifacts](#pre-populate-livecd-daemons-configuration-and-ncn-artifacts)
* [Boot the LiveCD](#boot-the-livecd)
   * [First Login](#first-login)


<a name="download-and-expand-the-csm-release"></a>
## Download and Expand the CSM Release

Fetch the base installation tarball and extract it, installing the contained CSI tool.

> **`INTERNAL USE`** The `ENDPOINT` URL below are for internal use, customer/external should
> use the URL for the server hosting their tarball.

1. Download the CSM software release to the Linux host which will be preparing the LiveCD.
   ```bash
   linux# cd ~
   linux# export ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm/
   linux# export CSM_RELEASE=csm-x.y.z
   linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
   ```

2. Expand the CSM software release:
   ```bash
   linux# tar -zxvf ${CSM_RELEASE}.tar.gz
   linux# ls -l ${CSM_RELEASE}
   ```

3. Install/upgrade the CSI RPM.
   ```bash
   linux# rpm -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
   ```

The ISO and other files are now available in the extracted CSM tar.

<a name="create-the-bootable-media"></a>
## Create the Bootable Media

Cray Site Init will create the bootable LiveCD. Before creating the media, we need to identify
which device that is.

1. Identify the USB device.

    This example shows the USB device is /dev/sdd on the host.

    ```bash
    linux# lsscsi
    [6:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sda
    [7:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdb
    [8:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdc
    [14:0:0:0]   disk    SanDisk  Extreme SSD      1012  /dev/sdd
    [14:0:0:1]   enclosu SanDisk  SES Device       1012  -      
    ```
    In the above example, we can see our internal disks as the `ATA` devices and our USB as the `disk` or `enclsou` device. Since the `SanDisk` fits the profile we're looking for, we are going to use `/dev/sdd` as our disk.

    Set a variable with your disk to avoid mistakes:

    ```bash
    linux# export USB=/dev/sd<disk_letter>
    ```

2. Format the USB device

    On Linux using the CSI application:
    ```bash
    linux# csi pit format $USB ~/${CSM_RELEASE}/cray-pre-install-toolkit-*.iso 50000
    ```
    On MacOS using the bash script:
    ```bash
    macos# ./cray-site-init/write-livecd.sh $USB ~/${CSM_RELEASE}/cray-pre-install-toolkit-*.iso 50000
    ```

    > NOTE: At this point the USB stick is usable in any server with an x86_64 architecture based CPU. The remaining steps help add the installation data and enable SSH on boot.

3. Mount the configuration and persistent data partition:

    ```bash
    linux# mkdir -pv /mnt/{cow,pitdata}
    linux# mount -L cow /mnt/cow && mount -L PITDATA /mnt/pitdata
    ```

4.  Copy and extract the tarball (compressed) into the USB:
    ```bash
    linux# cp -r ~/${CSM_RELEASE}.tar.gz /mnt/pitdata/
    linux# tar -zxvf ~/${CSM_RELEASE}.tar.gz -C /mnt/pitdata/
    ```

The USB stick now bootable and contains our artifacts. This may be useful for internal or quick usage. Administrators seeking a Shasta installation must continue onto the [configuration payload](#configuration-payload).

<a name="configuration-payload"></a>
## Configuration Payload

* [SHASTA-CFG](#SHASTA-CFG)
* [Generate Installation Files](#generate-installation-files)
* [CSI Workarounds](#csi-workarounds)

<a name="SHASTA-CFG"></a>
### SHASTA-CFG

SHASTA-CFG is a distinct repository of relatively static, installation-centric artifacts, including:

* Cluster-wide network configuration settings required by Helm Charts deployed by product stream Loftsman Manifests
* [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
* Sealed Secret Generate Blocks -- an form of plain-text input that renders to a Sealed Secret
* Helm Chart value overrides that are merged into Loftsman Manifests by product stream installers

Follow the instructions [here](./067-SHASTA-CFG.md) to prepare a SHASTA-CFG repository for your system.

<a name="generate-installation-files"></a>
### Generate Installation Files

Three files are needed for generating the configuration payload. New systems will need to create these three files before continuing.

> Note: The USB stick is usable at this time, but without SSH enabled as well as core services. This means
> the stick could be used to boot the system now, and a user can return to this step at another time.

Pull these files into the current working directory:
- `ncn_metadata.csv`
- `hmn_connections.json`
- `switch_metadata.csv`
- `system_config.yaml` (see below)

> Optionally a `application-node-config.yaml` file may be provided for further tweaking of settings. See the CSI usage for more information.

After gathering the files into the working directory, generate your configs:

1. Change into the preparation directory:
   ```bash
   linux# mkdir -pv /mnt/pitdata/prep
   linux# cd /mnt/pitdata/prep
   ```

2. Re-use a parameter file (see [avoiding parameters](./063-CSI-FILES.md#save-file--avoiding-parameters)) **or skip this step**.
   ```bash
   # All the needed files together.
   linux# ls -1
   hmn_connections.json
   ncn_metadata.csv
   shasta_system_configs
   switch_metadata.csv
   system_config.yaml

   # Generating system configuration.
   linux# csi config init
   ```

3. Run this command by hand if a parameter file is unavailable:
   ```bash
   # All the needed files together.
   linux# ls -1
   hmn_connections.json
   ncn_metadata.csv
   shasta_system_configs
   switch_metadata.csv
   system_config.yaml
   linux# csi config init \
       --bootstrap-ncn-bmc-user root \
       --bootstrap-ncn-bmc-pass changeme \
       --system-name eniac  \
       --mountain-cabinets 0 \
       --hill-cabinets 0 \
       --river-cabinets 1  \
       --can-cidr 10.103.11.0/24 \
       --can-gateway 10.103.11.1 \
       --can-static-pool 10.103.11.112/28 \
       --can-dynamic-pool 10.103.11.128/25 \
       --nmn-cidr 10.252.0.0/17 \
       --hmn-cidr 10.254.0.0/17 \
       --ntp-pool time.nist.gov \
       --site-ip 172.30.53.79/20 \
       --site-gw 172.30.48.1 \
       --site-nic p1p2 \
       --site-dns 172.30.84.40 \
       --install-ncn-bond-members p1p1,p10p1
   ```

A new directory matching your `--system-name` argument will now exist in your working directory.

<a name="csi-workarounds"></a>
### CSI Workarounds

Check for workarounds in the `~/${CSM_RELEASE}/fix/csi-config` directory.  If there are any workarounds in that directory, run those now. Instructions are in the README files.

  ```bash
  # Example
  linux# ls ~/${CSM_RELEASE}/fix/csi-config
  casminst-999
  ```


<a name="pre-populate-livecd-daemons-configuration-and-ncn-arti"></a>
## Pre-Populate LiveCD Daemons Configuration and NCN Artifacts

Now that the configuration is generated, we can populate the LiveCD with the generated files.

This will enable SSH, and other services when the LiveCD starts.

1. Use CSI to populate the LiveCD, provide both the mountpoint and the CSI generated config dir.
    ```bash
    linux# csi pit populate cow /mnt/cow/ eniac/
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
2. Optionally set the hostname, print it into the hostname file.
   > Do not confuse other admins and name the LiveCD "ncn-m001", please append the "-pit" suffix
   > to flag the context.
   ```bash
   echo 'bigbird-ncn-m001-pit' >/mnt/cow/rw/etc/hostname
   ```

2. Unmount the Overlay, we're done with it
    ```bash
    linux# umount /mnt/cow    
    ```

3. Make directories needed for basecamp (cloud-init) and the squashFS images

    ```bash
    linux# mkdir -p /mnt/pitdata/configs/
    linux# mkdir -p /mnt/pitdata/data/{k8s,ceph}/
    ```

4. Copy basecamp data
    ```bash
    linux# csi pit populate pitdata $SYSTEM_NAME /mnt/pitdata/configs -b
    data.json---------------------> /mnt/pitdata/configs/data.json...OK
    ```

5. Update CA Cert on the copied `data.json` file. Provide the path to the `data.json`, the path to
   our `customizations.yaml`, and finally the `sealed_secrets.key`
    ```bash
    linux# csi patch ca \
    --cloud-init-seed-file /mnt/pitdata/configs/data.json \
    --customizations-file /mnt/pitdata/prep/site-init/customizations.yaml \
    --sealed-secret-key-file /mnt/pitdata/prep/site-init/certs/sealed_secrets.key
   ```
6. Copy k8s artifacts:
    ```bash
    linux# csi pit populate pitdata ~/${CSM_RELEASE}/images/kubernetes/ /mnt/pitdata/data/k8s/ -kiK
    5.3.18-24.37-default-0.0.6.kernel-----------------> /mnt/pitdata/data/k8s/...OK
    initrd.img-0.0.6.xz-------------------------------> /mnt/pitdata/data/k8s/...OK
    kubernetes-0.0.6.squashfs-------------------------> /mnt/pitdata/data/k8s/...OK
    ```
7. Copy ceph/storage artifacts:
    ```bash
    linux# csi pit populate pitdata ~/${CSM_RELEASE}/images/storage-ceph/ /mnt/pitdata/data/ceph/ -kiC
    5.3.18-24.37-default-0.0.5.kernel-----------------> /mnt/pitdata/data/ceph/...OK
    initrd.img-0.0.5.xz-------------------------------> /mnt/pitdata/data/ceph/...OK
    storage-ceph-0.0.5.squashfs-----------------------> /mnt/pitdata/data/ceph/...OK
    ```

8. Unmount the data partition:
    ```bash
    linux# cd; umount /mnt/pitdata
    ```

Now the USB stick may be reattached to the CRAY, or if it was made on the CRAY then its server can now
reboot into the LiveCD.

<a name="boot-the-livecd"></a>
## Boot the LiveCD

Some systems will boot the USB stick automatically if no other OS exists (bare-metal). Otherwise the
administrator may need to use the BIOS Boot Selection menu to choose the USB stick.

If an administrator is rebooting a node into the LiveCD, vs booting a bare-metal or wiped node, then `efibootmgr` will deterministically set the boot order. See the [EFI Boot Manager](064-EFIBOOTMGR.md) page for more information on this topic..

> UEFI booting must be enabled to find the USB sticks EFI bootloader.

> **An integrity check** runs before Linux starts by default, it can be skipped by selecting "OK" in its prompt.

<a name="first-login"></a>
### First Login

On first login (over SSH or at local console) the LiveCD will prompt the administrator to change the password.

1. **The initial password is empty**; set the username of `root` and press `return` twice:

   ```bash
   pit login: root
   Password:           <-------just press Enter here for a blank password
   You are required to change your password immediately (administrator enforced)
   Changing password for root.
   Current password:   <------- press Enter here, again, for a blank password
   New password:       <------- type new password
   Retype new password:<------- retype new password
   Welcome to the CRAY Prenstall Toolkit (LiveOS)

   Offline CSM documentation can be found at /usr/share/doc/metal (version: rpm -q docs-csm-install)
   ```

   > **`NOTE`** If this password is forgotten, it can be reset by mounting the USB stick on another computer. See [LiveCD Troubleshooting](058-LIVECD-TROUBLESHOOTING.md#root-password) for information on clearing the password.

2. Mount the data partition
    > The data partition is set to `fsopt=noauto` to facilitate LiveCDs over virtual-ISO mount. USB installations need to mount this manually.
    ```bash
    pit:~ # mount -L PITDATA
    ```

2. Verify the system:
   ```bash
   pit:~ # csi pit validate --network
   pit:~ # csi pit validate --services
   ```

   > - If nexus is dead, restart it with `systemctl restart nexus`.
   > - If basecamp is dead, restart it with `systemctl restart basecamp`.
   > - If conman is dead, restart it with `systemctl restart conman`.
   > - If dnsmasq is dead, restart it with `systemctl restart dnsmasq`.


3. Follow the output's directions for failed validations before moving on.

After successfully validating the LiveCD USB environment, the administrator may start the [CSM Metal Install](005-CSM-METAL-INSTALL.md).
