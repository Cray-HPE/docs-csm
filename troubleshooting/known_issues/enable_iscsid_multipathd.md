# Boot content projection services can fail if `iscsid` and `multipathd` services are not enabled on compute nodes and UANs

## Issue Description

iSCSI based boot content projection which is also known as "Scalable Boot Content Projection" (SBPS) for `rootfs` and `PE` images
is supported in CSM version CSM 1.6.0 and later. On a customer system, using `CSM-1.6.0` with `USS-1.1.x` on compute nodes/ UANs in order to support AARCH64 images,
`iscsid` and `multipathd` services are not enabled by default. SBPS will not be resilient across worker node reboots if these services are not enabled by default on compute nodes or UANs.

## Issue Identification

This issue can be identified by the following symptoms:

On a compute node or UAN (iSCSI Initiator) we can observe the following SQUASHFS error messages in the console log:

```bash
dmesg -T | grep "SQUASHFS error" | head -n  1
```

Example output:

```text
[Sat Nov  2 22:32:41 2024] SQUASHFS error: xz decompression failed, data probably corrupt
```

On a compute node or UAN (iSCSI Initiator) we can observe that the `iscsid` service is not active:

```bash
ncn-s004# systemctl status iscsid
● iscsid.service - Open-iSCSI
     Loaded: loaded (/usr/lib/systemd/system/iscsid.service; disabled; preset: disabled)
     Active: active (running) since Wed 2024-11-06 08:16:23 CST; 1 day 4h ago
TriggeredBy: ● iscsid.socket
```

From the `journalctl` logs:

```text
Nov 07 10:24:23 nid000004 iscsid[22286]: iscsid: Kernel reported iSCSI connection 2:0 error (1020 - ISCSI_ERR_TCP_CONN_CLOSE: TCP connection closed) state (3)
Nov 07 10:25:14 nid000004 iscsid[22286]: iscsid: connect to 10.253.0.3:3260 failed (No route to host)
...
Nov 07 10:30:43 nid000004 iscsid[22286]: iscsid: connect to 10.253.0.3:3260 failed (Connection refused)
...
```

## Workaround Description

### 1: Get the version of the `csm-packages` from compute node BOS session template

Example:

Find the session template name (`ncn#`):

```bash
cray bos sessiontemplates list | grep compute-*
```

Example output:

```toml
name = "compute-25.1.0-alpha2.x86_64-csm-160-rc4"
```

Using the `sessiontemplate` name from the previous command, find the `configuration` name (`ncn#`):

```bash
cray bos sessiontemplates describe compute-25.1.0-alpha2.x86_64-csm-160-rc4  --format json
```

Example output:

```json
{
    "cfs": {
        "configuration": "compute-25.1.0-alpha2-csm-160-rc4"
    }
}
```

Use the `configuration` value to describe the configuration (`ncn#`):

```bash
cray cfs configurations describe compute-25.1.0-alpha2-csm-160-rc4 --format json
```

Example output:

```json
{
    "lastUpdated": "2024-11-02T12:15:21Z",
    "layers": [
        {
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "commit": "d530f0a277c9d5dc9e3cb487d32d6b316757f00e",
            "name": "csm-packages-1.6.0-rc.4",
            "playbook": "csm_packages.yml"
        }
    ]
}
```

The `name` from the describe above identifies the product catalog. Use the version after `csm-packages-` in the next step.

### 2: Get the corresponding `csm-config` branch (@VCS) from product catalog given `csm-packages-*` version found from `Step-1`

Example (`ncn-#`):

```bash
kubectl get cm -n services cray-product-catalog -o yaml | yq - r 'data.csm' | grep ^1.6.0-rc.4: -A 10
```

Example output:

```yaml
1.6.0-rc.4:
  configuration:
    clone_url: https://vcs.cmn.fanta.hpc.amslabs.hpecorp.net/vcs/cray/csm-config-management.git
    commit: d530f0a277c9d5dc9e3cb487d32d6b316757f00e
    import_branch: cray/csm/1.27.2
```

