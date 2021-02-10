# CSM Metal Install

This page will go over deploying the non-compute nodes.

* [Configure Bootstrap Registry to Proxy an Upstream Registry](#configure-bootstrap-registry-to-proxy-an-upstream-registry)
* [Tokens](#tokens)
* [Timing of Deployments](#timing-of-deployments)
* [NCN Deployment](#ncn-deployment)
    * [Apply NCN Pre-Boot Workarounds](#apply-ncn-pre-boot-workarounds)
    * [Start Deployment](#start-deployment)
    * [Apply NCN Post-Boot Workarounds](#apply-ncn-post-boot-workarounds)
    * [LiveCD Cluster Authentication](#livecd-cluster-authentication)
    * [BGP Routing](#bgp-routing)
    * [Static Routing](#static-routing)
    * [Validation](#validation)
    * [Optional Validation](#optional-validation)
    * [Change Password](#change-password)


<a name="configure-bootstrap-registry-to-proxy-an-upstream-registry"></a>
## Configure Bootstrap Registry to Proxy an Upstream Registry

> **`SKIP IF AIRGAP/OFFLINE`** - Online installs require a URL to the proxied
> registry.

By default, the bootstrap registry is a `type: hosted` Nexus repository,
which requires container images to be imported prior to platform
installation. However, it may be reconfigured to proxy container images from
an upstream registry as follows:

1.  Stop Nexus:

    ```bash
    pit:~ # systemctl stop nexus
    ```

2.  Remove `nexus` container:

    ```bash
    pit:~ # podman container exists nexus && podman container rm nexus
    ```

3.  Remove `nexus-data` volume:

    ```bash
    pit:~# podman volume rm nexus-data
    ```

4.  Add the corresponding URL to the `ExecStartPost` script in
    `/usr/lib/systemd/system/nexus.service`. For example, Cray internal systems
    may want to proxy to https://dtr.dev.cray.com as follows:

    ```bash
    pit:~ # URL=https://dtr.dev.cray.com
    pit:~ # sed -e "s,^\(ExecStartPost=/usr/sbin/nexus-setup.sh\).*$,\1 $URL," -i /usr/lib/systemd/system/nexus.service
    ```

5.  Restart Nexus:

    ```bash
    pit:~ # systemctl start nexus
    ```


<a name="tokens"></a>
## Tokens

These tokens will assist an administrator as they follow this page. Copy these into the shell environment

> These exist as an avoidance measure for hard-codes, so these may be used in various system contexts.

```bash
export mtoken='ncn-m\w+-mgmt'
export stoken='ncn-s\w+-mgmt'
export wtoken='ncn-w\w+-mgmt'
```

Optionally save them to the PIT's `.bashrc` file to load these on every login:
```bash
export mtoken='ncn-m\w+-mgmt'
export stoken='ncn-s\w+-mgmt'
export wtoken='ncn-w\w+-mgmt'
cat << EOF >> ~/.bashrc
export mtoken='$mtoken'
export stoken='$stoken'
export wtoken='$wtoken'
EOF
```

Throughout the guide, simple one-liners can be used to query status of expected nodes. If the shell or environment is terminated, these environment variables should be re-exported.

Examples:
```bash
export IPMI_PASSWORD=
export username=root

# grep -oE : outputs only the lexeme, and allows expanded regexs.
# Power status of all expected NCNs:
grep -oE "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power status

# Power off all expected NCNs:
grep -oE "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
```

<a name="timing-of-deployments"></a>
## Timing of Deployments

The timing of each set of boots varies based on hardware, some manufacturers will POST faster than others or vary based on BIOS setting. After powering a set of nodes on, an administrator can expect a healthy boot-session to take the follow times:

1. Storage nodes; 15-20 minutes
2. Managers and Worker nodes; 5-10 minutes

<a name="ncn-deployment"></a>
## NCN Deployment

This section will walk an administrator through NCN deployment.

<a name="apply-ncn-pre-boot-workarounds"></a>
#### Apply NCN Pre-Boot Workarounds

> **There will be post-boot workarounds as well**.

Check for workarounds in the `fix/before-ncn-boot` directory within the CSM tar. Each has its own instructions in their respective `README` files.

```bash
# Example
pit:~ # export CSM_RELEASE=csm-0.7.29
pit:~ # ls /var/www/ephemeral/${CSM_RELEASE}/fix/before-ncn-boot
CASMINST-980
```

<a name="start-deployment"></a>
### Start Deployment

1. Create boot directories for any NCN in DNS:
   > This will create folders for each host in `/var/www`, allowing each host to have their own unique set of artifacts; kernel, initrd, SquashFS, and `script.ipxe` bootscript.

   ```bash
   pit:~ # /root/bin/set-sqfs-links.sh
   ```

2. Set each node to always UEFI Network Boot, and ensure they're powered off
   ```bash
    export IPMI_PASSWORD=
    export username=root
    grep -oE "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} chassis bootdev pxe options=efiboot,persistent
    grep -oE "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
   ```
   > Note: some BMCs will "flake" and ignore the bootorder setting by `ipmitool`. As a fallback, cloud-init will
   > correct the bootorder after NCNs complete their first boot. The first boot may need manual effort to set the boot order over the conman console. The NCN boot order is further explained in [101 NCN Booting](101-NCN-BOOTING.md).

3. Validate that the LiveCD is ready for installing NCNs
   ```bash
   pit:~ # csi pit validate --livecd-preflight
   ```
   > Observe the output of the checks and note any failures, then remediate them.

3. Print the consoles available to you:
   ```bash
   pit:~ # conman -q
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

4. Boot the **Storage Nodes**
    ```bash
    export IPMI_PASSWORD=
    export username=root
    grep -oE $stoken /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power on
    ```

5. Wait. Observe the installation through ncn-s001-mgmt's console:
   ```bash
   # Print the console name
   pit:~ # conman -q | grep s001
   ncn-s001-mgmt

   # Join the console
   pit:~ # conman -j ncn-s001-mgmt
   ```
   > **`NOTE`**: All consoles are located at `/var/log/conman/console*`

   > **`NOTE`**: If the nodes are booted without a hostname or they didn't run all their cloud-init scripts the following commands need to be ran **(but only in that circumstance)**.
   > ```
   > /srv/cray/scripts/metal/set-dhcp-to-static.sh
   > ```
   > After this you should have network connectivity.
   > Then you will run.
   > ```
   > cloud-init clean
   > cloud-init init
   > cloud-init modules -m init
   > cloud-init modules -m config
   > cloud-init modules -m final
   > ```
   > This should pull all the required cloud-init data for the NCN to join the cluster.

6. Boot **Kubernetes Managers and Workers**
    ```bash
    export IPMI_PASSWORD=
    export username=root
    grep -oE "($mtoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power on
    ```

7. Wait. Observe the installation through ncn-m002-mgmt's console:
   ```bash
   # Print the console name
   pit:~ # conman -q | grep m002
   ncn-m002-mgmt

   # Join the console
   pit:~ # conman -j ncn-m002-mgmt
   ```

8. Refer to [timing of deployments](#timing-of-deployments). After a while, `kubectl get nodes` should return
   all the managers and workers aside from the LiveCD's node.
   ```bash
   ncn-m002:~ # kubectl get nodes -o wide
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

Check for workarounds in the `/var/www/ephemeral/${CSM_RELEASE}/fix/after-ncn-boot` directory.  If there are any workarounds in that directory, run those now.   Instructions are in the `README` files.

```
# Example
pit:~ # ls /var/www/ephemeral/${CSM_RELEASE}/fix/after-ncn-boot
casminst-12345
```

<a name="livecd-cluster-authentication"></a>
#### LiveCD Cluster Authentication

The LiveCD needs to authenticate with the cluster to facilitate the rest of the CSM installation.

Copy the Kubernetes config to the LiveCD to be able to use `kubectl` as cluster administrator.

> This will always be whatever node is the `first-master-hostname` in your `/var/www/ephemeral/configs/data.json | jq` file. If you are provisioning your CRAY from `ncn-m001` then you can expect to fetch these from `ncn-m002`.

```
pit:~ # mkdir ~/.kube
pit:~ # scp ncn-m002.nmn:/etc/kubernetes/admin.conf ~/.kube/config
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
   pit:~ # ls -1 /usr/bin/*peer*py
   /usr/bin/aruba_set_bgp_peers.py
   /usr/bin/mellanox_set_bgp_peers.py
   ```

<a name="static-routing"></a>
#### Static Routing

If you have MTN/Hill Cabinets, you will need to add static routes on all the NCNs to reach the those networks.
You can find these networks from NMN_MTN.yaml and HMN_MTN.yaml
```
m001-pit: # cat NMN_MTN.yaml
full_name: Mountain Node Management Network
cidr: 10.104.0.0/17

m001-pit: # cat HMN_MTN.yaml
full_name: Mountain Hardware Management Network
cidr: 10.100.0.0/17
```
Once you have those networks you can now add the routes to all NCNs.
```
ip route add 10.100.0.0/17 via 10.252.0.1
ip route add 10.104.0.0/17 via 10.254.0.1
```

<a name="validation"></a>
#### Validation

The following command will run a series of remote tests on the storage nodes to validate they are healthy and configured correctly.

Observe the output of the checks and note any failures, then remediate them.
1. Check CEPH
    ```bash
    pit:~ # csi pit validate --ceph
    ```

2. Check K8s
    ```bash
    pit:~ # csi pit validate --k8s
    ```

> **`NOTE`** The **administrator may proceed to the [CSM Platform Install](006-CSM-PLATFORM-INSTALL.md) guide
> at this time.** The optional validation may have differing value in various install contexts.

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
4. Verify that the ceph-csi requirements are in place (see [CEPH RSI](066-CEPH-RSI.md))

<a name="change-password"></a>
## Change Password

> **`EXTERNAL USE`** Internally this may be skipped based on context.

The NCNs are online, and their default password can now be customized. For details on changing
the root password, see [056 NCN Reset Passwords](056-NCN-RESET-PASSWORDS.md).

> It is possible to update the password before booting NCNs, see [NCN Development](107-NCN-DEVEL.md) for more
information.

> This step is **strongly encouraged** for external/site deployments. Airgapped deployments may opt to skip this step, as well as internal CI deployments.

Whether the password is changed or not, an administrator may now move onto the [CSM Platform Install](006-CSM-PLATFORM-INSTALL.md) page to continue the CSM install.
