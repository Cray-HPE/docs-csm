# While upgrading CSM having 1.6.x to 1.7.0, Kubernetes worker nodes may become unresponsive and `dmesg` may be flooded with iSCSI errors

## Symptom

On a CSM 1.6.x cluster, after upgrading to CSM 1.7.0, the Kubernetes worker nodes may hang and become unresponsive due to LUN remapping followed by a flood of the following message appearing in the Kubernetes worker nodes `dmesg` logs.

```text
[Fri Feb 6 19:31:01 2026] TARGET_CORE[iSCSI]: Detected NON_EXISTENT_LUN Access for 0x0000004b from iqn.2023-06.csm.iscsi:x1005c6s4b1n0
```

**Note:**
LUN remapping occurs when the storage system changes the Logical Unit Number (LUN) identifiers associated with previously mapped
storage devices presented to the host.

## Root cause

In CSM `1.7.0`, the target port group (TPG) was temporarily disabled and later re-enabled to address an issue where worker nodes were entering a hung state
during the management node rollout stage. However, disabling the TPG during the management node rollout resulted in LUN remapping and `dmesg` being flooded with
`Detected NON_EXISTENT_LUN Access errors`, which eventually caused the worker nodes to become unresponsive.

This issue has been resolved in CSM `1.7.1`, and the fix now needs to be backported to the 1.6.x release.

## Resolution

The resolution is to apply the following fixes to remove the TPG disablement, followed by restarting the `target` service on the Kubernetes worker nodes.

After the update-vcs-config stage of the CSM upgrade through IUF, follow the procedure below:

### A. Update `cfs-config`

#### Step 1: (`ncn-mw#`) Retrieve the Latest CSM Version

```bash
kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V | tail -n 1
```

Example output:

```text
1.7.0
```

#### Step 2: (`ncn-mw#`) Find the CFS configuration branch associated with the CSM version found in Step 1

```bash
kubectl get cm -n services cray-product-catalog -o yaml | yq r - 'data.csm' | grep ^1.7.0: -A 10 | grep import_branch
```

Example output:

```text
import_branch: cray/csm/1.48.2
```

**Note:** The `import_branch` from this output will be used below.

#### Step 3: (`ncn-mw#`) Apply Changes to VCS

Get VCS credentials:

```bash
GITUSER=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_username | base64 -d)
GITPASS=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_password | base64 -d)
```

Clone `csm-config-management.git`(Use above VCS credentials) repo:

```bash
git clone https://$GITUSER:$GITPASS@api-gw-service-nmn.local/vcs/cray/csm-config-management.git
```

Check out the `import_branch` identified in the `Step 2`:

In the following command, substitute the actual branch name found in the `Step 2`:

```bash
cd csm-config-management
git checkout cray/csm/1.48.2
```

Create new branch under `import_branch`:

For example:

```bash
git branch CAST-39550
git checkout CAST-39550
```

Create patch file by copying below content into new `iscsi_fix.patch` file:

```bash
cat > iscsi_fix.patch << 'EOF'
diff --git a/roles/csm.sbps.lio_config/files/provision_iscsi_server.sh b/roles/csm.sbps.lio_config/files/provision_iscsi_server.sh
index 5921e68..452f793 100644
--- a/roles/csm.sbps.lio_config/files/provision_iscsi_server.sh
+++ b/roles/csm.sbps.lio_config/files/provision_iscsi_server.sh
@@ -70,11 +70,6 @@ function auto_generate_node_acls()
         targetcli "/iscsi/${TARGET_SERVER_IQN}/tpg1 set attribute generate_node_acls=1"
 }

-function disable_target_port()
-{
-        targetcli "/iscsi/${TARGET_SERVER_IQN}/tpg1" disable
-}
-
 #--------------------------------------------------------------------
 # Base Target Configuration
 #--------------------------------------------------------------------
@@ -98,5 +93,4 @@ SERVER_IQN="$(add_server_target)"
 #--------------------------------------------------------------------

 auto_generate_node_acls "$SERVER_IQN"
-disable_target_port
 save_server_config
EOF
```

Now apply `iscsi_fix.patch`:

```bash
git apply iscsi_fix.patch
```

Commit and push above patch changes to VCS:

Commit changes:

```bash
git add roles/csm.sbps.lio_config/files/provision_iscsi_server.sh
git commit -m "fix for CAST-39550"
```

Push the changes to VCS:

```bash
git push --set-upstream origin CAST-39550
COMMIT=`git log | head -n 1 | awk '{print $2}'`
echo $COMMIT
```

Example output:

