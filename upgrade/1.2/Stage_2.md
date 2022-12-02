# Stage 2 - Kubernetes Upgrade from 1.19.9 to 1.20.13

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Stage 2.1

1. Run `ncn-upgrade-master-nodes.sh` for `ncn-m002`.

   Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m002
   ```

   > **NOTE:** The root password for the node may need to be reset after it is rebooted.

1. Repeat the previous step for each other master node **excluding `ncn-m001`**, one at a time.

## Stage 2.2

1. Make sure that not all pods of `ingressgateway-hmn` or `spire-server` are running on the same worker node.

    1. See where the pods are running.

        ```bash
        ncn-m001# kubectl get pods -A -o wide | grep -E 'ingressgateway-hmn|spire-server|^NAMESPACE'
        ```

        Example output:

        ```text
        NAMESPACE           NAME                                                              READY   STATUS              RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
        istio-system        istio-ingressgateway-hmn-555dbc8c6b-2b6rv                         1/1     Running             0          5h2m    10.42.1.41    ncn-w001   <none>           <none>
        istio-system        istio-ingressgateway-hmn-555dbc8c6b-ks75r                         1/1     Running             0          5h3m    10.44.1.16    ncn-w003   <none>           <none>
        istio-system        istio-ingressgateway-hmn-555dbc8c6b-npmhz                         1/1     Running             0          5h2m    10.47.0.185   ncn-w002   <none>           <none>
        spire               spire-server-0                                                    2/2     Running             0          22d     10.47.0.190   ncn-w002   <none>           <none>
        spire               spire-server-1                                                    2/2     Running             0          22d     10.42.1.133   ncn-w001   <none>           <none>
        spire               spire-server-2                                                    2/2     Running             0          22d     10.44.0.184   ncn-w003   <none>           <none>
        ```

        In the example output, for each deployment, the pods are spread out across different worker nodes, so no action would be required.

    1. For either of those two deployments, if all pods are running on a single worker node, then move at least one pod to a different worker node.

        Use the `/opt/cray/platform-utils/move_pod.sh` script to do this.

        ```bash
        ncn-m001# /opt/cray/platform-utils/move_pod.sh <pod_name> <target_node>
        ```

1. Run `ncn-upgrade-worker-nodes.sh` for `ncn-w001`.

   Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-worker-nodes.sh ncn-w001
   ```

   > **NOTE:** The root password for the node may need to be reset after it is rebooted.

1. Assign a new CFS configuration to the worker node.

   The content of the new CFS configuration is described in _HPE Cray EX System Software Getting Started Guide S-8000_, section
   "HPE Cray EX Software Upgrade Workflow" subsection "Cray System Management (CSM)". Replace `${NEW_NCN_CONFIGURATION}` with
   the name of the new CFS configuration and `${XNAME}` with the component name (xname) of the worker node that was upgraded.

   ```bash
   ncn-m001# cray cfs components update --desired-config ${NEW_NCN_CONFIGURATION} ${XNAME}
   ```

1. Repeat the previous steps for each other worker node, one at a time.

## Stage 2.3

By this point, all NCNs have been upgraded, except for `ncn-m001`. In the upgrade process so far, `ncn-m001`
has been the "stable node" -- that is, the node from which the other nodes were upgraded. At this point, the
upgrade procedure pivots to use `ncn-m002` as the new "stable node", in order to allow the upgrade of `ncn-m001`.

1. If the CSM tarball is located on an `rbd` device, then remap that device to `ncn-m002`.

    See [Move an `rbd` device to another node](../../operations/utility_storage/Alternate_Storage_Pools.md#move-an-rbd-device-to-another-node).

1. Log in to `ncn-m002` from outside the cluster.

    > **NOTE:** Very rarely, a password hash for the `root` user that works properly on a SLES SP2 NCN is
    > not recognized on a SLES SP3 NCN. If password login fails, then log in to `ncn-m002` from
    > `ncn-m001` and use the `passwd` command to reset the password. Then log in using the CMN IP address as directed
    > below. Once `ncn-m001` has been upgraded, log in from `ncn-m002` and use the `passwd` command to reset
    > the password. The other NCNs will have their passwords updated when NCN personalization is run in a
    > subsequent step.

   `ssh` to the `bond0.cmn0`/CMN IP address of `ncn-m002`.

1. Authenticate with the Cray CLI on `ncn-m002`.

   See [Configure the Cray Command Line Interface](../../operations/configure_cray_cli.md) for details on how to do this.

1. Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade. Be sure you have the `CSM_RELEASE` version set appropriately for the version of CSM 1.2.x you are upgrading to.

   ```bash
   ncn-m002# CSM_RELEASE=csm-1.2.2
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

Apply the workaround for `kdump`:

```bash
ncn-m002# /usr/share/doc/csm/scripts/workarounds/kdump/run.sh
```

Example output:

```text
Uploading hotfix files to ncn-m001:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-m002:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-m003:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-s001:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-s002:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-s003:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-s004:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-w001:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-w002:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-w003:/srv/cray/scripts/common/ ... Done
Uploading hotfix files to ncn-w004:/srv/cray/scripts/common/ ... Done
Running updated create-kdump-artifacts.sh script on [11] NCNs ... Done
The following NCNs contain the kdump patch:
ncn-m001
ncn-m002
ncn-m003
ncn-s001
ncn-s002
ncn-s003
ncn-s004
ncn-w001
ncn-w002
ncn-w003
ncn-w004
This hotfix has completed.
```

## Stage 2.5

Run the following command to complete the upgrade of the `weave` and `multus` manifest versions:

```bash
ncn-m002# /srv/cray/scripts/common/apply-networking-manifests.sh
```

## Stage 2.6

Run the following script to apply anti-affinity to `coredns` pods:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/apply-coredns-pod-affinity.sh
```

## Stage 2.7

Complete the Kubernetes upgrade. This script will restart several pods on each master node to their new Docker containers.

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/upgrade_control_plane.sh
```

> **`NOTE`**: `kubelet` has been upgraded already, ignore the warning to upgrade it.

<a name="stage_completed"></a>

## Stage completed

All Kubernetes nodes have been rebooted into the new image.

> **REMINDER**: If password for `ncn-m002` was reset during Stage 2.3, then also reset the password
> on `ncn-m001` at this time.

This stage is completed. Continue to [Stage 3](Stage_3.md).
