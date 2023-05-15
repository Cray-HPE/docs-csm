# Deprecated Features

This page lists deprecated features in CSM. They are no longer being actively developed and are planned to be removed in a future CSM release.

When a feature is first deprecated, it may not yet be announced in which CSM version that feature will be fully removed. When such a decision has
been made, that information will be available on this page. For any deprecated features listed on this page that do not yet have an announced CSM
version for their planned removal, customers are still strongly encouraged to make plans to migrate away from the deprecated feature.

* [Removals](#removals)
  * [Removals in CSM 1.5](#removals-in-csm-15)
  * [Removals in CSM 1.6](#removals-in-csm-16)
* [Deprecations](#deprecations)
  * [Deprecated in CSM 1.3](#deprecated-in-csm-13)
  * [Deprecated in CSM 1.2](#deprecated-in-csm-12)
  * [Deprecated in CSM 1.0](#deprecated-in-csm-10)
  * [Deprecated in CSM 0.9.3](#deprecated-in-csm-093)

## Removals

Any features that are being removed in the current or upcoming CSM releases are listed in this section, grouped by the CSM release when they are being removed,
in chronological order.

### Removals in CSM 1.4

* [SLS](../../glossary.md#system-layout-service-sls) support for downloading and uploading credentials in the `dumpstate` and `loadstate` REST APIs

### Removals in CSM 1.5

* [Compute Rolling Upgrade Service (CRUS)](../../glossary.md#compute-rolling-upgrade-service-crus)

### Removals in CSM 1.6

* [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v1

## Deprecations

This section groups the deprecated features by the CSM release in which they were deprecated, in reverse chronological order (the most recently deprecated
features are listed first).

### Deprecated in CSM 1.3

* [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v1
  * BOS v1 will be removed in CSM 1.6.
  * The [Cray CLI](../../glossary.md#cray-cli-cray) changed in CSM 1.4 so that it defaults to BOS v2 when no version is explicitly specified in BOS commands.

### Deprecated in CSM 1.2

* [Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd) v1 REST API
  * The v1 HMNFD APIs are targeted for removal in the CSM 1.5 release.
* [Compute Rolling Upgrade Service (CRUS)](../../glossary.md#compute-rolling-upgrade-service-crus)
  * CRUS will be removed in CSM 1.5.
  * Enhanced [BOS](../../glossary.md#boot-orchestration-service-bos) functionality will replace CRUS. This includes the ability to stage changes to nodes that can be acted upon later when the node reboots.
    It also includes the ability to reboot nodes without specifying any boot artifacts, provided that the artifacts had been previously staged.
* The `--template-body` option for the [BOS](../../glossary.md#boot-orchestration-service-bos) Cray CLI.

### Deprecated in CSM 1.0

* Many [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) v1 features
  * See the [CAPMC Deprecation Notice](CAPMC_Deprecation_Notice.md) for more details.

### Deprecated in CSM 0.9.3

* [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) v1 REST API
