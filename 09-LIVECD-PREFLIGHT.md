# LiveCD Pre-flight Information

This will go over what values you need from 1.3 configuration files 
in order too run a 1.4 install.

This presumes you have 1.3.x configuration files, 1.2 should suffice but
locations may differ and milage may vary.

### Information for Making the LiveCD:

1. A USB stick or other Block Device, local to ncn-w001 or ncn-mXXX (external-managers).
2. The drive letter of that device (i.e. `/dev/sdd`)
3. Access to stash, to `git pull ssh://git@stash.us.cray.com:7999/mtl/shasta-pre-install-toolkit.git` onto your NCN.
4. The block device should be `>16GB`, the toolkit is built from "just-enough-OS" but you want space for
artifacts for booting.

### Information for Using the LiveCD:

> 1.3.x -> 1.4 Quick-n-dirty data gathering...
 
LiveCD setup information can be collected by hand or alterantively you can run this on any 1.3.X system
 to print out an easy-script for setting up your liveCD for your system.
 
> This will all be replaced by the shasta-instance-control tool; this is just a helper for 1.3.X 
> testing.

The one exception to the quick-n-dirty script below is the external/site-link information. You will
need to collect:
- CIDR (IP/prefix) of your node.
- Gateway/router IP for your node's IP.
- The interface name the site-link is using after booting into the liveCD (i.e. `em1`, `eth0`)

The script below will output a bash script to run to make your life easier during setup. 

Run this on any system that's made it past `crayctl init`,
 
```bash
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
Now copy `/tmp/qnd-1.4.sh` off of the system so that you can re-use it when the time comes. The
values are pre-filled to match what should be usable for your system based on 1.3 installations.

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
