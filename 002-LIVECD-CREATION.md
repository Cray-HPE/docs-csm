# LiveCD Creation

This page will assist you with creating a LiveCD for a CSM install (formally known by "CRAY Pre-Install Toolkit") from a laptop
or an existing shasta-1.3+ system.

> **`NOTE`** For installs using the remote mounted LiveCD (no USB stick), pay attention to your memory usage while download and also extracting artifacts.
>
> Remote LiveCDs run entirely in memory, which fills as artifacts are downloaded and subsequently extracted. For most cases this is fine, but in cases when RAM is limited to less than 128GB memory pressure may occur from increasing file-system usage.
>
> For instances where memory is scarce, an NFS/CIF or HTTP/S share can be mounted in-place of the USB's data partition at `/var/www/ephemeral`. Using the same
mount point as the USB data partition will help ward off mistakes when following along.

## Requirements:

> If you are installing a system that previously had 1.3 installed, move external network connections from ncn-w001 to ncn-m001. See [MOVE-SITE-CONNECTIONS](050-MOVE-SITE-CONNECTIONS.md) for instructions.

1. A USB stick or other Block Device
   - The block device should be `>=256GB`
2. The drive letter of that device (i.e. `/dev/sdx`)
3. The number of mountain and river cabinets in the system.
4. A set of configuration information sufficient to fill out the [listed flags for the `csi config init` command](#configuration-payload)

> **`INTERNAL USE`**
5. Access to stash/bitbucket
6. The system's CCD/SHCD `.xlsx` file

## Overview:

1. [Download and expand the CSM release](#download-and-expand-the-csm-release)
2. [Install `csi`](#install-csi)
3. [Create the Bootable Media](#create-the-bootable-media)
4. [Gather and Create Seed Files](#gather--create-seed-files)
5. [Generate the Configuration Payload](#configuration-payload)
6. [Pre-Populate LiveCD OS Configuration and Daemon Files](#pre-populate-livecd-os-configuration-and-daemon-files)
7. [Pre-Populate the LiveCD Data and Deployment Files](#pre-populate-the-livecd-data-and-deployment-files)

### Download and Expand the CSM Release

Download the CSM software release to the Linux host which will be preparing the LiveCD.

> **`INTERNAL USE`** The `ENDPOINT` URL below are for internal use, customer/external should
> use the URL for the server hosting their tarball.

```bash
linux# cd ~
linux# export ENDPOINT=https://arti.dev.cray.com/artifactory/shasta-distribution-stable-local/csm/
linux# export CSM_RELEASE=csm-x.y.z
linux# wget ${ENDPOINT}/${CSM_RELEASE}.tar.gz
```

Expand the CSM software release

```bash
linux# tar -zxvf ${CSM_RELEASE}.tar.gz
```

### Install `csi`

> **`IMPORTANT`** If you're using the remote ISO please skip this step and move onto [LiveCD Setup](004-LIVECD-SETUP.md), return here to "Gather / Create Seed Files" if needed.

Install the included Cray Site Init package from the tarball:

```bash
rpm -Uvh ./${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
```

### Create the Bootable Media

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

If building the LiveCD on ncn-m001 which is booted from a previous v1.3 install, there will be three real disks/SSDs, and the fourth disk will be the USB device.  This example shows the fourth disk is clearly a different vendor than the others.

```bash
linux# export USB=/dev/sdd  
```

2. Format the USB device

    > **`IMPORTANT`** If you're using the remote ISO please skip this step and move onto [LiveCD Setup](004-LIVECD-SETUP.md), return here to "Gather / Create Seed Files" if needed.

    ```bash
    linux# csi pit format $USB ./${CSM_RELEASE}/cray-pre-install-toolkit-*.iso 50000

    ```

3. Create and mount the partitions needed:

    ```bash
    linux# mkdir -pv /mnt/{cow,pitdata}
    linux# mount -L cow /mnt/cow && mount -L PITDATA /mnt/pitdata
    ```
4.  Unpack the release so it's available on the livecd:

    ```bash
    linux# tar -zxvf ~/${CSM_RELEASE}.tar.gz -C /mnt/pitdata/
    ```

### Gather / Create Seed Files

This is the set of files that you will currently need to create or find to generate the config payload for the system:

1. `ncn_metadata.csv` (NCN configuration)
2. `hmn_connections.json` (RedFish configuration)
3. `switch_metadata.csv` (Switch configuration)
4. `application_node_config.yaml` (Optional: Application node configuration for SLS file generation)

From these four files, you can run `csi config init` and it will generate all of the necessary config files needed for beginning an install.

#### ncn_metadata.csv

Create `ncn_metadata.csv` by referencing these two pages:

- [NCN Metadata BMC](301-NCN-METADATA-BMC.md)
- [NCN Metadata BONDX](302-NCN-METADATA-BONDX.md)

#### hmn_connections.json

Create [hmn_connections.json](307-HMN-CONNECTIONS.md) by running a container against the CCD/SHCD spreadsheet.

#### switch_metadata.csv

Create [switch_metadata.csv](305-SWITCH-METADATA.md).

#### application-node-config.yaml

Create [application-node-config.yaml](308-APPLICATION-NODE-CONFIG.md). Optional configuration file. It allows modification to how CSI finds and treats application nodes discovered from the `hmn_connections.json` file when building the SLS Input file.

### Configuration Payload

The configuration payload comes from the `csi config init` command below.

1. To execute this command you will need the following:

> The hmn_connections.json, ncn_metadata.csv, switch_metadata.csv, and optionally application_node_config.yaml files in the current directory as well as values for the flags listed below.
> If you have a `application_node_config.yaml` input file, you will need to add the flag `--application-node-config-yaml application_node_config.yaml` to `csi config init` in the example below.
> If you have a `system_config.yaml` file from a previous configuration payload generated by CSI, then it can be used to supply configuration options to CSI instead of specifying CLI flags. The `system_config.yaml` must be in the current directory.
> An example of the command to run with the required options.

> **`IMPORTANT`** At this time (shasta-1.4.0), multiple NTP servers are NOT supported for the `ntp-upstream-server` argument.

```bash
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

This will generate the following files in a subdirectory with the system name.

```
linux# ls -R eniac
eniac/:
basecamp  conman.conf  cpt-files  credentials  dnsmasq.d  manufacturing  metallb.yaml  networks  sls_input_file.json  system_config

eniac/basecamp:
data.json

eniac/cpt-files:
ifcfg-bond0  ifcfg-lan0  ifcfg-vlan002  ifcfg-vlan004  ifcfg-vlan007

eniac/credentials:
bmc_password.json  mgmt_switch_password.json  root_password.json

eniac/dnsmasq.d:
CAN.conf  HMN.conf  mtl.conf  NMN.conf  statics.conf

eniac/manufacturing:

eniac/networks:
CAN.yaml  HMNLB.yaml  HMN.yaml  HSN.yaml  MTL.yaml  NMNLB.yaml  NMN.yaml
```

If you see warnings from `csi config init` that are similar to the warning messages below, it means that CSI encountered an unknown piece of hardware in the `hmn_connections.json` file. If you do not see this message you can move on to sub-step 2.
```json
{"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":{"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
```
If the piece of hardware is expected to be an application node then [follow the procedure to create the application_node_config.yaml](308-APPLICATION-NODE-CONFIG.md) file. The argument `--application-node-config-yaml ./application-node-config.yaml` can be given to `csi config init` to include the additional application node configuration. Due to systems having system specific application node source names in `hmn_connections.json` (and the SHCD) the `csi config init` command will need to be given additional configuration file to properly include these nodes in SLS Input file.

2. Clone the shasta-cfg repository for the system.
  > **IMPORTANT - NOTE FOR `INTERNAL`** - It is recommended to sync with STABLE after cloning if you have not already done so.
  > **IMPORTANT - NOTE FOR `INTERNAL`** - Configure Cray Datacenter LDAP if this hasn't been done for this system. See the section [Configuring Cray Datacenter LDAP](054-NCN-LDAP.md).

  > **IMPORTANT - NOTE FOR `AIRGAP`** - You must do this now while preparing the USB on your local machine if your CRAY is airgapped or if it cannot otherwise reach your local GIT server.

  ```bash
  linux# git clone https://stash.us.cray.com/scm/shasta-cfg/eniac.git /mnt/pitdata/prep/site-init
  ```

  If you would like to customize the PKI Certificate Authority (CA) used by the platform, see [Customizing the Platform CA](055-CERTIFICATE-AUTHORITY.md). This is an optional step. Note that the CA can not be modified after install.

3. Apply workarounds

  Check for workarounds in the `~/${CSM_RELEASE}/fix/csi-config` directory.  If there are any workarounds in that directory, run those now.   Instructions are in the README files.

  ```bash
  # Example
  linux# ls ~/${CSM_RELEASE}/fix/csi-config
  casminst-999
  ```

### Pre-Populate LiveCD OS Configuration and Daemon Files

This is accomplished by populating the cow partition with the necessary config files generated by `csi`

```bash
# Copy network config files and DNSMasq
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

### Pre-Populate the LiveCD Data and Deployment Files

> NOTE:  When running on a system that has 1.3 installed, you may hit a collision with an ip rule that prevents access to arti.dev.cray.com.  If you cannot ping that name, try removing this ip rule: `ip rule del from all to 10.100.0.0/17 lookup rt_smnet`

Populate your live cd with the kernel, initrd, and squashfs images (KIS), as well as the basecamp configs and any files you may have in your dir that you'll want on the livecd.

```
linux# mkdir -p /mnt/pitdata/configs/
linux# mkdir -p /mnt/pitdata/data/{k8s,ceph}/

# 1. Copy basecamp data
linux# csi pit populate pitdata ~/eniac/ /mnt/pitdata/configs -b
data.json---------------------> /mnt/pitdata/configs/data.json...OK

# 2. Copy k8s KIS
linux# csi pit populate pitdata ~/${CSM_RELEASE}/images/kubernetes/ /mnt/pitdata/data/k8s/ -kiK
5.3.18-24.37-default-0.0.6.kernel-----------------> /mnt/pitdata/data/k8s/...OK
initrd.img-0.0.6.xz-------------------------------> /mnt/pitdata/data/k8s/...OK
kubernetes-0.0.6.squashfs-------------------------> /mnt/pitdata/data/k8s/...OK

# 3. Copy ceph/storage KIS
linux# csi pit populate pitdata ~/${CSM_RELEASE}/images/storage-ceph/ /mnt/pitdata/data/ceph/ -kiC
5.3.18-24.37-default-0.0.5.kernel-----------------> /mnt/pitdata/data/ceph/...OK
initrd.img-0.0.5.xz-------------------------------> /mnt/pitdata/data/ceph/...OK
storage-ceph-0.0.5.squashfs-----------------------> /mnt/pitdata/data/ceph/...OK

# 4. Copy the CSI config files to prep dir
linux# cp -r ~/eniac /mnt/pitdata/prep
```

### Next: Boot into your LiveCD.

Now you can boot into your LiveCD [LiveCD USB Boot](003-LIVECD-USB-BOOT.md)
