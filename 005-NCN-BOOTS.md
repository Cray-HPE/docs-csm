# NCN Boots

Before starting this you are expected to have networking and services setup.
If you are unsure, see the bottom of [LiveCD Setup](004-LIVECD-SETUP.md).

## Overview:

> NOTE: These steps will be automated. CASM/MTL is automating this process  with the cray-site-init (`csi`) tool.

**Checks**

- [Warm-up / Pre-flight Checks](#warm-up--pre-flight-checks)
- [Optional safeguards](#optional-safeguards)
- [Safeguards Ceph OSDs](#safeguard-ceph-osds)
- [Safeguard RAIDS / BOOTLOADERS / SquashFS / OverlayFS](#safeguard-raids-bootloaders-squashfs-overlayfs)

**Deployment**

- [Ensure artifacts are in place](#ensure-artifacts-are-in-place)
- [Add Certificate Authority](#add-ca-to-cloud-init-metadata-server)
- [Pre-NCN Boot Workarounds](#apply-pre-ncn-boot-workarounds)
- [Run Automated Pre-flight Checks on PIT Node](#run-automated-pre-flight-checks-on-pit-node)
- [Wipe nodes, if needed](#wipe-nodes-if-needed)
- [Power Off NCNs and Set Boot Order](#power-off-ncns-and-set-network-boot)
- [Boot Storage Nodes](#boot-storage-nodes)
- [Run Pre-flight Checks on Storage Nodes](#run-pre-flight-checks-on-storage-nodes)
- [Boot Kubernetes Nodes](#boot-kubernetes-managers-and-workers)
- [Post-NCN Boot Workarounds](#post-ncn-boot-work-arounds)
- [Get Kubernetes Cluster Credentials](#add-cluster-credentials-to-the-livecd)
- [Run Kubernetes Pre-flight Checks on NCNs](#run-kubernetes-pre-flight-checks-on-ncns)
- [Update BGP Peers](#manual-step-9-update-bgp-peers-on-switches)
- [Manual Checks](#manual-checks)
- [Update New Password](#update-new-password)
- [Run Loftsman Platform Deployments](#run-loftsman-platform-deployments)

## Warm-up / Pre-flight Checks

First, there are some important checks to be done before continuing. These serve to prevent mayhem during installation and operation that are hard to debug.   Please note, more checks may be added over time  and existing checks may receive updates or become defunct.

#### Optional Safeguards

**If you are upgrading** you should run through these safe-guards on a by-case basis:

1. Whether or not CEPH should be preserved.
2. Whether or not the RAIDs should be protected.

##### Safeguard CEPH OSDs

Edit `/var/www/ephemeral/configs/data.json` and align the following options:

```json
{
  ..
  // Disables ceph wipe:
  "wipe-ceph-osds": "no"
  ..
}
```
```json
{
  ..
  // Restores default behavior:
  "wipe-ceph-osds": "yes"
  ..
}
```

Quickly toggle yes or no to the file:

```bash
# set wipe-ceph-osds=no
sed -i 's/wipe-ceph-osds": "yes"/wipe-ceph-osds": "no"/g' /var/www/ephemeral/configs/data.json

# set wipe-ceph-osds=yes
sed -i 's/wipe-ceph-osds": "no"/wipe-ceph-osds": "yes"/g' /var/www/ephemeral/configs/data.json
```

Activate the new setting:

```
pit:~ # systemctl restart basecamp
```

##### Safeguard RAIDS / BOOTLOADERS / SquashFS / OverlayFS

Edit `/var/www/boot/script.ipxe` and align the following options as you see them here:

- `rd.live.overlay.reset=0` will prevent any overlayFS files from being cleared.
- `metal.no-wipe=1` will guard against touching RAIDs, disks, and partitions.

# Deployment

Once warmup / pre-flight checks are done the following procedure can be started.

### Ensure artifacts are in place

This will create folders for each host in `/var/www`, allowing each host to have their own unique kernel, initrd, and squashfs image (KIS).

```bash
pit:~ # /root/bin/set-sqfs-links.sh
```

### Add CA to cloud-init Metadata Server

Platform Certificate Authority (CA) certificates must be added to Basecamp (cloud-init), so that NCN nodes can verify the certificates for components such as the ingress gateways.

> **Failure to perform this step will result in subsequent, often hard to diagnose and fix, problems.**

> **IMPORTANT - NOTE FOR `AIRGAP`** You must have already brought this with you from [002 LiveCD Creation](002-LIVECD-CREATION.md), or your Git server must be reachable. If it is not because this is a true-airgapped environment, then you must obtain and port this manifiest repository to your LiveCD and return to this step.

1. If you have not already done so, please clone the shasta-cfg repository for the system.

```
pit:~ # git clone https://stash.us.cray.com/scm/shasta-cfg/eniac.git /var/www/ephemeral/prep/site-init
```

2. Use `csi` to patch `data.json` using `customizations.yaml` and the sealed secret private key.

> This process is idempotent if the CAs have already been added.

```
pit:~ # PREP=/var/www/ephemeral/prep/site-init
pit:~ # csi patch ca --customizations-file $PREP/customizations.yaml --cloud-init-seed-file /var/www/ephemeral/configs/data.json --sealed-secret-key-file $PREP/certs/sealed_secrets.key
2020/12/01 11:41:29 Backup of cloud-init seed data at /var/www/ephemeral/configs/data.json-1606844489
2020/12/01 11:41:29 Patched cloud-init seed data in place
```

> NOTE: If using a non-default Certificate Authority (sealed secret), you'll need to verify that the vault chart overrides are updated with the correct sealed secret name to inject and use the `--sealed-secret-name` parameter. See `csi patch ca --help` for usage.

3. Restart basecamp to force loading the new metadata.

```
pit:~ # systemctl restart basecamp
```

### Apply "Pre-NCN Boot" Workarounds

Check for workarounds in the `/var/www/ephemeral/${CSM_RELEASE}/fix/before-ncn-boot` directory.  If there are any workarounds in that directory, run those now.   Instructions are in the `README` files.

```
# Example
pit:~ # ls /var/www/ephemeral/${CSM_RELEASE}/fix/before-ncn-boot
casminst-124
```

### Run Automated Pre-flight Checks on PIT Node

Now that the PIT node configuration is complete, it's time to validate that it has been set up properly using the automated test suite.

To execute tests, run:

```bash
pit:~ # csi pit validate --livecd-preflight
```

Observe the output of the checks and note any failures, then remediate them.

### Wipe nodes, if needed

**If you're doing a reinstall, you'll need to wipe the machines first**

> If you have more than 9 NCNs, you should add those hostnames into the `for` loops below.

```bash
for i in m002 m003 w001 w002 w003 s001 s002 s003;do ssh ncn-$i "wipefs --all --force /dev/sd* /dev/disk/by-label/*";done
```

### Power Off NCNs and Set Network Boot

1. **IMPORTANT** all other NCNs (not including the one your liveCD will be on) must be powered **off**. If you still have access to the BMC IPs, you can use `ipmitool` to confirm power state:

> If you have more than 9 NCNs, you should add those hostnames into the `for` loops below.

```bash
for i in m002 m003 w001 w002 w003 s001 s002 s003;do ipmitool -I lanplus -U username -P password -H ncn-${i}-mgmt chassis power status;done
for i in m002 m003 w001 w002 w003 s001 s002 s003;do ipmitool -I lanplus -U username -P password -H ncn-${i}-mgmt chassis power off;done
```

2. Set each node to always UEFI Network Boot

```bash
# ALWAYS PXE BOOT; sets a system to PXE
for i in m002 m003 w001 w002 w003 s001 s002 s003;do ipmitool -I lanplus -U username -P password -H ncn-${i}-mgmt chassis bootdev pxe options=efiboot,persistent;done
```

The NCNs are now primed, ready for booting.

> Note: some BMCs will "flake" and not adhear to these `ipmitool chassi bootdev` options. As a fallback, cloud-init will
> correct the bootorder after NCNs complete their first boot. The boot order is defined in [101 NCN Booting](101-NCN-BOOTING.md).

**Important Note**
```bash
Our recommended boot order for the ncn management plane is as follows
  1. storage
  2. managers
  3. workers

Please keep in mind the timing of the ceph installation is dependent on the number of storage nodes.
You can opt to use this boot stratedgy.
  1. storage then wait 1-2 minutes
  2. boot managers then wait 1-2 minutes
  3. boot workers.

There is code in place to handle waiting for the different node types to come online so additional configuration step can be completed.
```

### Boot Storage Nodes

```bash
# Boot just the storage nodes
for i in s001 s002 s003;do ipmitool -I lanplus -U username -P password -H ncn-${i}-mgmt chassis power on;done
```

Watch consoles with the Serial-over-LAN, or use conman if you've setup `/etc/conman.conf` with the static IPs for the BMCs.

```bash
# Connect to ncn-s001..
echo ipmitool -I lanplus -U username -P password -H ncn-s001-mgmt sol activate

# ..or print available consoles:
conman -q
conman -j ncn-s001-mgmt

# ..or tail multiple log files
tail -f /var/log/conman/console.ncn-s*
```

Once you see your first 3 storage nodes boot, you should start seeing the CEPH installer running
on the first storage nodes console. Optionally, you can also tail -f /var/log/cloud-init-ouput.log.
**Remember, the ceph installation time is dependent on the number of storage nodes**

You can start booting the manager and worker nodes during the ceph installation.

### Boot Kubernetes Managers and Workers

```bash
for i in m002 m003 w001 w002 w003;do ipmitool -I lanplus -U username -P password -H ncn-${i}-mgmt chassis power on;done
```

> **NOTE FOR `HPE Systems`:** Some systems hang at system POST with the following messages on the console, if you hang here for more than five minutes, power the node off and back on again. If this is the case, you can wait or attempt a reboot. A short-term fix for this is in [304 NCN PCIe Netboot and Recable](304-NCN-PCIE-NETBOOT-AND-RECABLE.md) which disables SR-IOV on Mellanox cards.

```
RAS]No Valid Oem Memory Map Table Found
[RAS]Set Error Type With Address structure locate: 0x0000000077EEAD98
 33%: BIOS Configuration Initialization
RbsuSetupDxeEntry, failed to initial product lines feature: Unsupported
Create243Record: Error finding ME Type 216 record.
HpSmbiosType243AbsorokaFwInformationEntryPoint: SmbiosSystemOptionString failed! Status = Not Found
CheckDebugCertificateStatus: unpack error.
 41%: Early PCI Initialization - Start
CreatePciIoDevice: The SR-IOV card[0x00000000|0x86|0x00|0x00] has invalid setting on InitialVFs register
CreatePciIoDevice: its SR-IOV function will be disabled. We need to report the issue to card vandor
CreatePciIoDevice: The SR-IOV card[0x00000000|0x86|0x00|0x00] has invalid setting on InitialVFs register
CreatePciIoDevice: its SR-IOV function will be disabled. We need to report the issue to card vandor
CreatePciIoDevice: The SR-IOV card[0x00000000|0x03|0x00|0x00] has invalid setting on InitialVFs register
CreatePciIoDevice: its SR-IOV function will be disabled. We need to report the issue to card vandor
CreatePciIoDevice: The SR-IOV card[0x00000000|0x03|0x00|0x00] has invalid setting on InitialVFs register
CreatePciIoDevice: its SR-IOV function will be disabled. We need to report the issue to card vandor
CreatePciIoDevice: The SR-IOV card[0x00000000|0x86|0x00|0x00] has invalid setting on InitialVFs register
CreatePciIoDevice: its SR-IOV function will be disabled. We need to report the issue to card vandor
CreatePciIoDevice: The SR-IOV card[0x00000000|0x03|0x00|0x00] has invalid setting on InitialVFs register
CreatePciIoDevice: its SR-IOV function will be disabled. We need to report the issue to card vandor
```

### Post NCN Boot Work-arounds

Check for workarounds in the `/var/www/ephemeral/${CSM_RELEASE}/fix/after-ncn-boot` directory.  If there are any workarounds in that directory, run those now.   Instructions are in the `README` files.

```
# Example
pit:~ # ls /var/www/ephemeral/${CSM_RELEASE}/fix/after-ncn-boot
casminst-12345
```

### Add Cluster Credentials to the LiveCD

After 5-10 minutes, the first master should be provisioning other nodes in the cluster. At this time, credentials can be obtained.

Copy the Kubernetes config to the LiveCD to be able to use `kubectl` as cluster administrator.

> This will always be whatever node is the `first-master-hostname` in your `/var/www/ephemeral/configs/data.json | jq` file. If you are provisioning your CRAY from `ncn-m001` then you can expect to fetch these from `ncn-m002`.

```
pit:~ # mkdir ~/.kube
pit:~ # scp ncn-m002.nmn:/etc/kubernetes/admin.conf ~/.kube/config
```

### Run Pre-flight Checks on Storage Nodes

The following command will run a series of remote tests on the storage nodes to validate they are healthy and configured correctly.

```bash
pit:~ # csi pit validate --ceph
```

Observe the output of the checks and note any failures, then remediate them.

### Run Kubernetes Pre-flight Checks on NCNs

The following command will run a series of remote tests on the NCNs to confirm the Kubernetes cluster is configured properly.

```bash
pit:~ # csi pit validate --k8s
```
Observe the output of the checks and note any failures, then remediate them.

### Update BGP peers on switches.

After the NCNs are booted, the BGP peers will need to be checked and updated if the neighbor IPs are incorrect on the switches. See the doc to [Check and Update BGP Neighbors](400-SWITCH-BGP-NEIGHBORS.md).

> **`NOTE`**:  Make sure you clear the BGP sessions here.  Use the commands `clear ip bgp all` (Mellanox) or `clear bgp *` (Aruba) to restart the BGP peering sessions on each of the switches with BGP.

> **`NOTE`**: At this point all but possibly one of the peering sessions with the BGP neighbors should be in IDLE or CONNECT state and not ESTABLISHED state.   If the switch is an Aruba, you will have one peering session established with the other switch.  You should check that all of the neighbor IPs are correct.

### Manual Checks

1.  Verify that the ceph-csi requirements are in place

    1. Verify all post ceph install tasks have run
    2. Log into ncn-s001
    3. Check /etc/cray/ceph for completed task files
        ```bash
        ncn-s001:~ # ls /etc/cray/ceph/
        ceph_k8s_initialized  csi_initialized  installed  kubernetes_nodes.txt  tuned
        ```
    4. Check to see if k8s ceph-csi prequisites have been created 
        > You can also run this from any k8s-manager/k8s-worker node
        ```bash
        pit:~ # kubectl get cm
        NAME               DATA   AGE
        ceph-csi-config    1      3h50m
        cephfs-csi-sc      1      3h50m
        kube-csi-sc        1      3h50m
        sma-csi-sc         1      3h50m
        sts-rados-config   1      4h
    
        pit:~ # kubectl get secrets |grep csi
        csi-cephfs-secret             Opaque                                4      3h51m
        csi-kube-secret               Opaque                                2      3h51m
        csi-sma-secret                Opaque                                2      3h51m
        ```
    
    5. check your results against the above example.
    6. if you are missing any components then you will want to re-run the storage node cloud-init script
       a.  log in to ncn-s001
       b.  run the storage-ceph-cloudinit.sh script
       ```bash
       ncn-s001:~ # /srv/cray/scripts/common/storage-ceph-cloudinit.sh
       Configuring node auditing software
       Using generic auditing configuration
       This ceph cluster has been initialized
       This ceph cluster has already been tuned
       This ceph radosgw config and initial k8s integration already complete
       ceph-csi configuration has been already been completed
       ```
       * if your output is like above then that means that all the steps ran.
       * if the script failed out then you will have more output for the tasks that are being run. 


**Important to make sure the following have been checked before continuing (either by a goss test or manually).**
1. Verify all nodes have joined the cluster
2. Verify etcd is running outside kubernetes on master nodes
3. Verify that all the pods in the kube-system namespace are running
4. Verify that the ceph-csi requirements are in place

### Update New Password

> **`EXTERNAL USE`**

The NCNs are now confirmed up and their default password can no be customized. For details on changing
the root password, see [056 NCN Reset Passwords](056-NCN-RESET-PASSWORDS.md).

> **`NOTE`**: This step is **strongly encouraged** for external/site deployments. Airgapped deployments may opt to skip this step, as well as internal CI deployments.

### Run Loftsman Platform Deployments

Move onto the [CSM Platform Install](006-CSM-PLATFORM-INSTALL.md) page to continue the CSM install.
