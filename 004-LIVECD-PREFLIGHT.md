# LiveCD Setup

This page will assist you with configuring the LiveCD, a.k.a. Shasta Pre-Install Toolkit.

### Requirements:

Before starting, you should have:

1. A machine with 1.3.x installed
2. A USB stick or other Block Device, local to ncn-m001.
   - The block device should be `>=32GB`, the toolkit's built from "just-enough-OS" and can fit on smaller drives.
3. The drive letter of that device (i.e. `/dev/sdd`)
4. External network connections moved from ncn-w001 to ncn-m001
   - See [012-MOVE-SITE-CONNECTIONS.md](012-MOVE-SITE-CONNECTIONS.md).
5. Access to stash, to `git clone https://stash.us.cray.com/scm/mtl/cray-pre-install-toolkit.git` onto your NCN.
6. `csi` installed (get the [latest built rpm](http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/x86_64/dev/master/metal-team/)

### Steps:

> These steps will be automated. CASM/MTL is automating this process  with the cray-site-init tool.

1. Install `csi`
2. Setup ENV vars for use with `csi`
3. Create the USB Stick
4. Information gathering and configuration payload (most of your time will be spent here)
5. Init and prep configuration files; download the artifacts for PXE booting
6. Shutdown NCNs
7. Boot into the LiveCD

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


## `source` the above file and copy to the livecd

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
    ncn-m001:~ # mount /dev/disk/by-label/PITDATA /mnt/
    ```

Now that your disk is setup and the data partition is mounted, you can begin gathering info and configs and populating it to the USB disk so it's available when you boot into the livecd.

### Copy your vars file over

```bash
cp vars.sh /mnt/
```

## Manual Step 2: Gather Information

### The variables are just examples (your system will likely be different)
This presumes you have 1.3.x configuration files, 1.2 should suffice but locations may differ and mileage may vary. They are for visual reference only. It will not be possible to fully deploy a system (NCN, CN, & HSN) using these values, it is safer to **use 1.3 values or start fresh.**

### 1.3.x -> 1.4 Quick-n-dirty data gathering...

LiveCD setup information can be collected by hand.  Alternatively, you can run this on any 1.3.X system to print out an easy-script for setting up your liveCD for your system.

> **This will all be replaced by the cray-site-init tool; this is just a helper for 1.3.X
> testing.**

The following steps will detail how to quickly collect information from a semi, or fully installed 1.3 system. "Semi" installed refers to at least running `crayctl init`, ideally making it through `stage1`.

1. Copy the qnd-1.4.sh file that you created on ncn-w001 in [012-MOVE-SITE-CONNECTIONS.md](012-MOVE-SITE-CONNECTIONS.md) to the mounted data partition.

    ```bash
    ncn-m001:~ # cp /root/qnd-1.4.sh /mnt
    ```


2. You'll also want to gather network info for the interfaces on ncn-m001. This would be:

    > These are example variables; adjust them as needed for your environment.

    - site_cidr: The IP/netmask for em1 on ncn-m001
    - site_gw: The default gateway IP on ncn-m001 shown by running ip route | grep default
    - site_dns: These should match the example below
    - nmn_cidr: The IP/netmask for vlan002 on ncn-m001
    - hmn_cidr: The IP/netmask for vlan004 on ncn-m001

    ```bash
    echo export site_cidr=172.30.52.220/20 >>/mnt/qnd-1.4.sh
    echo export site_gw=172.30.48.1 >>/mnt/qnd-1.4.sh
    echo export site_dns="'172.30.84.40 172.31.84.40'" >>/mnt/qnd-1.4.sh
    echo export nmn_cidr=10.252.0.10/17 >>/mnt/qnd-1.4.sh
    echo export hmn_cidr=10.254.0.10/17 >>/mnt/qnd-1.4.sh
    ```


3.  Customer Access Network information will need to be gathered by hand and kept. (For current BGP Dev status, see [Can BGP status on Shasta systems](https://connect.us.cray.com/confluence/display/CASMPET/CAN-BGP+status+on+Shasta+systems)):

    > These are example variables; adjust them as needed for your environment

    ```bash
    echo export can_cidr=10.102.4.110/24 >> /mnt/qnd-1.4.sh
    echo export can_dhcp_start=10.102.4.5 >> /mnt/qnd-1.4.sh
    echo export can_dhcp_end=10.102.4.109 >> /mnt/qnd-1.4.sh
    echo export can_gw=10.102.4.111 >> /mnt/qnd-1.4.sh
    ```


4. Optionally, adjust dhcp time for 1.4 leases:

    > These are example variables; adjust them as needed for your environment

    ```bash
    # Default is 10m
    echo export dhcp_ttl=2m >> /mnt/qnd-1.4.sh
    ```


5. Print the script into terminal to visually verify things. There will be a reminder to copy this file into our LiveCD in the creation readme.

    > These are example variables; adjust them as needed for your environment

    ```bash
    # Print the file we made:
    ncn-m001:~/csi # cat /mnt/qnd-1.4.sh
    export site_nic=em1
    export bond_member0=p801p1
    export bond_member1=p801p2
    export mtl_cidr=10.1.1.1/16
    export mtl_dhcp_start=10.1.2.3
    export mtl_dhcp_end=10.1.2.254
    export nmn_dhcp_start=10.252.50.0
    export nmn_dhcp_end=10.252.99.252
    export hmn_dhcp_start=10.254.50.5
    export hmn_dhcp_end=10.254.99.252
    export site_cidr=172.30.52.220/20
    export site_gw=172.30.48.1
    export site_dns='172.30.84.40 172.31.84.40'
    export nmn_cidr=10.252.0.10/17
    export hmn_cidr=10.254.0.10/17
    export can_cidr=10.102.4.110/24
    export can_dhcp_start=10.102.4.5
    export can_dhcp_end=10.102.4.109
    export can_gw=10.102.4.111
    export dhcp_ttl=2m    
    ```

   > Alternative / Hand-collection.

    If you don't have that information, then you need the following otherwise move on (for current BGP Dev status, see [Can BGP status on Shasta systems](https://connect.us.cray.com/confluence/display/CASMPET/CAN-BGP+status+on+Shasta+systems)).
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

Your quick-and-dirty script is now saved to your USB stick.  Next, we'll gather more information needed for `dnsmasq`.


## Manual Step 3: Init Configs and Fetch Artifacts

data.json is the main metadata file for configuring nodes in cloud-init.

> Note: This manual step is tedious and will be removed by automation.

1. Fetch the latest metadata file for your system.

    > Replace `<system-name>` with your system (e.g. fanta)

   ```bash
   ncn-m001:~ # wget https://stash.us.cray.com/projects/DST/repos/shasta_system_configs/raw/<system-name>/ncn_metadata.csv
   ```


2. Edit the `ncn_metadata.csv` file to add `Bond MAC`, `Node Name`, and `NMN IP` columns.

   - Bond MAC will be the MAC of the bond0 interface on the NCN.   You can get this from the macs.txt file that was created in [012-MOVE-SITE-CONNECTIONS.md](012-MOVE-SITE-CONNECTIONS.md) if you are installing a system that previously had 1.3 installed.
   - Node Name will be the hostname for the node.
   - NMN IP should match what was on the 1.3 install.   If you are installing a new system, make sure the IPs for the worker nodes match IPs in the spine switch configuration.


   You will also need to set the BMC MAC and Bond MAC for w001 since that was not captured originally.   You can leave the NMN MAC set to 00:00:00:00:00:00 since we will not use that.  
   You can get BMC MAC and Bond MAC from the macs.txt file that was created in [012-MOVE-SITE-CONNECTIONS.md](012-MOVE-SITE-CONNECTIONS.md) if you are installing a system that previously had 1.3 installed.

   ```bash
   NCN xname,NCN Role,NCN Subrole,BMC MAC,BMC Switch Port,NMN MAC,NMN Switch Port,Bond MAC,Node Name,NMN IP
   x3000c0s1b0n0,Management,Master,a4:bf:01:5a:aa:03,x3000u25-p25,a4:bf:01:5a:a9:ff,x3000u25-p02,98:03:9b:1a:f6:70,ncn-m001,10.252.0.10
   x3000c0s3b0n0,Management,Master,a4:bf:01:5a:b0:00,x3000u25-p26,a4:bf:01:5a:af:fc,x3000u25-p03,b8:59:9f:2b:31:02,ncn-m002,10.252.0.11
   x3000c0s5b0n0,Management,Master,a4:bf:01:68:55:ad,x3000u25-p27,a4:bf:01:68:55:a9,x3000u25-p04,b8:59:9f:2b:31:06,ncn-m003,10.252.0.12
   x3000c0s7b0n0,Management,Worker,a4:bf:01:5a:ad:34,Site Connection,00:00:00:00:00:00,Site Connection,98:03:9b:1a:f6:70,ncn-w001,10.252.0.4
   x3000c0s9b0n0,Management,Worker,a4:bf:01:5a:d5:fa,x3000u25-p28,a4:bf:01:5a:d5:f6,x3000u25-p05,98:03:9b:0f:39:4a,ncn-w002,10.252.0.5
   x3000c0s11b0n0,Management,Worker,a4:bf:01:5a:d5:ec,x3000u25-p29,a4:bf:01:5a:d5:e8,x3000u25-p06,50:6b:4b:08:d0:4a,ncn-w003,10.252.0.6
   x3000c0s13b0n0,Management,Storage,a4:bf:01:65:66:cc,x3000u25-p30,a4:bf:01:65:66:c8,x3000u25-p07,b8:59:9f:2b:2e:d2,ncn-s001,10.252.0.7
   x3000c0s15b0n0,Management,Storage,a4:bf:01:65:6b:b8,x3000u25-p31,a4:bf:01:65:6b:b4,x3000u25-p08,b8:59:9f:34:88:9e,ncn-s002,10.252.0.8
   x3000c0s17b0n0,Management,Storage,a4:bf:01:64:f4:3b,x3000u25-p32,a4:bf:01:64:f4:37,x3000u25-p09,b8:59:9f:34:88:7a,ncn-s003,10.252.0.9
   ```


3. Fetch the latest example file, this can be done off of ncn-m001:

    ```bash
    ncn-m001:~ # mkdir -pv /mnt/configs
    ncn-m001:~ # git clone https://stash.us.cray.com/scm/mtl/docs-non-compute-nodes.git
    ncn-m001:~ # cp -pv docs-non-compute-nodes/example-data.json /mnt/configs/data.json
    ```

    The example `data.json` is now saved to your USB stick.


4. Edit the `data.json` file and manually adjust all the `~FIXMES~`.

    ```bash
    # STOP!
    # STOP! This next step requires some manual work.
    # STOP!
    # Edit, adjust all the ~FIXMES
    # The values for the `global_data` should be cross-referenced to `networks*.yml` and
    # `kubernetes.yml`.
    ncn-m001:~ # vim /mnt/configs/data.json
    ```

    - `k8s-virtual-ip` and `rgw-virtual-ip`

        You can get these values from networks.yml for your system:  `https://stash.us.cray.com/projects/DST/repos/shasta_system_configs/browse/<system-name>/networks.yml`

        ```bash
        ncn-m001:~ # grep rgw_virtual_ip networks.yml
        ncn-m001:~ # grep k8s_virtual_ip networks.yml
        ```

    - `first-master-hostname`

        set this to ncn-m002 since ncn-m001 will be used for the LiveCD.

    - `dns-server`

        Set this to the IP used for `nmn_cidr` in qnd-1.4.sh.  Do not include the /netmask.  This should be the IP only.  This will be the IP of the LiveCD where dnsmasq will be running.

    - `can-gw`

        Set this to the IP used for `can_gw` in qnd-1.4.sh

    -  `ntp_local_nets`

        Leave this as the provided defaults `10.252.0.0/17,10.254.0.0/17`.   Just remove the `~FIXME~`.

    -  `ntp_peers`

        Enumerate all of the NCNs in the cluster.  In most cases, you can leave this as the default.


    `data.json` is now partially complete.  We will complete it in the next step.


5. Create this little script below on m001 which will generate `statics.conf` and finish `data.json`.

  ```bash
  #!/bin/bash
  INPUT="$1"
  OLDIFS=$IFS
  IFS=','
  [[ ! -f $INPUT ]] && { echo "$INPUT file not found"; exit 99; }

  rm -f /mnt/statics.conf
  rm -f /mnt/ncn-hosts
  sed -i 's/$mac_address/mac_address/g' /mnt/configs/data.json
  while read xname role subrole bmcmac bmcport nmnmac nmnport bondmac nodename nmnip
  do
    if [ "$xname" == "NCN xname" ]; then
      continue
    fi
    echo "host-record=$nodename,$nodename.nmn,$nmnip" >> /mnt/statics.conf
    echo "host-record=$nodename,$nodename.mtl" >> /mnt/statics.conf
    echo "dhcp-host=$bondmac,$nmnip,$nodename,infinite" >> /mnt/statics.conf
    echo "dhcp-host=${xname%n0},$bmcmac,${nodename}-mgmt" >> /mnt/statics.conf
    shortname=`echo $nodename | sed 's/ncn-//'`
    sed -i "s/mac_address_$shortname/$bondmac/" /mnt/configs/data.json
  done < $INPUT
  IFS=$OLDIFS
  ```

3. Run it to save the files to your USB stick:

```
chmod 755 ./script.sh
./script.sh ./ncn_metadata.csv
cat /mnt/statics.conf
```

## Manual Step 4: Download booting artifacts

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
# This will pull from the vars created in step 1.  You can also pull individual components with the command flags
# If you didn't earlier:
source vars.sh
# Then download the artifacts:
csi pit get
```

## Manual Step 5 : Shutdown NCNs

Make sure all of the NCNs other than ncn-m001 are powered off.  If you still have access to the BMC IPs, you can use ipmitool to confirm.

```bash
for i in m002 m003 w001 w002 w003 s001 s002 s003;do ipmitool -I lanplus -U $username -P $password -H ncn-${i}-mgmt chassis power status;done
```

## Manual Step 6 : Boot into your LiveCD.
Now you can boot into your LiveCD [005-LIVECD-BOOTS.md](005-LIVECD-BOOTS.md)
