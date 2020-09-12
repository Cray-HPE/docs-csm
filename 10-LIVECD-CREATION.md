# LiveCD Setup
The LiveCD, formally known as the Shasta Pre-Install Toolkit, requires some setup before it can be 
used on metal or virtual platforms.

## Creating & Booting into the LiveCD from an NCN.

The following directions will show you how to create a USB stick (or internal disk) on an existing
Shasta-1.3 system.

There are 4 steps:
1. USB Stick
2. Configuration Payload
3. Stop-Gap solutions
4. Booting

**The above steps** are prone to change as development of Shasta Instance Control carries forward.

## Manual Step: USB Stick

```bash
## 1.
# Make the USB and fetch artifacts.

# Fetch the latest ISO:
ncn-w001:~ # rm -f shasta-pre-install-toolkit-latest.iso
ncn-w001:~ # wget http://car.dev.cray.com/artifactory/internal/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/shasta-pre-install-toolkit-latest.iso

# Find your USB stick with your linux tool of choice, for this it's /dev/sdd.
# Run this command, or adjust the copy-on-write (COW) overlay size for persistent storage
# from 5000MiB.                                                                                       
ncn-w001:
ncn-w001:~ # ./spit/scripts/write-livecd.sh /dev/sdd $(pwd)/shasta-pre-install-toolkit-latest.iso 5000

## 2.
# Mount data partition.
ncn-w001:~ # mount /dev/sdd4 /mnt/
```

## Manual Step: Configuration Payload

Now our stick is ready, and we can load configuration payload information.
```bash
## 3.a.
# Option 1: Fetch configs from a flat webroot:
ncn-w001:~ # mkdir -pv /mnt/configs
ncn-w001:~ # pushd /mnt/configs
ncn-w001:~ # url_endpoint=http://somewhere/out/there/
ncn-w001:~ # wget --mirror -np -nH -A *.yml,*.yaml,*.toml,*.csv -nv --cut-dirs=1 $url_endpoint
ncn-w001:~ # popd

## 3.b.     
# Option 2: Fetch configs from GIT:
ncn-w001:~ # git clone $config_repo /mnt/configs

## 3.c.
# Option 3: Unpack a tarball:
ncn-w001:~ # mkdir -pv /mnt/configs 
ncn-w001:~ # scp user:password@server/path/tar.gz /mnt/configs/
ncn-w001:~ # pushd /mnt/configs 
ncn-w001:~ # tar -xzvf tar.gz 
ncn-w001:~ # popd 
                                                                             
```

Edit `data.json`...

```bash
## 4. 
# Get data.json template for booting NCNs.
ncn-w001:~ # git clone https://stash.us.cray.com/scm/mtl/docs-non-compute-nodes.git docs-ncn
ncn-w001:~ # cp -pv docs-ncn/example-data.json /mnt/configs/data.json
# STOP!
# STOP! This next step requires some manual work.
# STOP!
# Edit, adjust all the ~FIXMES
# The values for the `global_data` should be cross-referenced to `networks_derived.yaml` and
# `ncn_metadata.csv`.
ncn-w001:~ # vim /mnt/configs/data.json
ncn-w001:~ # umount /mnt/
```

## Manual Step: Boot into your LiveCD.

```bash
## 5.
# Boot up, setup the liveCD (nics/dnsmasq/ipxe)
ncn-w001:~ # reboot                                                       
# Use the Serial-over-LAN to control the system...                  
mypc:~ > system=loki-ncn-m001
mypc:~ > ipmitool -I lanplus -U $user -P $password -H ${system}-mgmt sol activate
# Or use the iKVM: https://${system}-mgmt/ 
```
If you observe the entire boot, you will see an integrity check occur before Linux starts. This
can be skipped by hitting OK when it appears. It is very quick.

Once the system is booted, have your network information handy:
- IP and netmask for your external connection(s).
- IP and netmask for your bis nodes (MTL, NMN, & HMN IPs)
- Ranges for DHCP (MTL, NMN, & HMN)

Then you can move onto these next two pages:
1. Setting up communication...[11-LIVECD-SETUP.md](11-LIVECD-SETUP.md)
2. Booting NCNs [12-LIVECD-DEPLOY.md](12-LIVECD-DEPLOY.md) `#TODO`
