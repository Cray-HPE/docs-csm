# Deprecated Features

This page lists deprecated features in CSM. They are no longer being actively developed and are planned to be removed in a future CSM release.

When a feature is first deprecated, it may not yet be announced in which CSM version that feature will be fully removed. When such a decision has
been made, that information will be available on this page. For any deprecated features listed on this page that do not yet have an announced CSM
version for their planned removal, customers are still strongly encouraged to make plans to migrate away from the deprecated feature.

This page groups the deprecated features by the CSM release in which they were deprecated, in reverse chronological order (the most recently deprecated
features are listed first).

## Deprecated in CSM 1.3

* [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) v1
  * It is likely that even prior to BOS v1 being removed from CSM, the [Cray CLI](../../glossary.md#cray-cli-cray) will change its behavior when no
    version is explicitly specified in BOS commands. Currently it defaults to BOS v1, but it may change to default to BOS v2 even before BOS v1
    is removed from CSM.
* [System Layout Service (SLS)](../../glossary.md#system-layout-service-sls) removed public and private key options from the `loadstate` and `dumpstate` REST API
  * The SLS `loadstate` and `dumpstate` no longer support the option to load or dump credential information. This includes the removal of the `public_key` and
    `private_key` options that were used for encryption and decryption.

## Deprecated in CSM 1.2

* [Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd) v1 REST API
  * The v1 HMNFD APIs are targeted for removal in the CSM 1.6 release.
* [Compute Rolling Upgrade Service (CRUS)](../../glossary.md#compute-rolling-upgrade-service-crus)
  * CRUS is targeted for removal in the CSM 1.6 release.
  * Enhanced BOS functionality will replace CRUS. See [Rolling Upgrades using BOS](../../operations/boot_orchestration/Rolling_Upgrades.md).
* The `--template-body` option for the [BOS](../../glossary.md#boot-orchestration-service-bos) Cray CLI.

## Deprecated in CSM 1.0

* Many [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) v1 features
  * See the [CAPMC Deprecation Notice](CAPMC_Deprecation_Notice.md) for more details.

## Deprecated in CSM 0.9.3

* [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) v1 REST API
