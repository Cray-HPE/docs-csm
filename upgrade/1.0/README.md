# CSM 0.9.4 to 1.0.0 Upgrade Process

## Introduction

This document is intended to guide an administrator through the upgrade process going from Cray Systems Management 0.9 to v1.0. When upgrading a system, this top-level README.md file should be followed top to bottom, and the content on this top level page is meant to be terse. See the additional files in the various directories under the resource_material directory for additional reference material in support of the process/scripts mentioned explicitly on this page.

## Terminology

Throughout the guide the terms "stable" and "upgrade" are used in the context of the management nodes (NCNs). The
"stable" NCN is the master node from which all of these commands will be run and therefore cannot have its power state
affected. Then the "upgrade" node is the node to next be upgraded.

When doing a rolling upgrade of the entire cluster, at some point you will need to transfer the
responsibility of the "stable" NCN to another master node. However, you do not need to do this before you are ready to
upgrade that node.

## Upgrade Stages

### Stage 0. - Prerequisites and Preflight Checks

> NOTE: CSM-0.9.4 is the version of CSM required in order to upgrade to CSM-1.0.0 (available with Shasta v1.5).

> NOTE: Installed CSM versions may be listed from the product catalog using the following command. This will sort a semantic version without a hyphenated suffix after the same semantic version with a hyphenated suffix, e.g. 1.0.0 > 1.0.0-beta.19. 
>
> ```bash
> ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
> ```
>
> NOTE: The latest installed CSM version may be listed from the product catalog using the following command. This will sort a semantic version without a hyphenated suffix after the same semantic version with a hyphenated suffix, e.g. 1.0.0 > 1.0.0-beta.19. 
>
> ```bash
> ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$// | tail -n 1'
> ```

The following command can be used to check the CSM version on the system:

```bash
ncn# kubectl get cm -n services cray-product-catalog -o json | jq -r '.data.csm'
```

This check will also be conducted in the 'prerequisites.sh' script listed below and will fail if the system is not running CSM-0.9.4.

#### Stage 0.1. - Install latest docs RPM

1. Install latest document RPM package:

    * Internet Connected

        ```bash
        ncn-m001# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
        ncn-m001# rpm -Uvh docs-csm-install-latest.noarch.rpm
        ```

    * Air Gapped

        ```bash
        ncn-m001# rpm -Uvh [PATH_TO_docs-csm-install-*.noarch.rpm]
        ```

#### Stage 0.2. - Update `customizations.yaml`

Perform these steps to update `customizations.yaml`:

1. Extract `customizations.yaml` from the `site-init` secret:

   ```bash
   ncn-m001# cd /tmp
   ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
   ```

2. Update `customizations.yaml`:

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/update-customizations.sh -i customizations.yaml
   ```

3. Update the `site-init` secret:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

4. If using an external Git repository for managing customizations ([as recommended](../../install/prepare_site_init.md#version-control-site-init-files)),
   clone a local working tree and commit appropriate changes to `customizations.yaml`,
   e.g.:

   ```bash
   ncn-m001# git clone <URL> site-init
   ncn-m001# cp /tmp/customizations.yaml site-init
   ncn-m001# cd site-init
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Remove Gitea PVC configuration from customizations.yaml'
   ncn-m001# git push
   ```

5. Return to original working directory:

   ```bash
   ncn-m001# cd -
   ```

#### Stage 0.3. - Execute Prerequisites Check

1. Run check script:

    * Internet Connected

        ```bash
        ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
        ```

        **NOTE** ENDPOINT is optional for internal use. It is pointing to internal arti by default

    * Air Gapped

        ```bash
        ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
        ```

2. The script also runs the goss tests on the initial stable node (typically `ncn-m001`) where the latest version of CSM has been installed. Make sure the goss test pass before continue.

### Stage 1.  Ceph upgrade from Nautilus (14.2.x) to Octopus (15.2.x)

#### Stage 1.1

Run:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-initial.sh ncn-s001
```

> NOTE: Run the script once each for all storage nodes. Follow output of the script carefully. The script will pause for manual interaction

#### Stage 1.2

**`IMPORTANT:`** We scale down the conman deployements during stage 1.2 (this stage), so all console sessions will be down for portion of the upgrade

**`IMPORTANT`** If this has be run previously, then check point files may need to be deleted.

