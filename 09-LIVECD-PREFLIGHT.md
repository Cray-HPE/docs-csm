# LiveCD Pre-flight Information

This will go over what values you need from 1.3 configuration files to jump-start
 a shasta-1.4 development install.

This presumes you have 1.3.x configuration files, 1.2 should suffice but
locations may differ and mileage may vary.

## Shut down other nodes
To prevent DHCP conflicts, shut down all the other NCNs before booting into the liveCD

## Information Gathering for Making the LiveCD:

1. A USB stick or other Block Device, local to ncn-w001 or ncn-mXXX (external-managers).
2. The drive letter of that device (i.e. `/dev/sdd`)
3. Access to stash, to `git pull ssh://git@stash.us.cray.com:7999/mtl/shasta-pre-install-toolkit.git` onto your NCN.
4. The block device should be `>16GB`, the toolkit's built from "just-enough-OS" and can fit on smaller drives.

## Information Gathering for Using the LiveCD:

### 1.3.x -> 1.4 Quick-n-dirty data gathering...

LiveCD setup information can be collected by hand or alterantively you can run this on any 1.3.X system
 to print out an easy-script for setting up your liveCD for your system.

> **This will all be replaced by the shasta-instance-control tool; this is just a helper for 1.3.X
> testing.**

The following steps will detail how to quickly collect information from a semi, or fully installed
1.3 system. "Semi" installed refers to at least running `crayctl init`, ideally making it through
`stage1`.

#### Steps:

1. Copy the block below into a terminal window on a booted shasta-1.3.X-worker node (i.e. ncn-w001).

```shell script
# Make/truncate the file.
>/tmp/qnd-1.4.sh
# Echo commands into the file and onto the screen, these run locally and against ncn-w001.
echo export bond_member0=$(ansible ncn-w001 -c local -a "echo {{ platform.NICS.lan1 }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export bond_member1=$(ansible ncn-w001 -c local -a "echo {{ platform.NICS.lan3 }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export mtl_cidr=$(ansible ncn-w001 -c local -a "echo {{ [bis.mtl_ip, abbrv.mtl.network | ipaddr('prefix')] | join('/') }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export mtl_dhcp_start=$(ansible ncn-w001 -c local -a "echo {{ abbrv.mtl.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.start') | first }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export mtl_dhcp_end=$(ansible ncn-w001 -c local -a "echo {{ abbrv.mtl.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.end') | first }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export nmn_cidr=$(ansible ncn-w001 -c local -a "echo {{ [bis.nmn_ip, abbrv.nmn.network | ipaddr('prefix')] | join('/') }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export nmn_dhcp_start=$(ansible ncn-w001 -c local -a "echo {{ abbrv.nmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.start') | first }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export nmn_dhcp_end=$(ansible ncn-w001 -c local -a "echo {{ abbrv.nmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.end') | first }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export hmn_cidr=$(ansible ncn-w001 -c local -a "echo {{ [bis.hmn_ip, abbrv.hmn.network | ipaddr('prefix')] | join('/') }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export hmn_dhcp_start=$(ansible ncn-w001 -c local -a "echo {{ abbrv.hmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.start') | first }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
echo export hmn_dhcp_end=$(ansible ncn-w001 -c local -a "echo {{ abbrv.hmn.subnets | selectattr('label', 'equalto', 'default') | flatten | selectattr('dhcp') | map(attribute='dhcp.end') | first }}" | tail -n 1 ) | tee -a /tmp/qnd-1.4.sh
```

2. Print the script into terminal for capture. There will be a reminder to copy this file into our LiveCD
in the creation readme.

```shell script
# Print the file we made:
ncn-w001:~ # cat /tmp/qnd-1.4.sh
export bond_member0=p801p1            
export bond_member1=p801p2            
export mtl_cidr=10.1.1.1/16           
export mtl_dhcp_start=10.1.2.3        
export mtl_dhcp_end=10.1.2.254        
export nmn_cidr=10.252.1.1/17           
export nmn_dhcp_start=10.252.50.0     
export nmn_dhcp_end=10.252.99.252     
export hmn_cidr=10.254.1.1/17           
export hmn_dhcp_start=10.254.50.5     
export hmn_dhcp_end=10.254.99.252     
```

### Alternative / Hand-collection.

If you don't have that information, then you need the following:
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


## Information Gathering for identifying the first nodes:


The information from above should be parsable from a shasta-1.3.X `ncn_metadata.csv`. The last
columns in that CSV should denote BMCs.

A little script to parse that stuff out is below, but some manual intervention is still needed.  You can match this up to the ccd.

```
#!/bin/bash
INPUT="$1"
OLDIFS=$IFS
IFS=','
[[ ! -f $INPUT ]] && { echo "$INPUT file not found"; exit 99; }
while read xname role subrole bmcmac bmcport nmnmac nmnport
do
# dhcp-host=ncn-s002-mgmt,a4:bf:01:48:20:03,ncn-s002-mgmt
  echo "dhcp-host=HOST,$bmcmac,$bmcport"
  #echo "xname: $xname"
  #echo "role : $role"
  #echo "subrole : $subrole"
  #echo "bmc mac : $bmcmac"
  #echo "bmc port : $bmcport"
  #echo "nmn mac : $nmnmac"
  #echo "nmn port : $nmnport"
  done < $INPUT
IFS=$OLDIFS
```
This info will be used in `/etc/dnsmasq.d/statistics.conf` but is still incomplete.  You can compare the output to the CCD and replace the `HOST` and port with the hostname and then restart `dnsmasq`.  

### BMCs


```apacheconfig
dhcp-host=94:40:c9:37:66:98,10.254.2.13,uan01-mgmt
dhcp-host=b4:2e:99:be:1a:39,10.254.2.6,nid000001-mgmt
dhcp-host=b4:2e:99:be:24:ed,10.254.2.3,nid000002-mgmt
dhcp-host=b4:2e:99:be:1a:71,10.254.2.20,nid000003-mgmt
dhcp-host=b4:2e:99:be:19:f5,10.254.2.19,nid000004-mgmt
dhcp-host=94:40:c9:2a:ad:8a,10.254.2.17,ncn-s003-mgmt
dhcp-host=94:40:c9:2a:ad:d0,10.254.2.15,ncn-s002-mgmt
dhcp-host=94:40:c9:37:e3:8a,10.254.2.11,ncn-s001-mgmt
dhcp-host=94:40:c9:37:e3:4e,10.254.2.18,ncn-w003-mgmt
dhcp-host=94:40:c9:37:e3:3e,10.254.2.14,ncn-w002-mgmt
dhcp-host=94:40:c9:37:d3:de,10.254.2.8,ncn-w001-mgmt
dhcp-host=94:40:c9:37:d3:fc,10.254.2.12,ncn-m003-mgmt
dhcp-host=94:40:c9:37:e3:3a,10.254.2.10,ncn-m002-mgmt
```

### NCNs

> Note: Hostname resolution for NMN is not dynamic yet due to cloud-init integration.
> A shim to allow for this is provided in [12-LIVECD-NCN-BOOTS.md](12-LIVECD-NCN-BOOTS.md).

# Next..

Now move onto [10-LIVECD-CREATION](10-LIVECD-CREATION.md).
