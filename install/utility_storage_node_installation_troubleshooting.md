# Utility Storage Installation Troubleshooting

If there is a failure in the creation of ceph storage on the utility storage nodes for one of these scenarios,
the ceph storage might need to be reinitialized.

Please match your scenario prior to executing any workarounds.

### Topics

* [Scenario 1](#scenario-1)

## Detais

<a name="scenario-1">
#### Scenario 1  (Shasta 1.4 only)

**`IMPORTANT (FOR NODE INSTALLS/REINSTALLS ONLY)`**: If your ceph install failed please check the following

```bash
 ncn-s# ceph osd tree
ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
-1       83.83459 root default
-5       27.94470     host ncn-s001
 0   ssd  3.49309         osd.0         up  1.00000 1.00000
 4   ssd  3.49309         osd.4         up  1.00000 1.00000
 6   ssd  3.49309         osd.6         up  1.00000 1.00000
 8   ssd  3.49309         osd.8         up  1.00000 1.00000
10   ssd  3.49309         osd.10        up  1.00000 1.00000
12   ssd  3.49309         osd.12        up  1.00000 1.00000
14   ssd  3.49309         osd.14        up  1.00000 1.00000
16   ssd  3.49309         osd.16        up  1.00000 1.00000
-3       27.94470     host ncn-s002
 1   ssd  3.49309         osd.1       down  1.00000 1.00000
 3   ssd  3.49309         osd.3       down  1.00000 1.00000
 5   ssd  3.49309         osd.5       down  1.00000 1.00000
 7   ssd  3.49309         osd.7       down  1.00000 1.00000
 9   ssd  3.49309         osd.9       down  1.00000 1.00000
11   ssd  3.49309         osd.11      down  1.00000 1.00000
13   ssd  3.49309         osd.13      down  1.00000 1.00000
15   ssd  3.49309         osd.15      down  1.00000 1.00000
-7       27.94519     host ncn-s003                            <--- node where our issue exists
 2   ssd 27.94519         osd.2       down  1.00000 1.00000    <--- our problematic VG.  

```

   **SSH to our node(s) where the issue exists and do the following:**

   1. ncn-s# systemctl stop ceph-osd.target
   2. ncn-s# vgremove -f --select 'vg_name=~ceph*'  
   *This will take a little bit of time, so don't panic.**
   3. ncn-s# for i in {g..n}; do sgdisk --zap-all /dev/sd$i; done.

   **This will vary node to node and you should use lsblk to identify all drives available to ceph**

   >**Manually create OSDs on the problematic nodes**
   >ncn-s# for i in {g..n}; do ceph-volume lvm create --data /dev/sd$i  --bluestore; done

   **ALL THE BELOW WORK WILL BE RUN FROM NCN-S001**

   1. Verify the /etc/cray/ceph directory is empty.  If there are any files there then delete them
   2. Put in safeguard
        * Edit /srv/cray/scripts/metal/lib.sh
       * Comment out the below lines

    ```bash
    22   if [ $wipe == 'yes' ]; then
    23     ansible osds -m shell -a "vgremove -f --select 'vg_name=~ceph*'"
    24   fi```

   Run the cloud init script
   ncn-s001# /srv/cray/scripts/common/storage-ceph-cloudinit.sh

#### Scenario 2  (Shasta 1.5 only)

IMPORTANT (FOR NODE INSTALLS/REINSTALLS ONLY): If your ceph install failed please check the following

```bash
 nncn-s001:~ # ceph osd tree
ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
-1         31.43875  root default
-3         10.47958      host ncn-s001
 2    ssd   1.74660          osd.2          up   1.00000  1.00000
 3    ssd   1.74660          osd.3          up   1.00000  1.00000
 6    ssd   1.74660          osd.6          up   1.00000  1.00000
 9    ssd   1.74660          osd.9          up   1.00000  1.00000
12    ssd   1.74660          osd.12         up   1.00000  1.00000
15    ssd   1.74660          osd.15         up   1.00000  1.00000
-5         10.47958      host ncn-s002
 0    ssd   1.74660          osd.0          down   1.00000  1.00000   <-- our bad OSD
 4    ssd   1.74660          osd.4          up   1.00000  1.00000
 7    ssd   1.74660          osd.7          up   1.00000  1.00000
10    ssd   1.74660          osd.10         up   1.00000  1.00000
13    ssd   1.74660          osd.13         up   1.00000  1.00000
16    ssd   1.74660          osd.16         up   1.00000  1.00000
-7         10.47958      host ncn-s003
 1    ssd   1.74660          osd.1          up   1.00000  1.00000
 5    ssd   1.74660          osd.5          up   1.00000  1.00000
 8    ssd   1.74660          osd.8          up   1.00000  1.00000
11    ssd   1.74660          osd.11         up   1.00000  1.00000
14    ssd   1.74660          osd.14         up   1.00000  1.00000
17    ssd   1.74660          osd.17         up   1.00000  1.00000
```


Since we know our host and osd, we can easily get more information.

```bash
ceph orch ps --daemon-type osd ncn-s002
NAME    HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE ID      CONTAINER ID
osd.0   ncn-s002  running (23h)  7m ago     2d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  98859a09a946
osd.10  ncn-s002  running (23h)  7m ago     2d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  808162b421b8
osd.13  ncn-s002  running (23h)  7m ago     2d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  594d6fd03361
osd.16  ncn-s002  running (23h)  7m ago     2d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  726295e3625f
osd.4   ncn-s002  running (23h)  7m ago     2d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  ee1987d99e5a
osd.7   ncn-s002  running (23h)  7m ago     2d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  78a89eaef92a
```

>>**optionally leave off the host name and it will return all the osd processesin the cluster**

On the node in question you will have to gather some information to zap a single OSD.


To list out the devices on that host:
1. ceph orch device ls <hostname>


   ```bash
   ncn-s00[123]:~ # ceph orch device ls ncn-s002 --wide
   Hostname  Path      Type  Transport  RPM      Vendor  Model             Serial          Size   Health   Ident  Fault  Available  Reject Reasons
   ncn-s002  /dev/sdc  ssd   Unknown    Unknown  ATA     SAMSUNG MZ7LH1T9  S455NY0M811867  1920G  Unknown  N/A    N/A    No         locked, LVM detected, Insufficient space (<10 extents) on vgs
   ncn-s002  /dev/sdd  ssd   Unknown    Unknown  ATA     SAMSUNG MZ7LH1T9  S455NY0M812407  1920G  Unknown  N/A    N/A    No         locked, LVM detected, Insufficient space (<10 extents) on vgs
   ncn-s002  /dev/sde  ssd   Unknown    Unknown  ATA     SAMSUNG MZ7LH1T9  S455NY0M812406  1920G  Unknown  N/A    N/A    No         locked, LVM detected, Insufficient space (<10 extents) on vgs
   ncn-s002  /dev/sdf  ssd   Unknown    Unknown  ATA     SAMSUNG MZ7LH1T9  S455NY0M812405  1920G  Unknown  N/A    N/A    No         locked, LVM detected, Insufficient space (<10 extents) on vgs
   ncn-s002  /dev/sdg  ssd   Unknown    Unknown  ATA     SAMSUNG MZ7LH1T9  S455NY0M811921  1920G  Unknown  N/A    N/A    No         locked, LVM detected, Insufficient space (<10 extents) on vgs
   ncn-s002  /dev/sdh  ssd   Unknown    Unknown  ATA     SAMSUNG MZ7LH1T9  S455NY0M811873  1920G  Unknown  N/A    N/A    No         locked, LVM detected, Insufficient space (<10 extents) on vgs
   ```

You may see devices on a node where it is not starting osds.  The locked is more than likely a result of a wipe failure.

Find your drive path

```bash
cephadm ceph-volume lvm list
ncn-s002:~ #  cephadm ceph-volume lvm list
Inferring fsid 8f4dd38b-ee84-4d29-8305-1ef24e61a5d8
Using recent ceph image docker.io/ceph/ceph@sha256:16d37584df43bd6545d16e5aeba527de7d6ac3da3ca7b882384839d2d86acc7d
/usr/bin/podman: stdout
/usr/bin/podman: stdout
/usr/bin/podman: stdout ====== osd.0 =======
/usr/bin/podman: stdout
/usr/bin/podman: stdout   [block]       /dev/ceph-380453cf-4581-4616-b95e-30a8743bece0/osd-data-59bcf0c9-5867-41c3-8e40-2e99232cf8e9
/usr/bin/podman: stdout
/usr/bin/podman: stdout       block device              /dev/ceph-380453cf-4581-4616-b95e-30a8743bece0/osd-data-59bcf0c9-5867-41c3-8e40-2e99232cf8e9
/usr/bin/podman: stdout       block uuid                54CjSj-kxEs-df0N-13Vs-miIF-g2KH-sX2UMQ
/usr/bin/podman: stdout       cephx lockbox secret
/usr/bin/podman: stdout       cluster fsid              8f4dd38b-ee84-4d29-8305-1ef24e61a5d8
/usr/bin/podman: stdout       cluster name              ceph
/usr/bin/podman: stdout       crush device class        None
/usr/bin/podman: stdout       encrypted                 0
/usr/bin/podman: stdout       osd fsid                  b2eb119c-4f45-430b-96b0-bad9e8b9aca6
/usr/bin/podman: stdout       osd id                    0  <-- our osd number
/usr/bin/podman: stdout       osdspec affinity
/usr/bin/podman: stdout       type                      block
/usr/bin/podman: stdout       vdo                       0
/usr/bin/podman: stdout       devices                   /dev/sdf  <-- our path
/usr/bin/podman: stdout

# Shortened output for example
```

To zap a single device:
1. ceph orch device zap (hostname) (device path)

```bash
ncn-s00[123] ceph orch device zap ncn-s002 /dev/sdf
```