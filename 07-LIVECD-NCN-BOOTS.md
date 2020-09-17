# LiveCD NCN Boots

Before starting this you are expected to have networking and serices setup.
If you are unsure, see the bottom of [11-LIVECD-SETUP.md](06-LIVECD-SETUP.md).

## IMPORTANT: Make sure the other nodes are shut down
This was done in an earlier section, but it's important you have **shut down all the other NCNs to prevent DHCP conflicts**.  

Typically, we should have eight leases for NCN BMCs. Some systems may have less, but the
recommended minimum is 3 of each type (k8s-managers, k8s-workers, ceph-storage).

Check for NCN lease count:
```
grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | wc -l
8
```

`8` is the number we're expecting typically, since NCN "number 9" is the node
currently booted up with the LiveCD (the node you're standing on).

Print off each NCN we'll target for booting.
```shell script
spit:~ # grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | sort
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

#### SKIP THIS STEP FOR DURING A 1.3 UPGRADE TEST.

If we loose DHCP for some reason, we can use defined IP addresses from
DNSmasq.

> Note: this requires a statics.conf file to be generated with the BMC MAC addresses.
> See [09-LIVECD-PREFLIGHT.md](10-LIVECD-PREFLIGHT.md) for more information.

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

## Ensure artifacts are in place

Mount the USB stick's data partition, and setup links for booting.

> Note: The set-sqfs-links.sh only works for one image at a time, you may have to move the
> k8s images or storage images out of the folder to run the script. Then swap artifacts for the next
> node type.

```
mkdir -pv /mnt/var/www/ephemeral
mount /dev/sdb4 !$
pushd /mnt/var/www/ephemeral
/root/bin/set-sqfs-links.sh
```

### Boot K8s

This will again just `echo` the commands.  Look them over and validate they are ok before running them.  This just `grep`s out the storage nodes so you only get the workers and managers.

```shell script
username=''
password=''
for bmc in $(grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | grep -v s00 | sort); do
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
