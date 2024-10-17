# Deprecated Features

This page lists deprecated features in CSM. They are no longer being actively developed and are planned to be removed in a future CSM release.

When a feature is first deprecated, it may not yet be announced in which CSM version that feature will be fully removed. When such a decision has
been made, that information will be available on this page. For any deprecated features listed on this page that do not yet have an announced CSM
version for their planned removal, customers are still strongly encouraged to make plans to migrate away from the deprecated feature.

- [Removals](#removals)
    - [Removals in CSM 1.4](#removals-in-csm-14)
    - [Removals in CSM 1.5](#removals-in-csm-15)
    - [Removals in CSM 1.6](#removals-in-csm-16)
- [Deprecations](#deprecations)
    - [Deprecated in CSM 1.5](#deprecated-in-csm-15)
    - [Deprecated in CSM 1.3](#deprecated-in-csm-13)
    - [Deprecated in CSM 1.2](#deprecated-in-csm-12)
    - [Deprecated in CSM 1.0](#deprecated-in-csm-10)
    - [Deprecated in CSM 0.9.3](#deprecated-in-csm-093)

## Removals

Any features that are being removed in the current or upcoming CSM releases are listed in this section, grouped by the CSM release when they are being removed,
in chronological order.

### Removals in CSM 1.4

- [SLS](../../glossary.md#system-layout-service-sls) support for downloading and uploading credentials in the `dumpstate` and `loadstate` REST APIs

### Removals in CSM 1.5

- [Compute Rolling Upgrade Service (CRUS)](../../glossary.md#compute-rolling-upgrade-service-crus)
- Deprecated [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos)
  v1 session template and boot set fields are no longer stored in BOS.
    - This applied to the following deprecated BOS v1 session template fields: `cfs_branch`, `cfs_url`, `partition`
    - This applied to the following deprecated BOS v1 boot set fields: `boot_ordinal`, `network`, `shutdown_ordinal`
    - When upgrading to CSM 1.5, these fields were automatically removed from all BOS session
      templates that contain them.
    - When creating BOS v1 session templates in CSM 1.5, these fields were automatically removed.

### Removals in CSM 1.6

- [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v1
    - When upgrading to CSM 1.6, all BOS v1 session data is deleted. See [BOS data notice](../../upgrade/README.md#bos-data-notice)
      for more details.
- [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
  is deprecated, starting in CSM 1.5, and may be removed in the future. It has been
  replaced with the [Power Control Service (PCS)](../../glossary.md#power-control-service-pcs).
  Everyone is encouraged to transition to PCS as soon as possible.
- User Access Service
- User Access Instance

## Deprecations

This section groups the deprecated features by the CSM release in which they were deprecated, in reverse chronological order (the most recently deprecated
features are listed first).

### Deprecated in CSM 1.5

- Remaining [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) v3 features
    - See the [CAPMC Deprecation Notice](CAPMC_Deprecation_Notice.md) for more details.

### Deprecated in CSM 1.3

- [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v1
    - BOS v1 is removed in CSM 1.6.
    - The [Cray CLI](../../glossary.md#cray-cli-cray) changed in CSM 1.4 so that it defaults to BOS v2 when no version is explicitly specified in BOS commands.

### Deprecated in CSM 1.2

- [Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd) v1 REST API
    - The v1 HMNFD APIs are targeted for removal in the CSM 1.5 release.
- [Compute Rolling Upgrade Service (CRUS)](../../glossary.md#compute-rolling-upgrade-service-crus)
    - CRUS was removed in CSM 1.5.
    - Enhanced [BOS](../../glossary.md#boot-orchestration-service-bos) functionality replaces CRUS. This includes the ability to stage changes to nodes that can be acted upon later when the node reboots.
    It also includes the ability to reboot nodes without specifying any boot artifacts, provided that the artifacts had been previously staged.
- The `--template-body` option for the [BOS](../../glossary.md#boot-orchestration-service-bos) Cray CLI.

### Deprecated in CSM 1.0

- Many [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) v1 features
    - See the [CAPMC Deprecation Notice](CAPMC_Deprecation_Notice.md) for more details.

### Deprecated in CSM 0.9.3

- [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) v1 REST API
