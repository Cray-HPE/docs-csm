# LiveCD Setup

The LiveCD, formally known as the Shasta Pre-Install Toolkit, requires some setup before it can be used on metal or virtual platforms.

## Components
Before starting, you should have:

1. A machine with 1.3.x installed
2. A USB stick or other Block Device, local to ncn-w001 or ncn-mXXX (external-managers).
3. The drive letter of that device (i.e. `/dev/sdd`)
4. Access to stash, to `git pull ssh://git@stash.us.cray.com:7999/mtl/shasta-pre-install-toolkit.git` onto your NCN.
5. The block device should be `>=32GB`, the toolkit's built from "just-enough-OS" and can fit on smaller drives.

## Creating the LiveCD and populating it with information needed for the install

There are 5 steps here:
1. Create the USB Stick
2. Information gathering and configuration payload (most of your time will be spent here)
3. Craft `data.json` and `statics.conf`
4. Download the artifacts for PXE booting
5. Boot into the livecd

**The above steps** are prone to change as development of Shasta Instance Control carries forward.

## Manual Step 1: Create the USB Stick

1. Make the USB and fetch artifacts.

```bash
    # Fetch the latest ISO:
    ncn-w001:~ # rm -f shasta-pre-install-toolkit-latest.iso
    ncn-w001:~ # wget http://car.dev.cray.com/artifactory/internal/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/shasta-pre-install-toolkit-latest.iso

    # Find your USB stick with your linux tool of choice, for this it's /dev/sdd.
    # Run this command, or adjust the copy-on-write (COW) overlay size for persistent storage
    # from 5000MiB.                                                                                       
    ncn-w001:~ # git clone https://stash.us.cray.com/scm/mtl/shasta-pre-install-toolkit.git
    ncn-w001:~ # ./shasta-pre-install-toolkit/scripts/write-livecd.sh /dev/sdd $(pwd)/shasta-pre-install-toolkit-latest.iso 20000
```

2. Mount data partition:

    ```bash
    ncn-w001:~ # mount /dev/disk/by-label/PITDATA /mnt/
    ```

Now that your disk is setup and the data partition is mounted, you can begin gathering info and configs and populating it to the USB disk so it's available when you boot into the livecd.


## Manual Step 2: Gather Information

### The variables are just examples (your system will likely be different)
This presumes you have 1.3.x configuration files, 1.2 should suffice but locations may differ and mileage may vary. They are for visual reference only. It will not be possible to fully deploy a system (NCN, CN, & HSN) using these values, it is safer to **use 1.3 values or start fresh.**

### 1.3.x -> 1.4 Quick-n-dirty data gathering...

LiveCD setup information can be collected by hand or alternatively you can run this on any 1.3.X system to print out an easy-script for setting up your liveCD for your system.

> **This will all be replaced by the shasta-instance-control tool; this is just a helper for 1.3.X
> testing.**

The following steps will detail how to quickly collect information from a semi, or fully installed 1.3 system. "Semi" installed refers to at least running `crayctl init`, ideally making it through `stage1`.

1. Copy the block below into a terminal window on a booted shasta-1.3.X-worker node (i.e. ncn-w001).

    ```bash
    # Make/truncate the file.
    >/mnt/qnd-1.4.sh
    # Echo commands into the file and onto the screen, these run locally and against ncn-w001.
    echo export site_nic=$(ansible ncn-w001 -c local -a "echo {{ platform.NICS.lan2 }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export bond_member0=$(ansible ncn-w001 -c local -a "echo {{ platform.NICS.lan1 }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export bond_member1=$(ansible ncn-w001 -c local -a "echo {{ platform.NICS.lan3 }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export mtl_cidr=$(ansible ncn-w001 -c local -a "echo {{ [bis.mtl_ip, abbrv.mtl.network | ipaddr('prefix')] | join('/') }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export mtl_dhcp_start=$(ansible ncn-w001 -c local -a "echo {{ abbrv.mtl.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.start') | first }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export mtl_dhcp_end=$(ansible ncn-w001 -c local -a "echo {{ abbrv.mtl.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.end') | first }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export nmn_cidr=$(ansible ncn-w001 -c local -a "echo {{ [bis.nmn_ip, abbrv.nmn.network | ipaddr('prefix')] | join('/') }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export nmn_dhcp_start=$(ansible ncn-w001 -c local -a "echo {{ abbrv.nmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.start') | first }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export nmn_dhcp_end=$(ansible ncn-w001 -c local -a "echo {{ abbrv.nmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.end') | first }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export hmn_cidr=$(ansible ncn-w001 -c local -a "echo {{ [bis.hmn_ip, abbrv.hmn.network | ipaddr('prefix')] | join('/') }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export hmn_dhcp_start=$(ansible ncn-w001 -c local -a "echo {{ abbrv.hmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.start') | first }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    echo export hmn_dhcp_end=$(ansible ncn-w001 -c local -a "echo {{ abbrv.hmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.end') | first }}" | tail -n 1 ) | tee -a /mnt/qnd-1.4.sh
    ```

