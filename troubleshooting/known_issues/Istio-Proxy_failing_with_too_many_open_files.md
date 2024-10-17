# Istio-Proxy failing with too many open files

## Issue Description

After the CSM upgrade, some nodes with `Istio` might not have come up with the new `Istio-proxy` image due to too many open files so they need increased `fs.inotify.max_user_instances` and `fs.inotify.max_user_watches` values.
When pods with `istio-proxy` restart (such as after a power outage or node reboot), they may fail due to insufficient `inotify` resources, as the limits on the system are too low.

### Related Issue

- [Istio Issue #35829](https://github.com/istio/istio/issues/35829)

## Error Identification

When the issue occurs the following errors are emitted in the `istio-proxy` logs.

```sh
2024-07-22T17:00:37.322350Z info Workload SDS socket not found. Starting Istio SDS Server
2024-07-22T17:00:37.322393Z info CA Endpoint istiod.istio-system.svc:15012, provider Citadel
2024-07-22T17:00:37.322395Z info Opening status port 15020
2024-07-22T17:00:37.322436Z info Using CA istiod.istio-system.svc:15012 cert with certs: var/run/secrets/istio/root-cert.pem
2024-07-22T17:00:37.323487Z error failed to start SDS server: failed to start workload secret manager too many open files
Error: failed to start SDS server: failed to start workload secret manager too many open files
```

## Error Conditions

This issue manifests when:

- Pods are unable to create enough `inotify` instances to monitor required files.
- The system hits the maximum number of file watches, causing crashes or failures in services dependent on file system event monitoring.

This problem can be triggered by events like:

- A node dying and rebooting mid-upgrade.
- Power outages where pods restart on nodes with old kernel settings.

## Fix Description

Manually increase the `fs.inotify.max_user_instances` and `fs.inotify.max_user_watches` values to provide sufficient resources for Istio and other Kubernetes components.

```bash
pdsh -w ncn-m00[1-3],ncn-w00[1-5] 'sysctl -w fs.inotify.max_user_instances=1024'
pdsh -w ncn-m00[1-3],ncn-w00[1-5] 'sysctl -w user.max_inotify_instances=1024'
pdsh -w ncn-m00[1-3],ncn-w00[1-5] 'sysctl -w fs.inotify.max_user_watches=1048576'
pdsh -w ncn-m00[1-3],ncn-w00[1-5] 'sysctl -w user.max_inotify_watches=1048576'
```
