# Stage 2 - Kubernetes Upgrade from 1.19.9 to 1.20.13

## Stage 2.1

1. Run `ncn-upgrade-master-nodes.sh` for `ncn-m002`. Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m002
   ```

   > **NOTE:** The root password for the node may need to be reset after it is rebooted.

1. Repeat the previous step for each other master node **excluding `ncn-m001`**, one at a time.

## Stage 2.2

1. Run `ncn-upgrade-worker-nodes.sh` for `ncn-w001`. Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-worker-nodes.sh ncn-w001
   ```

   > **NOTE:** The root password for the node may need to be reset after it is rebooted.

1. Repeat the previous step for each other worker node, one at a time.

## Stage 2.3

All NCNs have been upgraded, except for `ncn-m001`. In the upgrade process so far, `ncn-m001` has been the "stable node" -- that is, the node
from which the other nodes were upgraded. At this point, the upgrade procedure pivots to use `ncn-m002` as the new "stable node", in order to allow the upgrade of `ncn-m001`.

1. Log in to `ncn-m002` from outside the cluster.

   `ssh` to the `bond0.cmn0`/CMN IP address of `ncn-m002`.

1. Authenticate with the Cray CLI on `ncn-m002`.

   See [Configure the Cray Command Line Interface](../../operations/configure_cray_cli.md) for details on how to do this.

1. Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   ```bash
   ncn-m002# CSM_RELEASE=csm-1.2.0
   ```

1. Copy artifacts from `ncn-m001`.

   A later stage of the upgrade expects the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm` on `ncn-m002`; that is why this command copies it there.

   ```bash
   ncn-m002# mkdir -pv /etc/cray/upgrade/csm/${CSM_RELEASE} &&
             scp ncn-m001:/etc/cray/upgrade/csm/myenv /etc/cray/upgrade/csm/myenv &&
             scp ncn-m001:/root/output.log /root/pre-m001-reboot-upgrade.log &&
             cray artifacts create config-data pre-m001-reboot-upgrade.log /root/pre-m001-reboot-upgrade.log
   ncn-m002# csi_rpm=$(ssh ncn-m001 "find /etc/cray/upgrade/csm/${CSM_RELEASE}/tarball/${CSM_RELEASE}/rpm/cray/csm/ -name 'cray-site-init*.rpm'") &&
             scp ncn-m001:${csi_rpm} /tmp/cray-site-init.rpm &&
             scp ncn-m001:/root/docs-csm-*.noarch.rpm /root/docs-csm-latest.noarch.rpm &&
             rpm -Uvh --force /tmp/cray-site-init.rpm /root/docs-csm-latest.noarch.rpm
   ```

1. Upgrade `ncn-m001`.

   ```bash
   ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m001
   ```

## Stage 2.4

Run the following command to complete the upgrade of the `weave` and `multus` manifest versions:

```bash
ncn-m002# /srv/cray/scripts/common/apply-networking-manifests.sh
```

## Stage 2.5

Run the following script to apply anti-affinity to `coredns` pods:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/apply-coredns-pod-affinity.sh
```

## Stage 2.6

Run the following script to complete the Kubernetes upgrade _(this will restart several pods on each master to their new Docker containers)_:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/upgrade_control_plane.sh
```

> **`NOTE`**: `kubelet` has been upgraded already, ignore the warning to upgrade it.

<a name="stage_completed"></a>

## Stage completed

All Kubernetes nodes have been rebooted into the new image.

This stage is completed. Continue to [Stage 3](Stage_3.md).
