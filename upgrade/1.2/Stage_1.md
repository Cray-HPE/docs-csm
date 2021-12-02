# Stage 1 - Kubernetes Upgrade from 1.19.9 to 1.20.13

> NOTE: During the CSM-0.9 install the LiveCD containing the initial install files for this system should have been unmounted from the master node when rebooting into the Kubernetes cluster. The scripts run in this section will also attempt to unmount/eject it if found to ensure the USB stick does not get erased.

## Stage 1.1

1. Run `ncn-upgrade-k8s-master.sh` for `ncn-m002`. Follow output of the script carefully. The script will pause for manual interaction.

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

1. Authenticate with the Cray CLI on `ncn-m002`.

    See [Configure the Cray Command Line Interface](../../operations/configure_cray_cli.md) for details on how to do this.

1. Set the `CSM_RELEASE` variable to the correct value for the CSM release upgrade being applied.

    ```bash
    ncn-m002# CSM_RELEASE=csm-1.2.0
    ```

1. Install document RPM and run check script on `ncn-m002`

    * Option 1 - Internet Connected Environment

        1. Install document RPM package:

            ```bash
            ncn-m002# wget https://storage.googleapis.com/csm-release-public/csm-1.2/docs-csm/docs-csm-latest.noarch.rpm
            ncn-m002# rpm -Uvh docs-csm-latest.noarch.rpm
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
            ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version $CSM_RELEASE --endpoint $ENDPOINT
            ```

    * Option 2 - Air Gapped Environment

        1. Copy the docs-csm RPM package and CSM release tarball to `ncn-m002`.

        1. Install document RPM package:

            ```bash
            ncn-m002# rpm -Uvh [PATH_TO_docs-csm-*.noarch.rpm]
            ```

        1. Set the `TAR_DIR` variable to the directory on `ncn-m002` containing the CSM release tarball.
        
            In other words, the full path to the CSM release tarball will be `${TAR_DIR}/${CSM_RELEASE}.tar.gz`

            ```bash
            ncn-m002# TAR_DIR=/path/to/tarball/dir
            ```

        1. Run the script

            ```bash
            ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version $CSM_RELEASE --tarball-file ${TAR_DIR}/${CSM_RELEASE}.tar.gz
            ```

1. Upgrade `ncn-m001`

    ```bash
    ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m001
    ```

## Stage 1.4

Run the following command to complete the upgrade of the weave and multus manifest versions:

```bash
ncn-m002# /srv/cray/scripts/common/apply-networking-manifests.sh
```

## Stage 1.5

Run the following command to complete the Kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

```bash
ncn-m002# export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ncn-m002# pdsh -b -S -w $(grep -oP 'ncn-m\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'kubeadm upgrade apply v1.20.13 -y'
```

> **`NOTE`**: `kubelet` has been upgraded already, so you can ignore the warning to upgrade it

## Stage 1.6

Run the following command to cleanup several prometheus alert configurations:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/ncn-clean-kube-alerts.sh
```

<a name="deploy-manifests"></a>
Once `Stage 1` is completed, all Kubernetes nodes have been rebooted into the new image. Now proceed to [Stage 2](Stage_2.md)
