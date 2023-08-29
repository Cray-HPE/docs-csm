# Stage 3 - Kubernetes Upgrade from 1.18.6 to 1.19.9

> NOTE: During the CSM-0.9 install the LiveCD containing the initial install files for this system should have been unmounted from the master node when rebooting into the Kubernetes cluster. The scripts run in this section will also attempt to unmount/eject it if found to ensure the USB stick does not get erased.

>**`IMPORTANT:`**
>
> Reminder: Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

## Stage 3.1

1. Run `ncn-upgrade-k8s-master.sh` for `ncn-m002`. Follow output of the script carefully. The script will pause for manual interaction.

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m002
    ```

    > NOTE: You may need to reset the root password for each node after it is rebooted

1. Repeat the previous step for each other master node **excluding `ncn-m001`**, one at a time.

## Stage 3.2

1. Run `ncn-upgrade-k8s-worker.sh` for `ncn-w001`. Follow output of the script carefully. The script will pause for manual interaction.

    > NOTE: It is expected that some pods may be in bad states during a worker node upgrade. This is due to a temporary lack of computing resources. Once the worker node has been upgraded and has rejoined the cluster, those pods will be up and running again. All critical services have more than one replica so that if one pod is down, the service is still available.

    > NOTE: It is possible that some postgres clusters may report errors when `ncn-upgrade-k8s-worker.sh` runs and checks the postgres clusters. If errors are reported indicating that a cluster does not have a leader or is lagging, it is recommended to re-run the `ncn-upgrade-k8s-worker.sh` again after waiting about 30 minutes to give the clusters time to resume to a healthy state. If postgres clusters still report leader or lag issues, then refer to [Troubleshoot Postgres Database](../../operations/kubernetes/Troubleshoot_Postgres_Database.md).

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/ncn-upgrade-k8s-worker.sh ncn-w001
    ```

    > NOTE: You may need to reset the root password for each node after it is rebooted

1. Repeat the previous step for each other worker node, one at a time.

## Stage 3.3

For `ncn-m001`, use `ncn-m002` as the stable NCN. Use `vlan007`/CAN IP address to `ssh` to `ncn-m002` for this `ncn-m001` install

1. Authenticate with the Cray CLI on `ncn-m002`.

    See [Configure the Cray Command Line Interface](../../operations/configure_cray_cli.md) for details on how to do this.

1. Set the `CSM_RELEASE` variable to the correct value for the CSM release upgrade being applied.

    ```bash
    ncn-m002# CSM_RELEASE=csm-1.0.1
    ```

1. Install document RPM and run check script on `ncn-m002`

    **NOTE** The `prerequisites.sh` script will warn that it will unmount `/mnt/pitdata`, but this is not accurate. The script will only unmount it if the script itself mounts it. That is, if it is mounted when the script begins, the script will not unmount it.

    * Option 1 - Internet Connected Environment

        1. Install document RPM package:

            > The install scripts will look for this RPM in `/root`, so it is important that you copy it there.

            ```bash
            ncn-m002# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm -P /root
            ncn-m002# rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
            ```

        1. Set the `ENDPOINT` variable to the URL of the directory containing the CSM release tarball.

            In other words, the full URL to the CSM release tarball will be `${ENDPOINT}${CSM_RELEASE}.tar.gz`

            **NOTE** This step is optional for Cray/HPE internal installs.

            ```bash
            ncn-m002# ENDPOINT=https://put.the/url/here/
            ```

        1. Run the script

            **NOTE** The `--endpoint` argument is optional for Cray/HPE internal use.

            ```bash
            ncn-m002# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/prerequisites.sh --csm-version $CSM_RELEASE --endpoint $ENDPOINT
            ```

    * Option 2 - Air Gapped Environment

        1. Copy the docs-csm RPM package and CSM release tarball to `ncn-m002`.

            > The install scripts will look for the RPM in `/root`, so it is important that you copy it there.

        1. Install document RPM package:

            ```bash
            ncn-m002# rpm -Uvh --force /root/docs-csm-*.noarch.rpm
            ```

        1. Set the `TAR_DIR` variable to the directory on `ncn-m002` containing the CSM release tarball.

            In other words, the full path to the CSM release tarball will be `${TAR_DIR}/${CSM_RELEASE}.tar.gz`

            ```bash
            ncn-m002# TAR_DIR=/path/to/tarball/dir
            ```

        1. Run the script

            ```bash
            ncn-m002# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/prerequisites.sh --csm-version $CSM_RELEASE --tarball-file ${TAR_DIR}/${CSM_RELEASE}.tar.gz
            ```

1. Upgrade `ncn-m001`

    ```bash
    ncn-m002# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m001
    ```

## Stage 3.4

Run the following command to complete the Kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

```bash
ncn-m002# export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ncn-m002# pdsh -b -S -w $(grep -oP 'ncn-m\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'kubeadm upgrade apply v1.19.9 -y'
```

> **`NOTE`**: `kubelet` has been upgraded already, so you can ignore the warning to upgrade it

After the above command has completed and pods have been restarted, execute the following command to ensure pods in the kube-system namespace are running new (`v1.19.9`) versions of their images:

```bash
ncn-m002# for i in `seq 3`; do echo "ncn-m00$i:"; kubectl get po -n kube-system kube-apiserver-ncn-m00${i} -o json | jq '.spec.containers[].image';   kubectl get po -n kube-system kube-controller-manager-ncn-m00${i} -o json | jq '.spec.containers[].image';   kubectl get po -n kube-system kube-scheduler-ncn-m00${i} -o json | jq '.spec.containers[].image'; done
```

Output should look like:
```text
ncn-m001:
"k8s.gcr.io/kube-apiserver:v1.19.9"
"docker.io/cray/kube-controller-manager:v1.19.9"
"k8s.gcr.io/kube-scheduler:v1.19.9"
ncn-m002:
"k8s.gcr.io/kube-apiserver:v1.19.9"
"docker.io/cray/kube-controller-manager:v1.19.9"
"k8s.gcr.io/kube-scheduler:v1.19.9"
ncn-m003:
"k8s.gcr.io/kube-apiserver:v1.19.9"
"docker.io/cray/kube-controller-manager:v1.19.9"
"k8s.gcr.io/kube-scheduler:v1.19.9"
```

> **`NOTE`**: If the output indicates the pods are still running `v1.18.6` images, this is an indication that the `kubeadm upgrade apply` may have had issues. *The output from that command should be inspected and addressed before moving on with the upgrade. If v1.18.6 is shown, discontinue the upgrade and contact HPE Service for support.*

## Stage 3.5

Run the following command cleanup several prometheus alert configurations:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/ncn-clean-kube-alerts.sh
```

<a name="deploy-manifests"></a>

Once `Stage 3` is completed, all Kubernetes nodes have been rebooted into the new image. Now proceed to [Stage 4](Stage_4.md)