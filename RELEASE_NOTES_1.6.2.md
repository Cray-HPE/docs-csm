# Cray System Management (CSM) 1.6.2 Release Notes

This page documents the changes introduced by this patch, compared to the previous patch
version of CSM.

For the main CSM 1.6 release notes page, including links to other patch release notes,
see [CSM 1.6 release notes](RELEASE_NOTES.md).

* [Additions and improvements](#additions-and-improvements)
* [Bug fixes](#bug-fixes)
* [Known issues](#known-issues)

## Additions and improvements

### General

* [Configuration Framework Service (CFS)](glossary.md#configuration-framework-service-cfs): Add bulk component update option to [Cray CLI](glossary.md#cray-cli-cray)
    * For more information, see [Managing many components](operations/configuration_management/CFS_Commands_Cheat_Sheet.md#managing-many-components)

### Security

* Fixed CVEs in [the `cmsdev` test tool](troubleshooting/known_issues/sms_health_check.md), `cray-console-node`, and `cray-console-operator`

### Test

* Add CFS node personalization to the [Barebones Image Boot Test](troubleshooting/cms_barebones_image_boot.md)
* Added fix to prevent false positives in the [Hardware State Manager (SMD)](glossary.md#hardware-state-manager-smd) CT tests when components are in the `DiscoveryStarted` state when the tests are launched

## Bug fixes

* Fixes to the [Boot Script Service (BSS)](glossary.md#boot-script-service-bss) and `cfs-trust` to allow large scale parallel boots of compute nodes
* Fix bug preventing [CFS batcher](operations/configuration_management/Automatic_Configuration_Management.md#cfs-batcher-scheduling)
  from starting sessions on very large scale systems
* [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos): Gracefully handle requests to validate session templates which do not exist
* Fixes for several concurrency issues in [Redfish Translation Service (RTS)](glossary.md#redfish-translation-service-rts) that will reduce the number of pod restarts

## Known issues

* After updating Paradise [BMC](glossary.md#baseboard-management-controller-bmc) firmware, the `hmcollector-poll` service will lose event subscriptions and must be restarted
    * See [Updating Foxconn Paradise Nodes with FAS](operations/firmware/FAS_Paradise.md) for details on how to do this
* `cfs-api` pods in CLBO state during CSM install.
    * When installing CSM 1.6, `cray-shared-kafka-kafka-` pods in the services namespace fail to come up which results in `cfs-api` pods in CLBO state.
    * A workaround is presented in [CFS API pods in CLBO](troubleshooting/known_issues/cfs-api_pods_in_CLBO_state.md).
* `istio-proxy` containers fail with too many open files.
    * This may happen when any pod with `istio injection` enabled is started.
    * A workaround is presented in [Istio-Proxy failing with too many open files](troubleshooting/known_issues/Istio-Proxy_failing_with_too_many_open_files.md)
* [Install and Upgrade Framework (IUF)](glossary.md#install-and-upgrade-framework-iuf) does not run the next stage for an activity
    * During CSM upgrade, IUF reports that multiple sessions are in progress for an activity.
    * A workaround is presented in [IUF does not run the next stage for an activity](troubleshooting/known_issues/iuf_unable_to_run_next_stage.md)
* iSCSI based boot content projection may fail if the image to be projected does not have an `etag`
    * A workaround is presented in [iSCSI SBPS boot failure](troubleshooting/known_issues/SBPS_boot_fail.md)
* [CSM Automatic Network Utility (CANU)](glossary.md#csm-automatic-network-utility-canu) 1.8.0 and later is known to cause a brief
  [Node Management Network (NMN)](glossary.md#node-management-network-nmn) network outage.
    * CANU 1.8.0 and later introduce a separation of administrative traffic and user traffic on the management network
      via addition of a new VRF and OSPF area. Until all switches are updated and new routes are propagated, there is a
      brief NMN network outage. IP addressing does not change, but NMN traffic will flow over a new isolated VRF
      channel. The length of the outage is dependent on the time to apply new switch configurations to all management
      network switches - OSPF will propagate routes within seconds. As this affects liquid-cooled Mountain cabinets,
      running jobs may be affected. A dedicated outage window is highly recommended for applying these changes.
* [System Monitoring Application (SMA)](glossary.md#system-monitoring-application-sma) 1.10.15 and later includes an upgraded LDMS that introduces an incompatibility with
  configuration files used in prior versions.
    * When upgrading from an older SMA version to a version with this new LDMS, the administrator must change the configuration files.
    * A workaround is presented as an Action in the deliver-product stage in the **IUF Stage Details for SMA** section of the *HPE Cray Supercomputing EX System Monitoring Application Installation Guide*.
* Services that use PostgreSQL may fail when a Kubernetes master node is rebooted or rebuilt.
    * A PostgreSQL database may fail over without clients reconnecting to the new cluster leader.
    * A workaround is presented in [PostgreSQL Database is in Recovery](troubleshooting/known_issues/postgres_database_recovery.md)

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).
