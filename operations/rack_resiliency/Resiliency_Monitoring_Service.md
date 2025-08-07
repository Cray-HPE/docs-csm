# Resiliency Monitoring Service (RMS)

- [Overview](#overview)
- [Operation](#operation)
    - [Control loop](#control-loop)
    - [Monitoring events](#monitoring-events)
    - [Timing](#timing)
- [ConfigMaps](#configmaps)
- [Log messages](#log-messages)

## Overview

The Resiliency Monitoring Service (RMS) is a part of the
[Rack Resiliency Service (RRS)](Rack_Resiliency_Service.md).
RMS runs along with the [RR API service](../../api/rrs.md) inside the `cray-rrs` pod.

The RMS continuously monitors the health and availability of critical services,
management nodes, and Ceph utility storage. The RMS uses the following components to
provide its functionality:

- [ConfigMaps](#configmaps)
- [Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd)
- [Kubernetes zones](Zones.md#command-to-view-Kubernetes-zones)
- [Ceph zones](Zones.md#command-to-view-Ceph-zones)

## Operation

RMS operates using two primary flows: the [Control loop](#control-loop) and the
[Monitoring events](#monitoring-events).

### Control loop

This loop ensures that the monitoring infrastructure is properly initialized and maintained.
It performs the following tasks:

- Starts the internal application server to receive notifications from HMNFD.
- Verifies and maintains active subscriptions to HMNFD.
- Periodically performs an update procedure, when no active [Monitoring events](#monitoring-events)
  are in progress. By default this happens every 10 minutes. This procedure entails the following steps:
    1. Read in the latest data from the [ConfigMaps](#configmaps)
    1. Scans to determine the current status of critical services and zones (Kubernetes and Ceph).
    1. Updates the [ConfigMaps](#configmaps) if the scan found any changes.

### Monitoring events

Triggered upon receiving a notification from HMNFD, this loop performs targeted analysis and
response actions. These actions include:

- Reading in the latest data from the [ConfigMaps](#configmaps).
- Determining whether the failure is isolated to a single node or is part of a rack-level failure.
- Monitoring placement and availability of management nodes (master, worker, and storage NCNs).
- Monitoring the health and status of critical services, and logging alerts if any imbalance is
  detected following a failure.
- Updating the [ConfigMaps](#configmaps) if the previous checks found any changes.

### Timing

When the RMS receives a notification from HMNFD, that will immediately trigger an RMS
[Monitoring event](#monitoring-events). Because the monitoring event is not instantaneous,
there may be a short delay before the results of the event are reflected in the Rack Resiliency API
and CLI responses.

Some incidents on a system do not result in HMNFD notifications. For example, a change in the
health of a critical service pod. Because these incidents do not trigger a monitoring event,
there will be a longer delay before the RMS notices them; it may take up to 10 minutes for such
changes to be reflected in the Rack Resiliency API and CLI responses.

The same delay is a factor when an administrator makes changes to the critical services
list (see [Manage Critical Services](#manage-critical-services)). It may take up to 10 minutes
before the RMS reads in the updated critical services data.

## ConfigMaps

RMS reads the [static ConfigMap (`rrs-mon-static`)](ConfigMaps.md#1-static-configmap) in order to
get the list of critical services to monitor.
RMS updates the [dynamic ConfigMap (`rrs-mon-dynamic`)](ConfigMaps.md#2-dynamic-configmap) at
regular intervals to reflect the latest status and balance of critical services, as well as the
latest zone information.

For more details on the Rack Resiliency ConfigMaps, see [ConfigMaps](ConfigMaps.md).

## Log messages

RMS emits log messages at different severities during the monitoring cycle.

For example:

| *Log level* | *Source file* | *Example message content*                                                                    |
| ----------- | ------------- | -------------------------------------------------------------------------------------------- |
| `INFO`      | `lib_rms`     | Ceph is healthy                                                                              |
| `WARNING`   | `rms`         | List of component xnames changed to `Standby` state                                          |
| `ERROR`     | `rms`         | Failed to retrieve data from the [Hardware State Manager (HSM)](#hardware-state-manager-hsm) |
| `WARNING`   | `lib_rms`     | List of imbalanced services                                                                  |
| `WARNING`   | `lib_rms`     | List of unconfigured services                                                                |
| `WARNING`   | `lib_rms`     | Ceph host (e.g. `ncn-s003`) is in `Offline` state                                            |

For details on troubleshooting RMS, including details on how to view and interpret the RMS logs,
see the [Resiliency Monitoring Service](#resiliency-monitoring-service-rms) section of the
[Troubleshooting](Troubleshooting.md) document.
