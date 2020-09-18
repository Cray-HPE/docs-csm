# LiveCD Setup
The LiveCD, formally known as the Shasta Pre-Install Toolkit, requires some setup before it can be
used on metal or virtual platforms.

## Creating & Booting into the LiveCD from an NCN.

The following directions will show you how to create a USB stick on an existing Shasta-1.3.x system.

There are 3 steps here:
1. USB Stick
2. Configuration Payload
4. Booting

**The above steps** are prone to change as development of Shasta Instance Control carries forward.

## Manual Step 1: USB Stick

1. Make the USB and fetch artifacts.

    ```bash
    # Fetch the latest ISO:
    ncn-w001:~ # rm -f shasta-pre-install-toolkit-latest.iso
    ncn-w001:~ # wget http://car.dev.cray.com/artifactory/internal/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/shasta-pre-install-toolkit-latest.iso

    # Find your USB stick with your linux tool of choice, for this it's /dev/sdd.
    # Run this command, or adjust the copy-on-write (COW) overlay size for persistent storage
    # from 5000MiB.                                                                                       
    ncn-w001:~ # git clone https://stash.us.cray.com/scm/mtl/shasta-pre-install-toolkit.git
    ncn-w001:~ # ./shasta-pre-install-toolkit/scripts/write-livecd.sh /dev/sdd $(pwd)/shasta-pre-install-toolkit-latest.iso 5000
    ```

2. Mount data partition:

    ```bash
    ncn-w001:~ # mount /dev/sdd4 /mnt/
    ```

## Manual Step 2: Configuration Payload

### Configs

Now our stick is ready, and we can load configuration payload information.

> Note: This manual step is tedious and will be removed by automation.

First fetch and edit `data.json`...

1. Fetch the latest example, this can be done off of ncn-w001:

    ```bash
    ncn-w001:~ # mkdir -pv /mnt/configs
    ncn-w001:~ # git clone https://stash.us.cray.com/scm/mtl/docs-non-compute-nodes.git
    ncn-w001:~ # cp -pv docs-non-compute-nodes/example-data.json /mnt/configs/data.json
    ```
2. Edit the MAC addresses with your values from:

    - `cray-macs`
    - `ncn_metadata.csv`

3. Still editing the `data.json` file, adjust all the `~FIXMES~`    
```bash
# STOP!
# STOP! This next step requires some manual work.
# STOP!
# Edit, adjust all the ~FIXMES
grep rgw_virtual_ip configs/networks.yml
grep k8s_virtual_ip configs/networks.yml
# The values for the `global_data` should be cross-referenced to `networks_derived.yml` and
# `kubernetes.yml`.
ncn-w001:~ # vim /mnt/configs/data.json
```

If you have `statics.conf` setup, you can populate `data.json` a bit easier like this:
```
spit:/var/www/ephemeral # cat /etc/dnsmasq.d/statics.conf
dhcp-host=ncn-m001-mgmt,a4:bf:01:5a:a9:ff,ncn-m001-mgmt
dhcp-host=ncn-m002-mgmt,a4:bf:01:5a:af:fc,ncn-m002-mgmt
dhcp-host=ncn-m003-mgmt,a4:bf:01:68:55:a9,ncn-m003-mgmt
dhcp-host=ncn-w001-mgmt,00:00:00:00:00:00,ncn-w001-mgmt
dhcp-host=ncn-w002-mgmt,a4:bf:01:5a:d5:f6,ncn-w002-mgmt
dhcp-host=ncn-w003-mgmt,a4:bf:01:5a:d5:e8,ncn-w003-mgmt
dhcp-host=ncn-s001-mgmt,a4:bf:01:65:66:c8,ncn-s001-mgmt
dhcp-host=ncn-s002-mgmt,a4:bf:01:65:6b:b4,ncn-s002-mgmt
dhcp-host=ncn-s003-mgmt,a4:bf:01:64:f4:37,ncn-s003-mgmt
dhcp-host=ncn-w004-mgmt,a4:bf:01:3e:ca:f2,ncn-w004-mgmt
dhcp-host=ncn-w005-mgmt,a4:bf:01:3e:f9:50,ncn-w005-mgmt
dhcp-host=ncn-w006-mgmt,a4:bf:01:3e:c7:f5,ncn-w006-mgmt
dhcp-host=ncn-w007-mgmt,a4:bf:01:3e:d3:26,ncn-w007-mgmt
spit:/var/www/ephemeral # sed -i 's/$mac_address_m001/a4:bf:01:5a:a9:ff/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_m002/a4:bf:01:5a:af:fc/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_m003/a4:bf:01:68:55:a9/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_w002/a4:bf:01:5a:d5:f6/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_w003/a4:bf:01:5a:d5:e8/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_w004/a4:bf:01:3e:ca:f2/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_w005/a4:bf:01:3e:f9:50/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_w006/a4:bf:01:3e:c7:f5/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_w007/a4:bf:01:3e:d3:26/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_s001/a4:bf:01:65:66:c8/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_s002/a4:bf:01:65:6b:b4/' data.json >/dev/null
spit:/var/www/ephemeral # sed -i 's/$mac_address_s003/a4:bf:01:64:f4:37/' data.json >/dev/null
```
The above could be automated more with a little more work.

You'll also want to gather network info for the external interface, so you can **manually** gather this info for now and then append it to the quick and dirty script.  You can append this info with some `echo` commands and then everything will be in one file.

This file (`data.json`) is the main metadata file for configuring nodes in cloud-init.

### Artifacts


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
ncn-w001:/mnt/data # popd
# VALIDATE
ncn-w001:/mnt/data # ls -R
# GET OFF THE USB STICK
ncn-w001:/mnt/data # popd
ncn-w001:~ #
```


#### 1.3.x Upgrade Notice

**Copy `/tmp/qnd-1.4.sh`** to `/mnt/` or wherever you've mounted the data partition **now**.
```bash
# The script does NOT need to be executable, preferably it shouldn't be.
ncn-w001:~ # cp -pv /tmp/qnd-1.4.sh /mnt/
```

## Manual Step 3 : Boot into your LiveCD.

```bash
# Boot up, setup the liveCD (nics/dnsmasq/ipxe)
ncn-w001:~ # reboot                                                       
# Use the Serial-over-LAN to control the system and boot into the USB drive                 
mypc:~ > system=loki-ncn-m001
mypc:~ > ipmitool -I lanplus -U $user -P $password -H ${system}-mgmt sol activate
# Or use the iKVM: https://${system}-mgmt/
```

If you observe the entire boot, you will see an integrity check occur before Linux starts. This
can be skipped by hitting OK when it appears. It is very quick.

Once the system is booted, have your network information handy so you can populate it in the next steps.
- IP and netmask for your external connection(s).
- IP and netmask for your bis nodes (MTL, NMN, & HMN IPs)
- Ranges for DHCP (MTL, NMN, CAN, & HMN)
- The CAN IP/CIDR (ex: `can_cidr=10.102.4.110/24`)

Then you can move onto these next two pages:
1. Setting up communication...[06-LIVECD-SETUP.md](006-LIVECD-SETUP.md)
2. Booting NCNs [07-LIVECD-NCN-BOOTS.md](007-LIVECD-NCN-BOOTS.md)
