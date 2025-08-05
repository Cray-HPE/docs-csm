# Resiliency Monitoring Service(RMS)

The Resiliency Monitoring Service(RMS) is a part of the [Rack Resiliency Service(RRS)](Rack_Resiliency_Service.md) which runs along with [API service](../../api/rrs.md) inside `cray-rrs` pod.

## RMS overview

The Resiliency Monitoring Service (RMS) continuously monitors the health and availability of CSM critical services and management nodes along with utility storage(ceph). The RMS uses the following components to provide its functionality:
- [ConfigMaps](ConfigMaps.md)
- [Hardware Management Notification Fanout Daemon (HMNFD)](../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd)
- [Kubernetes Zones](Zones.md#command-to-view-kubernetes-zones)
- [Ceph Zones](Zones.md#command-to-view-ceph-zones)

RMS operates using two primary loops:

### 1. RMS control loop

This loop ensures the monitoring infrastructure is properly initialized and maintained. It performs the following tasks:

* Starts the internal application server to receive notifications from HMNFD.
* Verifies and maintains active subscriptions to HMNFD.
* Periodically updates the status of critical services and zones(kubernetes and ceph) when no active monitoring events are in progress.

### 2. RMS monitoring loop

Triggered upon receiving a notification from HMNFD, this loop performs targeted analysis and response actions, including:

* Determining whether the failure is isolated to a single node or part of a rack-level failure.
* Monitors the health and status of critical services, and logs alerts if any imbalance is detected following a failure.
* Verifying placement and availability of management nodes, including both Kubernetes control plane and Ceph storage nodes.

**Note:** Any modifications to critical services may take up to 10 minutes to reflect in CLI command outputs and to appear in the monitored list.

## RMS and ConfigMaps

RMS reads the [static configmap(rrs-mon-static)](ConfigMaps.md#11-static-configmap) for getting  the list of critical services to monitor. It updates the [dynamic configmap(rrs-mon-dynamic)](ConfigMaps.md#12-dynamic-configmap) at regu;ar intervals to reflect the latest status and balance of critical services along with the zones information.

## RMS Messages

RMS emits log messages at different severities during the monitoring cycle.
For example:
- INFO in lib_rms - CEPH is healthy
- WARNING in rms - Components '['x3000c0s5b0n0', 'x3000c0s2b0n0']' are changed to Standby state.
- ERROR in rms - Failed to retrieve HSM data
- WARNING in lib_rms - list of imbalanced services are - ['istiod']
- WARNING in lib_rms - list of unconfigured services are - ['cilium-operator', 'cray-dvs-mqtt-ss', 'kyverno-cleanup-controller']
- WARNING in lib_rms - Host ncn-s003 is in - Offline state

For troubleshooting the messages logged by RMS refer to [troubleshooting section](Troubleshooting.md).
