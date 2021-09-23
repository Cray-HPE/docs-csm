# Stage 3 - Kubernetes Upgrade from 1.18.6 to 1.19.9

> NOTE: During the CSM-0.9 install the LiveCD containing the initial install files for this system should have been unmounted from the master node when rebooting into the Kubernetes cluster. The scripts run in this section will also attempt to unmount/eject it if found to ensure the USB stick does not get erased.

## Stage 3.1

For each master node in the cluster (exclude ncn-m001), again follow the steps:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m002
```

> NOTE: Run the script once each for all master nodes, excluding ncn-m001. Follow output of above script carefully. The script will pause for manual interaction
> NOTE: You may need to reset the root password for each node after it is rebooted

## Stage 3.2

For each worker node in the cluster, also follow the steps:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-worker.sh ncn-w002
```

> NOTE: Run the script once each for all worker nodes. Follow output of above script carefully. The script will pause for manual interaction.

> NOTE: It is expected that some pods may be in bad state during a worker node upgrade. This is due to a temporary lack of computing resources during a worker upgrade. Once the worker node has been upgraded and rejoined cluster, those pods will be up and running again. All critical services have more than one replica so if one pod is down, the service is still available.

## Stage 3.3

For ncn-m001, use ncn-m002 as the stable NCN:
> NOTE: using vlan007/CAN IP address to `ssh` to `ncn-m002` for `ncn-m001` install

`Option 1` - Internet Connected Environment

Install document RPM package:

```bash
ncn-m002# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm
ncn-m002# rpm -Uvh docs-csm-latest.noarch.rpm
```

Run:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
```

**NOTE** ENDPOINT is optional for internal use. It is pointing to internal arti by default

`Option 2` - Air Gapped Environment

Install document RPM package:

```bash
ncn-m002# rpm -Uvh [PATH_TO_docs-csm-*.noarch.rpm]
```

Run:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
```

> NOTE: Follow output of above script carefully. The script will pause for manual interaction

## Upgrade ncn-m001

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m001
```

## Stage 3.4

Run the following command to complete the Kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

```bash
ncn-m002# export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ncn-m002# pdsh -b -S -w $(grep -oP 'ncn-m\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'kubeadm upgrade apply v1.19.9 -y'
```

> **`NOTE`**: kubelet has been upgraded already so you can ignore the warning to upgrade kubelet

<a name="deploy-manifests"></a>
### Stage 4. - CSM Service Upgrades

Run `csm-service-upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/csm-service-upgrade.sh
```

**`IMPORTANT`:** This script will re-try up to three times if failures are encountered -- but if the script seems to hang for thirty minutes or longer without progressing, the administrator should interrupt the script (CTRL-C) and re-run it.

Once `Stage 3` is completed and all kubernetes nodes have been rebooted into the new image then please proceed to [Stage 4](Stage_4.md)