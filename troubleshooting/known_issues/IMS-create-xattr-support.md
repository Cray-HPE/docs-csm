## IMS create job missing extended attributes support

## Problem

On CSM 1.6 systems building USS 1.3.6 images, the IMS kiwi-ng image create job fails during RPM installation with:

```text
[ DEBUG ]: 22:11:59 | system: error: unpacking of archive failed on file /usr/lib/sssd/sssd_pam;6a02542e: cpio: cap_set_file failed - No such file or directory
```

The failure occurs when installing the `sssd-2.10.2-150600.3.41.1` RPM from the
`SUSE-SLE-Product-SLES-15-SP6-LTSS-x86_64-Updates` repository. The COS 25.3.6 base recipe did not include
the LTSS repo, and when it is manually added it to obtain the MUNGE security fix (`CVE-2026-25506`), the
image build broke.

## Root Cause

The IMS image build environment mounts the build filesystem via `virtiofs` (`none /mnt/image virtiofs rw,relatime 0 0`).
The `sssd` RPM in the LTSS repository uses **extended attributes (`xattr`)** for file capabilities. By default,
the `kata` containers `hypervisor` does not pass `xattr` support to the `virtiofs` mount, causing `cap_set_file` to fail
when `cpio` attempts to set file capabilities during RPM unpacking.

The `cray-configmap-ims-v2-image-customize` `configmap` has the necessary annotation:

```yaml
annotations:
  io.katacontainers.config.hypervisor.virtio_fs_extra_args: '["-o", "xattr"]'
```

However, the `cray-configmap-ims-v2-image-create-kiwi-ng` `configmap` is missing this annotation,
meaning the initial image creation step (where kiwi-ng installs base RPMs) has no `xattr` support.

This inconsistency was never caught in testing because HPE's internal systems had the MUNGE fix
applied from a separate repository that did not use `xattr-dependent` RPMs.

## Resolution

**Immediate workaround (manual):**

1. Edit the `cray-configmap-ims-v2-image-create-kiwi-ng` `configmap` to add the `xattr` annotation:

```bash
kubectl -n services edit configmap cray-configmap-ims-v2-image-create-kiwi-ng
```

Add under `template.metadata`

```yaml
      template:
        metadata:
          annotations:
            io.katacontainers.config.hypervisor.virtio_fs_extra_args: '["-o", "xattr"]'
          labels:
            app: ims-$id-create
```

1. Configure the LTSS repo for image customization in `vars/uan_repos.yaml` in the `uss-config-management` VCS repo:

```yaml
uan_sles_repositories:
  - name: SUSE-SLE-Product-SLES-15-SP6-LTSS-x86_64-Updates
    description: SUSE-SLE-Product-SLES-15-SP6-LTSS-x86_64-Updates
    repo: "https://packages.local/repository/SUSE-SLE-Product-SLES-15-SP6-LTSS-x86_64-Updates"
```

**Note:** This step is required until the USS fix to include LTSS repo in the base image recipe which will be delivered
in USS 1.3.7. This step can be skipped if USS 1.3.7 or higher version is installed.

1. Restart the IMS pod to pick up the `configmap` change

```bash
kubectl -n services rollout restart deployment cray-ims
```
