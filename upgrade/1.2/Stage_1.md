# Stage 1 - Kubernetes Upgrade from 1.19.9 to 1.20.12

> NOTE: During the CSM-0.9 install the LiveCD containing the initial install files for this system should have been unmounted from the master node when rebooting into the Kubernetes cluster. The scripts run in this section will also attempt to unmount/eject it if found to ensure the USB stick does not get erased.

## Stage 1.1

For each master node in the cluster (exclude ncn-m001), again follow the steps:

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m002
    ```
    
1. Repeat the previous step for each other master node **excluding `ncn-m001`**, one at a time.

## Stage 1.2

1. Run `ncn-upgrade-k8s-worker.sh` for `ncn-w001`. Follow output of the script carefully. The script will pause for manual interaction.

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-k8s-worker.sh ncn-w001
    ```
    
    > NOTE: You may need to reset the root password for each node after it is rebooted

1. Repeat the previous step for each other worker node, one at a time.

## Stage 1.3

For `ncn-m001`, use `ncn-m002` as the stable NCN. Use `bond0.cmn0`/CAN IP address to `ssh` to `ncn-m002` for this `ncn-m001` install

> NOTE: Run the script once each for all master nodes, excluding ncn-m001. Follow output of above script carefully. The script will pause for manual interaction
> NOTE: You may need to reset the root password for each node after it is rebooted

## Stage 1.2

For each worker node in the cluster, also follow the steps:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-k8s-worker.sh ncn-w002
```

> NOTE: Run the script once each for all worker nodes. Follow output of above script carefully. The script will pause for manual interaction.

> NOTE: It is expected that some pods may be in bad states during a worker node upgrade. This is due to a temporary lack of computing resources during a worker upgrade. Once the worker node has been upgraded and has rejoined the cluster, those pods will be up and running again. All critical services have more than one replica so that if one pod is down, the service is still available.

## Stage 1.3

For ncn-m001, use ncn-m002 as the stable NCN:
> NOTE: using vlan007/CAN IP address to `ssh` to `ncn-m002` for `ncn-m001` install

`Option 1` - Internet Connected Environment

Install document RPM package:

```bash
ncn-m002# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm
ncn-m002# rpm -Uvh docs-csm-latest.noarch.rpm
```

Download and untar the CSM tarball:

Run:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
```

**NOTE** ENDPOINT is optional for internal use. It is pointing to internal arti by default.

`Option 2` - Air Gapped Environment

Install document RPM package:

```bash
ncn-m002# rpm -Uvh [PATH_TO_docs-csm-*.noarch.rpm]
```

Untar the CSM tarball:

Run:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
```

> NOTE: Follow output of above script carefully. The script will pause for manual interaction.

## Upgrade ncn-m001

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m001
```

## Stage 1.4

Run the following command to complete the Kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

```bash
ncn-m002# export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ncn-m002# pdsh -b -S -w $(grep -oP 'ncn-m\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'kubeadm upgrade apply v1.20.12 -y'
```

> **`NOTE`**: kubelet has been upgraded already so you can ignore the warning to upgrade kubelet

## Stage 1.5

Run the following command cleanup several prometheus alert configurations:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-clean-kube-alerts.sh
```

<a name="deploy-manifests"></a>

Once `Stage 1` is completed and all kubernetes nodes have been rebooted into the new image then please proceed to [Stage 2](Stage_2.md)