2. You'll also want to gather network info for the external interface. This would be:

    > These are example variables; adjust them as needed for your environment.

    ```bash
    echo export site_cidr=172.30.52.220/20 >>/mnt/qnd-1.4.sh
    echo export site_gw=172.30.48.1 >>/mnt/qnd-1.4.sh
    echo export site_dns="'172.30.84.40 172.31.84.40'" >>/mnt/qnd-1.4.sh
    ```

3.  Customer Access Network information will need to be gathered by hand and kept (for current BGP Dev status, see [Can BGP status on Shasta systems](https://connect.us.cray.com/confluence/display/CASMPET/CAN-BGP+status+on+Shasta+systems)):

    > These are example variables; adjust them as needed for your environment

    ```bash
    echo export can_cidr=10.102.4.110/24 >> /mnt/qnd-1.4.sh
    echo export can_dhcp_start=10.102.4.5 >> /mnt/qnd-1.4.sh
    echo export can_dhcp_end=10.102.4.109 >> /mnt/qnd-1.4.sh
    echo export can_gw=10.102.4.111 >> /mnt/qnd-1.4.sh
    ```

4. Optionally, adjust dhcp time for 1.4 leases:

    > These are example variables; adjust them as needed for your environment

    ```bash
    # Default is 10m
    echo export dhcp_ttl=2m >> /mnt/qnd-1.4.sh
    ```

5. Print the script into terminal to visually verify things. There will be a reminder to copy this file into our LiveCD in the creation readme.

    > These are example variables; adjust them as needed for your environment

    ```bash
    # Print the file we made:
    ncn-w001:~/sic # cat /mnt/qnd-1.4.sh
    export site_nic=em1
    export bond_member0=p801p1
    export bond_member1=p801p2
    export mtl_cidr=10.1.1.1/16
    export mtl_dhcp_start=10.1.2.3
    export mtl_dhcp_end=10.1.2.254
    export nmn_cidr=10.252.0.4/17
    export nmn_dhcp_start=10.252.50.0
    export nmn_dhcp_end=10.252.99.252
    export hmn_cidr=10.254.0.4/17
    export hmn_dhcp_start=10.254.50.5
    export hmn_dhcp_end=10.254.99.252
    export site_cidr=172.30.52.220/20
    export site_gw=172.30.48.1
    export site_dns='172.30.84.40 172.31.84.40'
    export can_cidr=10.102.4.110/24
    export can_dhcp_start=10.102.4.5
    export can_dhcp_end=10.102.4.109
    export can_gw=10.102.4.111
    export dhcp_ttl=2m    
    ```

Your quick-and-dirty script is now saved to your USB stick.  Next, we'll gather more information needed for `dnsmasq`.

## Manual Step 3: Create `data.json` and `statics.conf`

data.json is the main metadata file for configuring nodes in cloud-init.

> Note: This manual step is tedious and will be removed by automation.

1. Fetch the latest metadata file for your system.

> Replace <system-name> with your system (e.g. fanta)

   ```bash
   ncn-w001:~ # wget https://stash.us.cray.com/projects/DST/repos/shasta_system_configs/raw/<system-name>/ncn_metadata.csv
   ```

2. Edit the `ncn_metadata.csv` file to add `Bond MAC`, `Node Name`, and `NMN IP` columns.

   Bond MAC will be the MAC of the bond0 interface on the NCN.   Set this to `00:00:00:00:00:00` for the `Site Connection` node.
   NMN IP will be the IP address that you want to use for the NCN on the NMN.

   ```bash
   NCN xname,NCN Role,NCN Subrole,BMC MAC,BMC Switch Port,NMN MAC,NMN Switch Port,Bond MAC,Node Name,NMN IP
   x3000c0s1b0n0,Management,Master,a4:bf:01:5a:aa:03,x3000u25-p25,a4:bf:01:5a:a9:ff,x3000u25-p02,98:03:9b:1a:f6:70,ncn-m001,10.252.2.10
   x3000c0s3b0n0,Management,Master,a4:bf:01:5a:b0:00,x3000u25-p26,a4:bf:01:5a:af:fc,x3000u25-p03,b8:59:9f:2b:31:02,ncn-m002,10.252.2.11
   x3000c0s5b0n0,Management,Master,a4:bf:01:68:55:ad,x3000u25-p27,a4:bf:01:68:55:a9,x3000u25-p04,b8:59:9f:2b:31:06,ncn-m003,10.252.2.12
   x3000c0s7b0n0,Management,Worker,00:00:00:00:00:00,Site Connection,00:00:00:00:00:00,Site Connection,00:00:00:00:00:00,ncn-w001,0.0.0.0
   x3000c0s9b0n0,Management,Worker,a4:bf:01:5a:d5:fa,x3000u25-p28,a4:bf:01:5a:d5:f6,x3000u25-p05,98:03:9b:0f:39:4a,ncn-w002,10.252.2.13
   x3000c0s11b0n0,Management,Worker,a4:bf:01:5a:d5:ec,x3000u25-p29,a4:bf:01:5a:d5:e8,x3000u25-p06,50:6b:4b:08:d0:4a,ncn-w003,10.252.2.14
   x3000c0s13b0n0,Management,Storage,a4:bf:01:65:66:cc,x3000u25-p30,a4:bf:01:65:66:c8,x3000u25-p07,b8:59:9f:2b:2e:d2,ncn-s001,10.252.2.15
   x3000c0s15b0n0,Management,Storage,a4:bf:01:65:6b:b8,x3000u25-p31,a4:bf:01:65:6b:b4,x3000u25-p08,b8:59:9f:34:88:9e,ncn-s002,10.252.2.16
   x3000c0s17b0n0,Management,Storage,a4:bf:01:64:f4:3b,x3000u25-p32,a4:bf:01:64:f4:37,x3000u25-p09,b8:59:9f:34:88:7a,ncn-s003,10.252.2.17
   ```

3. Fetch the latest example file, this can be done off of ncn-w001:

    ```bash
    ncn-w001:~ # mkdir -pv /mnt/configs
    ncn-w001:~ # git clone https://stash.us.cray.com/scm/mtl/docs-non-compute-nodes.git
    ncn-w001:~ # cp -pv docs-non-compute-nodes/example-data.json /mnt/configs/data.json
    ```

The example `data.json` is now saved to your USB stick.

4. Edit the `data.json` file and manually adjust all the `~FIXMES~`.

```bash
# STOP!
# STOP! This next step requires some manual work.
# STOP!
# Edit, adjust all the ~FIXMES
# The values for the `global_data` should be cross-referenced to `networks*.yml` and
# `kubernetes.yml`.
ncn-w001:~ # vim /mnt/configs/data.json
```

  + k8s-virtual-ip and rgw-virtual-ip

  Run these commands on the 1.3 system.

  ```
  ncn-w001:~ # grep rgw_virtual_ip /opt/cray/crayctl/files/group_vars/all/networks.yml
  ncn-w001:~ # grep k8s_virtual_ip /opt/cray/crayctl/files/group_vars/all/networks.yml
  ```

  + first-master-hostname

  On systems that use w001 for the liveCD, set this to ncn-m001
  On systems that use m001 for the liveCD, set this to ncn-m002

  + dns-server

  Set this to the IP used for `nmn_cidr` in qnd-1.4.sh.

  + can-gw

  Set this to the IP used for `can_gw` in qnd-1.4.sh.


`data.json` is now partially complete.  We will complete it in the next step.

5. Create this little script below on w001 (or whichever node you're on) which will generate `statics.conf` and finish `data.json`.

  ```
  #!/bin/bash
  INPUT="$1"
  OLDIFS=$IFS
  IFS=','
  [[ ! -f $INPUT ]] && { echo "$INPUT file not found"; exit 99; }

  sed -i 's/$mac_address/mac_address/g' /mnt/configs/data.json
  while read xname role subrole bmcmac bmcport nmnmac nmnport bondmac nodename nmnip
  do
    if [ "$xname" == "NCN xname" ]; then
      continue
    fi
    if [ "$bmcmac" == "00:00:00:00:00:00" ]; then
      continue
    fi
    echo "dhcp-host=$bondmac,$nmnip,$nodename" >> /mnt/statics.conf
    shortname=`echo $nodename | sed 's/ncn-//'`
    sed -i "s/mac_address_$shortname/$bondmac/" /mnt/configs/data.json
    echo "$nmnip $nodename.nmn $nodename" >> /mnt/ncn-hosts
  done < $INPUT
  while read xname role subrole bmcmac bmcport nmnmac nmnport bondmac nodename nmnip
  do
    if [ "$xname" == "NCN xname" ]; then
      continue
    fi
    if [ "$bmcmac" == "00:00:00:00:00:00" ]; then
      continue
    fi
    echo "dhcp-host=${xname%n0},$bmcmac,${nodename}-mgmt" >> /mnt/statics.conf
  done < $INPUT
  IFS=$OLDIFS
  ```

3. Run it to save the files to your USB stick:

```
chmod 755 ./script.sh
./script.sh ./ncn_metadata.csv
cat /mnt/statics.conf
```

## Manual Step 4: Download booting artifacts

Fetch the current working set of artifacts.
> Note: This chooses a fixed artifact ID, you can change it by editing the suffix of the URL(s).

1. Get the k8s squashFS images.
2. Get the ceph squashFS images.
3. Get the kernel and initrd from the base image for netboot.

```bash
# PREP
ncn-w001:~ # mkdir -pv /mnt/data/k8s /mnt/data/ceph
ncn-w001:~ # pushd /mnt/data/
# K8s
ncn-w001:/mnt/data # pushd k8s
ncn-w001:/mnt/data/k8s # wget --mirror -np -nH -A *.squashfs -nv --cut-dirs=5 http://arti.dev.cray.com:80/artifactory/node-images-unstable-local/shasta/kubernetes/0.0.1-4/
ncn-w001:/mnt/data/k8s # popd
# CEPH
ncn-w001:/mnt/data # pushd ceph
ncn-w001:/mnt/data/ceph # wget --mirror -np -nH -A *.squashfs -nv --cut-dirs=5 http://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/storage-ceph/0.0.1-6/
ncn-w001:/mnt/data/ceph # popd
# KERNEL & INITRD
ncn-w001:/mnt/data # wget --mirror -np -nH -A *.kernel,*initrd* -nv --cut-dirs=5 http://arti.dev.cray.com:80/artifactory/node-images-unstable-local/shasta/sles15-base/0.0.1-4/
# VALIDATE
ncn-w001:/mnt/data # ls -R
# GET OFF THE USB STICK
ncn-w001:/mnt/data # popd
ncn-w001:~ #
```

# Alternative / Hand-collection.

If you don't have that information, then you need the following otherwise move on (for current BGP Dev status, see [Can BGP status on Shasta systems](https://connect.us.cray.com/confluence/display/CASMPET/CAN-BGP+status+on+Shasta+systems)).
- Bond member 0 (i.e. p801p1)
- Bond member 1 (i.e. p801p2)
- MTL CIDR (i.e. 10.1.1.1/16)
- MTL DHCP start (i.e. 10.1.2.3)
- MTL DHCP end (i.e. 10.1.2.254)
- NMN CIDR (i.e. 10.252.1.1/17)
- NMN DHCP start (i.e. 10.252.50.0)
- NMN DHCP end (i.e. 10.252.99.252)
- HMN CIDR (i.e. 10.254.1.1/17)
- HMN DHCP start (i.e. 10.254.50.5)
- HMN DHCP end (i.e. 10.254.99.252)
- CAN CIDR (i.e. 10.102.9.110/24)
- CAN GW (i.e. 10.102.9.111)
- CAN DHCP start (i.e. 10.102.9.5)
- CAN DHCP end (i.e. 10.102.9.109)


## Manual Step 4 : Boot into your LiveCD.
Now you can boot into your LiveCD [005-LIVECD-BOOTS.md](005-LIVECD-BOOTS.md)
