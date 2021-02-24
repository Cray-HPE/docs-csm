# CSM Metal Install

<div style="border: 1px dashed red">
<span style="color:red">
WARNING
</span>

Gigabyte NCNs that install Shasta 1.4 can become unusable when Shasta 1.4 is installed.  This is a result of a bug in the Gigabyte firmware that ships with Shasta 1.4.  It is recommended that Gigabyte users wait to install Shasta 1.4 until a firmware patch is available.

A key symptom of this bug is that the NCN will not PXE boot and will instead fall through to the boot menu, despite being configure to PXE boot.  This behavior will persist until the failing node's CMOS is cleared.

[A procedure is available in this document.](./254-NCN-FIRMWARE-GB.md)
</div>

## Overview

This page will go over deploying the non-compute nodes.

* [Configure Bootstrap Registry to Proxy an Upstream Registry](#configure-bootstrap-registry-to-proxy-an-upstream-registry)
* [Tokens and IPMI Password](#tokens-and-ipmi-password)
* [Timing of Deployments](#timing-of-deployments)
* [NCN Deployment](#ncn-deployment)
    * [Apply NCN Pre-Boot Workarounds](#apply-ncn-pre-boot-workarounds)
    * [Ensure Time Is Accurate Before Deploying NCNs](#ensure-time-is-accurate-before-deploying-ncns)
    * [Start Deployment](#start-deployment)
    * [Apply NCN Post-Boot Workarounds](#apply-ncn-post-boot-workarounds)
    * [LiveCD Cluster Authentication](#livecd-cluster-authentication)
    * [BGP Routing](#bgp-routing)
    * [Validation](#validation)
    * [Optional Validation](#optional-validation)
    * [Change Password](#change-password)


<a name="configure-bootstrap-registry-to-proxy-an-upstream-registry"></a>
## Configure Bootstrap Registry to Proxy an Upstream Registry

> **`INTERNAL USE`** -- This section is only relevant for Cray/HPE internal
> systems.

> **`SKIP IF AIRGAP/OFFLINE`** - Do **NOT** reconfigure the bootstrap registry
> to proxy an upstream registry if performing an _airgap/offline_ install.

By default, the bootstrap registry is a `type: hosted` Nexus repository to
support _airgap/offline_ installs, which requires container images to be
imported prior to platform installation. However, it may be reconfigured to
proxy container images from an upstream registry in order to support _online_
installs as follows:

1.  Stop Nexus:

    ```bash
    pit# systemctl stop nexus
    ```

2.  Remove `nexus` container:

    ```bash
    pit# podman container exists nexus && podman container rm nexus
    ```

3.  Remove `nexus-data` volume:

    ```bash
    pit# podman volume rm nexus-data
    ```

4.  Add the corresponding URL to the `ExecStartPost` script in
    `/usr/lib/systemd/system/nexus.service`. For example, Cray internal systems
    may want to proxy to https://dtr.dev.cray.com as follows:

    ```bash
    pit# URL=https://dtr.dev.cray.com
    pit# sed -e "s,^\(ExecStartPost=/usr/sbin/nexus-setup.sh\).*$,\1 $URL," -i /usr/lib/systemd/system/nexus.service
    ```

5.  Restart Nexus:

    ```bash
    pit# systemctl daemon-reload
    pit# systemctl start nexus
    ```


<a name="tokens-and-ipmi-password"></a>
## Tokens and IPMI Password

These tokens will assist an administrator as they follow this page. Copy these into the shell environment **Notice** that one of them
is the `IPMI_PASSWORD`

> These exist as an avoidance measure for hard-codes, so these may be used in various system contexts.
```bash
pit# \
export mtoken='ncn-m(?!001)\w+-mgmt'
export stoken='ncn-s\w+-mgmt'
export wtoken='ncn-w\w+-mgmt'

export username=root
# Replace "opensesame" with the real root password.
export IPMI_PASSWORD=opensesame
```

Throughout the guide, simple one-liners can be used to query status of expected nodes. If the shell or environment is terminated, these environment variables should be re-exported.

Examples:
```bash
# Power status of all expected NCNs:
pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power status

# Power off all expected NCNs:
pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
```

<a name="timing-of-deployments"></a>
## Timing of Deployments

The timing of each set of boots varies based on hardware, some manufacturers will POST faster than others or vary based on BIOS setting. After powering a set of nodes on, an administrator can expect a healthy boot-session to take about 60 minutes depending on the number of storage and worker nodes.

<a name="ncn-deployment"></a>
## NCN Deployment

This section will walk an administrator through NCN deployment.

> Grab the [Tokens](#tokens-and-ipmi-password) to facilitate commands if loading this page from a bookmark.

<a name="apply-ncn-pre-boot-workarounds"></a>
#### Apply NCN Pre-Boot Workarounds

_There will be post-boot workarounds as well._

Check for workarounds in the `/opt/cray/csm/workarounds/before-ncn-boot` directory within the CSM tar. Each has its own instructions in their respective `README` files.

```bash
# Example
pit# export CSM_RELEASE=csm-x.y.z
pit# ls /opt/cray/csm/workarounds/before-ncn-boot
CASMINST-980
```

<a name="ensure-time-is-accurate-before-deploying-ncns"></a>
#### Ensure Time Is Accurate Before Deploying NCNs

1. Ensure that the PIT node has the current and correct time.  But also check that each NCN has the correct time set in BIOS.

   > This step should not be skipped

   Check the current time to see if it matches the current time:

   ```
   pit# date "+%Y-%m-%d %H:%M:%S.%6N%z"
   ```

   The time can be inaccurate if the system has been off for a long time, or, for example, [the CMOS was cleared](254-NCN-FIRMWARE-GB.md). If needed, set the time manually as close as possible, and then run the NTP script:

   ```
   pit# timedatectl set-time "2019-11-15 00:00:00"
   pit# /root/bin/configure-ntp.sh
   ```

   This ensures that the PIT is configured with an accurate date/time, which will be properly propagated to the NCNs during boot.

2. Ensure the current time is set in BIOS for all management NCNs.

   > If each NCN is booted to the BIOS menu, you can check and set the current UTC time.

   Repeat this process for each NCN.

   Start an IPMI console session to the NCN.
   ```bash
   pit# bmc=ncn-w001-mgmt  # Change this to be each node in turn.
   pit# conman -j $bmc
   ```

   Boot the node to BIOS.
   ```bash
   pit# ipmitool -I lanplus -U $username -E -H $bmc chassis bootdev bios
   pit# ipmitool -I lanplus -U $username -E -H $bmc chassis power off
   pit# sleep 10
   pit# ipmitool -I lanplus -U $username -E -H $bmc chassis power on
   ```

   When the node boots, you will be able to use the conman session to see the BIOS menu to check and set the time to current UTC time.  The process varies depending on the vendor of the NCN.

   Repeat this process for each NCN.

<a name="start-deployment"></a>
### Start Deployment

1. Create boot directories for any NCN in DNS:
   > This will create folders for each host in `/var/www`, allowing each host to have their own unique set of artifacts; kernel, initrd, SquashFS, and `script.ipxe` bootscript.

   ```bash
   pit# \
   /root/bin/set-sqfs-links.sh
   ```

2. Set each node to always UEFI Network Boot, and ensure they're powered off
    ```bash
    pit# \
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} chassis bootdev pxe options=efiboot,persistent
    grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
    ```
    > Note: some BMCs will "flake" and ignore the bootorder setting by `ipmitool`. As a fallback, cloud-init will
    > correct the bootorder after NCNs complete their first boot. The first boot may need manual effort to set the boot order over the conman console. The NCN boot order is further explained in [101 NCN Booting](101-NCN-BOOTING.md).

3. Validate that the LiveCD is ready for installing NCNs
   ```bash
   pit# \
   csi pit validate --livecd-preflight
   ```
   > Observe the output of the checks and note any failures, then remediate them.

4. Print the consoles available to you:
   ```bash
   pit# conman -q
   ncn-m001-mgmt
   ncn-m002-mgmt
   ncn-m003-mgmt
   ncn-s001-mgmt
   ncn-s002-mgmt
   ncn-s003-mgmt
   ncn-w001-mgmt
   ncn-w002-mgmt
   ncn-w003-mgmt
   ```

> **`IMPORTANT`** This is the administrators _last chance_ to run [NCN pre-boot workarounds](#apply-ncn-pre-boot-workarounds).

> **`NOTE`**: All consoles are located at `/var/log/conman/console*`
5. Boot the **Storage Nodes**
    ```bash
    pit# \
    grep -oP $stoken /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power on
    ```

6. Wait. Observe the installation through ncn-s001-mgmt's console:
   ```bash
   # Print the console name
   pit# conman -q | grep s001
   ncn-s001-mgmt

   # Join the console
   pit# conman -j ncn-s001-mgmt
   ```
    From there an administrator can witness console-output for the cloud-init scripts.
   > **`NOTE`**: If the nodes have pxe boot issues (e.g. getting pxe errors, not pulling the ipxe.efi binary) see [PXE boot troubleshooting](420-MGMT-NET-PXE-TSHOOT.md)

   > **`NOTE`**: If the nodes exhibit afflictions such as:
   > - no hostname (e.g. `ncn`)
   > - `mgmt0` or `mgmt1` does not indicate they exist in `bond0`, or has a mis-matching MTU of `1500` to the bond's members
   > - no route (e.g. `ip r` returns no `default` route)
   >   
    > then run the following script from the afflicted node **(but only in either of those circumstances)**.
   > ```bash
   > ncn# /srv/cray/scripts/metal/retry-ci.sh
   > ```
   > Running `hostname` or logging out and back in should yield the proper hostname.

7. Add in additional drives into Ceph (if necessary)
   ```bash
      *  On a manager node run
           a. watch "ceph -s"
              i.  This will allow you to monitor the progress of the drives being added
      *  On each storage node run the following
           a.  ceph-volume inventory --format json-pretty|jq '.[] | select(.available == true) |.path'
               i. you can run ceph-volume inventory at to see the unedited output from the above command.
           b.  ceph-volume lvm create --data /dev/<drive to be added> --bluestore
               i.  you will repeat for all drives on that node that need added and also for each node that has drives to add.

        After all the OSDs have been added, run the playbook to re-set the pool quotas (only necessary to run when you've increased the cluster capacity):

        % ansible-playbook /etc/ansible/ceph-rgw-users/ceph-pool-quotas.yml
   ```
  >**`NOTE`**: If you ceph install fails due to large volumes being created please do the following
  > - lsblk on each storage node.  you will see a lot of output, but look for the size of the lvm volumes associated with the drives.
  >     - Anything over the drive size (1.92TB, 3.84TB, 7.68TB) is the indicator that there is an issue
  >     - Another method is to run `vgs` on the storage nodes.  This will give you the size of the volume groups.
  >         - There should be 1 per drive.
  ? - if you meet this criteria please run the "Full Wipe" procudure in 051-DISK-CLEANSLATE.md.


8. Boot **Kubernetes Managers and Workers**
    ```bash
    pit# \
    grep -oP "($mtoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power on
    ```

9. Wait. Observe the installation through ncn-m002-mgmt's console:
   ```bash
   # Print the console name
   pit# conman -q | grep m002
   ncn-m002-mgmt

   # Join the console
   pit# conman -j ncn-m002-mgmt
   ```

10. Refer to [timing of deployments](#timing-of-deployments). After a while, `kubectl get nodes` should return
   all the managers and workers aside from the LiveCD's node.
   ```bash
   pit# ssh ncn-m002
   ncn-m002# kubectl get nodes -o wide
   NAME       STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                  KERNEL-VERSION         CONTAINER-RUNTIME
   ncn-m002   Ready    master   14m     v1.18.6   10.252.1.5    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
   ncn-m003   Ready    master   13m     v1.18.6   10.252.1.6    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
   ncn-w001   Ready    <none>   6m30s   v1.18.6   10.252.1.7    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
   ncn-w002   Ready    <none>   6m16s   v1.18.6   10.252.1.8    <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
   ncn-w003   Ready    <none>   5m58s   v1.18.6   10.252.1.12   <none>        SUSE Linux Enterprise High Performance Computing 15 SP2   5.3.18-24.43-default   containerd://1.3.4
   ```

The administrator needs to move onto the next sections, before considering continuing the installation:

- [NCN Post-Boot Workarounds](#apply-ncn-post-boot-workarounds)
- [LiveCD Cluster Authentication](#livecd-cluster-authentication)
- [BGP Routing](#bgp-routing)
- [Validation](#validation)

**After validating the install**, an administrator may proceed further to continue optional validations
_or_ head to [CSM Platform Install](006-CSM-PLATFORM-INSTALL.md).

<a name="apply-ncn-post-boot-workarounds"></a>
#### Apply NCN Post-Boot Workarounds

Check for workarounds in the `/opt/cray/csm/workarounds/after-ncn-boot` directory.  If there are any workarounds in that directory, run those now.   Instructions are in the `README` files.

```
# Example
pit# ls /opt/cray/csm/workarounds/after-ncn-boot
casminst-12345
```

<a name="livecd-cluster-authentication"></a>
#### LiveCD Cluster Authentication

The LiveCD needs to authenticate with the cluster to facilitate the rest of the CSM installation.

Copy the Kubernetes config to the LiveCD to be able to use `kubectl` as cluster administrator.

> This will always be whatever node is the `first-master-hostname` in your `/var/www/ephemeral/configs/data.json | jq` file. If you are provisioning your CRAY from `ncn-m001` then you can expect to fetch these from `ncn-m002`.

```
pit# mkdir ~/.kube
pit# scp ncn-m002.nmn:/etc/kubernetes/admin.conf ~/.kube/config
```

<a name="bgp-routing"></a>
#### BGP Routing

After the NCNs are booted, the BGP peers will need to be checked and updated if the neighbor IPs are incorrect on the switches. See the doc to [Check and Update BGP Neighbors](400-SWITCH-BGP-NEIGHBORS.md).

1. Make sure you clear the BGP sessions here.
    - Aruba:`clear bgp *`
    - Mellanox: `clear ip bgp all`

   > **`NOTE`**: At this point all but possibly one of the peering sessions with the BGP neighbors should be in IDLE or CONNECT state and not ESTABLISHED state.   If the switch is an Aruba, you will have one peering session established with the other switch.  You should check that all of the neighbor IPs are correct.

2. If needed, the following helper scripts are available for the various switch types:

   ```
   pit# ls -1 /usr/bin/*peer*py
   /usr/bin/aruba_set_bgp_peers.py
   /usr/bin/mellanox_set_bgp_peers.py
   ```

<a name="validation"></a>
#### Validation

The following command will run a series of remote tests on the storage nodes to validate they are healthy and configured correctly.

Observe the output of the checks and note any failures, then remediate them.
1. Check CEPH
    ```bash
    pit# csi pit validate --ceph
    ```

2. Check K8s
    ```bash
    pit# csi pit validate --k8s
    ```

> **`NOTE`** The **administrator may proceed to the [CSM Platform Install](006-CSM-PLATFORM-INSTALL.md) guide
> at this time.** The optional validation may have differing value in various install contexts.

3. Ensure that weave hasn't split-brained

    Run the following command on each member of the kubernetes cluster (masters and workers) to ensure that weave is operating as a single cluster:

    ```bash
    ncn# weave --local status connections  | grep failed
    ```
    If you see messages like **'IP allocation was seeded by different peers'** then weave looks to have split-brained.  At this point it is necessary to wipe the ncns and start the pxe boot again:

    1. Wipe the ncns using the 'Basic Wipe' section of [DISK CLEANSLATE](051-DISK-CLEANSLATE.md).
    2. Return to the 'Boot the **Storage Nodes**' step of [Start Deployment](#start-deployment) section above.

<a name="optional-validation"></a>
#### Optional Validation

These tests are for sanity checking. These exist as software reaches maturity, or as tests are worked
and added into the installation repertoire.

All validation should be taken care of by the CSI validate commands. The following checks can be
done for sanity-checking:

**Important common issues should be checked by tests, new pains in these areas should entail requests for
new tests.**

1. Verify all nodes have joined the cluster
2. Verify etcd is running outside kubernetes on master nodes
3. Verify that all the pods in the kube-system namespace are running
4. Verify that the ceph-csi requirements are in place (see [CEPH CSI](066-CEPH-CSI.md))

<a name="change-password"></a>
## Change Password

> **`EXTERNAL USE`** Internally this may be skipped based on context.

The NCNs are online, and their default password can now be customized. For details on changing
the root password, see [056 NCN Reset Passwords](056-NCN-RESET-PASSWORDS.md).

> It is possible to update the password before booting NCNs, see [Set the Default Password](110-NCN-IMAGE-CUSTOMIZATION.md#set-the-default-password) for more
information.

> This step is **strongly encouraged** for external/site deployments. Airgapped deployments may opt to skip this step, as well as internal CI deployments.

Whether the password is changed or not, an administrator may now move onto the [CSM Platform Install](006-CSM-PLATFORM-INSTALL.md) page to continue the CSM install.
