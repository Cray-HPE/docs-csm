# Known Issues with Rack Resiliency

## Issue: `cray-rrs` Pod is in `Init` State

### Description

When rack resiliency is disabled, the `cray-rrs` deployment remains in the `Init` state. This behavior is expected under certain conditions.

### Observed Behavior

1. The `cray-rrs` pod shows the following status:

   ```bash
   kubectl get po -n rack-resiliency
   ```
   Example Output:
   
   ```text
   NAME                        READY   STATUS     RESTARTS   AGE
   cray-rrs-6c5585cfdf-lmctt   0/2     Init:0/2   0          6d5h
   ```

2. Logs from the `cray-rrs-check` container indicate that rack resiliency is disabled:

    ```bash
    kubectl logs -n rack-resiliency cray-rrs-6c5585cfdf-lmctt cray-rrs-check
    ```

    ```text
    /etc/ssh/sshd_config line 32: Unsupported option UsePAM
    2025-09-18 22:06:22,589 - INFO in wait: Checking Rack Resiliency enablement and Kubernetes/CEPH zone creation...
    2025-09-18 22:06:22,815 - INFO in wait: 'spec.kubernetes.services.rack-resiliency.enabled' value in customizations.yaml is: False
    2025-09-18 22:06:22,817 - INFO in wait: Rack Resiliency is disabled.
    ```

## Root Cause

The cray-rrs deployment enters the Init state when the following conditions are not met:

1. Rack Resiliency is not enabled
2. [Zones](../../operations/rack_resiliency/Zones.md) are not configured(Kubernetes or Ceph)
3. [ConfigMaps](../../operations/rack_resiliency/ConfigMaps.md) not present

For more information related to troubleshooting for Rack Resiliency refer to [Rack Resiliency Troubleshooting](../../operations/rack_resiliency/Troubleshooting.md)