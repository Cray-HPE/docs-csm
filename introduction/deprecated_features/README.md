# Deprecated Features

This page lists deprecated features in CSM. They are no longer being actively developed and are planned to be removed in a future CSM release.

When a feature is first deprecated, it may not yet be announced in which CSM version that feature will be fully removed. When such a decision has
been made, that information will be available on this page. For any deprecated features listed on this page that do not yet have an announced CSM
version for their planned removal, customers are still strongly encouraged to make plans to migrate away from the deprecated feature.

- [Removals](#removals)
    - [Removals in CSM 1.2](#removals-in-csm-12)
    - [Removals in CSM 1.4](#removals-in-csm-14)
    - [Removals in CSM 1.5](#removals-in-csm-15)
    - [Removals in CSM 1.6](#removals-in-csm-16)
    - [Removals in CSM 1.7](#removals-in-csm-17)
- [Deprecations](#deprecations)
    - [Deprecated in CSM 1.7](#deprecated-in-csm-17)
    - [Deprecated in CSM 1.6](#deprecated-in-csm-16)
    - [Deprecated in CSM 1.5](#deprecated-in-csm-15)
    - [Deprecated in CSM 1.4](#deprecated-in-csm-14)
    - [Deprecated in CSM 1.3](#deprecated-in-csm-13)
    - [Deprecated in CSM 1.2](#deprecated-in-csm-12)
    - [Deprecated in CSM 1.0](#deprecated-in-csm-10)
    - [Deprecated in CSM 0.9](#deprecated-in-csm-09)

## Removals

Any features that are being removed in the current or upcoming CSM releases are listed in this section, grouped by the CSM release when they are being removed,
in chronological order.

### Removals in CSM 1.2

- [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) v1

### Removals in CSM 1.4

- [SLS](../../glossary.md#system-layout-service-sls) support for downloading and uploading credentials in the `dumpstate` and `loadstate` REST APIs

### Removals in CSM 1.5

- [Compute Rolling Upgrade Service (CRUS)](../../glossary.md#compute-rolling-upgrade-service-crus)
- Deprecated [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos)
  v1 session template and boot set fields are no longer stored in BOS.
    - When upgrading to CSM 1.5, these fields are automatically removed from all BOS session
      templates that contain them.
    - When creating BOS v1 session templates in CSM 1.5, these fields are automatically removed.
    - For more information, see
      [Deprecated fields](../../operations/boot_orchestration/Session_Templates.md#deprecated-fields).

### Removals in CSM 1.6

- [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v1
- User Access Service
- User Access Instance

### Removals in CSM 1.7

- Support for projecting root filesystems and PE images using the [Content Projection Service (CPS)](../../glossary.md#content-projection-service-cps) and the
  [Data Virtualization Service (DVS)](../../glossary.md#data-virtualization-service-dvs)
    - This projection is now done using the Scalable Boot Projection Service
- Top-level Ansible playbooks `ncn-master.yaml`, `ncn-storage.yaml`, and `ncn-worker.yaml` in `csm-config-management` repository in the
  [Version Control Service (VCS)](../../glossary.md#version-control-service-vcs).
    - These have been replaced by the unified `ncn_nodes.yaml` top-level playbook.
- Experimental `disable_components_on_completion` [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos)
  [option](../../operations/boot_orchestration/Options.md).
- Some sub-commands of the [Cray Site Init (CSI)](../../glossary.md#cray-site-init-csi) tool are removed.
    - `csi config load` (no longer used and had outdated/unmaintained structures)
    - `csi pit get` (no longer used and was causing problems with the lint workflow and circular dependencies)

## Deprecations

This section groups the deprecated features by the CSM release in which they were deprecated, in reverse chronological order (the most recently deprecated
features are listed first).

### Deprecated in CSM 1.7

- Some parts of the [Cray Site Init (CSI)](../../glossary.md#cray-site-init-csi) tool are deprecated in CSM 1.7.0.
    - Several `csi config init` flags are deprecated by flags added in CSM 1.7:
        - `cmn-cidr` (Deprecated by `cmn-cidr4`)
        - `cmn-gateway` (Deprecated by `cmn-gateway4`)
        - `chn-cidr` (Deprecated by `chn-cidr4`)
        - `chn-gateway` (Deprecated by `chn-gateway4`)
    - Several `csi patch` sub-commands are deprecated by sub-commands added in CSM 1.7:
        - `csi patch ca` (Deprecated by `csi patch init ca`)
        - `csi patch packages` (Deprecated by `csi patch init packages`)

### Deprecated in CSM 1.6

- The `sat swap cable` and `sat swap switch` commands are deprecated.
- Support for projecting root filesystems and PE images using the [Content Projection Service (CPS)](../../glossary.md#content-projection-service-cps) and the
  [Data Virtualization Service (DVS)](../../glossary.md#data-virtualization-service-dvs)
    - This projection should instead be done using the Scalable Boot Projection Service

### Deprecated in CSM 1.5

- Remaining [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) v3 features
    - CAPMC may be removed in the future. It is replaced with the [Power Control Service (PCS)](../../glossary.md#power-control-service-pcs).
      Everyone is encouraged to transition to PCS as soon as possible.
    - See the [CAPMC Deprecation Notice](CAPMC_Deprecation_Notice.md) for more details.

### Deprecated in CSM 1.4

- Top-level Ansible playbooks `ncn-master.yaml`, `ncn-storage.yaml`, and `ncn-worker.yaml` in `csm-config-management` repository in the
  [Version Control Service (VCS)](../../glossary.md#version-control-service-vcs).
    - These are replaced by the unified `ncn_nodes.yaml` top-level playbook.
    - The deprecated playbooks are removed in CSM 1.7.

### Deprecated in CSM 1.3

- [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v1
    - BOS v1 is removed in CSM 1.6.
    - The [Cray CLI](../../glossary.md#cray-cli-cray) changes in CSM 1.4 so that it defaults to BOS v2 when no version is explicitly specified in BOS commands.

### Deprecated in CSM 1.2

- [Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd) v1 REST API
- [Compute Rolling Upgrade Service (CRUS)](../../glossary.md#compute-rolling-upgrade-service-crus)
    - CRUS is removed in CSM 1.5.
    - Enhanced [BOS](../../glossary.md#boot-orchestration-service-bos) functionality replaces CRUS.
        - This includes the ability to stage changes to nodes that can be acted upon later when the node reboots.
        - It also includes the ability to reboot nodes without specifying any boot artifacts,
          provided that the artifacts have been previously staged.
- The `--template-body` option for the [BOS](../../glossary.md#boot-orchestration-service-bos) Cray CLI.

### Deprecated in CSM 1.0

- Many [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) v3 features
    - See the [CAPMC Deprecation Notice](CAPMC_Deprecation_Notice.md) for more details.

### Deprecated in CSM 0.9

- [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) v1 REST API (in CSM 0.9.3)
- [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) v1
    - In CSM 0.9, CFS v2 is the default for the [Cray CLI](../../glossary.md#cray-cli-cray)
