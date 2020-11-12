# LiveCD Setup

This page will assist you with configuring the LiveCD, a.k.a. Shasta Pre-Install Toolkit.

### Requirements:

Before starting, you should have:

1. A USB stick or other Block Device, local to ncn-m001.
   - The block device should be `>=256GB`
2. The drive letter of that device (i.e. `/dev/sdd`)
3. If you are installing a system that previously had 1.3 installed, move external network connections from ncn-w001 to ncn-m001
   - See [012-MOVE-SITE-CONNECTIONS.md](012-MOVE-SITE-CONNECTIONS.md).
4. Access to stash, to `git clone https://stash.us.cray.com/scm/mtl/cray-pre-install-toolkit.git` onto your NCN.
5. `csi` installed (get the [latest built rpm](http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/)

### Steps:

> These steps will be automated. CASM/MTL is automating this process  with the cray-site-init tool.

1. Install `csi`
2. Setup ENV vars for use with `csi`
3. Create the USB Stick
4. Gather the required input files
5. Generate the configuration payload
6. Download the artifacts for PXE booting
7. Shutdown NCNs
8. Boot into the LiveCD

## Manual Step 1: Install `csi`

`csi` can be used to create and populate your liveCD.  You can think of it as a "`crayctl`" if you need a way understand what the tool exists for.


You'll most likely want to grab whatever is the latest version:

```bash
# This won't work for copy/paste--adjust the rpm name
zypper in http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/cray-site-init-*.rpm
# If nexus isn't working or the pod is gone, you can also install with the rpm command:
rpm -Uhv http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/cray-site-init-*.rpm
```

## Manual Step 2: Create ENV vars for use with `csi`

Create a file with a bunch of environmental variables in it.  These are example values, but set these to what you need for your system:

```bash
vim vars.sh
```

```bash
#!/bin/bash
# These vars will likely stay the same unless there are development changes
export PIT_DISK_LABEL=/dev/disk/by-label/PITDATA
export PIT_ISO_NAME=cray-pre-install-toolkit-latest.iso
export PIT_REPO_URL=ssh://git@stash.us.cray.com:7999/mtl/cray-pre-install-toolkit.git
export PIT_ISO_URL=http://car.dev.cray.com/artifactory/internal/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/cray-pre-install-toolkit-latest.iso

# These will likely need to be modified
# These are the artifacts you want to be used to boot with
export PIT_WRITE_SCRIPT=/root/cray-pre-install-toolkit/scripts/write-livecd.sh
export PIT_DATA_DIR=/mnt/data
export PIT_CEPH_DIR=/mnt/data/ceph
export PIT_K8S_DIR=/mnt/data/k8s
export PIT_INITRD_URL=https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/sles15-base/0.0.1-5/initrd.img-0.0.1-5.xz
export PIT_KERNEL_URL=https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/sles15-base/0.0.1-5/5.3.18-24.24-default-0.0.1-5.kernel
export PIT_MANAGER_URL=https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/kubernetes/0.0.1-11/kubernetes-0.0.1-11.squashfs
export PIT_STORAGE_URL=https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/storage-ceph/0.0.1-12/storage-ceph-0.0.1-12.squashfs
# Note: Choose a different suffix for each of the URLs.  For example, your suffix may look something like `b020b06-1601944128692`.

# You can find the available builds here:
# - kubernetes image:  http://arti.dev.cray.com:80/artifactory/node-images-unstable-local/shasta/kubernetes
# - ceph image:  http://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/storage-ceph
# - base image:  http://arti.dev.cray.com:80/artifactory/node-images-unstable-local/shasta/sles15-base

# These won't be needed until you actually boot into the livecd, but you may want to set them now
# Set to false for now, so you can validate each step as you walk through the instructions
export PIT_VALIDATE_CEPH=false
export PIT_VALIDATE_DNS_DHCP=false
export PIT_VALIDATE_K8S=false
export PIT_VALIDATE_MTU=false
export PIT_VALIDATE_NETWORK=false
export PIT_VALIDATE_SERVICES=false
```


`source` the above file and copy to the livecd

Without this vars.sh file being `source`d you'd need to pass them manually at the command line.  

```bash
source vars.sh
```

## Manual Step 3: Create the USB Stick

1. Make the USB and fetch artifacts.

    ```bash
    # Find your USB stick with your linux tool of choice, for this example it is /dev/sdd
    wget $PIT_ISO_URL                                 
    git clone $PIT_REPO_URL
    csi pit format /dev/sdd ./cray-pre-install-toolkit-latest.iso 20000
    # If this fails, you may need to erase all the partitions and try again
    ```


2. Mount data partition:

    ```bash
    mount /dev/disk/by-label/PITDATA /mnt/
    ```

Now that your disk is setup and the data partition is mounted, you can begin gathering info and configs and populating it to the USB disk so it's available when you boot into the livecd.

3. Copy your vars file to the data partition

    ```bash
    cp vars.sh /mnt/
    ```

## Manual Step 4: Gather Information

This is the set of files that you will currently need to create or find to generate the config payload for the system

  1. ncn_metadata.csv
  2. hmn_connections.json

  In addition you will need to have the qnd-1.4.sh file to configure the LiveCD node.

#### qnd-1.4.sh

You will need to create the qnd-1.4.sh files with the following contents.   Replace values with those specific to your system.


```bash
export site_nic=em1
export site_cidr=172.30.52.220/20
export site_gw=172.30.48.1
export site_dns=172.30.84.40
export bond_member0=p801p1
export bond_member1=p801p2
export mtl_cidr=10.1.1.1/16
export nmn_cidr=10.252.0.10/17
export hmn_cidr=10.254.0.10/17
export can_cidr=10.102.4.110/24
```

- `site_nic`

    The interface that is directly attached to the site network on ncn-m001.

- `site_cidr`

    The IP address and netmask in CIDR notation that is assigned to the site connection on ncn-m001.  NOTE:  This is NOT just the network, but also the IP address.

- `site_gw`

    The gateway address for the site network.  This will be used to set up the default gateway route on ncn-m001.

- `site_dns`

    ONE of the site DNS servers.   The script does not currently handle setting more than one IP address here.

- `bond_member0` and `bond_member1`

    The two interfaces that will be bonded to the bond0 interface.

- `mtl_cidr`, `nmn_cidr`, `hmn_cidr`, and `can_cidr`

    The IP address and netmask in CIDR notation that is assigned to the bond0, vlan002, vlan004, and vlan007 interfaces on the LiveCD, respectively.  NOTE:  These include the IP address AND the netmask.  It is not just the network CIDR.

    Customer Access Network information will need to be gathered by hand. (For current BGP Dev status, see [Can BGP status on Shasta systems](https://connect.us.cray.com/confluence/display/CASMPET/CAN-BGP+status+on+Shasta+systems))


Copy this file to the mounted data partition.

```bash
cp qnd-1.4.sh /mnt
```


#### ncn_metadata.csv

This file should come from the shasta_system_configs repository at https://stash.us.cray.com/projects/DST/repos/shasta_system_configs/browse.   Each system has its own directory in the repository.   If this is a new system that doesn't yet have the ncn_metadata.csv file then one will need to be created by hand.   This is the format of that file.

```bash
NCN xname,NCN Role,NCN Subrole,BMC MAC,BMC Switch Port,NMN MAC,NMN Switch Port
x3000c0s9b0n0,Management,Storage,FIXME,x3000u14-j31,FIXME,NA
x3000c0s8b0n0,Management,Storage,FIXME,x3000u14-j30,FIXME,NA
x3000c0s7b0n0,Management,Storage,FIXME,x3000u14-j29,FIXME,NA
x3000c0s6b0n0,Management,Worker,FIXME,x3000u14-j28,FIXME,NA
x3000c0s5b0n0,Management,Worker,FIXME,x3000u14-j27,FIXME,NA
x3000c0s4b0n0,Management,Worker,FIXME,x3000u14-j40,FIXME,NA
x3000c0s3b0n0,Management,Master,FIXME,x3000u14-j26,FIXME,NA
x3000c0s2b0n0,Management,Master,FIXME,x3000u14-j25,FIXME,NA
x3000c0s1b0n0,Management,Master,FIXME,Site Connection,00:00:00:00:00:00,Site Connection
```

The NCN xname, BMC Switch Port, and NCN Switch Port can be determined from the CID for the system.
The BMC MAC should be the MAC of the BMC channel used to manage the system.
The NMN MAC should the MAC of the *first bond member*.

#### hmn_connections.json

This file should come from the shasta_system_configs repository at https://stash.us.cray.com/projects/DST/repos/shasta_system_configs/browse.   Each system has its own directory in the repository.   If this is a new system that doesn't yet have the hmn_connections.json file then one will need to be generated from the CID for the system.

```bash
docker run --rm -it --name hms-shcd-parser -v  ${shcd-absolute-path}:/input/shcd_file.xlsx -v $(pwd):/output dtr.dev.cray.com/cray/hms-shcd-parser:latest
```

Replace ${cid-absolute-path} with the absolute path to the latest CID for the system.
   
Make sure you have an up-to-date hmn_connections.json (i.e. one generated from the lastest CID for the system).
  

## Manual Step 5:  Generate the config payload

The configuration payload is generated with the `csi config init` command anywhere the command is installed and that has the required input files. 

1.  To execute this command you will need the following:

    - ncn_metadata.csv and hmn_connections.json in the current directory.

    - The username and password for the BMCs (normally, root and initial0)

    - xnames for the spine and leaf switches.   x3000c0wXX where XX is the slot in the rack

    - The CAN network in CIDR format (e.g. 10.103.10.0/24).  This will be different for every system.

    - The number of mountain and river cabinets in the system

    An example of the command to run with the required options.
    ``` bash
    csi config init --bootstrap-ncn-bmc-user root --bootstrap-ncn-bmc-pass initial0 --leaf-switch-xnames="x3000c0w14" --spine-switch-xnames="x3000c0w12,x3000c0w14" --system-name sif  --mountain-cabinets 0 --river-cabinets 1 --can-cidr 10.103.10.0/24
    ```


    This will generate the following files in a subdirectory with the system name.

    ``` bash
    sif-ncn-m001-pit:~ # ls -R sif
    sif:
    conman.conf  data.json      dnsmasq.d      metallb.yaml      sls_input_file.json
    credentials  manufacturing  networks       system_config.yaml

    sif/credentials:
    bmc_password.json  mgmt_switch_password.json  root_password.json

    sif/dnsmasq.d:
    CAN.conf  HMN.conf  mtl.conf  NMN.conf	statics.conf

    sif/manufacturing:

    sif/networks:
    CAN.yaml  HMN.yaml  HSN.yaml  MTL.yaml	NMN.yaml
    ```

2.  There are a few additional workarounds that need to be done manually in the files until some further bugs are fixed.

- First generate a data.json that is easier to edit.

  ```bash
  cp data.json data.json.orig
  cat data.json.orig | python -mjson.tool > data.json
  ```
- CASMINST-262 and CASMINST-281
n
  - Add `/srv/cray/scripts/metal/install-bootloader.sh` to the runcmd for each node immediately after set-ntp-config.sh.

  ```bash
        "runcmd": [
        "/srv/cray/scripts/metal/set-dns-config.sh",
        "/srv/cray/scripts/metal/set-ntp-config.sh",
        "/srv/cray/scripts/metal/install-bootloader.sh",
        "/srv/cray/scripts/common/kubernetes-cloudinit.sh"
      ]
  ```

  - Add `Global`, `Default`, `ncn-storage`, `ncn-master`, and `ncn-worker` sections to the end of data.json before the last curly bracket `}`.   Make sure to add a comma after the second-to-last curly bracket `{`.


   ``` bash
     },
     "Default": {
       "meta-data": {
         "foo": "bar",
         "shasta-role": "ncn-storage"
       },
       "user-data": {}
     },
     "ncn-storage": {
       "meta-data": {
         "ceph_version": "1.0",
         "self_destruct": "false"
       },
       "user-data": {
         "test": "123",
         "runcmd": [
           "echo This is a storage cmd $(date) > /opt/runcmd"
         ]
       }
     },
     "ncn-master": {
       "meta-data": {
         "self_destruct": "false"
       },
       "user-data": {
         "test": "123",
         "runcmd": [
           "echo This is a master cmd $(date) > /opt/runcmd"
         ]
       }
     },
     "ncn-worker": {
       "meta-data": {
         "self_destruct": "false"
       },
       "user-data": {
         "test": "123",
         "runcmd": [
           "echo This is a worker cmd $(date) > /opt/runcmd"
         ]
       }
     },
     "Global": {
       "meta-data": {
         "can-gw": "~FIXME~ e.g. 10.102.9.20",
         "can-if": "vlan007",
         "ceph-cephfs-image": "dtr.dev.cray.com/cray/cray-cephfs-provisioner:0.1.0-nautilus-1.3",
         "ceph-rbd-image": "dtr.dev.cray.com/cray/cray-rbd-provisioner:0.1.0-nautilus-1.3",
         "chart-repo": "http://helmrepo.dev.cray.com:8080",
         "dns-server": "~FIXME~ e.g. 10.252.1.1",
         "docker-image-registry": "dtr.dev.cray.com",
         "domain": "nmn hmn",
         "first-master-hostname": "~FIXME~ e.g. ncn-m002",
         "k8s-virtual-ip": "~FIXME~ e.g. 10.252.120.2",
         "kubernetes-max-pods-per-node": "200",
         "kubernetes-pods-cidr": "10.32.0.0/12",
         "kubernetes-services-cidr": "10.16.0.0/12",
         "kubernetes-weave-mtu": "1460",
         "ntp_local_nets": "~FIXME~ e.g. 10.252.0.0/17,10.254.0.0/17",
         "ntp_peers": "~FIXME~ e.g. ncn-w001 ncn-w002 ncn-w003 ncn-s001 ncn-s002 ncn-s003 ncn-m001 ncn-m002 ncn-m003",
         "num_storage_nodes": "3",
         "rgw-virtual-ip": "~FIXME~ e.g. 10.252.2.100",
       "upstream_ntp_server": "~FIXME~",
         "wipe-ceph-osds": "yes"
       }
     }
   }
   ```

- CASMINST-249

  - Fix the peers defined in metallb.yaml.   There should be two peers.   The IP addresses should match the vlan 7 IP of each of the spines.

   ```bash
      	peers:
	- peer-address: 10.252.0.2 
	  peer-asn: 65533
	  my-asn: 65533
	- peer-address: 10.252.0.3 
	  peer-asn: 65533
	  my-asn: 65533
   ```

  - Fix the customer-access-static and customer-access address pools to match what is in [Can BGP status on Shasta systems](https://connect.us.cray.com/confluence/display/CASMPET/CAN-BGP+status+on+Shasta+systems)

  - Set the hardware-management address pool to 10.94.100.0/24


   ```bash
	- name: hardware-management
	  protocol: bgp
	  addresses:
	  - 10.94.100.0/24
   ```

  - Set the node-management address pool to 10.92.100.0/24


   ```bash
	- name: node-management
	  protocol: bgp
	  addresses:
	  - 10.92.100.0/24
   ```

- CASMINST-294

   Add the MAC address for the MTL dhcp-host entry for each node in dnsmasq.d/statics.conf.   This should be the bond0 MAC (i.e. the same MAC as the one used for NMN, HMN, and CAN).

   ```bash
    # DHCP Entries for ncn-s002
    dhcp-host=14:02:ec:da:b9:38,10.252.0.154,ncn-s002,infinite # NMN
    dhcp-host=14:02:ec:da:b9:38,10.1.0.24,ncn-s002,infinite # MTL
    dhcp-host=14:02:ec:da:b9:38,10.254.0.154,ncn-s002,infinite # HMN
    dhcp-host=14:02:ec:da:b9:38,10.102.11.218,ncn-s002,infinite # CAN
    dhcp-host=94:40:c9:37:77:da,10.254.0.153,ncn-s002-mgmt,infinite #HMN
   ```


- CASMINST-250

   - Fix the `dns-server`, `ntp-server`, and `router` options in mtl.conf, HMN.conf, and NMN.conf to match the IP address for bond0, vlan004, and vlan002 (respectively) on the LiveCD node.

   For example, in this case, the vlan004 interface has IP address 10.254.0.9 on the LiveCD.
   
   ```bash
   dhcp-option=interface:vlan004,option:dns-server,10.254.0.9
   dhcp-option=interface:vlan004,option:ntp-server,10.254.0.9
   dhcp-option=interface:vlan004,option:router,10.254.0.9
   ```

   - Fix the `router` option in CAN.conf to match the *gateway* IP address of vlan7 on this spines.   For Aruba switches, this is the `active-gateway ip`.   For Mellanox switches, this is the `magp` IP.

   ```bash
   sw-spine01# show running-config interface vlan 7
   interface vlan7
    vsx-sync active-gateways
    ip address 10.102.11.1/24
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.102.11.111
    ip mtu 9198
    exit
   ```

   ```bash
   dhcp-option=interface:vlan004,option:router,10.102.11.111
   ```

- CASMINST-251

    For NMN.conf, HMN.conf, CAN.conf, and mtl.conf, make sure the dhcp-range starts AFTER the IPs that are fixed in statics.conf.

    ```bash
    sif-ncn-m001-spit:~/johren/sif/sif/dnsmasq.d # grep 10.252 statics.conf
    dhcp-host=14:02:ec:d9:7a:90,10.252.0.153,ncn-s003,infinite # NMN
    host-record=ncn-s003,ncn-s003.nmn,10.252.0.153
    dhcp-host=14:02:ec:da:b9:38,10.252.0.154,ncn-s002,infinite # NMN
    host-record=ncn-s002,ncn-s002.nmn,10.252.0.154
    dhcp-host=14:02:ec:d9:77:a8,10.252.0.155,ncn-s001,infinite # NMN
    host-record=ncn-s001,ncn-s001.nmn,10.252.0.155
    dhcp-host=14:02:ec:d9:7a:30,10.252.0.156,ncn-w003,infinite # NMN
    host-record=ncn-w003,ncn-w003.nmn,10.252.0.156
    dhcp-host=14:02:ec:d9:7b:b0,10.252.0.157,ncn-w002,infinite # NMN
    host-record=ncn-w002,ncn-w002.nmn,10.252.0.157
    dhcp-host=14:02:ec:da:b7:28,10.252.0.158,ncn-w001,infinite # NMN
    host-record=ncn-w001,ncn-w001.nmn,10.252.0.158
    dhcp-host=14:02:ec:d9:79:a0,10.252.0.159,ncn-m003,infinite # NMN
    host-record=ncn-m003,ncn-m003.nmn,10.252.0.159
    dhcp-host=14:02:ec:d9:78:20,10.252.0.160,ncn-m002,infinite # NMN
    host-record=ncn-m002,ncn-m002.nmn,10.252.0.160
    dhcp-host=14:02:ec:d9:7a:18,10.252.0.161,ncn-m001,infinite # NMN
    host-record=ncn-m001,ncn-m001.nmn,10.252.0.161
    host-record=kubeapi-vip,kubeapi-vip.nmn,10.252.0.151 # k8s-virtual-ip
    host-record=rgw-vip,rgw-vip.nmn,10.252.0.152 # rgw-virtual-ip
    ```

    For example, the last NMN IP in statics.conf is 10.252.0.161.   Therefore, the dhcp-range in NMN.conf should start AFTER 10.252.0.161.

    ```bash
    dhcp-range=interface:vlan002,10.252.0.165,10.252.0.190,10m
    ```

3. There are some FIXMES that need to be fixed in data.json. 
 
    ```
    # STOP!
    # Edit, adjust all the ~FIXMES
    # The values for the `global_data` should be cross-referenced to `networks*.yml` and
    # `kubernetes.yml`.
    vim data.json
    ```

    - `k8s-virtual-ip` and `rgw-virtual-ip`

        If you are installing a system that was previously 1.3, you can get these values from networks.yml for your system:  `https://stash.us.cray.com/projects/DST/repos/shasta_system_configs/browse/<system-name>/networks.yml`

        ```bash
        grep rgw_virtual_ip networks.yml
        grep k8s_virtual_ip networks.yml
        ```

    - `first-master-hostname`

        Set this to ncn-m002 since ncn-m001 will be used for the LiveCD.

    - `dns-server`

        Set this to the IP used for `nmn_cidr` in qnd-1.4.sh.  Do NOT include the /netmask.  This should be the IP only.  This will be the IP of the LiveCD where dnsmasq will be running.

    - `can-gw`

        Set this to the IP virtual gateway for vlan 7 on the spine switches.

    -  `ntp_local_nets`

        Leave this as the provided defaults `10.252.0.0/17,10.254.0.0/17`.   Just remove the `~FIXME~`.

    -  `ntp_peers`

        Enumerate all of the NCNs in the cluster.  In most cases, you can leave this as the default.

    -  `upstream_ntp_server`

        Set this to `cfntp-4-1.us.cray.com`

4.  Copy these files to the mounted data partition.

    ```bash
    cp -r ${system-name} /mnt
    mkdir /mnt/configs 
    cp ${system-name}/data.json /mnt/configs
    ```
    
## Manual Step 6: Download booting artifacts

Fetch the current working set of artifacts.

> Note:  When running on a system that has 1.3 installed, you may hit a collision with an ip rule that prevents access to arti.dev.cray.com.   If you cannot ping that name, try removing this ip rule:

```
ip rule del from all to 10.100.0.0/17 lookup rt_smnet
```

> NOTE: [CASMINST-245](https://connect.us.cray.com/jira/browse/CASMINST-245) k8s will encounter disk-pressure
> because the mount points for /run/containerd, /var/lib/kubelet, and /var/lib/containerd are not ready.
> These are coming in fast (week of 11/09), until then these images need to be fetched after running the `csi` command below.
> - https://arti.dev.cray.com/artifactory/node-images-unstable-local/shasta/kubernetes/b63f06b-1604671164414/kubernetes-b63f06b-1604671164414.squashfs

```bash
# This will pull from the vars created in step 1.  You can also pull individual components with the command flags.
# If you didn't earlier:
source vars.sh
# Then download the artifacts:
csi pit get
```

Unmount the data partition

```bash
    umount /mnt
```

## Manual Step 7 : Shutdown NCNs

Make sure all of the NCNs other than ncn-m001 are powered off.  If you still have access to the BMC IPs, you can use ipmitool to confirm.

```bash
for i in m002 m003 w001 w002 w003 s001 s002 s003;do ipmitool -I lanplus -U $username -P $password -H ncn-${i}-mgmt chassis power status;done
```

## Manual Step 8 : Boot into your LiveCD.
Now you can boot into your LiveCD [005-LIVECD-BOOTS.md](005-LIVECD-BOOTS.md)
