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

```shell script
## 1.
# Make the USB and fetch artifacts.

# Fetch the latest ISO:
ncn-w001:~ # rm -f shasta-pre-install-toolkit-latest.iso
ncn-w001:~ # wget http://car.dev.cray.com/artifactory/internal/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/shasta-pre-install-toolkit-latest.iso

# Find your USB stick with your linux tool of choice, for this it's /dev/sdd.
# Run this command, or adjust the copy-on-write (COW) overlay size for persistent storage
# from 5000MiB.                                                                                       
ncn-w001:~ git clone sssh://git@stash.us.cray.com:7999/mtl/shasta-pre-install-toolkit.git
ncn-w001:~ # ./shasta-pre-install-toolkit/scripts/write-livecd.sh /dev/sdd $(pwd)/shasta-pre-install-toolkit-latest.iso 5000

## 2.
# Mount data partition.
ncn-w001:~ # mount /dev/sdd4 /mnt/
```

## Manual Step 2: Configuration Payload

Now our stick is ready, and we can load configuration payload information.
```shell script
## 3.a.
# Option 1: Fetch configs from a flat webroot:
ncn-w001:~ # mkdir -pv /mnt/configs
ncn-w001:~ # pushd /mnt/configs
ncn-w001:~ # url_endpoint=http://somewhere/out/there/
ncn-w001:~ # wget --mirror -np -nH -A *.yml,*.yaml,*.toml,*.csv -nv --cut-dirs=1 $url_endpoint
ncn-w001:~ # popd

## 3.b.     
# Option 2: Fetch configs from GIT:
ncn-w001:~ # git clone $config_repo
ncn-w001:~ # mkdir /mnt/configs
ncn-w001:~ # cp -r shasta_system_configs/$system_name/* /mnt/configs/

## 3.c.
# Option 3: Unpack a tarball:
ncn-w001:~ # mkdir -pv /mnt/configs
ncn-w001:~ # scp user:password@server/path/tar.gz /mnt/configs/
ncn-w001:~ # pushd /mnt/configs
ncn-w001:~ # tar -xzvf tar.gz
ncn-w001:~ # popd

```

Edit `data.json`...

```shell script
## 4.
# Get data.json template for booting NCNs.
ncn-w001:~ # git clone https://stash.us.cray.com/scm/mtl/docs-non-compute-nodes.git docs-ncn
ncn-w001:~ # cp -pv docs-ncn/example-data.json /mnt/data.json
# STOP!
# STOP! This next step requires some manual work.
# STOP!
# Edit, adjust all the ~FIXMES
# The values for the `global_data` should be cross-referenced to `networks_derived.yml` and
# `kubernetes.yml`.
ncn-w001:~ # vim /mnt/configs/data.json
```
You'll also want to gather network info for the external interface, so you can **manually** gather this info for now and then append it to the quick and dirty script.  You can append this info with some `echo` commands and then everything will be in one file.

```
echo "export cidr=172.30.52.220/20" >> /mnt/qnd-1.4.sh
echo "export gw=172.30.48.1" >> /mnt/qnd-1.4.sh
echo "export dns='172.30.84.40 172.31.84.40'" >> /mnt/qnd-1.4.sh
# This may be eth0/em1 depending on the machine.  Choose what appears when you boot the livecd
# Overriding what you put here if necessary
echo "export nic=em1" >> /mnt/qnd-1.4.sh
# You may need to adjust this, but it's the same in several of these example commands:
echo "export dhcp_ttl=10m" >> /mnt/qnd-1.4.sh
# You'll have to gather this info:
echo "export can_cidr=10.102.4.110/24" >> /mnt/qnd-1.4.sh
echo "export can_dhcp_start=10.102.4.5" >> /mnt/qnd-1.4.sh
echo "export can_dhcp_end=10.102.4.109" >> /mnt/qnd-1.4.sh
```

#### 1.3.x Upgrade Notice

**Copy `/tmp/qnd-1.4.sh`** to `/mnt/` or wherever you've mounted the data partition **now**.
```shell script
ncn-w001:~ # cp -pv /tmp/qnd-1.4.sh /mnt/
```

## Manual Step 3 : Boot into your LiveCD.

```shell script
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
1. Setting up communication...[11-LIVECD-SETUP.md](11-LIVECD-SETUP.md)
2. Booting NCNs [12-LIVECD-NCN-BOOTS.md](12-LIVECD-NCN-BOOTS.md)

# remove block-device leeway
# add blurb to re-run the script on the setup page