```bash
Directory location = /etc/cray/ceph/_upgraded

/etc/cray/ceph/images_pre_pulled
/etc/cray/ceph/radosgw_converted
/etc/cray/ceph/upgrade_initialized
/etc/cray/ceph/mons_upgraded
/etc/cray/ceph/mgrs_upgraded
/etc/cray/ceph/keys_distributed
/etc/cray/ceph/converted_to_orch
/etc/cray/ceph/osds_upgraded
/etc/cray/ceph/mds_upgraded
/etc/cray/ceph/rgws_upgraded
```

**`NOTE:`** You can delete all these files and rerun or you can just delete any files from your last step. You may end up with checkpoint files if the upgrade was exited out of by the user.  But if you know you exited out of OSDs and it wasn't a clean exit, then you would only need remove `osd_upgraded`, `mds_upgraded` and `rgw_upgraded`.

1. Start the Ceph upgrade

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph.sh
   ```

   `**`IMPORTANT NOTES`**

   > * At this point your Ceph commands will still be working.  
   > * You have a new way of executing Ceph commands in addition to the traditional way.  
   >   * Please see [cephadm-reference.md](resource_material/storage/cephadm-reference.md) for more information.
   > * Both methods are dependent on the master nodes and storage nodes 001/2/3 have a ceph.client.admin.keyring and/or a ceph.conf file    (cephadm will not require the ceph.conf).
   > * When you continue with Stage 2, you may have issues running your Ceph commands.  
   >   * If you are experiencing this, please double check that you restored your /etc/ceph directory from your tar backup.
   > * Any deployments that are backed by a cephfs PVC will be unavailable during this stage of the upgrade. These deployments will be    scaled down and back up automatically. This includes **(but can vary by deployment)**: `nexus`, `cray-ipxe`, `cray-tftp`, `cray-ims`,    `cray-console-operator`, and `cray-cfs-api-db`. To view the complete list for the system being upgraded, run the following script to list    them:
    >>
    >>   ```bash
    >>   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/list-cephfs-clients.sh
    >>   ```

2. Verify that you conman is running

    ```bash
    ncn-m# kubectl get pods -n services|grep con
    ncn-w002:~ # kubectl get pods -n services|grep con
    cray-console-data-9b5984846-l6bvb                              2/2     Running            0          3d22h
    cray-console-data-postgres-0                                   3/3     Running            0          5h15m
    cray-console-data-postgres-1                                   3/3     Running            0          4d23h
    cray-console-data-postgres-2                                   3/3     Running            0          5d
    cray-console-data-wait-for-postgres-5-jrsq4                    0/2     Completed          0          3d22h
    cray-console-node-0                                            3/3     Running            0          5d
    cray-console-node-1                                            3/3     Running            0          5h15m
    cray-console-operator-c4748d6b4-vvpn7                          2/2     Running            0          4d23h
    csm-config-import-1.0.0-beta.46-5t7kx                          0/3     Completed          0          4d
    ```

**`NOTE:`** if conman is not running please see [establising conman console connections](operations/../../../operations/conman/Establish_a_Serial_Connection_to_NCNs.md)

### Stage 2. Ceph image upgrade

For each storage node in the cluster, start by following the steps: 

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-nodes.sh ncn-s001
```

> NOTE: Run the script once each for all storage nodes. Follow output of the script carefully. The script will pause for manual interaction
> Note that these steps should be performed on one storage node at a time.

### Stage 3. Kubernetes Upgrade from 1.18.6 to 1.19.9

> NOTE: During the CSM-0.9 install the LiveCD containing the initial install files for this system should have been unmounted from the master node when rebooting into the Kubernetes cluster. The scripts run in this section will also attempt to unmount/eject it if found to ensure the USB stick does not get erased.

#### Stage 3.1

For each master node in the cluster (exclude m001), again follow the steps:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m002
```

> NOTE: Run the script once each for all master nodes, excluding ncn-m001. Follow output of above script carefully. The script will pause for manual interaction

#### Stage 3.2

For each worker node in the cluster, also follow the steps:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-worker.sh ncn-w002
```

> NOTE: Run the script once each for all worker nodes. Follow output of above script carefully. The script will pause for manual interaction

#### Stage 3.3

For ncn-m001, use ncn-m002 as the stable NCN:
> NOTE: using vlan007/CAN IP address to `ssh` to `ncn-m002` for `ncn-m001` install

##### Option 1 - Internet Connected Environment

Install document RPM package:

```bash
ncn-m002# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
ncn-m002# rpm -Uvh docs-csm-install-latest.noarch.rpm
```

Run:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
```

**NOTE** ENDPOINT is optional for internal use. It is pointing to internal arti by default

##### Option 2 - Air Gapped Environment

