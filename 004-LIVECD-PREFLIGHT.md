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
    export dhcp_ttl=2m    
    ```

Your quick-and-dirty script is now saved to your USB stick.  Next, we'll gather more information needed for `dnsmasq`.

## Manual Step 3: Create `data.json` and `statics.conf`

This file is the main metadata file for configuring nodes in cloud-init.

> Note: This manual step is tedious and will be removed by automation.

First fetch and edit `data.json`...

1. Fetch the latest example file, this can be done off of ncn-w001:

    ```bash
    ncn-w001:~ # mkdir -pv /mnt/configs
    ncn-w001:~ # git clone https://stash.us.cray.com/scm/mtl/docs-non-compute-nodes.git
    ncn-w001:~ # cp -pv docs-non-compute-nodes/example-data.json /mnt/configs/data.json
    ```

The example `data.json` is now saved to your USB stick.

3. Edit the `data.json` file and manually adjust all the `~FIXMES~`.

```bash
# STOP!
# STOP! This next step requires some manual work.
# STOP!
# Edit, adjust all the ~FIXMES
# The values for the `global_data` should be cross-referenced to `networks*.yml` and
# `kubernetes.yml`.
ncn-w001:~ # vim /mnt/configs/data.json
```

> You can find two of the values needed above with the commands below:

```
ncn-w001:~ # grep rgw_virtual_ip configs/networks.yml
ncn-w001:~ # grep k8s_virtual_ip configs/networks.yml
```

`data.json` is now partially complete.  In order to save a little work, switch gears and create this `dnsmasq` config file first:

2. Create this little script is below on w001 (or whichever node you're on), which can  grab the MAC addresses needed for `dnsmasq`.

  ```
  #!/bin/bash
  INPUT="$1"
  OLDIFS=$IFS
  IFS=','
  [[ ! -f $INPUT ]] && { echo "$INPUT file not found"; exit 99; }
  while read xname role subrole bmcmac bmcport nmnmac nmnport
  do
  # dhcp-host=xname,a4:bf:01:48:20:03,ncn-s002-mgmt
    # BMC *-mgmt
    echo "dhcp-host=${xname%n0},$bmcmac,$bmcport" >> /mnt/statics.conf
    # NMN ncn-{s,m,w}0**
    echo "dhcp-host=$nmnmac,$nmnport" >> /mnt/statics.conf
  done < $INPUT
  IFS=$OLDIFS
  ```

3. Run it to save the file to your USB stick:

```
chmod 755 ./script.sh
./script.sh configs/$SYSTEM/ncn_metadata.csv
cat /mnt/statics.conf
```

  4. Now that `/mnt/statics.conf` is made, you need to compare the output of that command to the CCD and replace the port with the hostname of the BMC.  This is a tedious step that currently has no automation.  You should also replace the NMN MAC addresses with the NCN hostname (ncn-s001, ncn-w002, etc.), though this bit isn't currently working until you add an entry for it in `/etc/hosts`: [MTL-1199](https://connect.us.cray.com/jira/browse/MTL-1199)

  5. Once you have `statics.conf` setup, you can now come back to finish populating `data.json` a bit easier than hand-editing.  Do so like this (the MACs will of course be different for your system):

> These are example variables; adjust them as needed for your environment

  ```
  ncn-w001:~ # cat /mnt/statics.conf
  dhcp-host=ncn-m001-mgmt,a4:bf:01:5a:a9:ff,ncn-m001-mgmt
  dhcp-host=ncn-m002-mgmt,a4:bf:01:5a:af:fc,ncn-m002-mgmt
  dhcp-host=ncn-m003-mgmt,a4:bf:01:68:55:a9,ncn-m003-mgmt
  dhcp-host=ncn-w001-mgmt,00:00:00:00:00:00,ncn-w001-mgmt
  dhcp-host=ncn-w002-mgmt,a4:bf:01:5a:d5:f6,ncn-w002-mgmt
  dhcp-host=ncn-w003-mgmt,a4:bf:01:5a:d5:e8,ncn-w003-mgmt
  dhcp-host=ncn-s001-mgmt,a4:bf:01:65:66:c8,ncn-s001-mgmt
  dhcp-host=ncn-s002-mgmt,a4:bf:01:65:6b:b4,ncn-s002-mgmt
  dhcp-host=ncn-s003-mgmt,a4:bf:01:64:f4:37,ncn-s003-mgmt
  ncn-w001:~ # sed -i 's/$mac_address_m001/a4:bf:01:5a:aa:03/' /mnt/data.json >/dev/null
  ncn-w001:~ # sed -i 's/$mac_address_m002/a4:bf:01:5a:b0:00/' /mnt/data.json >/dev/null
  ncn-w001:~ # sed -i 's/$mac_address_m003/a4:bf:01:68:55:ad/' /mnt/data.json >/dev/null
  ncn-w001:~ # sed -i 's/$mac_address_w002/a4:bf:01:5a:d5:fa/' /mnt/data.json >/dev/null
  ncn-w001:~ # sed -i 's/$mac_address_w003/a4:bf:01:5a:d5:ec/' /mnt/data.json >/dev/null
  ncn-w001:~ # sed -i 's/$mac_address_s001/a4:bf:01:65:66:cc/' /mnt/data.json >/dev/null
  ncn-w001:~ # sed -i 's/$mac_address_s002/a4:bf:01:65:6b:b8/' /mnt/data.json >/dev/null
  ncn-w001:~ # sed -i 's/$mac_address_s003/a4:bf:01:64:f4:3b/' /mnt/data.json >/dev/null
  ```
The above commands will put your BMC MAC addresses into `data.json`.

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
ncn-w001:/mnt/data # wget --mirror -np -nH -A *.kernel,*initrd* -nv --cut-dirs=5 http://arti.dev.cray.com:80/artifactory/node-images-unstable-local/shasta/sles15-base/0.0.1-1/
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
Now you can boot into your LiveCD [005-LIVECD-BOOT.md](005-LIVECD-BOOT.md)
