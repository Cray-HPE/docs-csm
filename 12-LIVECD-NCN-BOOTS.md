# LiveCD NCN Boots

Before starting this you are expected to have networking and serices setup.
If you are unsure, see the bottom of [11-LIVECD-SETUP.md](11-LIVECD-SETUP.md).

Typically, we should have eight leases for NCN BMCs. Some systems may have less, but the 
recommended minimum is 3 of each type (k8s-managers, k8s-workers, ceph-storage).

Check for NCN lease count:
spit:~ # grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | wc -l
8

`8` is the number we're expecting typically, since NCN "number 9" is the node
currently booted up with the LiveCD (the node you're standing on).

Print off each NCN we'll target for booting.
```shell script
spit:~ # grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases
ncn-w002-mgmt
ncn-s001-mgmt
ncn-m002-mgmt
ncn-w001-mgmt
ncn-s002-mgmt
ncn-m003-mgmt
ncn-s003-mgmt
ncn-w003-mgmt
```

### Set fallback/static IPs.

If we loose DHCP for some reason, we can use defined IP addresses from
DNSmasq.

> Note: this requires a statics.conf file to be generated with the BMC MAC addresses.
> See [09-LIVECD-PREFLIGHT.md](09-LIVECD-PREFLIGHT.md) for more information.

```shell script
username=''
password=''
for bmc in $(grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases); do
    ipaddr=$(grep $bmc /var/lib/misc/dnsmasq.leases | awk '{print $3}') 
    netmask=$(ipmitool -I lanplus -U root -P initial0 -H ${bmc} lan print 1 | grep Mask | awk '{print $NF}')
    echo $bmc commands:
    echo ipmitool -I lanplus -U $username -P $password -H $bmc lan 1 set ipaddr $ipaddr 
    echo ipmitool -I lanplus -U $username -P $password -H $bmc lan 1 set netmask $netmask
    echo ipmitool -I lanplus -U $username -P $password -H $bmc lan 1 set defgw ipaddr $ipaddr
    echo ipmitool -I lanplus -U $username -P $password -H $bmc lan 1 set ipsrc static
    echo console name="$bmc" dev="ipmi:$ipaddr" ipmiopts="U:$username,P:$password,W:solpayloadsize" >>/etc/conman.conf 
    echo
done
```
Running the above loop will output commands to copy-and-paste, it will not actually set anything
on your BMCs.

Verify the output, make sure it looks right.

### Boot K8s

```shell script
username=''
password=''
for bmc in $(grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | sort); do
    echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis bootdev pxe options=efiboot 
    echo "ipmitool -I lanplus -U $username -P $password -H $bmc chassis power on 2>/dev/null || echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis power reset"
done
```

Watch consoles with the Serial-over-LAN, or use conamn if you've setup `/etc/conman.conf` with
the static IPs for the BMCs.

```shell script
# Connect to ncn-s002..
username=''
password=''
bmc='ncn-s002-mgmt'
spit:~ # echo ipmitool -I lanplus -U $username -P $password -H $bmc sol activate

# ..or print available consoles:
spit:~ # conman -q
spit:~ # conman -j ncn-s002
```