Install document RPM package:

```bash
ncn-m002# rpm -Uvh [PATH_TO_docs-csm-install-*.noarch.rpm]
```

Run:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
```

> NOTE: Follow output of above script carefully. The script will pause for manual interaction

##### Upgrade ncn-m001

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m001
```

#### Stage 3.4

On each master node in the cluster, run the following command to complete the Kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

```bash
ncn-m# kubeadm upgrade apply v1.19.9 -y
```

> **`NOTE`**: kubelet has been upgraded already so you can ignore the warning to upgrade kubelet

<a name="deploy-manifests"></a>
### Stage 4. - CSM Service Upgrades

Run `csm-service-upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/csm-service-upgrade.sh
```

**`IMPORTANT`:** This script will re-try up to three times if failures are encountered -- but if the script seems to hang for thirty minutes or longer without progressing, the administrator should interrupt the script (CTRL-C) and re-run it.

### Stage 5. - Hotfix to workaround known mac-learning issue with 8325. 


#### Issue description

> **Aruba CR:**          90598
>
> **Affected platform:** 8325
>
>**Symptom:**           MAC learning stops.
>
>**Scenario:**          Under extremely rare DMA stress conditions, anL2 learning thread may timeout and exit preventing future MAC learning.
>
>**Workaround:**        Reboot the switch or monitor the L2 thread and restart it with an NAE script
>
>**Fixed in:**	       10.06.0130, 10.7.0010 and above. 
>
>[Aruba release notes](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches;productSeries=Aruba%208325%20Switch%20Series) 

#### To fix the issue without upgrading software:

	You can run a NAE script on the 8325 platform switches to resolve mac learning issue.

#### Important information:

	- This NAE script creates a bash script in /tmp and runs every 60s.
	- The script writes file to a storage every 60s (NAE alert file)
	- There are no controls over alert status.
	- Event log is created when a problem is detected
	
	“BCML2X has quit unexpectedly, attempting to restart...”

	- You can also grep the error from /var/log/messages
	- REST-API URI = /rest/v10.04/logs/event?SYSLOG_IDENTIFIER=root&since=yesterday
	- Delete agent & script after upgrading to 10.06.0130+
	- Monitor eMMC health if you plan on running for a long time
	- show system resource | include utiliz

#### The file locations in doc-csm

	- The NAE script (L2X-Watchdog-creates-bash-script.py) is located at: ../docs-csm/troubleshooting/known_issue
	- Automatic NAE install script (nae_upload.py) is located at: ../docs-csm/troubleshooting/known_issue


### Automated install of NAE script 

#### Prerequisites: 

1. The nae-upload.py script relies on /etc/hosts file to pull IP addresses of the switch. Without this information the script won’t run.
2. You have 8325 in your setup that is running software version below 10.06.0130. 
3. Script assumes you  are using default username "admin"  for the switch and it will prompt you for password. 

NOTE: 	The nae-upload script automatically detects 8325’s and only applies the fix to this platform.

#### How to run the install script: 

**Step 1:** 

Give run permissions for the script: 

> pit-ncn-m001:~ # chmod +x nae_upload.py

**Step 2:** 

> pit-ncn-m001:~ # chmod +x nae_upload.py

**Step 3:** 

> pit-non-m991”:~ # ./nae_upload.py

**step 4:**

> Type in your switch password and the script will upload and enable the NAE script. 

### Manually Install of NAE script:
 
**Step 1:**
 
	To get started, login to an AOS-CX device via the Web User Interface, and click on the Analytics section on the left, then click on the Scripts button on the top middle section.

**Step 2:** 

	On the Scripts page: 

	Install the script from your PC to your AOS-CX device by clicking the Upload button on the scripts page and navigating to the file location on your PC.

**Step 3:**
 
	After you have the script on the AOS-CX device, you now need to create an agent. On the Scripts page, you can click the Create Agent button and a Create Agent popup box will appear.

	Give the Agent a name (no spaces).

	NOTE: You can leave all other default values and click Create.

**Step 4:** 

	Navigate you to the Agents page, where you can click on the name of the Agent you made to confirm it is running and no errors are generated. 

	The Network Analytics Engine will monitor the switch and automatically fix the mac learning issue. 

#### Troubleshooting and known error messages: 

Incorrect password: 

