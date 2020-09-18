# LiveCD NCN Boots

Before starting this you are expected to have networking and serices setup.
If you are unsure, see the bottom of [006-LIVECD-SETUP.md](006-LIVECD-SETUP.md).

## IMPORTANT: Make sure the other nodes are shut down
This was done in an earlier section, but it's important you have **shut down all the other NCNs to prevent DHCP conflicts**.  

Typically, we should have eight leases for NCN BMCs. Some systems may have less, but the
recommended minimum is 3 of each type (k8s-managers, k8s-workers, ceph-storage).

## Manual Check 1: Validate Controller Leases

You will need to create a static file for the BMCs, at least so DNSMasq can map MAC to Hostname.
Follow BMC section guide at the bottom of [004-LIVECD-PREFLIGHT](004-LIVECD-PREFLIGHT.md).

If you have that file, you can move on.

1. Check for NCN lease count:

    ```bash
    grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | wc -l
    8
    ```

    `8` is the number we're expecting typically, since NCN "number 9" is the node
    currently booted up with the LiveCD (the node you're standing on).

2. Print off each NCN we'll target for booting.

    ```bash
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

# Manual Step 1:  Ensure artifacts are in place

Mount the USB stick's data partition, and setup links for booting.

> Note: The `set-sqfs-links.sh` only works for one image at a time, you may have to move the
> k8s images or storage images out of the folder to run the script. Then swap artifacts for the next
> node type.

The ideal is to mount the data disk where we're serving from, since it's already on the same device.
It is not recommended to copy the artifacts into place, because the copy-on-write partition may be
smaller than the data partition.

    ```bash
    spit:~ # mkdir -pv /mnt/var/www/ephemeral
    spit:~ # mount /dev/sdb4 !$
    spit:~ # pushd /mnt/var/www/ephemeral
    spit:~ # /root/bin/set-sqfs-links.sh
    ```

# Manual Step 2: Boot Storage Nodes

This will again just `echo` the commands.  Look them over and validate they are ok before running them.  This just `grep`s out the storage nodes so you only get the workers and managers.

```bash
username=''
password=''
for bmc in $(grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | grep s | sort); do
    echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis bootdev pxe options=efiboot
    echo "ipmitool -I lanplus -U $username -P $password -H $bmc chassis power on 2>/dev/null || echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis power reset"
done
```

Watch consoles with the Serial-over-LAN, or use conman if you've setup `/etc/conman.conf` with
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

### Manual Step 3: Boot K8s

This will again just `echo` the commands.  Look them over and validate they are ok before running them.  This just `grep`s out the storage nodes so you only get the workers and managers.

```bash
# Fixup the link to boot K8s nodes:
spit:~ # ln -snf /var/www/filesystem.squashfs /var/www/kubernetes.squashfs
```
Then go ahead and boot your nodes:
```bash
username=''
password=''
for bmc in $(grep -Eo ncn-.*-mgmt /var/lib/misc/dnsmasq.leases | grep -v s | sort); do
    echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis bootdev pxe options=efiboot
    echo "ipmitool -I lanplus -U $username -P $password -H $bmc chassis power on 2>/dev/null || echo ipmitool -I lanplus -U $username -P $password -H $bmc chassis power reset"
done
```

### Manual Check 2: Storage

> TODO: Craig Delatte

### Manual Check 3: Check K8s

> TODO: Brad Klein and Jeanne Ohren
