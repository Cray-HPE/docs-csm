# LiveCD NCN Boots

Before starting this you are expected to have networking and services setup.
If you are unsure, see the bottom of [006-LIVECD-SETUP.md](006-LIVECD-SETUP.md).

### IMPORTANT : NCN Power State & DHCP

Make sure the other nodes are shutdown.  This was done in an earlier section, but it's important
 you have **shut down all the other NCNs to prevent DHCP conflicts**.  

### IMPORTANT : Switchport MTU

Make sure the MTU of the spine ports connected to the NCNs is set to 9216.  Check this on both spines.

  ```bash
  sw-spine01 [standalone: master] # show interface status | include ^Mpo
  Mpo1                  Up                    Enabled                                           9216              -
  Mpo2                  Up                    Enabled                                           9216              -
  Mpo3                  Up                    Enabled                                           9216              -
  Mpo4                  Up                    Enabled                                           9216              -
  Mpo5                  Up                    Enabled                                           9216              -
  Mpo6                  Up                    Enabled                                           9216              -
  Mpo7                  Up                    Enabled                                           9216              -
  Mpo8                  Up                    Enabled                                           9216              -
  Mpo9                  Up                    Enabled                                           9216              -
  Mpo11                 Down                  Enabled                                           9216              -
  Mpo12                 Down                  Enabled                                           9216              -
  Mpo15                 Down                  Enabled                                           9216              sw-leaf01-mlag
  Mpo114                Down                  Enabled                                           9216              -
  Mpo115                Up                    Enabled                                           9216              -
  ```


Typically, we should have eight leases for NCN BMCs. Some systems may have less, but the
recommended minimum is 3 of each type (k8s-managers, k8s-workers, ceph-storage).

## STOP and Check: Manually Validate Controller Leases

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
    ncn-m002-mgmt
    ncn-m003-mgmt
    ncn-w001-mgmt
    ncn-w002-mgmt
    ncn-w003-mgmt
    ncn-s001-mgmt
    ncn-s002-mgmt
    ncn-s003-mgmt
    ```

# Manual Step 1:  Ensure artifacts are in place

Mount the USB stick's data partition, and setup links for booting.

> Note: The `set-sqfs-links.sh` only works for one image at a time, you may have to move the
> k8s images or storage images out of the folder to run the script. Then swap artifacts for the next
> node type.


# Manual Step 2: Boot Storage Nodes

This will again just `echo` the commands.  Look them over and validate they are ok before running them.  This just `grep`s out the storage nodes so you only get the workers and managers.

Setup the ceph image to boot:
```bash
spit:~ # /root/bin/set-sqfs-links.sh ceph
# Now double-check ceph-storage is chosen:
spit:~ # ls -l /var/www/filesystem.squashfs
lrwxrwxrwx 1 root root 58 Sep 23 00:23 /var/www/filesystem.squashfs -> /var/www/ephemeral/data/ceph/storage-ceph-0.0.1-6.squashfs
```

Get our boot commands:
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

# Manual Step 3: Boot K8s

This will again just `echo` the commands.  Look them over and validate they are ok before running them.  This just `grep`s out the storage nodes so you only get the workers and managers.

```bash
spit:~ # /root/bin/set-sqfs-links.sh k8s
# Now double-check kubernetes is chosen:
spit:~ # ls -l /var/www/filesystem.squashfs
lrwxrwxrwx 1 root root 55 Sep 23 10:04 /var/www/filesystem.squashfs -> /var/www/ephemeral/data/k8s/kubernetes-0.0.1-4.squashfs
```

```bash
# Fixup the link to boot K8s nodes:
spit:~ # ln -snf /var/www/filesystem.squashfs /var/www/k8s-filesystem.squashfs
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

## STOP and Check: Manually Inspect Storage

Run ceph -s and verify cluster is healthy from ncn-s001.nmn.  Verify that health is HEALTH_OK, and that we have mon, mgr, mds, osd and rgw services in the output:

```bash
ncn-s001:~ # ceph -s
  cluster:
    id:     99ffa799-1209-49d4-9889-c7c3056e2062
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 13m)
    mgr: ncn-s001(active, since 5m), standbys: ncn-s003, ncn-s002
    mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
    osd: 18 osds: 18 up (since 10m), 18 in (since 10m)
    rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)

  task status:
    scrub status:
        mds.ncn-s002: idle

  data:
    pools:   10 pools, 968 pgs
    objects: 342 objects, 26 KiB
    usage:   18 GiB used, 24 TiB / 24 TiB avail
    pgs:     968 active+clean
```
Verify 3 storage classes have been created (can run on ncn-s001.nmn):

```bash
ncn-s001:~ # kubectl get storageclass
NAME                             PROVISIONER       RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
ceph-cephfs-external             ceph.com/cephfs   Delete          Immediate           false                  4m47s
k8s-block-replicated (default)   ceph.com/rbd      Delete          Immediate           true                   5m50s
sma-block-replicated             ceph.com/rbd      Delete          Immediate           true                   5m31s
```

## STOP and Check: Manually Check K8s

Verify all nodes have joined the cluster (can run on any master/worker):

```bash
ncn-m002:~ # kubectl get nodes
NAME       STATUS   ROLES    AGE     VERSION
ncn-m002   Ready    master   7m31s   v1.18.6
ncn-m003   Ready    master   8m16s   v1.18.6
ncn-w001   Ready    <none>   7m21s   v1.18.6
ncn-w002   Ready    <none>   7m42s   v1.18.6
ncn-w003   Ready    <none>   8m02s   v1.18.6
```

Also verify that all the pods in the kube-system namespace are running:

```bash
ncn-m002:~ # kubectl get po -n kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-66bff467f8-7psjb           1/1     Running   0          8m12s
coredns-66bff467f8-hhw8f           1/1     Running   0          8m12s
etcd-ncn-m001                      1/1     Running   0          8m20s
etcd-ncn-m002                      1/1     Running   0          7m25s
etcd-ncn-m003                      1/1     Running   0          2m34s
kube-apiserver-ncn-m001            1/1     Running   0          8m20s
kube-apiserver-ncn-m002            1/1     Running   0          7m5s
kube-apiserver-ncn-m003            1/1     Running   0          2m21s
kube-controller-manager-ncn-m001   1/1     Running   1          8m20s
kube-controller-manager-ncn-m002   1/1     Running   0          7m5s
kube-controller-manager-ncn-m003   1/1     Running   0          2m21s
kube-multus-ds-amd64-7cnxz         1/1     Running   0          2m39s
kube-multus-ds-amd64-8vdld         1/1     Running   0          2m35s
kube-multus-ds-amd64-dxxvj         1/1     Running   1          7m30s
kube-multus-ds-amd64-ltncv         1/1     Running   0          8m12s
kube-proxy-lr6z9                   1/1     Running   0          2m35s
kube-proxy-pmv8l                   1/1     Running   0          7m30s
kube-proxy-s7jsl                   1/1     Running   0          2m39s
kube-proxy-z9r2m                   1/1     Running   0          8m12s
kube-scheduler-ncn-m001            1/1     Running   1          8m20s
kube-scheduler-ncn-m002            1/1     Running   0          7m4s
kube-scheduler-ncn-m003            1/1     Running   0          2m20s
weave-net-bf8qn                    2/2     Running   0          7m55s
weave-net-hsczs                    2/2     Running   4          7m30s
weave-net-schwt                    2/2     Running   0          2m39s
weave-net-vwqbt                    2/2     Running   0          2m35s
```

Now you can start **Installing platform services** [008-PLATFORM-INSTALL.md](008-PLATFORM-INSTALL.md)