> pit-ncn-m001:~ # ./nae_upload.py
> Switch login password:
> Traceback (most recent call last):
> File "./nae_upload.py", line 57, in <module>
> platform = system.json()
> File "/usr/lib/python3.6/site-packages/requests/models.py", line 898, in json
> return complexjson.loads(self.text, **kwargs)
> File "/usr/lib64/python3.6/site-packages/simplejson/__init__.py", line 518, in loads
> return _default_decoder.decode(s)
> File "/usr/lib64/python3.6/site-packages/simplejson/decoder.py", line 373, in decode
> raise JSONDecodeError("Extra data", s, end, len(s))
> simplejson.errors.JSONDecodeError: Extra data: line 1 column 5 - line 1 column 27 (char 4 - 26)

Script has already been loaded: 

> pit-ncn-m001:~ # ./nae_upload.py
> Switch login password:
> L2X-Watchdog NAE script is already installed on sw-spine-001.
> L2X-Watchdog NAE script is already installed on sw-spine-002.
> loki-ncn-m001:~ #

## Troubleshooting and Recovering from Errors During or After Upgrade

### Rerun a step/script

When running upgrade scripts, each script record what has been done successfully on a node. This `state` file is stored at `/ect/cray/upgrade/csm/{CSM_VERSION}/{NAME_OF_NODE}/state`. If a rerun is required, you will need to remove the recorded steps from this file.

Here is an example of state file of `ncn-m001`:

```bash
ncn-m001:~ # cat /etc/cray/upgrade/csm/csm-1.0.0-beta.46/ncn-m001/state
[2021-07-22 20:05:27] UNTAR_CSM_TARBALL_FILE
[2021-07-22 20:05:30] INSTALL_CSI
[2021-07-22 20:05:30] INSTALL_WAR_DOC
[2021-07-22 20:13:15] SETUP_NEXUS
[2021-07-22 20:13:16] UPGRADE_BSS <=== Remove this line if you want to rerun this step
[2021-07-22 20:16:30] CHECK_CLOUD_INIT_PREREQ
[2021-07-22 20:19:17] APPLY_POD_PRIORITY
[2021-07-22 20:19:38] UPDATE_BSS_CLOUD_INIT_RECORDS
[2021-07-22 20:19:38] UPDATE_CRAY_DHCP_KEA_TRAFFIC_POLICY
[2021-07-22 20:21:03] UPLOAD_NEW_NCN_IMAGE
[2021-07-22 20:21:03] EXPORT_GLOBAL_ENV
[2021-07-22 20:50:36] PREFLIGHT_CHECK
[2021-07-22 20:50:38] UNINSTALL_CONMAN
[2021-07-22 20:58:39] INSTALL_NEW_CONSOLE
```

* See the inline comment above on how to rerun a single step
* If you need to rerun the whole upgrade of a node, you can just delete the state file 

### General Kubernetes Commands for Troubleshooting

Please see [Kubernetes_Troubleshooting_Information.md](../../operations/kubernetes/Kubernetes_Troubleshooting_Information.md).

### Troubleshooting PXE Boot Issues

If execution of the upgrade procedures results in NCNs that have errors booting, please refer to these troubleshooting procedures: 
[PXE Booting Runbook](../../troubleshooting/pxe_runbook.md)

### Troubleshooting NTP

During execution of the upgrade procedure, if it is noted that there is clock skew on one or more NCNs, the following procedure can be used to troubleshoot NTP config or to sync time:
[configure_ntp_on_ncns.md](../../operations/configure_ntp_on_ncns.md)

### Bare-Metal Etcd Recovery

If in the upgrade process of the master nodes, it is found that the bare-metal etcd cluster (that houses values for the Kubernetes cluster) has a failure,
it may be necessary to restore that cluster from back-up. Please see
[Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md](../../operations/kubernetes/Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md) for that procedure.

### Back-ups for Etcd-Operator Clusters

After upgrading, if health checks indicate that etcd pods are not in a healthy/running state, recovery procedures may be needed. Please see
[Backups_for_etcd-operator_Clusters.md](../../operations/kubernetes/Backups_for_etcd-operator_Clusters.md) for these procedures.

### Recovering from Postgres Dbase Issues

After upgrading, if health checks indicate the Postgres pods are not in a healthy/running state, recovery procedures may be needed.
Please see [Troubleshoot_Postgres_Database.md](../../operations/kubernetes/Troubleshoot_Postgres_Database.md) for troubleshooting and recovery procedures.

### Troubleshooting Spire Pods Not Staring on NCNs

Please see [Troubleshoot_SPIRE_Failing_to_Start_on_NCNs.md](../../operations/security_and_authentication/Troubleshoot_SPIRE_Failing_to_Start_on_NCNs.md).
`