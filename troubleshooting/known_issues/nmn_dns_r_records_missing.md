# iSCSI SBPS projection over NMN will fail if DNS "A" (address) records for NMN are not created

## Issue Description

iSCSI based boot content projection which is also known as "Scalable Boot Content Projection" (SBPS) for `rootfs` and `PE` images is
supported in CSM version CSM 1.6.0 and later. On a customer system, using `CSM-1.6.0` and later with fresh install, DNS SRV "A" records
for NMN may not be created due to trailing CRLFs(Carriage Return Line Feed) with NMN IPs.

## Issue Identification

This issue can be identified by the following symptoms:

On any worker node with one of the below command we can observe that the DNS "SRV" "A" records are missing for NMN

**Using powerdns command**

```bash
ncn-w001:~ # kubectl -n services exec -it deployment/cray-dns-powerdns -- sh -c 'pdnsutil list-all-zones | xargs -n1 pdnsutil list-zone | grep iscsi'
_sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net.
_sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net.
_sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net.
iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.4
iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.2
iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.8
iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.14
```

**Using dig command:**

```bash
ncn-w001:~ # dig -t SRV +short _sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net _sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net
1 0 3260 iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.

ncn-w001:~ # dig -t A +short iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
10.253.0.14
10.253.0.8
10.253.0.2
10.253.0.4
```

On a compute node or UAN (iSCSI Initiator) we can observe below error messages in the console log when iSCSI SBPS is booted over NMN

```text
[  139.758355] dracut-pre-mount[2358]: Warning: sbps-init.sh failed.
[  139.772137] dracut-pre-mount[2353]: Warning: Unable to prepare squashfs file /tmp/cps/rootfs, dropping to debug.
//lib/dracut/hooks/emergency/10-cray-dump-dracut-log.sh: line 12: echo: write error: Invalid argumentGenerating "/run/initramfs/rdsosreport.Press Enter for maintenance
(or press Control-D to continue): &.
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
name = "compute-25.3.0-alpha2.x86_64-161rc7"
```

Using the `sessiontemplate` name from the previous command, find the `configuration` name (`ncn#`):

```bash
cray bos sessiontemplates describe compute-25.3.0-alpha2.x86_64-161rc7  --format json
```

Example output:

```json
{
    "cfs": {
        "configuration": "compute-25.3.0-alpha2-161rc7"
    }
}
```

Use the `configuration` value to describe the configuration (`ncn#`):

```bash
cray cfs configurations describe compute-25.3.0-alpha2-161rc7 --format json
```

Example output:

```json
{
    "lastUpdated": "2025-03-12T07:25:18Z",
    "layers": [
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
          "commit": "eaa4ee6948961592b0fa279ae775326ad63eb875",
          "name": "csm-packages-1.6.1-rc.7",
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
1.6.1-rc.7:
  configuration:
    clone_url: https://vcs.cmn.drax.hpc.amslabs.hpecorp.net/vcs/cray/csm-config-management.git
    commit: eaa4ee6948961592b0fa279ae775326ad63eb875
    import_branch: cray/csm/1.28.0
```

The `import_branch` from above output will be used below.

### 3: Log into VCS and clone `csm-config-management.git` @ VCS

Example (`ncn#`):

```bash
USERNAME=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_username | base64 -d  )
PSWD=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_password | base64 -d  )
git clone https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
```

**Note:** use above $USERNAME and $PSWD for VCS login

### 4: Apply workaround from `import_branch` found in `step-2`

Example (`ncn#`):

```bash
cd csm-config-management
git checkout cray/csm/1.28.0
```

Copy scripts `roles/csm.sbps.dns_srv_records/files/sbps_get_host_hsn_nmn.sh` and `roles/csm.sbps.dns_srv_records/files/sbps_dns_srv_records.sh` from this branch 
to any of the worker node followed by executing below commands:

```bash
# chmod +x sbps*
```

```bash
# ./sbps_get_host_hsn_nmn.sh | ./sbps_dns_srv_records.sh
```

### 5: After workaround applied

On any worker node, issue one of the below command to see if we are able to see DNS "SRV" "A" records for NMN too

**Using powerdns command**

```bash
ncn-w001:~ # kubectl -n services exec -it deployment/cray-dns-powerdns -- sh -c 'pdnsutil list-all-zones | xargs -n1 pdnsutil list-zone | grep iscsi'
_sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net.
_sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net.
_sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net.
_sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
_sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net     3600    IN      SRV     1 0 3260 iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net.
iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.4
iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.2
iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.8
iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.253.0.14
iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.252.1.7
iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.252.1.8
iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.252.1.9
iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net    3600    IN      A       10.252.1.10
```

**Using dig command:**

```bash
ncn-w001:~ # dig -t SRV +short _sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net _sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net
1 0 3260 iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.

ncn-w001:~ # dig -t A +short iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
10.253.0.14
10.253.0.8
10.253.0.2
10.253.0.4
10.252.1.8
10.252.1.9
10.252.1.10
10.252.1.7
```

**Note:** After this booting iSCSI SBPS over NMN should succeed
