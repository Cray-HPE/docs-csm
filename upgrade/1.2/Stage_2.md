# Stage 2 - Kubernetes Upgrade from 1.19.9 to 1.20.13

> NOTE: During the CSM-0.9 install the LiveCD containing the initial install files for this system should have been unmounted from the master node when rebooting into the Kubernetes cluster. The scripts run in this section will also attempt to unmount/eject it if found to ensure the USB stick does not get erased.

## Stage 2.1

1. Run `ncn-upgrade-master-nodes.sh` for `ncn-m002`. Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m002
   ```

1. Repeat the previous step for each other master node **excluding `ncn-m001`**, one at a time.

## Stage 2.2

1. Run `ncn-upgrade-worker-nodes.sh` for `ncn-w001`. Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-worker-nodes.sh ncn-w001
   ```

   > NOTE: You may need to reset the root password for each node after it is rebooted

1. Repeat the previous step for each other worker node, one at a time.

## Stage 2.3

For `ncn-m001`, use `ncn-m002` as the stable NCN. Use `bond0.cmn0`/CAN IP address to `ssh` to `ncn-m002` for this `ncn-m001` install

1. Authenticate with the Cray CLI on `ncn-m002`.

   See [Configure the Cray Command Line Interface](../../operations/configure_cray_cli.md) for details on how to do this.

1. Set the `CSM_RELEASE` variable to the correct value for the CSM release upgrade being applied.

   ```bash
   ncn-m002# CSM_RELEASE=csm-1.2.0
   ```
1. Copy arfifacts from `ncn-m001`

   ```bash
   mkdir -p /etc/cray/upgrade/csm/${$CSM_RELEASE}

   scp ncn-m001:/etc/cray/upgrade/csm/${$CSM_RELEASE}/myenv /etc/cray/upgrade/csm/${$CSM_RELEASE}/myenv

   csi_rpm=$(ssh ncn-m001 "find /etc/cray/upgrade/csm/${CSM_RELEASE}/tarball/${CSM_RELEASE}/rpm/cray/csm/ -name 'cray-site-init*.rpm'")

   scp ncn-m001:${csi_rpm} /tmp/cray-site-init.rpm

   rpm -Uvh --force /tmp/cray-site-init.rpm
   ```

1. Upgrade `ncn-m001`

   ```bash
   ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m001
   ```

## Stage 2.4

Run the following command to complete the upgrade of the weave and multus manifest versions:

```bash
ncn-m002# /srv/cray/scripts/common/apply-networking-manifests.sh
```

## Stage 2.5

Run the following script to apply anti-affinity to coredns pods:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/apply-coredns-pod-affinity.sh
```

## Stage 2.6

Run the following script to complete the Kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/upgrade_control_plane.sh
```

> **`NOTE`**: `kubelet` has been upgraded already, so you can ignore the warning to upgrade it

Once `Stage 2` is completed, all Kubernetes nodes have been rebooted into the new image. Now proceed to [Stage 3](Stage_3.md)