```text
3aac2910252cc55a8b952a36243826a10e70b705
```

#### Step 4: (`ncn-mw#`) Update `cray` product catalog with new commit id captured from the above step

Update the `cray` product catalog:

```bash
kubectl edit cm -n services cray-product-catalog
```

Example of current `cray-product-catalog` snippet:

```text
    1.7.0:
      configuration:
        clone_url: https://vcs.cmn.vidar.hpc.amslabs.hpecorp.net/vcs/cray/csm-config-management.git
        commit: 26d739d6d2642e72d55cfc7b141902ae4fdceb95
        import_branch: cray/csm/1.48.2
```

Optional command to get the current "commit id" using:

```bash
kubectl get cm -n services cray-product-catalog -o yaml | yq r - 'data.csm' | grep ^1.7.0: -A 10 | grep commit
```

Example output:

```text
    commit: 26d739d6d2642e72d55cfc7b141902ae4fdceb95
```

Replace the above commit id with the new commit id (obtained using `echo $COMMIT`).

Example of `cray-product-catalog` snippet after update:

```text
    1.7.0:
      configuration:
        clone_url: https://vcs.cmn.vidar.hpc.amslabs.hpecorp.net/vcs/cray/csm-config-management.git
        commit: 3aac2910252cc55a8b952a36243826a10e70b705
        import_branch: cray/csm/1.48.2
```

Optional command just to validate the updated "commit id" using:

```bash
kubectl get cm -n services cray-product-catalog -o yaml | yq r - 'data.csm' | grep ^1.7.0: -A 10 | grep commit
```

Example output:

```text
    commit: 3aac2910252cc55a8b952a36243826a10e70b705
```

#### Step 5: (`ncn-mw#`) Get and update CFS configuration with new commit id

Example case for node `ncn-w001`:

* Get the xname of node:  

```bash
XNAME=$(ssh ncn-w001 cat /etc/cray/xname)
```

* Get the desired component configuration name:

```bash
CONFIG=$(cray cfs components describe $XNAME --format json | jq -r '.desiredConfig')
```

* Get the desired component configuration:

```bash
cray cfs configurations describe $CONFIG --format json | jq -r '. | del(.name) | del(.lastUpdated)' > ${CONFIG}.json
```

* Update the config with new "commit id" from the above step and save:

```bash
vim ${CONFIG}.json
```

Example:

```json
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
      "commit": "3aac2910252cc55a8b952a36243826a10e70b705",
      "name": "csm-sbps_iscsi_targets-1.7.0",
      "playbook": "config_sbps_iscsi_targets.yml"
    },
```

#### Step 6: (`ncn-mw#`) Update CFS configuration

```bash
cray cfs configurations update --file ${CONFIG}.json ${CONFIG}
```

**Note:** The status is stored in `configurationStatus` field of the below command. Wait till it changes to `configured`.

For Example:

```bash
cray cfs components describe $XNAME
```

Example output:

```text
configurationStatus = "pending"
desiredConfig = "management-release-cr_2025-2319974"
enabled = true
errorCount = 0
…
```

```text
configurationStatus = "configured"
desiredConfig = "management-release-cr_2025-2319974"
enabled = true
errorCount = 0
…
```

### B. Restart `target` service on Kubernetes worker nodes after upgrade

#### Step 1: (`ncn-w#`) Perform Pre-checks

On Kubernetes worker node:

* Wait for upgrade to complete followed by `cfs` configuration completion
* Check if `iSCSI SBPS` is up and running:
    * `targetcli ls` shows the `LUNs` and portals created
* Check if `systemctl status sbps-marshal.service` shows `sbps marshal` agent is in `active (running)` state

#### Step 2: (`ncn-w#`) Restart the target service

```bash
systemctl restart target.service
```

#### Step 3: (`ncn-w#`) Check the target service status

```bash
systemctl status target.service
```

Example output:

```text
● target.service - Restore LIO kernel target configuration
     Loaded: loaded (/usr/lib/systemd/system/target.service; enabled; preset: disabled)
     Active: active (exited) since Mon 2026-03-09 07:42:44 UTC; 10h ago
    Process: 1625411 ExecStart=/usr/bin/targetctl restore $CONFIG_FILE (code=exited, status=0/SUCCESS)
   Main PID: 1625411 (code=exited, status=0/SUCCESS)
        CPU: 899ms

Mar 09 07:42:38 ncn-w004 systemd[1]: Starting Restore LIO kernel target configuration...
Mar 09 07:42:44 ncn-w004 systemd[1]: Finished Restore LIO kernel target configuration.
```
