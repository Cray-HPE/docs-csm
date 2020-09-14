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
```bash
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

```bash
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
    echo
done
```
Running the above loop will output commands to copy-and-paste, it will not actually set anything
on your BMCs.

Verify the output, make sure it looks right - and then 
### Fix NMN Hostname Resolution

The NMN won't resolve because the nodes don't update DHCP/DNS A, AAAA, nor PTR records
when their own hostnames change.

To work around this by hand, you will need to obtain the IP from dnsmasq logs, or from
it's `/var/lib/mic/dnsmasq.leases` file. This is a high-priority issue, that is just from a 
shortage of hands.

Once you map out which NMN IP goes to which node (ssh to the IP and see the hostname, or print off 
the IP for vlan002), then you may add them to `/etc/hosts` as such:

```
10.252.2.10	ncn-m001.nmn
10.252.2.11	ncn-m002.nmn
10.252.2.12	ncn-m003.nmn
10.252.2.13	ncn-w002.nmn
10.252.2.14	ncn-s001.nmn
10.252.2.15	ncn-s002.nmn
10.252.2.16	ncn-s003.nmn
```
**Note the domain, `.nmn`**.

Once `/etc/hosts` is adjusted, restart DNSMasq with:
```bash
systemctl restart dnsmasq
```
Now NMN names will be resolvable for the entire cluster, and our liveCD.

### Boot K8s

```bash
for bmc in $(grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases); do
    echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis bootdev pxe options=efiboot 
    echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis bootdev power on || echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis bootdev power reset
```

Watch consoles with the Serial-over-LAN, or use conamn if you've setup `/etc/conman.conf` with
the static IPs for the BMCs.

```bash
# Connect to ncn-s002..
username=''
password=''
bmc='ncn-s002-mgmt'
spit:~ # echo ipmitool -I lanplus -U $username -P $password -H $bmc sol activate

# ..or print available consoles:
spit:~ # conman -q
spit:~ # conman -j ncn-s002
```
