
### Utility Storage Installation Troubleshooting

Occasionally we observe an installation failure during the ceph install.  We will break these up into scenarios.  Please match your scenario prior to executing any workarounds

#### Scenario 1

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
   
   1.  ncn-s# systemctl stop ceph-osd.target
   2.  ncn-s# vgremove -f --select 'vg_name=~ceph*'  
   *This will take a little bit of time, so don't panic.**
   3.  ncn-s# for i in {g..n}; do sgdisk --zap-all /dev/sd$i; done.
   
   **This will vary node to node and you should use lsblk to identify all drives available to ceph** 

   >**Manually create OSDs on the problematic nodes**
   >ncn-s# for i in {g..n}; do ceph-volume lvm create --data /dev/sd$i  --bluestore; done
   
   **ALL THE BELOW WORK WILL BE RUN FROM NCN-S001**
   
   1. Verify the /etc/cray/ceph directory is empty.  If there are any files there then delete them
   2. Put in safeguard
        - Edit /srv/cray/scripts/metal/lib.sh
       - Comment out the below lines
   
    ```bash
    22   if [ $wipe == 'yes' ]; then
    23     ansible osds -m shell -a "vgremove -f --select 'vg_name=~ceph*'"
    24   fi```
   
   Run the cloud init script
   ncn-s001# /srv/cray/scripts/common/storage-ceph-cloudinit.sh