The `import_branch` from above output will be used below.

### 3: Log into VCS and clone `csm-config-management.git` @ VCS

Example (`ncn#`):

```bash
USERNAME=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_username | base64 -d  )
PSWD=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_password | base64 -d  )
git clone https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
```

> **Note:** use above $USERNAME and $PSWD for VCS login

### 4: Apply fix against `import_branch` found in `step-2`

Example (`ncn#`):

```bash
cd csm-config-management
git checkout cray/csm/1.27.2
git checkout -b CASMTRIAGE-7509
```

> **Note:** `cray/csm/1.27.2` is a target branch and `CASMTRIAGE-7509` is a new branch

Add new role to enable `iscsid` and `multipathd` service:

```bash
cat > roles/csm.enable_iscsid_multipathd/tasks/main.yml << EOF
---
- name: Ensure iscsid service is started
  ansible.builtin.systemd:
    name: iscsid
    state: started
    enabled: true

- name: Ensure multipathd service is started
  ansible.builtin.systemd:
        name: multipathd
        state: started
        enabled: true
EOF
```

Apply the following changes to `csm-config-management/csm_packages.yml` to Application-nodes only play and Compute-nodes only play under `csm_services` in order to enable `iscsid` and `multipathd` services.

```diff
diff --git a/csm_packages.yml b/csm_packages.yml
index e3366f8..b223aec 100755
--- a/csm_packages.yml
+++ b/csm_packages.yml
@@ -137,6 +137,9 @@
       vars:
         packages: "{{application_csm_sles_packages }}"
       when: ansible_distribution_file_variety == "SUSE"
+    # Enable iscsid and multipathd service
+    - role: csm.enable_iscsid_multipathd
+
   tasks:
     - name: Enable smart service
       systemd:
@@ -148,3 +151,12 @@
         name: cray-node-exporter
         state: started
         enabled: true
+
+# Compute-nodes only play
+- hosts: Compute:!cfs_image
+  gather_facts: no
+  any_errors_fatal: true
+  remote_user: root
+  roles:
+    # Enable iscsid and multipathd service
+    - role: csm.enable_iscsid_multipathd
```

### 5: Commit the changes and push them to VCS

Example (`ncn#`):

```bash
git add csm_packages.yml
git commit -m "fix for CASMTRIAGE-7509"
git push --set-upstream origin CASMTRIAGE-7509

COMMIT="$(git log -1 --pretty='format:%H')"
echo $COMMIT
```

Example output:

```text
bf214b8a9867531a38f8ca28b6ffae1fe56724ce
```

### 6: Create new CFS configuration with above change to be applied

Example (`ncn#`):

```bash
SESSIONTEMPLATE=compute-25.1.0-alpha2.x86_64-csm-160-rc4
CFS_CONFIG="$(cray bos sessiontemplates describe "$SESSIONTEMPLATE" --format json | jq -r .cfs.configuration)"
cray cfs configurations describe "$CFS_CONFIG" --format json | jq '. | del(.lastUpdated) | del(.name)'  > "$CFS_CONFIG"
```

### 7: Update commit id

Update the `$COMMIT`from [5: Commit the changes and push them to VCS](#5-commit-the-changes-and-push-them-to-vcs) (`ncn#`):

```bash
vim "$CFS_CONFIG"
```

```bash
cat "$CFS_CONFIG"
```

Example output:

```json
{
    "layers": [
        {
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "commit": "bf214b8a9867531a38f8ca28b6ffae1fe56724ce",
            "name": "csm-packages-1.6.0-rc.4",
            "playbook": "csm_packages.yml"
        }
    ]
}
```

### 8: Update `cfs` config

Update `cfs` (`ncn#`):

```bash
cray cfs configurations update --file $CFS_CONFIG $CFS_CONFIG
```

### 9: Create new BOS session template with this new config change

Please refer to: [Create BOS session template for iSCSI SBPS](../../operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md)
