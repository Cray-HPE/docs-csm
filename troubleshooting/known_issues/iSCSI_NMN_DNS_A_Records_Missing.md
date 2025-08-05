# iSCSI NMN DNS A Records Missing

## Description

The [Scalable Boot Projection Service (SBPS)](../../glossary.md#scalable-boot-projection-service-sbps)
supports iSCSI-based boot content projection for `rootfs` and `PE` images in CSM version CSM 1.6.0 and
later.

In CSM 1.6, there is a bug that may cause DNS "A" records for the NMN not to be created. iSCSI SBPS
projection over NMN will fail if DNS "A" (address) records for the NMN are not created. This bug is
fixed in CSM 1.7.0.

## Symptom

This issue can be identified by the following symptoms:

On any worker node, use one of the following commands to observe that the DNS "SRV" "A" records are missing for NMN

### Using `powerdns` command

```bash
kubectl -n services exec -it deployment/cray-dns-powerdns -- sh -c 'pdnsutil list-all-zones | xargs -n1 pdnsutil list-zone | grep iscsi'
```

Example output:

```text
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

### Using `dig` command

```bash
dig -t SRV +short _sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net _sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net
```

Example output:

```text
1 0 3260 iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
```

```bash
dig -t A +short iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
```

Example output:

```text
10.253.0.14
10.253.0.8
10.253.0.2
10.253.0.4
```

On a compute node or UAN (iSCSI initiator), these error messages may appear on the console when iSCSI SBPS is booted over the NMN.

```text
[  139.758355] dracut-pre-mount[2358]: Warning: sbps-init.sh failed.
[  139.772137] dracut-pre-mount[2353]: Warning: Unable to prepare squashfs file /tmp/cps/rootfs, dropping to debug.
//lib/dracut/hooks/emergency/10-cray-dump-dracut-log.sh: line 12: echo: write error: Invalid argumentGenerating "/run/initramfs/rdsosreport.Press Enter for maintenance
(or press Control-D to continue): &.
```

## Workaround

### 1. Get `csm-packages` version

(`ncn-mw#`) Get the version of the `csm-packages` Ansible layer.

1. Find the compute node BOS session template name.

    ```bash
    cray bos sessiontemplates list | grep compute-*
    ```

    Example output:

    ```toml
    name = "compute-25.3.0-alpha2.x86_64-161rc7"
    ```

1. Find the CFS configuration associated with that BOS session template.

    > In the following command, substitute the actual template name found in the previous step.

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

1. Describe the CFS configuration identified in the previous step.

    > In the following command, substitute the actual configuration name found in the previous step.

    ```bash
    cray cfs configurations describe compute-25.3.0-alpha2-161rc7 --format json | grep csm-packages-
    ```

    Example output:

    ```text
              "name": "csm-packages-1.6.1-rc.7",
    ```

Use the version after `csm-packages-` in the next step.

### 2. Identify VCS branch

(`ncn-mw#`) In the Cray Product Catalog, get the `import_branch` name associated with the CSM version string from the last step.

> In the following command, substitute the actual version found in the previous step.

```bash
kubectl get cm -n services cray-product-catalog -o yaml | yq - r 'data.csm' | grep ^1.6.1-rc.7: -A 10
```

Example output:

```yaml
1.6.1-rc.7:
  configuration:
    clone_url: https://vcs.cmn.drax.hpc.amslabs.hpecorp.net/vcs/cray/csm-config-management.git
    commit: eaa4ee6948961592b0fa279ae775326ad63eb875
    import_branch: cray/csm/1.28.0
```

The `import_branch` from this output will be used below.

### 3. Apply workaround

(`ncn-mw#`) Clone the CSM VCS git repository and apply the workaround.

1. Clone `csm-config-management.git`.

    ```bash
    GITUSER=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_username | base64 -d  )
    GITPASS=$( kubectl get secrets -n services vcs-user-credentials -o json | jq -r .data.vcs_password | base64 -d  )
    git clone https://$GITUSER:$GITPASS@api-gw-service-nmn.local/vcs/cray/csm-config-management.git
    ```

1. Check out the `import_branch` identified in the previous section.

    > In the following command, substitute the actual branch name found in the previous section.

    ```bash
    cd csm-config-management
    git checkout cray/csm/1.28.0
    ```

1. Copy scripts to any worker node and execute them.

    This example uses `ncn-w001`, but any worker may be used.

    ```bash
    scp roles/csm.sbps.dns_srv_records/files/sbps_get_host_hsn_nmn.sh \
        roles/csm.sbps.dns_srv_records/files/sbps_dns_srv_records.sh ncn-w001:/tmp \
    && ssh ncn-w001 'chmod +x /tmp/sbps_get_host_hsn_nmn.sh /tmp/sbps_dns_srv_records.sh && /tmp/sbps_get_host_hsn_nmn.sh | /tmp/sbps_dns_srv_records.sh'
    ```

### 4: Validate workaround

(`ncn-w#`) On any worker node, issue one of the following commands to verify that the DNS "SRV" "A" records for the NMN are shown.

#### Using `powerdns` command after workaround

```bash
kubectl -n services exec -it deployment/cray-dns-powerdns -- sh -c 'pdnsutil list-all-zones | xargs -n1 pdnsutil list-zone | grep iscsi'
```

Example output:

```text
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

#### Using `dig` command after workaround

```bash
dig -t SRV +short _sbps-hsn._tcp.drax.hpc.amslabs.hpecorp.net _sbps-nmn._tcp.drax.hpc.amslabs.hpecorp.net
```

Example output:

```text
1 0 3260 iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net.
1 0 3260 iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
```

```bash
dig -t A +short iscsi-server-id-004.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.hsn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-002.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-003.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-004.nmn.drax.hpc.amslabs.hpecorp.net. iscsi-server-id-001.nmn.drax.hpc.amslabs.hpecorp.net.
```

Example output:

```text
10.253.0.14
10.253.0.8
10.253.0.2
10.253.0.4
10.252.1.8
10.252.1.9
10.252.1.10
10.252.1.7
```

### 5: Workaround complete

Booting iSCSI SBPS over the NMN should now succeed.
